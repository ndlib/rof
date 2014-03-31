module ROF
  class NotFobjectError < Exception
  end

  class MissingPidError < Exception
  end

  # Ingest or update item in fedora
  # if fedora is nil, then we verify that item is in the proper format
  def self.Ingest(item, fedora=nil)
    raise NotFobjectError if item["type"] != "fobject"
    raise MissingPidError unless item["pid"]
    # does it already exist in fedora?

    ds_touched = []

    item.each do |k,v|
      case k
      # fields having special treatement
      when "rights"
      when "metadata"
      when "rels-ext"
      # ignore these fields
      when "type", "pid"
      # datastream fields
      when /^(.*)-file/, /^(.*)-meta/, /^(.*)/
        # ingest a datastream!
        ds_name = $1
        next if ds_touched.include?(ds_name)
        ds_touched << ds_name
      end
    end
  end
end
