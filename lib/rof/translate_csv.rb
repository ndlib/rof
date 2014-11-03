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
  # access is described by an "access string". The following are valid access strings:
  #
  #   "public"
  #   "restricted"
  #   "private"
  #   "read:"+username,
  #   "edit:"+username,
  class TranslateCSV
    class ParseError < RuntimeError
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
        rof_contents << result
      end
      rof_contents
    end
  end
end
