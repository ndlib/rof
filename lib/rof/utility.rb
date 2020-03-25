require 'mime-types'
require 'zlib'
require 'rsolr'
require 'rubygems/package'

module ROF
  # A few common utility methods
  class Utility
    # set 'properties'
    def self.prop_ds(owner, representative = nil, depositor = nil)
      s = "<fields><depositor>#{depositor}</depositor>\n<owner>#{owner}</owner>\n"
      if representative
        s += "<representative>#{representative}</representative>\n"
      end
      s += "</fields>\n"
      s
    end

    def self.prop_ds_to_values(ds_value)
      m = ds_value.match(/<depositor>(.*)<\/depositor>/)
      depositor = if m then m[1] end
      m = ds_value.match(/<owner>(.*)<\/owner>/)
      owner = if m then m[1] end
      m = ds_value.match(/<representative>(.*)<\/representative>/)
      representative = if m then m[1] end
      { owner: owner, representative: representative, depositor: depositor }
    end

    # test for embargo xml cases
    def self.has_embargo_date?(embargo_xml)
      return false if embargo_xml == '' || embargo_xml.nil?
      return false unless embargo_xml.elements['machine'].has_elements? && embargo_xml.elements['machine'].elements['date'].has_text?
      true
    end

    # @api public
    # @param fname [String] Path to filename
    # @param outfile [#puts] Where to write exceptions
    # @return [Array] The items in the JSON document, coerced into an Array (if a single item was encountered)
    def self.load_items_from_json_file(fname, outfile = STDERR)
      items = nil
      File.open(fname, 'r:UTF-8') do |f|
        items = JSON.parse(f.read)
      end
      items = [items] unless items.is_a? Array
      items
    rescue JSON::ParserError => e
      outfile.puts("Error reading #{fname}:#{e}")
      exit!(1)
    end

    # query SOLR for Previous version of OSF Project.
    # Return its fedora pid if it is found, nil otherwise
    def self.check_solr_for_previous(config, osf_project_identifier)
      solr_url = config.fetch('solr_url', nil)
      return nil if solr_url.nil?
      solr = RSolr.connect url: solr_url.to_s
      query = solr.get 'select', params: {
        q: "desc_metadata__osf_project_identifier_ssi:#{osf_project_identifier}",
        rows: 1,
        sort_by: 'date_archived',
        fl: ['id'],
        wt: 'json'
      }
      return nil if (query['response']['numFound']).zero?
      # should only be 1 SOLR doc (the most recent) in docs[0]
      query['response']['docs'][0]['id']
    end

    # read file from gzipped tar archive
    def self.file_from_targz(targzfile, file_name)
      File.open(targzfile, 'rb') do |file|
        Zlib::GzipReader.wrap(file) do |gz|
          Gem::Package::TarReader.new(gz) do |tar|
            # FYI: The TarReader requires the tar file to be in strict POSIX
            # compliance. But GNU tar will encode very large user IDs (as found
            # on network filesystems) in a non-standard way, which causes a
            # exception that XXX is "not an octal string". One can force files
            # to be archived with a 0 UID using GNU tar with the command line
            # option `--owner=0`.
            tar.seek(file_name) do |file_entry|
              file_dest_dir = File.join(File.dirname(targzfile),
                                        File.dirname(file_entry.full_name))
              FileUtils.mkdir_p(file_dest_dir)
              File.open(File.join(file_dest_dir, File.basename(file_name)), 'wb') do |file_handle|
                file_handle.write(file_entry.read)
              end
            end
            tar.close
          end
        end
      end
    end

    # decode a double caret encoding to a hash
    #
    # example: decode "^^name Jane Doe^^age 45^^dc:relation und:123456" to
    # { "name" => "Jane Doe", "age" => "45", "dc:relation" => "und:123456" }
    def self.DecodeDoubleCaret(s)
      return s unless s.start_with?('^^')
      result = {}
      s.scan(/\^\^([^ ]+) (([^^]|\^[^^])*)/) do |first, second|
        result[first] = second
      end
      result
    end

    # encode a hash as a double caret encoding
    #
    # example: encode { "name" => "Jane Doe", "age" => "45", "dc:relation" => "und:123456" }
    # as "^^age 45^^dc:relation und:123456^^name Jane Doe"
    def self.EncodeDoubleCaret(hsh, sort_keys = false)
      keys = hsh.keys
      keys.sort! if sort_keys
      pieces = keys.map do |k|
        '^^' + k.to_s + ' ' + hsh[k].to_s
      end
      pieces.join('')
    end
  end
end
