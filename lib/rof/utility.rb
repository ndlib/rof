require 'mime-types'
require 'zlib'
require 'rsolr'
require 'rubygems/package'

module ROF
  # A few common utility methods
  class Utility
    def initialize
      @seq = 0
      @workdir = '.'
    end

    WORK_TYPE_WITH_PREFIX_PATTERN = /^[Ww]ork(-(.+))?/

    # Strictly speaking, a Collection is not a Work-
    # it's included here to cull out and pass down
    # the batch processing pipeline

    WORK_TYPES = {
      # csv name => af-model
      'article' => 'Article',
      'dataset' => 'Dataset',
      'document' => 'Document',
      'collection' => 'Collection',
      'etd' => 'Etd',
      'image' => 'Image',
      'gtar' => 'Gtar',
      'osfarchive' => 'OsfArchive'
    }.freeze

    # use base directory of given file for workdir
    def set_workdir(filename)
      @workdir = File.dirname(filename)
    end

    # give base directory of given file for workdir
    attr_reader :workdir

    # Given an object's type, detrmine and return its af-model
    def decode_work_type(obj)
      if obj['type'] =~ WORK_TYPE_WITH_PREFIX_PATTERN
        return 'GenericWork' if Regexp.last_match(2).nil?
        Regexp.last_match(2)
      else
        # this will return nil if key t does not exist
        work_type = obj['type'].downcase
        WORK_TYPES[work_type]
      end
    end

    # Issue pid label
    def next_label
      "$(pid--#{@seq})".tap { |_| @seq += 1 }
    end

    # set 'properties'
    def self.prop_ds(owner, representative = nil)
      s = "<fields><depositor>batch_ingest</depositor>\n<owner>#{owner}</owner>\n"
      if representative
        s += "<representative>#{representative}</representative>\n"
      end
      s += "</fields>\n"
      s
    end

    # test for embargo xml cases
    def self.has_embargo_date?(embargo_xml)
      return false if embargo_xml == '' || embargo_xml.nil?
      return false unless embargo_xml.elements['machine'].has_elements? && embargo_xml.elements['machine'].elements['date'].has_text?
      true
    end

    # query SOLR for Previous version of OSF Project.
    # Return its fedora pid if it is found, nil otherwise
    def self.check_solr_for_previous(config, osf_project_identifier)
      solr_url = config.fetch('solr_url', nil)
      return nil if solr_url.nil?
      solr = RSolr.connect url: "#{solr_url}/curatend"
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
  end
end
