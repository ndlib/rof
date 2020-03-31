# frozen_string_literal: true

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

      class AccessMappingNotFound < RuntimeError
      end

      # @param options [Hash]
      # @option options [String, nil] :prefix - if truthy, prepend "<prefix>:" to each identifier
      # @option options [Array, nil] :id_list - circumvent using the :noids configuration and instead use these for next_ids
      # @option options [Hash] :noids - A Hash with keys :noid_server and :pool_name; Responsible for minting next_ids
      # @raise NoPool if we don't have a means of determining the next_id
      def initialize(options = {})
        prefix = options.fetch(:prefix, nil)
        @id_list =  if options[:id_list]
                      options[:id_list]
                    elsif options[:noids]
                      NoidsPool.new(options[:noids].fetch(:noid_server), options[:noids].fetch(:pool_name))
                    else
                      raise NoPool
                    end
        @prefix = "#{prefix}:" if prefix
        # The first match group in the RE provides the label name
        @label_re = /\$\(([^)]+)\)/
      end

      # mutate rec_list by assigning labels and resolving labels where needed
      # Every fobject will be assigned an pid and a bendo_item
      def process(rec_list)
        labels = {}

        # Use two passes. First assign ids, and then resolve labels
        # Do this since labels can be referenced before being defined

        # Assign pids to each fobject. If we find any labels in the pid field, then
        # record a mapping of label => pid into the labels hash.
        # Take first item's pid as the default bendo id.
        default_bendo_item = nil
        rec_list.each do |rec|
          assign_pid(rec, labels)
          default_bendo_item = rec.find_first('pid') if default_bendo_item.nil?
        end

        # now replace any reference labels with the pids we've assigned them
        rec_list.each do |rec|
          rec.add_if_missing('bendo-item', default_bendo_item)
          replace_labels_in_record(rec, labels)
        end

        rec_list
      end

      # assign pids, recording any labels we find.
      # obj is mutated
      def assign_pid(rec, labels)
        return if rec.find_first('rof-type') != 'fobject'

        label = nil
        pid = rec.find_first('pid')
        unless pid.nil?
          label = parse_label(pid)
          # skip if the "pid" is not a label
          return if label.nil?
        end
        pid = "#{@prefix}#{next_id}"
        rec.set('pid', pid)
        labels[label] = pid unless label.nil?
      end

      # replace any label references we find in obj.
      # obj is mutated
      def replace_labels_in_record(rec, labels)
        return if rec.find_first('rof-type') != 'fobject'

        rec.update! do |k, v|
          # This used to "force" labels in rels-ext. maybe that can be moved
          # to a validation rule to make sure everything in rels-ext is a pid?
          [k, v.map { |vv| replace_match(vv, labels, false) }]
        end
      end

      # look for any labels in s and replace them with their resolution as
      # given in `labels`. If the flag `force` is true, an MissingLabel
      # exception will be raised if a found label is not in `labels`.
      # Returns the new string.
      def replace_match(s, labels, force)
        s.gsub(@label_re) do |match|
          pid = labels[Regexp.last_match(1)]
          raise MissingLabel if pid.nil? && force

          pid || match
        end
      end

      def parse_label(s)
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
