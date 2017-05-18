require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/deep_dup'

module ROF
  module Translators
    module JsonldToRof
      # @api pubilc
      # The accumulator is a "passive" object. Things happen to it. All in the name of building the
      # hash that is ROF.
      #
      # @note The accumulator is only for one PID. See [ROF::Translators::JsonldToRof::Accumulator#add_pid]
      class Accumulator
        # @param [Hash] initial_rof - The base ROF document to which we will be adding elements.
        def initialize(initial_rof = {})
          @rof = initial_rof
          @blank_nodes = {}
          @blank_node_locations = {}
        end

        # @api public
        # @return [Hash]
        def to_rof
          rof = @rof.deep_dup
          expand_blank_node_locations!(rof)
          rof = append_properties_to(rof)
          rof = force_cardinality_for_backwards_compatability(rof)
          rof
        end

        private

        # The antics of the blank node! See the specs for blank nodes to see the expected behavior.
        def expand_blank_node_locations!(rof)
          @blank_node_locations.each_pair do |node, locations|
            locations.each_pair do |location, key_value_pairs|
              data = rof
              location[0..-2].each do |slug|
                data[slug] ||= {}
                data = data[slug]
              end

              # We may encounter a shallow map, if so we need for it to behave differently
              slug = location[-1]
              if slug
                data[slug] ||= []
                hash = {}
              else
                hash = data
              end
              Array.wrap(key_value_pairs).each do |key_value|
                key_value.each_pair do |key, value|
                  hash[key] ||= []
                  hash[key] += Array.wrap(value)
                end
              end
              data[slug] << hash if slug
            end
          end
        end

        def append_properties_to(rof)
          return rof unless @properties
          rof['properties-meta'] = { "mime-type" => "text/xml" }
          xml = '<fields>'
          @properties.each do |node_name, object|
            xml += "<#{node_name}>#{object}</#{node_name}>"
          end
          xml += '</fields>'
          rof['properties'] = xml
          rof
        end

        class TooManyElementsError < RuntimeError
          def initialize(context, expected_count, got_count)
            super(%(Expected #{expected_count} in "#{context}" but instead got #{got_count}))
          end
        end

        def force_cardinality_for_backwards_compatability(rof)
          rof = force_rights_cardinality(rof)
          rof = force_bendo_cardinality(rof)
          rof
        end

        def force_rights_cardinality(rof)
          rights = rof.fetch('rights', {})
          if rights.key?('embargo-date')
            embargo_dates = Array.wrap(rights['embargo-date'])
            raise TooManyElementsError.new('rights > embargo-date', 1, embargo_dates.size) if embargo_dates.size > 1
            rof['rights']['embargo-date'] = embargo_dates.first
          end
          rof
        end

        def force_bendo_cardinality(rof)
          if rof.key?('bendo-item')
            bendo_items = Array.wrap(rof['bendo-item'])
            raise TooManyElementsError.new('bendo-item', 1, bendo_items.size) if bendo_items.size > 1
            rof['bendo-item'] = bendo_items.first
          end
          rof
        end

        public

        # @api public
        # @param [String] node_name - the XML node's name (e.g. <node_name>node_value</node_name>)
        # @param [String] node_value - the XML element's value
        # @return [Array] of given node_name and node_value
        def register_properties(node_name, node_value)
          @properties ||= []
          @properties << [node_name, coerce_object_to_string(node_value)]
          [node_name, node_value]
        end

        class PidAlreadySetError < RuntimeError
        end

        # @api public
        # @param [RDF::Statement] statement
        # @return [RDF::Statement]
        def add_blank_node(statement)
          @blank_nodes[statement.subject] ||= {}
          @blank_nodes[statement.subject][statement.predicate] ||= []
          @blank_nodes[statement.subject][statement.predicate] << statement.object
          statement
        end

        # @api public
        # @param [RDF::Subject] subject - Fetch the corresponding blank node that was added
        # @return [RDF::Statement]
        # @raise [KeyError] when the subject has not previosly been added
        # @see #add_blank_node
        def fetch_blank_node(subject)
          @blank_nodes.fetch(subject)
        end

        # @api public
        # @param [String] pid - an identifier
        # @return [String] pid
        # @raise PidAlreadySetError - if you attempted to a different PID
        def add_pid(pid)
          pid = coerce_object_to_string(pid)
          if @rof.key?('pid')
            if @rof['pid'] != pid
              raise PidAlreadySetError, "Attempted to set pid=#{pid}, but it is already set to #{@rof['pid']}"
            end
          else
            @rof['pid'] = pid
          end
          pid
        end

        # @api public
        # @param [Array<String>, String] location - a list of nested hash keys (or a single string)
        # @param [String] value - a translated value for the original RDF Statement
        # @param [false, RDF::Node] blank_node
        # @return [Array] location, value
        def add_predicate_location_and_value(location, value, blank_node = false)
          # Because I am making transformation on the location via #shift method, I need a duplication.
          location = Array.wrap(location)
          if location == ['pid']
            return add_pid(value)
          end
          if blank_node
            add_predicate_location_and_value_direct_for_blank_node(location, value, blank_node)
          else
            add_predicate_location_and_value_direct_for_non_blank_node(location, value)
          end
          [location, value]
        end

        def add_predicate_location_and_value_direct_for_blank_node(location, value, blank_node)
          fetch_blank_node(blank_node) # Ensure the node exists
          @blank_node_locations[blank_node] ||= {}
          @blank_node_locations[blank_node][location[0..-2]] ||= []
          @blank_node_locations[blank_node][location[0..-2]] << { location[-1] => Array.wrap(coerce_object_to_string(value)) }
        end

        def add_predicate_location_and_value_direct_for_non_blank_node(location, value)
          data = @rof
          location[0..-2].each do |slug|
            data[slug] ||= {}
            data = data[slug]
          end
          slug = location[-1]
          data[slug] ||= []
          data[slug] << coerce_object_to_string(value)
        end

        private

        def coerce_object_to_string(object)
          return object if object.nil?
          if object.to_s =~ ROF::Translators::JsonldToRof::REGEXP_FOR_A_CURATE_RDF_SUBJECT
            return "und:#{$1}"
          elsif object.respond_to?(:value)
            return object.value
          else
            object
          end
        end
      end
    end
  end
end
