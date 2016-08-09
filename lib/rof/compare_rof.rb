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
     error_count += compare_rights( fedora_rof, bendo_rof, output)
     error_count += compare_rels_ext(fedora_rof, bendo_rof, output)
     error_count += compare_metadata(fedora_rof, bendo_rof, output)
     error_count += compare_everything_else(fedora_rof, bendo_rof, output)
     error_count
   end

    # do rights comparison
    def self.compare_rights( fedora_rof, bendo_rof, output )

      error_count =0
     
      # Use same comparison scheme on all rights
      [ 'read' , 'read-groups', 'edit', 'edit-groups', 'edit-users', 'embargo-date'].each { |attribute|
        exist_count = rights_exist(attribute, fedora_rof[0], bendo_rof[0])
	return 1 if exist_count == 1
	error_count += rights_equal(attribute, fedora_rof[0], bendo_rof[0]) if exist_count == 2
      }

      error_count
    end

    # returns 2 is rights attribute exists in both fedora and bendo, 0 if in neither, 1 otherwise 
    def self.rights_exist(rights_attr, fedora, bendo)
      exist_count = 0
      exist_count += 1 if fedora['rights'].has_key?(rights_attr)
      exist_count += 1 if bendo['rights'].has_key?(rights_attr)
      exist_count
    end

    # compare array or element for equivalence
    def self.rights_equal(rights_attr, fedora, bendo)
      error_count = 0

      # this should always be an array, except for embargo-date
      if bendo['rights'][rights_attr].respond_to?('sort')
        error_count +=1 if bendo['rights'][rights_attr].sort.to_s != fedora['rights'][rights_attr].sort.to_s 
      else
        error_count +=1 if bendo['rights'][rights_attr].to_s != fedora['rights'][rights_attr].to_s 
      end

      error_count
    end

    # convert RELS-EXT sections to RDF::graph and compater w/ rdf-isomorphic
    def self.compare_rels_ext( fedora, bendo, output)
      error_count =0
      bendo[0]['rels-ext']['@context'] = ROF::RelsExtRefContext.dup
      bendo_rdf = RDF::Graph.new << JSON::LD::API.toRdf(bendo[0]['rels-ext'])
      fedora_rdf = RDF::Graph.new << JSON::LD::API.toRdf(fedora[0]['rels-ext'])
      error_count +=1 if ! bendo_rdf.isomorphic_with? fedora_rdf
      error_count
    end
    
    # convert metadata sections to RDF::graph and compater w/ rdf-isomorphic
    def self.compare_metadata( fedora, bendo, output)
      error_count =0
      bendo[0]['metadata']['@context'] = ROF::RdfContext.dup
      bendo_rdf = RDF::Graph.new << JSON::LD::API.toRdf(bendo[0]['metadata'])
      fedora_rdf = RDF::Graph.new << JSON::LD::API.toRdf(fedora[0]['metadata'])
      error_count +=1 if ! bendo_rdf.isomorphic_with? fedora_rdf
      error_count
    end

    #
    def self.compare_everything_else( fedora, bendo, output)
      error_count =0
      fedora = remove_others(fedora)
      bendo = remove_others(bendo)
      bendo = sort_recurse( bendo )
      fedora = sort_recurse( fedora )
      error_count +=1 if fedora.to_s != bendo.to_s
      error_count
    end

    # recursive sort through hashes and arrays
    def self.sort_recurse( item )
      if item.is_a?(Hash)
	item.each do | key, value |
          item[ key] = sort_recurse( item[ key] )
	end
        return Hash[item.sort]
      elsif item.is_a?(Array)
	item.each do | idx, value |
          item[ idx] = sort_recurse( item[ idx] )
	end
	return item.sort
      else
        return item
      end
    end

    #
    def self.remove_others( list)
      list[0].delete('rights')
      list[0].delete('rels-ext')
      list[0].delete('metadata')
      list[0].delete('thumbnail-file')
      sl = Hash[list[0].sort]
      sl
    end
  end
end
