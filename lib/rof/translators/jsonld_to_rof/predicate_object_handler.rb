require 'rdf'
require 'rof/translators/jsonld_to_rof/predicate_handler'

module ROF
  module Translators
    module JsonldToRof
      # We need to handle the Predicate / Object pair as one (thank you RDF blank nodes for this nuance)
      #
      # @see ROF::Translators::JsonldToRof::PredicateObjectHandler.call
      module PredicateObjectHandler
        # @api public
        #
        # Parse the RDF::Predicate, RDF::Object and the relevant data to the contents to the accumulator
        #
        # @example
        #   Given the following 4 RDF N-Triples (subject, predicate, object). The first and second RDF objects are RDF::Literal. The 3rd triple's object is
        #   and RDF::Node. And the last is an RDF::URI. Each require different handlers as they have nuanced differences.
        #     _:b0 <http://purl.org/dc/terms/contributor> "David R.Hyde" .
        #     _:b0 <http://www.ndltd.org/standards/metadata/etdms/1.1/role> "Research Director" .
        #     <https://curate.nd.edu/show/zk51vd69n1r> <http://purl.org/dc/terms/contributor> _:b0 .
        #     <https://curate.nd.edu/show/zk51vd69n1r> <http://projecthydra.org/ns/relations#hasEditorGroup> <https://curate.nd.edu/show/q524jm23g92> .
        #
        # @note It is assumed that all blank nodes (e.g. RDF::Node) will be processed before you process any RDF::URI nodes.
        #
        # @param [RDF::Predicate] predicate - the RDF predicate that we will parse and add to the appropriate spot in the accumulator
        # @param [RDF::Object] object - the RDF object that we will parse and add to the appropriate spot in the accumulator
        # @param [ROF::Translators::JsonldToRof::Accumulator] accumulator - a data accumulator that will be changed in place
        # @return [ROF::Translators::JsonldToRof::Accumulator] the given accumulator
        # @raise [ROF::Translators::JsonldToRof::UnknownRdfObjectTypeError] when the RDF::Object's subject is not a valid type
        def self.call(predicate, object, accumulator, options = {})
          case object
          when RDF::URI, RDF::Literal
            PredicateHandler.call(predicate, object, accumulator, options[:blank_node])
          when RDF::Node
            blank_node = accumulator.fetch_blank_node(object)
            blank_node.each_pair do |blank_node_predicate, blank_node_objects|
              blank_node_objects.each do |blank_node_object|
                PredicateObjectHandler.call(blank_node_predicate, blank_node_object, accumulator, blank_node: object)
              end
            end
          else
            raise UnknownRdfObjectTypeError, "Unable to determine object handler for #{object.inspect}"
          end
          accumulator
        end

        class UnknownRdfObjectTypeError < RuntimeError
        end
      end
    end
  end
end
