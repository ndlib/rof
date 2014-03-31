module ROF
  class NotFobjectError < RuntimeError
  end

  class MissingPidError < RuntimeError
  end

  class SourceError < RuntimeError
  end

  # Ingest or update item in fedora
  # if fedora is nil, then we verify that item is in the proper format
  def self.Ingest(item, fedora=nil)
    raise NotFobjectError if item["type"] != "fobject"
    raise MissingPidError unless item["pid"]
    # does it already exist in fedora? Create it otherwise
    begin
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
      when "type", "pid"

      # datastream fields
      when /^(.+)-file$/, /^(.+)-meta$/, /^(.+)$/
        # ingest a datastream!
        dsname = $1
        next if ds_touched.include?(dsname)
        self.ingest_datastream(dsname, item, fedora)
        ds_touched << dsname
      end
    end
  end

  def self.ingest_datastream(dsname, item, fedora)
    # What kind of content is there?
    ds_content = item[dsname]
    ds_filename = item["#{dsname}-file"]
    if ds_filename && ds_content
      raise SourceError.new("Both #{dsname} and #{dsname}-file are present.")
    end

    md = {"mime-type": "text/plain",
          "label" : "",
          "versionable" : true,
          "control-group" : "M",
    }
    if item["#{dsname}-meta"]
      md.merge!(item["#{dsname}-meta"])
    end


  end
end
