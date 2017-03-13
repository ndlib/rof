require 'active_support/core_ext/array/wrap'

module ROF
  module Translators
    module JsonldToRof
      # Responsible for dealing with registered predicates and how those are handled.
      module PredicateHandler
        class UnhandledPredicateError < RuntimeError
          def initialize(predicate, urls)
            super(%(Unable to handle predicate "#{predicate}". The following predicate URLs were registered #{urls.inspect}))
          end
        end

        # @api public
        #
        # Parse the RDF predicate and RDF object and add it's contents to the accumulator
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
        # @param [RDF::Predicate] predicate - the RDF predicate that we will parse and add to the appropriate spot in the accumulator
        # @param [RDF::Object] object - the RDF object that we will parse and add to the appropriate spot in the accumulator
        # @param [ROF::Translators::JsonldToRof::Accumulator] accumulator - a data accumulator that will be changed in place
        # @return [ROF::Translators::JsonldToRof::Accumulator] the given accumulator
        # @raise [ROF::Translators::JsonldToRof::UnhandledPredicateError] when we are unable to handle the given predicate
        def self.call(predicate, object, accumulator)
          handler = registry.handler_for(predicate)
          handler.handle(object, accumulator)
          accumulator
        end

        # @api public
        # @param [String] url - The URL that we want to match against
        # @yield The block to configure how we handle RDF Predicates that match the gvien URL
        # @yieldparam [ROF::JsonldToRof::PredicateHandler::UrlHandler]
        # @see ./spec/lib/rof/translators/jsonld_to_rof/predicate_handler_spec.rb for details and usage usage
        def self.register(url, &block)
          registry << UrlHandler.new(url, &block)
        end

        # @api private
        def self.registry
          @registry ||= RegistrySet.new
        end
        private_class_method :registry

        def self.clear_registry!(set_with = RegistrySet.new)
          @registry = set_with
        end
        private_class_method :clear_registry!

        class RegistrySet
          def initialize
            @set = []
          end

          def <<(value)
            @set << value
          end

          def handler_for(predicate)
            location_extractor = nil
            @set.each do |handler|
              location_extractor = handler.location_extractor_for(predicate)
              break if location_extractor
            end
            raise UnhandledPredicateError.new(predicate, @set.map(&:url)) if location_extractor.nil?
            location_extractor
          end
        end
        private_constant :RegistrySet

        # For a given URL map all of the predicates; Some predicates require explicit mapping, while others
        # may use implicit mapping.
        class UrlHandler
          def initialize(url)
            @url = url
            @within = []
            @namespace_prefix = ''
            @slug_handlers = {}
            yield(self) if block_given?
          end
          attr_reader :url

          # The final key in the location array should be prefixed with the namespace_prefix; By default this is ""
          def namespace_prefix(prefix = nil)
            return @namespace_prefix if prefix.nil?
            @namespace_prefix = prefix
          end

          # Prepend the within array to the location array
          def within(location = nil)
            return @within if location.nil?
            @within = Array.wrap(location)
          end

          # @param [#to_s] predicate
          # @return [nil, LocationExtractor] if the given predicate does not match the url, return nil; Otherwise return a LocationExtractor
          # @see LocationExtractor
          def location_extractor_for(predicate)
            return nil unless predicate.to_s =~ %r{^#{Regexp.escape(@url)}(.*)}
            slug = $1
            handlers = handlers_for(slug)
            LocationExtractor.new(predicate, handlers)
          end

          private

          # @param [String] slug - a slug that may or may not have been registered
          # @return [Array<#call>] an array of handlers that each respond to #call
          # @see ImplicitLocationHandler
          # @see ExplicitLocationSlugHandler
          # @see BlockSlugHandler
          def handlers_for(slug)
            Array.wrap(@slug_handlers.fetch(slug) { ImplicitLocationHandler.new(self, slug) })
          end

          public

          # @param [String] slug =
          # @param [Hash] options (with symbol keys)
          # @option options [Boolean] :force - don't apply the within nor namespace prefix
          # @option options [Array] :to - an array that will be nested Hash keys
          # @yield If a block is given, call the block (and skip all other configuration)
          # @yieldparam [String] object
          # @see BlockSlugHandler for details concerning a mapping via a block
          # @see ExplicitLocationSlugHandler for details concerning a mapping via a to: option
          def map(slug, options = {}, &block)
            @slug_handlers ||= {}
            @slug_handlers[slug] ||= []
            if block_given?
              @slug_handlers[slug] << BlockSlugHandler.new(self, slug, options, block)
            else
              @slug_handlers[slug] << ExplicitLocationSlugHandler.new(self, slug, options)
            end
          end

          # Responsible for coordinating the extraction of the
          class LocationExtractor
            def initialize(predicate, handlers)
              @predicate = predicate
              @handlers = Array.wrap(handlers)
            end

            def handle(object, accumulator)
              @handlers.each do |handler|
                handler.call(object, accumulator)
              end
              accumulator
            end
          end

          class ImplicitLocationHandler
            def initialize(url_handler, slug)
              @url_handler = url_handler
              @slug = slug
            end
            attr_reader :slug
            def call(object, accumulator)
              to = @url_handler.within + Array.wrap(slug)
              to[-1] = "#{@url_handler.namespace_prefix}#{to[-1]}"
              accumulator.add_predicate_location_and_value(to, object)
            end
          end
          private_constant :ImplicitLocationHandler

          class BlockSlugHandler
            def initialize(url_handler, slug, options, block)
              @url_handler = url_handler
              @slug = slug
              @options = options
              @block = block
            end
            attr_reader :slug

            def call(object, accumulator)
              @block.call(object, accumulator)
            end
          end
          private_constant :BlockSlugHandler

          class ExplicitLocationSlugHandler
            def initialize(url_handler, slug, options)
              @url_handler = url_handler
              @slug = slug
              @options = options
            end
            attr_reader :slug

            def call(object, accumulator)
              to = @options.fetch(:to)
              unless force?
                to = @url_handler.within + Array.wrap(to)
                to[-1] = "#{@url_handler.namespace_prefix}#{to[-1]}"
              end
              accumulator.add_predicate_location_and_value(to, object)
            end

            def force?
              @options.fetch(:force, false)
            end
          end
          private_constant :ExplicitLocationSlugHandler
        end
        private_constant :UrlHandler
      end
    end
  end
end
