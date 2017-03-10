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
        end

        # @api public
        # @return [Hash]
        def to_rof
          rof = @rof.deep_dup
          append_properties_to(rof)
          rof
        end

        private

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
        # @return [Array] location, value
        def add_predicate_location_and_value(location, value)
          location = Array.wrap(location)
          if location == ['pid']
            return add_pid(value)
          end
          data = @rof
          while slug = location.shift
            if location.empty?
              data[slug] ||= []
              data[slug] << coerce_object_to_string(value)
            else
              data[slug] ||= {}
              data = data[slug]
            end
          end
          [location, value]
        end

        private

        def coerce_object_to_string(object)
          return object if object.nil?
          if object.to_s =~ %r{https?://curate.nd.edu/show/([^\\]+)/?}
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
