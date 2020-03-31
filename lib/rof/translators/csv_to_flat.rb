# frozen_string_literal: true

require 'rof/translator'
require 'rof/utility'
require('csv')
require('json')

module ROF::Translators
  # Turn a CSV file into a list of Flat records.
  #
  # Additional processing may be necessary.
  #
  # Columns are mapped pretty much as-is. Multiple values in a single field are
  # allowed, separate them with a pipe '|'
  #
  # Special fields
  # --------------
  # type  -- mandatory. single valued, the ROF type of this object
  # curate_id -- optional. single valued, the pid or noid of the parent object (e.g. "ab12cd34j" or "und:ab12cd34j")
  # owner -- mandatory. The owner of this object and any children objects. Must be a Curate User name
  # access -- optional. The access policy of this object. defaults to "public". See below
  # bendo-item -- optional. The bendo item name to save this object into.
  #
  # access is described by an "access string".
  #
  # fields with a name of the form XXX:YYY will be treated as descriptive metadata.
  #
  # As a special case, a type of "+" will insert a generic file associated
  # with the previous work translated into ROF. This will allow a work to have
  # attached files with different access permissions, owners, etc...
  # Any extra files are appended to the file list for the work.
  class CsvToFlat < ROF::Translator
    class UnknownNamespace < RuntimeError
      attr_reader :ns
      def initialize(ns)
        @ns = ns
      end
    end

    class NoPriorWork < RuntimeError
    end

    def self.call(csv_contents, _config = {})
      first_line = nil
      flat_records = []
      previous_work = nil
      CSV.parse(csv_contents) do |row|
        if first_line.nil?
          first_line = row
          next
        end
        next if row.length <= 1 # skip blank lines

        result = Flat.new
        access = nil
        row.each_with_index do |field, i|
          next if field.nil? || field.empty?

          column_name = first_line[i]
          field.strip!
          case column_name
          when 'rights'
            access = field
          when 'owner', 'access', 'bendo-item', 'representative', 'file-mime-type', 'filename', 'file-with-path', 'af-model'
            result.add(column_name, field)
          when 'file-URL'
            result.add('file-url', field)
          when 'type', 'rof-type'
            result.add('type', field)
          when 'curate_id', 'pid'
            result.add('pid', field)
          when 'collections'
            result.add('isMemberOfCollection', field.split('|').map(&:strip))
          else
            result.add(column_name, field.split('|').map(&:strip))
          end
        end
        decode_access(result, access || 'private')

        if result.find_first('depositor').nil?
          result.add('depositor', 'batch_ingest')
        end

        # is this a generic file which should be attached to the previous work?
        if result.find_first('type') == '+'
          raise NoPriorWork if previous_work.nil?

          # HACK: we need to pass a structured flat record to the work decoder
          # but values should only be strings. So we sexp encode it, and on the
          # other side the work processer is smart enough to decode it.
          previous_work.add('files', result.to_sexp)
        else
          previous_work = result
          flat_records << result
        end
      end
      flat_records
    end

    def decode_access(flatrecord, access)
      h = ROF::Access.decode(access, flatrecord.find_first('owner'))
      flatrecord.add('read-person', h['read'])
      flatrecord.add('read-group', h['read-groups'])
      flatrecord.add('edit-person', h['edit'])
      flatrecord.add('edit-group', h['edit-groups'])
      flatrecord.add('embargo-date', h['embargo-date'])
    end
  end
end
