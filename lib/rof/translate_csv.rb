require('csv')
require('json')

module ROF
  # Turn a CSV file into a ROF file.
  #
  # pass in the contents of the CSV file.
  # Out come an array of ROF objects.
  # Additional processing may be necessary.
  #
  # Will raise an error if there are no type or owner columns, or if those
  # columns are blank for some row.
  #
  # other columns are mapped pretty much as is.
  #
  # Multiple values in a single field are allowed, separate them with a pipe '|'
  #
  # Special fields
  # --------------
  # type  -- mandatory. single valued, the ROF type of this object
  # curate_id -- optional. single valued, the pid or noid of the parent object (e.g. "ab12cd34j" or "und:ab12cd34j")
  # owner -- mandatory. The owner of this object and any children objects. Must be a Curate User name
  # access -- optional. The access policy of this object. defaults to "public". See below
  #
  # access is described by an "access string".
  #
  # fields with a name of the form XXX:YYY will be treated as descriptive metadata.
  #
  class TranslateCSV
    class ParseError < RuntimeError
    end

    class UnknownNamespace < RuntimeError
      attr_reader :ns
      def initialize(ns)
        @ns = ns
      end
    end

    def self.run(csv_contents)
      first_line = nil
      rof_contents = []
      CSV.parse(csv_contents) do |row|
        if first_line.nil?
          first_line = row
          if ! (first_line.include?("type") && first_line.include?("owner"))
            raise ParseError
          end
          next
        end
        next if row.length <= 1
        result = {}
        row.each_with_index do |item, i|
          next if item.nil?
          item.strip!
          case first_line[i]
          when "type", "owner", "access"
            result[first_line[i]] = item
          when "curate_id"
            result["pid"] = item
          else
            result[first_line[i]] = item.split("|")
          end
        end
        if result["type"].nil? or result["owner"].nil?
          raise ParseError
        end
        result["rights"] = ROF::Access.decode(result.fetch("access", "private"), result["owner"])
        result.delete("access")
        result = self.collect_metadata(result)
        rof_contents << result
      end
      rof_contents
    end

    def self.collect_metadata(rof)
      # pull any fields of the form XXX:YYY into
      # a metadata section and add a "@context" key
      metadata = {}
      rof = rof.delete_if do |k,v|
        if k =~ /([^:]+):.+/
          xv = v.first if v.length == 1
          metadata[k] = v.length == 1 ? v.first : v
          true
        else
          false
        end
      end
      return rof if metadata.empty?
      # TODO(dbrower): check there are no unknown namespaces
      metadata["@context"] = ROF::Namespaces
      rof["metadata"] = metadata
      rof
    end
  end
end
