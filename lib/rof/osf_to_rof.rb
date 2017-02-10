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
      @osf_map = ROF::OsfToNDMap
      rof_array = []
      return {} if osf_projects.nil?
      this_project = osf_projects
      ttl_data = ttl_from_targz(config, this_project,
                                this_project['project_identifier'] + '.ttl')
      rof_array[0] = build_archive_record(config, this_project, ttl_data)
      rof_array
    end

    # reads a ttl file and makes it a JSON-LD file that we can parse
    def self.fetch_from_ttl(ttl_file)
      graph = RDF::Turtle::Reader.open(ttl_file,
                                       prefixes:  ROF::OsfPrefixList.dup)
      JSON::LD::API.fromRdf(graph)
    end

    # extracts given ttl file from JHU tar.gz package
    # - assumed to live under data/obj/root
    def self.ttl_from_targz(config, this_project, ttl_filename)
      id =  this_project['project_identifier']
      ttl_path = File.join(id,
                           'data/obj/root',
                           ttl_filename)
      ROF::Utility.file_from_targz(File.join(config['package_dir'], id + '.tar.gz'),
                                   ttl_path)
      ttl_data = fetch_from_ttl(File.join(config['package_dir'], ttl_path))
      # this is an array- the addition elements are the contributor(s)
      ttl_data
    end

    # Maps RELS-EXT
    def self.map_rels_ext(_ttl_data)
      rels_ext = {}
      rels_ext['@context'] = ROF::RelsExtRefContext.dup
      rels_ext
    end

    # sets metadata
    def self.map_metadata(config, project, ttl_data)
      metadata = {}
      metadata['@context'] = ROF::RdfContext.dup
      # metdata derived from project ttl file
      metadata['dc:created'] = Time.iso8601(ttl_data[0][@osf_map['dc:created']][0]['@value']).to_date.iso8601 + 'Z'
      metadata['dc:title'] = ttl_data[0][@osf_map['dc:title']][0]['@value']
      metadata['dc:description'] =
        ttl_data[0][@osf_map['dc:description']][0]['@value']
      metadata['dc:subject'] = map_subject(ttl_data[0])
      # metadata derived from osf_projects data, passed from UI
      metadata['dc:source'] = 'https://osf.io/' + project['project_identifier']
      metadata['dc:creator#adminstrative_unit'] = project['administrative_unit']
      metadata['dc:creator#affiliation'] = project['affiliation']
      metadata['dc:creator'] = map_creator(config, project, ttl_data)
      metadata['nd:osfProjectIdentifier'] = osf_url_from_filename(ttl_data[0][@osf_map['registeredFrom']][0]['@id'])
      metadata
    end

    # Constructs OsfArchive Record from ttl_data, data from the UI form,
    # and task config data
    def self.build_archive_record(config, this_project, ttl_data)
      this_rof = {}
      this_rof['owner'] = this_project['owner']
      this_rof['type'] = 'OsfArchive'
      this_rof['rights'] = map_rights(ttl_data[0])
      this_rof['rels-ext'] = map_rels_ext(ttl_data[0])
      this_rof['metadata'] = map_metadata(config, this_project, ttl_data)
      this_rof['files'] = [this_project['project_identifier'] + '.tar.gz']
      this_rof
    end

    # sets subject
    def self.map_subject(ttl_data)
      if ttl_data.key?(@osf_map['dc:subject'])
        return ttl_data[@osf_map['dc:subject']][0]['@value']
      end
      ''
    end

    # make osf url from bagfile name
    def self.osf_url_from_filename(ttl_file)
      project_id = ttl_file.rpartition('/')[2].rpartition('.')[0]
      project_id
    end

    # figures out the rights
    def self.map_rights(ttl_data)
      rights = {}
      if ttl_data[@osf_map['isPublic']][0]['@value'] == 'true'
        rights['read-groups'] = ['public']
      end
      rights
    end

    # sets the creator- needs to read another ttl for the User data
    # only contrubutors with isBibliographic true are considered
    def self.map_creator(config, project, ttl_data)
      creator = []
      ttl_data[0][@osf_map['hasContributor']].each do |contributor|
        ttl_data.each do |item|
          next unless item['@id'] == contributor['@id']
          if item[@osf_map['isBibliographic']][0]['@value'] == 'true'
            creator.push map_user_from_ttl(config, project,
                                           item[@osf_map['hasUser']][0]['@id'])
          end
        end
      end
      creator
    end

    # read user ttl file, extract User's full name
    def self.map_user_from_ttl(config, project, file_subpath)
      ttl_data = ttl_from_targz(config, project, File.basename(file_subpath))
      ttl_data[0][@osf_map['hasFullName']][0]['@value']
    end
  end
end
