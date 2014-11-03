module ROF
  # provide translation between access strings and the ROF access hash
  # e.g. ("public", owner=dbrower) --> {read-groups: "public", edit: "dbrower"}
  class Access
    class DecodeError < RuntimeError
    end

    # convert from a string to a hash
    def self.decode(access_string, owner=nil)
      result = {}
      access_string.split(",").each do |clause|
        t = self.decode_clause(clause, owner)
        t.each do |k,v|
          if v.is_a?(Array)
            result[k] = (result.fetch(k, []) + v).uniq
          else
            result[k] = v
          end
        end
      end

      result
    end

    # convert from a hash to a string
    # simple because we do not try to recover "public", et al.
    def self.encode(access_hash)
      result = []
      access_hash.each do |k,v|
        xk = k.gsub("-groups", "group").gsub("embargo-date","embargo")
        xv = v.join('|') if v.is_a?(Array)
        result << "#{xk}:#{xv}"
      end
      result.join(",")
    end

    def self.decode_clause(access, owner)
      case access
      when "public"
        {"read-groups" => ["public"], "edit" => [owner]}
      when "restricted"
        {"read-groups" => ["registered"], "edit" => [owner]}
      when "private"
        {"edit" => [owner]}
      when /^embargo:(.+)/
        {"embargo-date" => $1}
      when /^(read|readgroup|edit|editgroup|discover|discovergroup):(.+)/
        which = $1
        who = $2.split("|")
        xwhich = which.gsub("group", "-groups")
        Hash[xwhich, who]
      else
        raise DecodeError
      end
    end
  end
end
