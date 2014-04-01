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
  def self.Ingest(item, fedora=nil)
    raise NotFobjectError if item["type"] != "fobject"
    raise MissingPidError unless item["pid"].is_a? String
    models = string_nil_to_array(item["model"])
    models += string_nil_to_array(item["af-model"]).map { |m| af_model_name(m) }
    # does it already exist in fedora? Create it otherwise
    doc = nil
    if fedora
      doc = fedora.find_or_initialize(item["pid"])
      update_cmodels(models, doc)
      # the addRelationship API is broken in Fedora 3.6.x.
      # Since the `models` method in Rubydora uses that API, it
      # also doesn't work. ActiveFedora is not affected since it
      # serializes to RELS-EXT itself, bypassing addRelationship endpoint.
      # models.each do |m|
      #   doc.models << m unless doc.models.include?(m)
      # end
    end

    ds_touched = []
    item.each do |k,v|
      case k
      # fields having special treatement
      when "rights"
        ds_touched << "rightsMetadata"
      when "metadata"
        ds_touched << "descMetadata"
      when "rels-ext"
        ds_touched << "RELS-EXT"

      # ignore these fields
      when "type", "pid", "model", "af-model"

      # datastream fields
      when /\A(.+)-file\Z/, /\A(.+)-meta\Z/, /\A(.+)\Z/
        # ingest a datastream
        dsname = $1
        next if ds_touched.include?(dsname)
        self.ingest_datastream(dsname, item, doc)
        ds_touched << dsname
      end
    end
    return ds_touched
  end

  def self.ingest_datastream(dsname, item, fdoc)
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
    case
    when ds_filename
      File.open(ds_filename, "r") do |f|
        if ds
          ds.content = f
          ds.save!
        end
      end
    when ds_content
      if ds
        ds.content = ds_content
        ds.save!
      end
    else
      ds.save! if ds
    end
  end

  def self.update_cmodels(models, fdoc)
    # this is ugly to work around addRelationship bug in 3.6.x
    # (See bugs FCREPO-1191 and FCREPO-1187)
    content = '<rdf:RDF xmlns:ns0="info:fedora/fedora-system:def/model#" xmlns:ns1="info:fedora/fedora-system:def/relations-external#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
    content += %Q{<rdf:Description rdf:about="info:fedora/#{pid}">}
    models.each do |m|
      content += %Q{<ns0:hasModel rdf:resource="#{m}"/>}
    end
    content += %Q{<ns1:isPartOf rdf:resource="info:fedora/vecnet:mw22v546v"/>}
    content += '</rdf:Description></rdf:RDF>'
    ds = fdoc['RELS-EXT']
    ds.content = content
    ds.mimeType = "application/rdf+xml"
    ds.save!
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
