require 'json'
require 'zlib'
require 'rubygems/package'
require 'rdf/turtle'
require 'rof/osf_context'
require 'rof/rdf_context'
require 'rof/utility'

module ROF
  # Class for managing OSF Archive data transformations
  # It is called after the get-from-osf task, and before the work-xlat task
  class OsfToRof
    # Convert Osf Archive tar.gz  to ROF
    def self.osf_to_rof(config, osf_projects = nil)
      new(config, osf_projects).call
    end

    def initialize(config, osf_projects = nil)
      @config = config
      @project = osf_projects
      @osf_map = ROF::OsfToNDMap
    end

    def call
      rof_array = []
      return {} if project.nil?
      ttl_data = ttl_from_targz(project_identifier + '.ttl')
      rof_array[0] = build_archive_record(ttl_data)
      rof_array
    end

    private

    attr_reader :config, :project

    def project_identifier
      project.fetch('project_identifier')
    end

    # reads a ttl file and makes it a JSON-LD file that we can parse
    def fetch_from_ttl(ttl_file)
      graph = RDF::Turtle::Reader.open(ttl_file, prefixes:  ROF::OsfPrefixList.dup)
      JSON::LD::API.fromRdf(graph)
    end

    # extracts given ttl file from JHU tar.gz package
    # - assumed to live under data/obj/root
    def ttl_from_targz(ttl_filename)
      package_dir = config.fetch('package_dir')
      ttl_path = File.join(project_identifier, 'data/obj/root', ttl_filename)
      ROF::Utility.file_from_targz(File.join(package_dir, project_identifier + '.tar.gz'), ttl_path)
      ttl_data = fetch_from_ttl(File.join(package_dir, ttl_path))
      # this is an array- the addition elements are the contributor(s)
      ttl_data
    end

    # Maps RELS-EXT
    def map_rels_ext(_ttl_data)
      rels_ext = {}
      rels_ext['@context'] = ROF::RelsExtRefContext.dup
      rels_ext
    end

    # sets metadata
    def map_metadata(ttl_data)
      metadata = {}
      metadata['@context'] = ROF::RdfContext.dup
      # metdata derived from project ttl file
      metadata['dc:created'] = Time.iso8601(ttl_data[0][@osf_map['dc:created']][0]['@value']).to_date.iso8601 + 'Z'
      metadata['dc:title'] = ttl_data[0][@osf_map['dc:title']][0]['@value']
      metadata['dc:description'] =
        ttl_data[0][@osf_map['dc:description']][0]['@value']
      metadata['dc:subject'] = map_subject(ttl_data[0])
      # metadata derived from osf_projects data, passed from UI
      metadata['dc:source'] = 'https://osf.io/' + project_identifier
      metadata['dc:creator#adminstrative_unit'] = project['administrative_unit']
      metadata['dc:creator#affiliation'] = project['affiliation']
      metadata['dc:creator'] = map_creator(ttl_data)
      metadata
    end

    # Constructs OsfArchive Record from ttl_data, data from the UI form,
    # and task config data
    def build_archive_record(ttl_data)
      this_rof = {}
      this_rof['owner'] = project['owner']
      this_rof['type'] = 'OsfArchive'
      this_rof['rights'] = map_rights(ttl_data[0])
      this_rof['rels-ext'] = map_rels_ext(ttl_data[0])
      this_rof['metadata'] = map_metadata(ttl_data)
      this_rof['files'] = [project_identifier + '.tar.gz']
      this_rof
    end

    # sets subject
    def map_subject(ttl_data)
      if ttl_data.key?(@osf_map['dc:subject'])
        return ttl_data[@osf_map['dc:subject']][0]['@value']
      end
      ''
    end

    # figures out the rights
    def map_rights(ttl_data)
      rights = {}
      if ttl_data[@osf_map['isPublic']][0]['@value'] == 'true'
        rights['read-groups'] = ['public']
      end
      rights
    end

    # sets the creator- needs to read another ttl for the User data
    # only contrubutors with isBibliographic true are considered
    def map_creator(ttl_data)
      creator = []
      ttl_data[0][@osf_map['hasContributor']].each do |contributor|
        ttl_data.each do |item|
          next unless item['@id'] == contributor['@id']
          if item[@osf_map['isBibliographic']][0]['@value'] == 'true'
            creator.push map_user_from_ttl(item[@osf_map['hasUser']][0]['@id'])
          end
        end
      end
      creator
    end

    # read user ttl file, extract User's full name
    def map_user_from_ttl(file_subpath)
      user_ttl_data = ttl_from_targz(File.basename(file_subpath))
      user_ttl_data[0][@osf_map['hasFullName']][0]['@value']
    end
  end
end
