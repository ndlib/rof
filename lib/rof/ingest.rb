require 'json/ld'
require "rof/ingesters/rels_ext_ingester"
require "rof/ingesters/rights_metadata_ingester"

module ROF
  class NotFobjectError < RuntimeError
  end

  class MissingPidError < RuntimeError
  end

  class TooManyIdentitiesError < RuntimeError
  end

  class SourceError < RuntimeError
  end

  # Ingest or update item in fedora
  # if fedora is nil, then we verify that item is in the proper format
  # Otherwise fedora is a Rubydora::Reporitory object (for now...)
  # Returns a list of ingested datastreams, if everything is okay.
  # Otherwise raises an exception depending on the error.
  def self.Ingest(item, fedora=nil, search_paths=[], bendo=nil)
    raise NotFobjectError if item["type"] != "fobject"
    raise TooManyIdentitiesError if item.key?("id") && item.key?("pid")
    item["pid"] = item["id"] unless item.key?("pid")
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
    # update rels-ext if there is either a rels-ext present or if there
    # is a model to set. Otherwise, don't touch it!
    if (item.has_key?("rels-ext") || !models.empty?)
      update_rels_ext(models, item, doc)
      ds_touched << "rels-ext"
    end
    # now handle all the other datastreams
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
      when "type", "pid", "model", "id", "af-model", "rels-ext", "collections"

      # datastream fields
      when /\A(.+)-file\Z/, /\A(.+)-meta\Z/, /\A(.+)\Z/
        # ingest a datastream
        dsname = $1
        next if ds_touched.include?(dsname)
        self.ingest_datastream(dsname, item, doc, search_paths, bendo)
        ds_touched << dsname
      end
    end
    return ds_touched
  end

  def self.ingest_datastream(dsname, item, fdoc, search_paths, bendo)
    # What kind of content is there?
    ds_content = item[dsname]
    ds_filename = item["#{dsname}-file"]
    ds_meta = item["#{dsname}-meta"]
    if ds_filename && ds_content
      raise SourceError.new("Both #{dsname} and #{dsname}-file are present.")
    end
    if ds_content && !ds_content.is_a?(String)
      raise SourceError.new("Content for #{dsname} is not a string.")
    end
    # A URL, without content or file, is an R datastream
    # A URL, with content or file, raises an error
    ds_url = ds_meta["URL"] if ds_meta && ds_meta.is_a?(Hash)
    if ds_url && ds_content
      raise SourceError.new("Both #{ds_url} and #{dsname} are present.")
    end
    if ds_url && ds_filename
      raise SourceError.new("Both #{ds_url} and #{dsname}-file are present.")
    end

    md = {"mime-type" => "text/plain",
          "label" => "",
          "versionable" => true,
          "control-group" => "M",
    }

    if ds_meta
      md.merge!(item["#{dsname}-meta"])
    end

    if ds_url
       md["control-group"] = "R"

       # If the bendo server was passed in the command line, assume that the URL is in
       # the form "bendo:/item/<item#>/<item name> and substitute bendo: w/ the server name
       # if no bendo provided, use whatever's there.
       if bendo
         md["URL"] = md["URL"].sub("bendo:", bendo)
       end
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
      ds.dsLocation = md["URL"] if md["URL"]
    end
    need_close = false
    if ds_filename
      ds_content = self.find_file_and_open(ds_filename, search_paths, "rb")
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
    Ingesters::RightsMetadataIngester.call(item: item, fedora_document: fdoc)
  end

  def self.ingest_ld_metadata(item, fdoc)
    input = item['metadata']
    # sometimes json-ld generates @graph structures when converting from fedora to ROF.
    # in that case, don't provide an id key
    if !input.has_key?("@graph")
      input["@id"] = "info:fedora/#{item['pid']}" unless input["@id"]
    end
    graph = RDF::Graph.new << JSON::LD::API.toRdf(input)
    content = graph.dump(:ntriples)
    # we read the rof file as utf-8. the RDF gem seems to convert it back to
    # the default encoding. so fix it.
    content.force_encoding('UTF-8')
    if fdoc
      ds = fdoc['descMetadata']
      ds.mimeType = "text/plain"
      ds.content = content
      ds.save
    end
    content
  end

  def self.update_rels_ext(models, item, fdoc)
    Ingesters::RelsExtIngester.call(models: models, item: item, fedora_document: fdoc)
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
