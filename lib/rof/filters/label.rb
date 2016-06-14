require 'noids_client'

module ROF
  module Filters
    # Class Label locates in-place labels of the form
    # "$(label)_name)" in the ROF file, assigns each
    # label a pid, then replaces the label with that pid.
    class Label
      class MissingLabel < RuntimeError
      end

      class NoPool < RuntimeError
      end

      class OutOfIdentifiers < RuntimeError
      end

      # if not nil, "#{prefix}:" is prepended to every identifier
      # either pass in options for :noid_server, :pool_name
      # or pass in :id_list, a list of identifiers
      # to use (responds to :shift method)
      def initialize(prefix, options)
        @id_list = if options[:id_list]
                     options[:id_list]
                   elsif options[:noid_server]
                     NoidsPool.new(options[:noid_server], options[:pool_name])
                   else
                     raise NoPool
                   end
        @prefix = "#{prefix}:" if prefix
        # The first match group in the RE provides the label name
        @label_re = /\$\(([^)]+)\)/
      end

      # mutate obj_list by assigning labels and resolving labels where needed
      def process(obj_list)
        labels = {}
        master_pid = nil

        # Use two passes. First assign ids, and then resolve labels
        # Do this since labels can be referenced before being defined
        obj_list.each do |obj|
          next if obj['type'] != 'fobject'
          label = nil
          unless obj['pid'].nil?
            label = find_label(obj['pid'])
            next if label.nil?
          end
          pid = "#{@prefix}#{next_id}"
          obj['pid'] = pid
          labels[label] = pid unless label.nil?
        end

        # Handle rels-ext
        obj_list.each do |obj|
          next if obj['type'] != 'fobject'
          next if obj['rels-ext'].nil?
          next if obj['rels-ext']['isMemberOf'].nil?
          obj['rels-ext']['isMemberOf'].each_with_index do |parent_pid, _index|
            label = nil
            label = find_label(parent_pid) unless parent_pid.nil?
            pid = "#{@prefix}#{next_id}"
            labels[label] = pid unless label.nil?
          end
        end

        obj_list.each do |obj|
          next if obj['type'] != 'fobject'
          obj.each do |k, v|
            obj[k] = if k == 'rels-ext'
                       replace_labels(v, labels, true)
                     else
                       replace_labels(v, labels, false)
                     end
          end
          master_pid = obj['pid'].gsub(/^.*:/, '') if master_pid.nil?
          obj = add_bendo_id(obj, master_pid)
        end

        obj_list
      end

      # recurse through obj replacing any labels in strings
      # with the id in labels, which is a hash.
      # The relacement is done in place.
      # Hash keys are not touched (only hash values).
      # if force is true, labels which don't resolve will raise
      # a MissingLabel error.
      def replace_labels(obj, labels, force = false)
        if obj.is_a?(Array)
          obj.map! { |x| replace_labels(x, labels, force) }
        elsif obj.is_a?(Hash)
          obj.each do |k, v|
            obj[k] = replace_labels(v, labels, force)
          end
        elsif obj.is_a?(String)
          replace_match(obj, labels, force)
        else
          obj
        end
      end

      # small matching function- uses regular expression
      def replace_match(obj, labels, force)
        obj.gsub(@label_re) do |match|
          pid = labels[Regexp.last_match(1)]
          raise MissingLabel if pid.nil? && force
          pid.nil? ? match : pid
        end
      end

      # If object contains empty bendo-item key, assign
      # it id of provided  pid stripped of prefix
      def add_bendo_id(obj, bid)
        obj['bendo-item'] = bid if !obj['bendo-item'] || obj['bendo-item'] == ''

        obj
      end

      def find_label(s)
        s[@label_re, 1]
      end

      def next_id
        raise OutOfIdentifiers if @id_list.empty?
        @id_list.shift
      end

      # Encapsulates connection to Noids Server
      class NoidsPool
        def initialize(noids_server, pool_name)
          @pool = NoidsClient::Connection.new(noids_server).get_pool(pool_name)
        end

        def shift
          @pool.mint.first
        end

        def empty?
          @pool.closed?
        end
      end
    end
  end
end
