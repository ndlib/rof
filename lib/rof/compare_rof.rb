require 'json'
require 'rdf/ntriples'
require 'rdf/rdfxml'
require 'rof/rdf_context'
require 'rdf/isomorphic'

module ROF
 class CompareRof

    # compare fedora rof to bendo_rof
    # return true in equivalent, false if not
    def self.fedora_vs_bendo( fedora_rof, bendo_rof, output)

      error_count = 0
      # dereferencing an array of one element with [0]. Oh, the horror of it.
      error_count += compare_rights( fedora_rof[0], bendo_rof[0], output)
      error_count += compare_rels_ext(fedora_rof[0], bendo_rof[0])
      error_count += compare_metadata(fedora_rof[0], bendo_rof[0])
      error_count += compare_everything_else(fedora_rof[0], bendo_rof[0], output)
      error_count
    end

    # do rights comparison
    # return 0 if the same, >0 if different
    def self.compare_rights( fedora_rof, bendo_rof, output )

      error_count =0

      # Use same comparison scheme on all rights
      [ 'read' , 'read-groups', 'edit', 'edit-groups', 'edit-users', 'embargo-date'].each do |attribute|
        error_count += rights_equal(attribute, fedora_rof, bendo_rof)
        break if error_count != 0
      end

      error_count
    end

    # compare array or element for equivalence
    def self.rights_equal(rights_attr, fedora, bendo)
      f_rights = fedora.fetch('rights', {}).fetch(rights_attr, [])
      b_rights = bendo.fetch('rights', {}).fetch(rights_attr, [])

      f_rights = f_rights.sort if f_rights.respond_to?(:"sort")
      b_rights = b_rights.sort if b_rights.respond_to?(:"sort")

      return 0 if f_rights == b_rights
      1
    end

    # convert RELS-EXT sections to RDF::graph and compater w/ rdf-isomorphic
    def self.compare_rels_ext(fedora, bendo)
      error_count = 0
      bendo_rdf = jsonld_to_rdf(bendo['rels-ext'], ROF::RelsExtRefContext)
      fedora_rdf = jsonld_to_rdf(fedora['rels-ext'], ROF::RelsExtRefContext)
      error_count +=1 if ! bendo_rdf.isomorphic_with? fedora_rdf
      error_count
    end
    
    def self.jsonld_to_rdf(doc, default_context)
      doc["@context"] = default_context unless doc.has_key?("@context")
      RDF::Graph.new << JSON::LD::API.toRdf(doc)
    end

    # convert metadata sections to RDF::graph and compater w/ rdf-isomorphic
    def self.compare_metadata(fedora, bendo)
      error_count = 0
      bendo_rdf = jsonld_to_rdf(bendo['metadata'], ROF::RdfContext)
      fedora_rdf = jsonld_to_rdf(fedora['metadata'], ROF::RdfContext)
      error_count +=1 if ! bendo_rdf.isomorphic_with? fedora_rdf
      error_count
    end

    # compare what remains
    def self.compare_everything_else( fedora, bendo, output)
      error_count =0
      fedora = remove_others(fedora)
      bendo = remove_others(bendo)
      # comparsion using builtin equivalency operation
      error_count = 1 if bendo != fedora
      error_count
    end

    # remove elements we've dealt with already
    def self.remove_others( rof_object)
      rof_object.delete('rights')
      rof_object.delete('rels-ext')
      rof_object.delete('metadata')
      rof_object.delete('thumbnail-file')
      rof_object
    end
  end
end
