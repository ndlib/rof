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
        next if dsname == 'DC'
        method_key = dsname.sub('-', '')
        if respond_to?(method_key)
          send(method_key, ds, config)
        else
          # dump generic datastream
          meta = create_meta(ds, config)
          @fedora_info["#{dsname}-meta"] = meta unless meta.empty?

          # TODO(dbrower): change dump algorithm:
          # if content is short < X bytes, save as string
          # if content is > X bytes, save as file only if config option is given
          content = ds.datastream_content
          if content.length <= 1024 || config['inline']
            @fedora_info[dsname] = content.to_s
          elsif config['download']
            fname = "#{@fedora_info['pid']}-#{dsname}"
            abspath = File.join(config['download_path'], fname)
            @fedora_info["#{dsname}-file"] = fname
            if File.file?(config['download_path'])
              puts "Error: --download directory #{config['download_path']} specified is an existing file."
              exit 1
      end
            FileUtils.mkdir_p(config['download_path'])
            File.open(abspath, 'w') do |f|
              f.write(content)
            end
          end
        end
      end
    end

    def self.create_meta(ds, config)
      result = {}

      label = ds.profile['dsLabel']
      result['label'] = label unless label.nil? || label == ''
      result['mime-type'] = ds.profile['dsMIME'] if ds.profile['dsMIME'] != 'text/plain'
      # TODO(dbrower): make sure this is working as intended
      if %w(R E).include?(ds.profile['dsControlGroup'])
        s = result['URL'] = ds.profile['dsLocation']
        s = s.sub(config['bendo'], 'bendo:') if config['bendo']
        result['URL'] = s
      end
      result
    end

    # set fedora_indo['af-model']
    #
    def self.setModel(rdora_obj)
      # only keep info:fedora/afmodel:XXXXX
      models = rdora_obj.profile['objModels'].map do |model|
        Regexp.last_match(1) if model =~ /^info:fedora\/afmodel:(.*)/
      end.compact
      models[0]
    end

    # The methods below are called if the like-named datastream exists in fedora

    # set metadata
    #
    def self.descMetadata(ds, _config)
      # desMetadata is encoded in ntriples, convert to JSON-LD using our special context
      graph = RDF::Graph.new
      data = ds.datastream_content
      # force utf-8 encoding. fedora does not store the encoding, so it defaults to ASCII-8BIT
      # see https://github.com/ruby-rdf/rdf/issues/142
      data.force_encoding('utf-8')
      graph.from_ntriples(data, format: :ntriples)
      JSON::LD::API.fromRdf(graph) do |expanded|
        result = JSON::LD::API.compact(expanded, RdfContext)
        @fedora_info['metadata'] = result
      end
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

      %w(read edit).each do |access|
        this_access = root.elements["//access[@type=\'#{access}\']"]

        next if this_access.nil?

        unless this_access.elements['machine'].elements['group'].nil?
          group_array = []
          this_access.elements['machine'].elements['group'].each do |this_group|
            group_array << this_group
          end
          rights_array["#{access}-groups"] = group_array
        end

        next if this_access.elements['machine'].elements['person'].nil?
        person_array = []

        this_access.elements['machine'].elements['person'].each do |this_person|
          person_array << this_person
        end
        rights_array[access.to_s] = person_array
      end

      @fedora_info['rights'] = rights_array
    end

    def self.RELSEXT(ds, _config)
      # RELS-EXT is RDF-XML - parse it
      ctx = ROF::RelsExtRefContext.dup
      ctx.delete('@base') # @base causes problems when converting TO json-ld (it is = "info:/fedora") but info is not a namespace
      graph = RDF::Graph.new
      graph.from_rdfxml(ds.datastream_content)
      result = nil
      JSON::LD::API.fromRdf(graph) do |expanded|
        result = JSON::LD::API.compact(expanded, ctx)
      end
      # now strip the info:fedora/ prefix from the URIs
      strip_info_fedora(result)
      # remove extra items
      result.delete('hasModel')
      @fedora_info['rels-ext'] = result
    end

    private

    def self.strip_info_fedora(rels_ext)
      rels_ext.each do |relation, targets|
        next if relation == '@context'
        if targets.is_a?(Hash)
          strip_info_fedora(targets)
          next
        end
        targets = [targets] if targets.is_a?(String)
        targets.map! do |target|
          if target.is_a?(Hash)
            strip_info_fedora(target)
          else
            target.sub('info:fedora/', '')
          end
        end
        # some single strings cannot be arrays in json-ld, so convert back
        # this shouldn't cause any problems with items that began as arrays
        targets = targets[0] if targets.length == 1
        rels_ext[relation] = targets
      end
    end
  end
end
