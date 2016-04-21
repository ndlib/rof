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
    #
    rdora_obj.datastreams.each do |key, value|
      method_key = key.sub('-', '')
      if self.respond_to?(method_key)
	      send(method_key, value, config)
      else
        @fedora_info[key] = ds.profile if config['show_all'] == true
      end
    end
  end

  # set fedora_indo['af-model']
  #
  def self.setModel(rdora_obj)
    model_string = rdora_obj.profile['objModels'][0].split(':')
    model_string[2]
  end

  # set bendo-item
  #
  def self.bendoitem(ds, _config)
    @fedora_info['bendo-item'] = ds.datastream_content
  end

  # The methods below are called if the like-named datastream exists in fedora

  # set properties
  #
  def self.properties(ds, _config)
    @fedora_info['properties'] = ds.datastream_content
    @fedora_info['properties-meta'] = ds.profile['dsMIME']
  end

  # set metadata
  #
  def self.descMetadata(ds, _config)
    # desMetadata is encoded in ntriples
    meta_array = {}
    meta_array['@context'] = RdfContext
    RDF::Reader.for(:ntriples).new(ds.datastream_content) do |reader|
      reader.each_statement do |statement|
        key = statement.predicate.to_s
	normalized_key = key.sub('http://purl.org/dc/terms/', 'dc:')
	meta_array[normalized_key] = statement.object
      end
    end

    @fedora_info['metadata'] = meta_array
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

  # set content
  #
  def self.content(ds, _config)
    content_array = {}

    content_array['label'] = ds.profile['dsLabel']
    content_array['mime_type'] = ds.profile['dsMIME']
    content_array['URL'] = 'bendo:' + ds.profile['dsLocation'].split(':')[2]
    @fedora_info['content-meta'] = content_array
  end

  def self.RELSEXT(ds, _config)
    # RELS-EXT is RDF-XML - parse it
    relsext_array = {}

    RDF::RDFXML::Reader.new(ds.datastream_content).each do |relsext|
      key = relsext.predicate.to_s.split('#')
      value = relsext.object.to_s.split(':')
      value_array = []
      value_array << value[2]
      relsext_array[key[1]] = value_array
    end

    @fedora_info['rels-ext'] = relsext_array
  end
 end
end
