require 'json/ld'
require "rof/ingesters/rels_ext_ingester"

module ROF
  class NotFobjectError < RuntimeError
  end

  class MissingPidError < RuntimeError
  end

  class SourceError < RuntimeError
  end

  # Ingest or update item in fedora
  # if fedora is nil, then we verify that item is in the proper format
  # Otherwise fedora is a Rubydora::Reporitory object (for now...)
  # Returns a list of ingested datastreams, if everything is okay.
  # Otherwise raises an exception depending on the error.
  def self.Ingest(item, fedora=nil, search_paths=[])
    raise NotFobjectError if item["type"] != "fobject"
    raise MissingPidError unless item["pid"].is_a? String
    models = string_nil_to_array(item["model"])
    models += string_nil_to_array(item["af-model"]).map { |m| af_model_name(m) }
    # does it already exist in fedora? Create it otherwise
    doc = nil
    if fedora
      doc = fedora.find_or_initialize(item["pid"])
      # the addRelationship API is broken in Fedora 3.6.x.
      # Since the `models` method in Rubydora uses that API, it
      # also doesn't work. ActiveFedora is not affected since it
      # serializes to RELS-EXT itself, bypassing addRelationship endpoint.
      # models.each do |m|
      #   doc.models << m unless doc.models.include?(m)
      # end

      # it seems like we need to save the document before adding datastreams?!?
      doc.save
    end

    ds_touched = []
    if doc
      update_rels_ext(models, item, doc)
      ds_touched << "rels-ext"
    end
    item.each do |key,value|
      case key
      # fields having special treatement
      when "rights"
        self.ingest_rights_metadata(item, doc)
        ds_touched << "rightsMetadata"
      when "metadata"
        self.ingest_ld_metadata(item, doc)
        ds_touched << "descMetadata"

      # ignore these fields
      when "type", "pid", "model", "af-model", "rels-ext"

      # datastream fields
      when /\A(.+)-file\Z/, /\A(.+)-meta\Z/, /\A(.+)\Z/
        # ingest a datastream
        dsname = $1
        next if ds_touched.include?(dsname)
        self.ingest_datastream(dsname, item, doc, search_paths)
        ds_touched << dsname
      end
    end
    return ds_touched
  end

  def self.ingest_datastream(dsname, item, fdoc, search_paths)
    # What kind of content is there?
    ds_content = item[dsname]
    ds_filename = item["#{dsname}-file"]
    if ds_filename && ds_content
      raise SourceError.new("Both #{dsname} and #{dsname}-file are present.")
    end

    md = {"mime-type" => "text/plain",
          "label" => "",
          "versionable" => true,
          "control-group" => "M",
    }
    if item["#{dsname}-meta"]
      md.merge!(item["#{dsname}-meta"])
    end

    # NOTE(dbrower): this could be refactored a bit. I was trying to keep the
    # same path for whether fdoc is nil or not as much as possible.
    ds = nil
    if fdoc
      ds = fdoc[dsname]
      # TODO(dbrower): maybe verify these options to be within bounds?
      ds.controlGroup = md["control-group"]
      ds.dsLabel = md["label"]
      ds.versionable = md["versionable"]
      ds.mimeType = md["mime-type"]
    end
    need_close = false
    if ds_filename
      ds_content = self.find_file_and_open(ds_filename, search_paths, "r")
      need_close = true
    end
    if ds
      ds.content = ds_content if ds_content
      ds.save
    end
  ensure
    ds_content.close if ds_content && need_close
  end

  def self.ingest_rights_metadata(item, fdoc)
    rights = item["rights"]
    return if rights.nil?
    #
    # we really should be building this using an xml engine.
    #
    content = %Q{<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">\n}
    # TODO(dbrower): Does the copyright need to be exposed in the rof?
    content += %Q{  <copyright>\n    <human type="title"/>\n    <human type="description"/>\n    <machine type="uri"/>\n  </copyright>\n}
    content += self.format_rights_section("discover", rights["discover"], rights["discover-groups"])
    content += self.format_rights_section("read", rights["read"], rights["read-groups"])
    content += self.format_rights_section("edit", rights["edit"], rights["edit-groups"])
    # TODO(dbrower): expose embargo information
    content += %Q{  <embargo>\n    <human/>\n    <machine/>\n  </embargo>\n}
    content += %Q{</rightsMetadata>\n}

    if fdoc
      ds = fdoc['rightsMetadata']
      ds.mimeType = 'text/xml'
      ds.content = content
      ds.save
    end
    content
  end

  def self.format_rights_section(section_name, people, groups)
    people = [people] if people.is_a? String
    groups = [groups] if groups.is_a? String
    result = %Q{  <access type="#{section_name}">\n    <human/>\n}
    if people || groups
      result += "    <machine>\n"
      (people || []).each do |person|
        result += %Q{      <person>#{person}</person>\n}
      end
      (groups || []).each do |group|
        result += %Q{      <group>#{group}</group>\n}
      end
      result += "    </machine>\n"
    else
      result += "    <machine/>\n"
    end
    result += "  </access>\n"
    result
  end

  def self.ingest_ld_metadata(item, fdoc)
    input = item['metadata']
    input["@id"] = "info:fedora/#{item['pid']}" unless input["@id"]
    graph = RDF::Graph.new << JSON::LD::API.toRdf(input)
    content = graph.dump(:ntriples)
    if fdoc
      ds = fdoc['descMetadata']
      ds.mimeType = "text/plain"
      ds.content = content
      ds.save
    end
    content
  end

  def self.update_rels_ext(models, item, fdoc)
    Ingester::RelsExtIngester.call(models: models, item: item, fedora_document: fdoc)
  end

  # find fname by looking through directories in search_path,
  # an array of strings.
  # Will not find any files if search_path is empty.
  # Raises Errno::ENOENT if no file is found, otherwise
  # opens the file and returns a fd
  def self.find_file_and_open(fname, search_path, flags)
    # don't search if file has an absolute path
    if fname[0] == "/"
      return File.open(fname, flags)
    end
    search_path.each do |path|
      begin
        f = File.open(File.join(path,fname), flags)
        return f
      rescue Errno::ENOENT
      end
    end
    raise Errno::ENOENT.new(fname)
  end

  def self.af_model_name(model)
    "info:fedora/afmodel:#{model}"
  end

  def self.string_nil_to_array(x)
    return [] if x.nil?
    return [x] unless x.is_a? Array
    x
  end
end
