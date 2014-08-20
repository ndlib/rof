require 'noids_client'

module ROF
  module Filters
    class Label
      class MissingLabel < RuntimeError
      end

      class NoPool < RuntimeError
      end

      class OutOfIdentifiers < RuntimeError
      end

      # if not nil, "#{prefix}:" is prepended to every identifier
      # either pass in options for :noid_server, :pool_name
      # or pass in :id_list, a list of identifiers to use (responds to :shift method)
      def initialize(prefix, options)
        @id_list = case
        when options[:id_list]
          options[:id_list]
        when options[:noid_server]
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

        # Use two passes. First assign ids, and then resolve labels
        # Do this since labels can be referenced before being defined
        obj_list.each do |obj|
          next if obj["type"] != "fobject"
          label = nil
          if ! obj["pid"].nil?
            label = find_label(obj["pid"])
            next if label.nil?
          end
          pid = "#{@prefix}#{next_id}"
          obj["pid"] = pid
          labels[label] = pid if ! label.nil?
        end

        obj_list.each do |obj|
          next if obj["type"] != "fobject" || obj["rels-ext"].nil?
          obj["rels-ext"].each do |k,v|
            v.map! do |id|
              label = find_label(id)
              if ! label.nil?
                pid = labels[label]
                raise MissingLabel if pid.nil?
              end
              label.nil? ? id : pid
            end
          end
        end

        obj_list
      end

      def find_label(s)
        s[@label_re, 1]
      end

      def next_id
        raise OutOfIdentifiers if @id_list.empty?
        @id_list.shift
      end

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
