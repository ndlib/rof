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
    # @todo Set this to be something more meaningful than an empty lambda
    # @return [#call]
    def self.default_previously_archived_pid_finder
      ->(archive_type, osf_project_identifier) { }
    end

    # Convert Osf Archive tar.gz  to ROF
    def self.osf_to_rof(config, osf_projects = nil, previously_archived_pid_finder = default_previously_archived_pid_finder)
      new(config, osf_projects, previously_archived_pid_finder).call
    end

    def initialize(config, osf_projects = nil, previously_archived_pid_finder = self.class.default_previously_archived_pid_finder)
      @config = config
      @project = osf_projects
      @previously_archived_pid_finder = previously_archived_pid_finder
      @osf_map = ROF::OsfToNDMap
    end

    def call
      rof_array = []
      return {} if project.nil?
      @ttl_data = ttl_from_targz(source_slug + '.ttl')
      rof_array[0] = build_archive_record
      rof_array
    end

    # @api private
    # @see https://github.com/ndlib/curate_nd/blob/677c05c836ff913c01dcbbfc5e5d21366b87d500/app/repository_models/osf_archive.rb#L62
    def archive_type
      # TODO: Somehow we need to know this value based on the end-point that we called
      :archive_type
    end

    # @api private
    # This is a bit of a misnomer; As used it represents the path to the project or registration
    # that we have ingested (e.g. https://osf.io/:source_slug)
    #
    # It was previously named :project_identifier in this class, but that gets conflated with the
    # underlying object's osf_project_identifier (e.g. what OSF Project was this archive originally based on)
    #
    # @see https://github.com/ndlib/curate_nd/blob/115efec2e046257282a86fe2cd98c7d229d04cf9/app/repository_models/osf_archive.rb#L96
    def source_slug
      project.fetch('project_identifier')
    end

    # @api private
    # @see https://github.com/ndlib/curate_nd/blob/115efec2e046257282a86fe2cd98c7d229d04cf9/app/repository_models/osf_archive.rb#L106
    def osf_project_identifier
      # TODO: Don't have anything just yet; I assume this would be extracted from the ttl file
      :osf_project_identifier
    end

    private

    attr_reader :config, :project

    # A function responsible for finding the previously archive pid.
    # @return [#call]
    # @see #default_previously_archived_pid_finder for interface
    attr_reader :previously_archived_pid_finder

    # this is an array- the addition elements are the contributor(s)
    # @return [Array<Hash>]
    # @see #ttl_from_targz
    attr_reader :ttl_data

    # reads a ttl file and makes it a JSON-LD file that we can parse
    def fetch_from_ttl(ttl_file)
      graph = RDF::Turtle::Reader.open(ttl_file, prefixes:  ROF::OsfPrefixList.dup)
      JSON::LD::API.fromRdf(graph)
    end

    # extracts given ttl file from JHU tar.gz package
    # - assumed to live under data/obj/root
    # @return [Array<Hash>] the first element is the "work" and the additional elements, if any, are the contributor(s)
    def ttl_from_targz(ttl_filename)
      package_dir = config.fetch('package_dir')
      ttl_path = File.join(source_slug, 'data/obj/root', ttl_filename)
      ROF::Utility.file_from_targz(File.join(package_dir, source_slug + '.tar.gz'), ttl_path)
      fetch_from_ttl(File.join(package_dir, ttl_path))
    end

    # Maps RELS-EXT
    def map_rels_ext
      rels_ext = {}
      rels_ext['@context'] = ROF::RelsExtRefContext.dup
      apply_previous_archived_version_if_applicable(rels_ext)
      rels_ext
    end

    # sets metadata
    def map_metadata
      metadata = {}
      metadata['@context'] = ROF::RdfContext.dup
      # metdata derived from project ttl file
      metadata['dc:created'] = Time.iso8601(ttl_data[0][@osf_map['dc:created']][0]['@value']).to_date.iso8601 + 'Z'
      metadata['dc:title'] = ttl_data[0][@osf_map['dc:title']][0]['@value']
      metadata['dc:description'] = ttl_data[0][@osf_map['dc:description']][0]['@value']
      metadata['dc:subject'] = map_subject
      # metadata derived from osf_projects data, passed from UI
      metadata['dc:source'] = 'https://osf.io/' + source_slug
      metadata['dc:creator#adminstrative_unit'] = project['administrative_unit']
      metadata['dc:creator#affiliation'] = project['affiliation']
      metadata['nd:osfProjectIdentifier'] = osf_url_from_filename(ttl_data[0][@osf_map['registeredFrom']][0]['@id'])
      metadata['dc:creator'] = map_creator
      metadata
    end

    # For reference to the assumed RELS-EXT see the following spec in CurateND
    # @see https://github.com/ndlib/curate_nd/blob/115efec2e046257282a86fe2cd98c7d229d04cf9/spec/repository_models/osf_archive_spec.rb#L97
    def apply_previous_archived_version_if_applicable(rels_ext)
      # For the osf_project_identifier and the archive type (Project or Registration),
      #   find the pid of the ingested object via the #previously_archived_pid_finder method
      pid = previously_archived_pid_finder.call(archive_type, osf_project_identifier)
      rels_ext['pav:previousVersion'] = pid if pid
      rels_ext
    end

    # Constructs OsfArchive Record from ttl_data, data from the UI form,
    # and task config data
    def build_archive_record
      this_rof = {}
      this_rof['owner'] = project['owner']
      this_rof['type'] = 'OsfArchive'
      this_rof['rights'] = map_rights
      this_rof['rels-ext'] = map_rels_ext
      this_rof['metadata'] = map_metadata
      this_rof['files'] = [source_slug + '.tar.gz']
      this_rof
    end

    # sets subject
    def map_subject
      if ttl_data[0].key?(@osf_map['dc:subject'])
        return ttl_data[0][@osf_map['dc:subject']][0]['@value']
      end
      ''
    end

    # make osf url from bagfile name
    def osf_url_from_filename(ttl_file)
      project_id = ttl_file.rpartition('/')[2].rpartition('.')[0]
      project_id
    end

    # figures out the rights
    def map_rights
      rights = {}
      if ttl_data[0][@osf_map['isPublic']][0]['@value'] == 'true'
        rights['read-groups'] = ['public']
      end
      rights
    end

    # sets the creator- needs to read another ttl for the User data
    # only contrubutors with isBibliographic true are considered
    def map_creator
      creator = []
      ttl_data[0][@osf_map['hasContributor']].each do |contributor|
        # Looping through the primary document and the contributors
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
