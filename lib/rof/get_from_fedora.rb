require 'json'
require 'rexml/document'
require 'rdf/ntriples'
require 'rdf/rdfxml'
require 'rubydora'

module ROF
 class FedoraToRof
  # connect to fedora and fetch object
  # returns array of fedora attributes or nil

  def self.GetFromFedora(pid, fedora, config)
    @fedora_info = {}

    # Try to connect to fedora, and search for the desired item
    # If either of these actions fail, handle it, and exit.
    begin
      fedora = Rubydora.connect(fedora)
      doc = fedora.find(pid)
    rescue StandardError => e
      puts "Error: #{e}"
      exit 1
    end

    # set pid, type
    @fedora_info['pid'] = pid
    @fedora_info['type'] = 'fobject'

    readFedora(doc, config)

    @fedora_info
  end

  # Given a rubydora object, extract what we need
  # to create our ROF object in an associative array
  #
  def self.readFedora(rdora_obj, config)
    @fedora_info['af-model'] = setModel(rdora_obj)
    # iterate through the data streams that are present.
    # use reflection to call appropriate method for each
    rdora_obj.datastreams.each do |dsname, ds|
      next if dsname == "DC"
      method_key = dsname.sub('-', '')
      if self.respond_to?(method_key)
        send(method_key, ds, config)
      else
        # dump generic datastream
        meta = create_meta(ds, config)
        @fedora_info["#{dsname}-meta"] = meta unless meta.empty?

        # TODO(dbrower): change dump algorithm:
        # if content is short < X bytes, save as string
        # if content is > X bytes, save as file only if config option is given
        content = ds.datastream_content.to_s
        if content.length <= 1024
          @fedora_info[dsname] = content
        end
        #@fedora_info[key] = ds.profile if config['show_all'] == true
      end
    end
  end

  def self.create_meta(ds, _config)
    result = {}

    label = ds.profile['dsLabel']
    result["label"] = label unless label.nil? || label == ''
    result["mime-type"] = ds.profile['dsMIME'] if ds.profile['dsMIME'] != "text/plain"
    # TODO(dbrower): make sure this is working as intended
    if ["R", "E"].include?(ds.profile['TYPE'])
      content_array['URL'] = 'bendo:' + ds.profile['dsLocation'].split(':')[2]
    end
    result
  end

  # set fedora_indo['af-model']
  #
  def self.setModel(rdora_obj)
    # only keep info:fedora/afmodel:XXXXX
    models = rdora_obj.profile['objModels'].map do |model|
      if model =~ /^info:fedora\/afmodel:(.*)/
         $1
      end
    end.compact
    models[0]
  end

  # The methods below are called if the like-named datastream exists in fedora

  # set metadata
  #
  def self.descMetadata(ds, _config)
    # desMetadata is encoded in ntriples, convert to JSON-LD using our special context
    graph = RDF::Graph.new
    graph.from_ntriples(ds.datastream_content, format: :ntriples)
    result = nil
    JSON::LD::API::fromRdf(graph) do |expanded|
      result = JSON::LD::API.compact(expanded, RdfContext)
    end
    @fedora_info['metadata'] = result
  end

  # set rights
  #
  def self.rightsMetadata(ds, _config)
    # rights is an XML document
    # the access array may have read or edit elements
    # each of these elements may contain group or person elements
    xml_doc = REXML::Document.new(ds.datastream_content)

    rights_array = {}

    root = xml_doc.root

    ['read', 'edit'].each do |access|
      this_access = root.elements["//access[@type=\'#{access}\']"]

      if !this_access.nil?

        if !this_access.elements['machine'].elements['group'].nil?
          group_array = []
          this_access.elements['machine'].elements['group'].each do |this_group|
            group_array << this_group
          end
          rights_array["#{access}-groups"] = group_array
        end

        if !this_access.elements['machine'].elements['person'].nil?
          person_array = []

          this_access.elements['machine'].elements['person'].each do |this_person|
            person_array << this_person
          end
          rights_array["#{access}"] = person_array
        end
      end
    end

    @fedora_info['rights'] = rights_array
  end

  def self.RELSEXT(ds, _config)
    # RELS-EXT is RDF-XML - parse it
    graph = RDF::Graph.new
    graph.from_rdfxml(ds.datastream_content)
    ctx = {
      "@vocab" => "info:fedora/fedora-system:def/relations-external#",
      "fedora-model" => "info:fedora/fedora-system:def/model#",
      "hydra" => "http://projecthydra.org/ns/relations#",
      "hasModel" => {"@id" => "fedora-model:hasModel", "@type" => "@id"},
      "hasEditor" => {"@id" => "hydra:hasEditor", "@type" => "@id"},
      "hasEditorGroup" => {"@id" => "hydra:hasEditorGroup", "@type" => "@id"},
      "isPartOf" => {"@type" => "@id"}
    }
    result = nil
    JSON::LD::API::fromRdf(graph) do |expanded|
      result = JSON::LD::API.compact(expanded, ctx)
    end
    # now strip the info:fedora/ prefix from the URIs
    strip_info_fedora(result)
    # remove extra items
    result.delete("@id")
    result.delete("hasModel")
    @fedora_info['rels-ext'] = result
  end

  private
  def self.strip_info_fedora(rels_ext)
    rels_ext.each do |relation, targets| 
      next if relation == "@context"
      if targets.is_a?(Hash)
        strip_info_fedora(targets)
      else
        targets = [targets] if targets.is_a?(String)
        rels_ext[relation] = targets.map do |target|
          target.sub("info:fedora/", '')
        end
      end
    end
  end

 end
end
