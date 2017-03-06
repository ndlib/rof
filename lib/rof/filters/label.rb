require 'rof/filter'
require 'noids_client'

module ROF
  module Filters
    # Class Label locates in-place labels of the form
    # "$(label_name)" in the ROF file, assigns each
    # label a pid, then replaces the label with that pid.
    class Label < ROF::Filter
      class MissingLabel < RuntimeError
      end

      class NoPool < RuntimeError
      end

      class OutOfIdentifiers < RuntimeError
      end

      # Create a new label assigner and resolver. The source of identifiers
      # is given using options.
      # Use :noid_server and :pool_name to connect to an external noid server.
      # Use :id_list to pass in a ruby object responding to #shift and #empty? to generate
      # ids. This is usually a list, to facilitate testing.
      #
      # If prefix is not nil, then "#{prefix}:" is prepended to
      # every identifier.
      def initialize(options = {})
        prefix = options.fetch(:prefix, nil)
        @id_list =  case
                    when options[:id_list]
                      options[:id_list]
                    when options[:noid_server]
                      NoidsPool.new(options[:noid_server], options.fetch(:pool_name))
                    else
                      raise NoPool
                    end
        @prefix = "#{prefix}:" if prefix
        # The first match group in the RE provides the label name
        @label_re = /\$\(([^)]+)\)/
      end

      # mutate obj_list by assigning labels and resolving labels where needed
      # Every fobject will be assigned an pid and a bendo_item
      def process(obj_list)
        labels = {}

        # Use two passes. First assign ids, and then resolve labels
        # Do this since labels can be referenced before being defined

        # Assign pids to each fobject. If we find any labels in the pid field, then
        # record a mapping of label => pid into the labels hash.
        obj_list.each do |obj|
          assign_pid(obj, labels)
        end

        # now replace any reference labels with the pids we've assigned them
        obj_list.each do |obj|
          replace_labels_in_obj(obj, labels)
        end

        # now assign bendo ids
        bendo_item = nil
        obj_list.each do |obj|
          # for now we just use the first item's pid stripped of any namespaces as the bendo item id
          if bendo_item.nil?
            bendo_item = obj['pid'].gsub(/^.*:/, '') unless obj['pid'].nil?
            next if bendo_item.nil?
          end
          # don't touch if a bendo item has already been assigned
          obj['bendo-item'] = bendo_item if obj['bendo-item'].nil? || obj['bendo-item'] == ''
        end

        obj_list
      end

      # assign pids, recording any labels we find.
      # obj is mutated
      def assign_pid(obj, labels)
        return if obj['type'] != 'fobject'

        label = nil
        unless obj['pid'].nil?
          label = find_label(obj['pid'])
          # skip if the "pid" is not a label
          return if label.nil?
        end
        pid = "#{@prefix}#{next_id}"
        obj['pid'] = pid
        labels[label] = pid unless label.nil?
      end

      # replace any label references we find in obj.
      # obj is mutated
      def replace_labels_in_obj(obj, labels)
        return if obj['type'] != 'fobject'
        obj.each do |k, v|
          # only force labels to exist if we are looking in the rels-ext
          obj[k] = replace_labels(v, labels, k == 'rels-ext')
        end
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
          obj.each { |k, v| obj[k] = replace_labels(v, labels, force) }
          obj
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

      def find_label(s)
        s[@label_re, 1]
      end

      def next_id
        raise OutOfIdentifiers if @id_list.empty?
        @id_list.shift
      end

      # Encapsulates connection to Noids Server
      class NoidsPool
        def initialize(noids_server_url, pool_name)
          @pool = NoidsClient::Connection.new(noids_server_url).get_pool(pool_name)
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
