require 'json'
require 'rexml/document'
require 'rdf/ntriples'
require 'rdf/rdfxml'
require 'rubydora'

module ROF
  module Translators
    class FedoraToRof
      # @param pids [Array] Fedora PIDs
      # @param fedora [nil, Hash] Hash with connection information (e.g. URL, User)
      # @param outfile [String, (#write, #close)] A String that is interpretted as a path to a file. Else an IO object responding to #write and #close
      # @param config [Hash]
      # @return Void
      def self.run(pids, fedora = nil, outfile = STDOUT, config = {})
        need_close = false
        # use outfile is_a String
        if outfile.is_a?(String)
          outfile = File.open(outfile, 'w')
          need_close = true
        end

        rof = new(pids, fedora, config).to_rof
        outfile.write(JSON.pretty_generate(rof))
        outfile.write()
      ensure
        outfile.close if outfile && need_close
      end

      def initialize(pids, fedora, config)
        @pids = pids
        @fedora = fedora
        @config = config
        connect_to_fedora!
      end
      attr_reader :pids, :fedora, :config, :connection

      private
        def connect_to_fedora!
          @connection = Rubydora.connect(fedora)
        rescue StandardError => e
          $stderr.puts "Error: #{e} (with fedora #{fedora.inspect})"
          exit!(1)
        end
      public

      def to_rof
        # wrap the objects inside a JSON list
        pids.map do |pid|
          PidToRofElement.new(pid, connection, config).convert
        end
      end

      # Responsible for converting a single PID to an ROF Element
      class PidToRofElement
        def initialize(pid, connection, config)
          @pid = pid
          @connection = connection
          @config = config
          @fedora_info = { 'pid' => pid, 'type' => 'fobject' }
          @rdora_obj = connection.find(pid)
        end
        attr_reader :pid, :config, :rdora_obj

        def convert
          readFedora
          @fedora_info
        end

        # Given a rubydora object, extract what we need
        # to create our ROF object in an associative array
        #
        def readFedora
          @fedora_info['af-model'] = setModel
          # iterate through the data streams that are present.
          # use reflection to call appropriate method for each
          rdora_obj.datastreams.each do |dsname, ds|
            next if dsname == 'DC'
            method_key = dsname.sub('-', '')
            if respond_to?(method_key)
              send(method_key, ds)
            else
              # dump generic datastream
              meta = create_meta(ds)
              @fedora_info["#{dsname}-meta"] = meta unless meta.empty?

              # if content is short < X bytes and valid utf-8, save as string
              # if content is > X bytes or is not utf-8, save as file only if config option is given
              content = ds.datastream_content
              if content.length <= 1024 || config['inline']
                # this downloads the contents of the datastream into memory
                content_string = content.to_s.force_encoding('UTF-8')
                if content_string.valid_encoding?
                  @fedora_info[dsname] = content_string
                  next # we're done! move on to next datastream
                end
                # not utf-8, so keep going and see if download option was given
              end
              next unless config['download']
              # download option was given, so save this datastream as a file
              fname = "#{@fedora_info['pid']}-#{dsname}"
              abspath = File.join(config['download_path'], fname)
              @fedora_info["#{dsname}-file"] = fname
              if File.file?(config['download_path'])
                $stderr.puts "Error: --download directory #{config['download_path']} specified is an existing file."
                exit 1
              end
              FileUtils.mkdir_p(config['download_path'])
              File.open(abspath, 'w') do |f|
                f.write(content)
              end
            end
          end
        end

        def create_meta(ds)
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
        def setModel
          # only keep info:fedora/afmodel:XXXXX
          models = rdora_obj.profile['objModels'].map do |model|
            Regexp.last_match(1) if model =~ /^info:fedora\/afmodel:(.*)/
          end.compact
          models[0]
        end

        # The methods below are called if the like-named datastream exists in fedora

        # set metadata
        #
        def descMetadata(ds)
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
        def rightsMetadata(ds)
          # rights is an XML document
          # the access array may have read or edit elements
          # each of these elements may contain group or person elements
          xml_doc = REXML::Document.new(ds.datastream_content)

          rights_array = {}

          root = xml_doc.root

          # check for optional embargo date - set if present
          this_embargo = root.elements['embargo']
          rights_array['embargo-date'] = this_embargo.elements['machine'].elements['date'][0] if Utility.has_embargo_date?(this_embargo)

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

        def RELSEXT(ds)
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

        def strip_info_fedora(rels_ext)
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
      private_constant :PidToRofElement
    end
  end
end
