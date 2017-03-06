require 'json'
require 'rdf/ntriples'
require 'rdf/rdfxml'
require 'rof/rdf_context'
require 'rdf/isomorphic'
require 'active_support/core_ext/array/wrap'

module ROF
 class CompareRof

    # Compare two ROF objects; we'll call one fedora_rof and the other bendo_rof
    # @return 0 if no errors; otherwise there are errors
    def self.fedora_vs_bendo(fedora_rof, bendo_rof, _output = nil, options = {})
      new(Array.wrap(fedora_rof)[0], Array.wrap(bendo_rof)[0], options).error_count
    end

    def initialize(fedora, bendo, options = {})
      @fedora = Array.wrap(fedora).first
      @bendo = Array.wrap(bendo).first
      @skip_rels_ext_context = options.fetch(:skip_rels_ext_context) { false }
    end
    attr_reader :fedora, :bendo

    def error_count
      @error_count = 0
      @error_count += compare_rights
      @error_count += compare_rels_ext
      @error_count += compare_metadata
      @error_count += compare_everything_else
      @error_count
    end

    # do rights comparison
    # return 0 if the same, >0 if different
    def compare_rights

      error_count =0

      # Use same comparison scheme on all rights
      [ 'read' , 'read-groups', 'edit', 'edit-groups', 'edit-users', 'embargo-date'].each do |attribute|
        error_count += rights_equal(attribute)
        break if error_count != 0
      end

      error_count
    end

    private

    # compare array or element for equivalence
    def rights_equal(rights_attr)
      f_rights = Array.wrap(fedora.fetch('rights', {}).fetch(rights_attr, [])).sort
      b_rights = Array.wrap(bendo.fetch('rights', {}).fetch(rights_attr, [])).sort

      return 0 if f_rights == b_rights
      1
    end

    public

    # convert RELS-EXT sections to RDF::graph and compater w/ rdf-isomorphic
    def compare_rels_ext
      error_count = 0
      # Because Sipity's RELS-EXT context was out of whack, I need a switch to skip comparing
      # the @context of the rels-ext document
      bendo_rdf = jsonld_to_rdf(bendo.fetch('rels-ext', {}), ROF::RelsExtRefContext, @skip_rels_ext_context)
      fedora_rdf = jsonld_to_rdf(fedora.fetch('rels-ext', {}), ROF::RelsExtRefContext, @skip_rels_ext_context)
      error_count +=1 if ! bendo_rdf.isomorphic_with? fedora_rdf
      error_count
    end

    private

    def jsonld_to_rdf(doc, default_context, skip_context = false)
      if skip_context
        doc.delete('@context')
      else
        doc["@context"] ||= default_context
      end
      RDF::Graph.new << JSON::LD::API.toRdf(doc)
    end

    public

    # convert metadata sections to RDF::graph and compater w/ rdf-isomorphic
    def compare_metadata
      error_count = 0
      bendo_rdf = jsonld_to_rdf(bendo.fetch('metadata', {}), ROF::RdfContext)
      fedora_rdf = jsonld_to_rdf(fedora.fetch('metadata', {}), ROF::RdfContext)
      error_count +=1 if ! bendo_rdf.isomorphic_with? fedora_rdf
      error_count
    end

    # compare what remains
    def compare_everything_else
      error_count =0
      exclude_keys = ['rights', 'rels-ext', 'metadata', 'thumbnail-file']
      all_keys_to_check = (bendo.keys + fedora.keys - exclude_keys).uniq
      all_keys_to_check.each do |key|
        bendo_value = bendo.fetch(key, nil)
        fedora_value = fedora.fetch(key, nil)
        next if Array.wrap(bendo_value) == Array.wrap(fedora_value)
        error_count += 1
        break
      end
      error_count
    end
  end
end
