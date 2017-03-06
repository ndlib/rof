require 'rof/translators/jsonld_to_rof/predicate_object_handler'

module ROF
  module Translators
    module JsonldToRof
      # Responsible for parsing an RDF statement and adding to the accumulator.
      module StatementHandler
        # @api public
        #
        # Parse the RDF statement and add it's contents to the accumulator
        #
        # @example
        #   Given the following 4 RDF N-Triples (subject, predicate, object). The first two, with subject "_:b0" represent blank nodes.
        #   The last one with subject "<https://curate.nd.edu/show/zk51vd69n1r>" has an object that points to the "_:b0" blank node.
        #     _:b0 <http://purl.org/dc/terms/contributor> "David R.Hyde" .
        #     _:b0 <http://www.ndltd.org/standards/metadata/etdms/1.1/role> "Research Director" .
        #     <https://curate.nd.edu/show/zk51vd69n1r> <http://purl.org/dc/terms/contributor> _:b0 .
        #     <https://curate.nd.edu/show/zk51vd69n1r> <http://projecthydra.org/ns/relations#hasEditorGroup> <https://curate.nd.edu/show/q524jm23g92> .
        #   For the first two N-Triples you would get a BlankNodeHandler; For the last two, you would get a UriSubjectHandler
        #
        # @note It is assumed that all blank nodes (e.g. RDF::Node) will be processed before you process any RDF::URI nodes.
        #
        # @param [RDF::Statement] statement - the RDF statement that we will parse and add to the appropriate spot in the accumulator
        # @param [ROF::Translators::JsonldToRof::Accumulator] accumulator - a data accumulator that will be changed in place
        # @return [ROF::Translators::JsonldToRof::Accumulator] the given accumulator
        # @raise [ROF::Translators::JsonldToRof::UnhandledRdfSubjectError] when the RDF::Statement's subject is not a valid type
        def self.call(statement, accumulator)
          new(statement, accumulator).call
          accumulator
        end

        class UnhandledRdfSubjectError < RuntimeError
        end

        # @api private
        def self.new(statement, accumulator)
          case statement.subject
          when RDF::URI
            UriSubjectHandler.new(statement, accumulator)
          when RDF::Node
            BlankNodeHandler.new(statement, accumulator)
          else
            raise UnhandledRdfSubjectError, "Unable to determine subject handler for #{statement.inspect}"
          end
        end

        # Responsible for accumulating the ROF data for a URI based resource
        class UriSubjectHandler
          def initialize(statement, accumulator)
            @accumulator = accumulator
            @statement = statement
          end

          def call
            handle_subject
            handle_predicate_and_object
            @accumulator
          end

          private

          def handle_predicate_and_object
            PredicateObjectHandler.call(@statement.predicate, @statement.object, @accumulator)
          end

          def handle_subject
            return nil unless @statement.subject.to_s =~ %r{https://curate.nd.edu/show/([^\\]+)/?}
            pid = "und:#{$1}"
            @accumulator.add_pid(pid)
          end
        end
        private_constant :UriSubjectHandler

        # Responsible for handling blank nodes in the RDF graph; Examples include ETD degree information
        # Blank node subjects behave different from UriSubjectHandler
        class BlankNodeHandler
          def initialize(statement, accumulator)
            @accumulator = accumulator
            @statement = statement
          end

          def call
            @accumulator.add_blank_node(@statement)
            @accumulator
          end
        end
        private_constant :BlankNodeHandler
      end
    end
  end
end
