require 'rof/translator'
require 'rof/utility'
require('csv')
require('json')

module ROF::Translators
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
  class CsvToRof < ROF::Translator
    class MissingOwnerOrType < RuntimeError
    end

    class UnknownNamespace < RuntimeError
      attr_reader :ns
      def initialize(ns)
        @ns = ns
      end
    end

    class NoPriorWork < RuntimeError
    end

    def self.call(csv_contents, config = {})
      first_line = nil
      rof_contents = []
      previous_work = nil
      CSV.parse(csv_contents) do |row|
        if first_line.nil?
          first_line = row
          next
        end
        next if row.length <= 1
        result = {}
        row.each_with_index do |item, i|
          next if item.nil?
          column_name = first_line[i]
          case column_name
          when 'owner', 'access', 'bendo-item', 'representative', 'file-URL', 'file-mime-type', 'filename', 'file-with-path', 'af-model'
            result[column_name] = item.strip
          when 'type', 'rof-type'
            result['type'] = item.strip
          when 'curate_id', 'pid'
            result['pid'] = item.strip
          when 'collections'
            result['rels-ext'] = {}
            result['rels-ext']['isMemberOfCollection'] = item.split('|').map(&:strip)
          else
            result[column_name] = item.split('|').map(&:strip)
          end
        end
        raise MissingOwnerOrType if result['type'].nil? || result['owner'].nil?
        result['rights'] = ROF::Access.decode(result.fetch('access', 'private'), result['owner'])
        result.delete('access')
        result = collect_metadata(result)
        if result['type'] == 'fobject'
          # this is an already processed item, so populate all of the datastreams
          result = collect_other_datastreams(result)
        end
        # is this a generic file which should be attached to the previous work?
        if result['type'] == '+'
          raise NoPriorWork if previous_work.nil?
          previous_work['files'] = previous_work.fetch('files', []) + [result]
        else
          previous_work = result
          rof_contents << result
        end
      end
      rof_contents
    end

    def self.collect_metadata(rof)
      # pull any fields of the form XXX:YYY into
      # a metadata section and add a "@context" key
      metadata = {}
      rof = rof.delete_if do |field, v|
        if field =~ /([^:]+):.+/
          vv = v.map{|x| ROF::Utility.DecodeDoubleCaret(x)}
          metadata[field] = vv.length == 1 ? vv.first : vv
          true
        else
          false
        end
      end
      return rof if metadata.empty?
      # TODO(dbrower): check there are no unknown namespaces
      metadata['@context'] = ROF::RdfContext
      rof['metadata'] = metadata
      rof
    end

    RELS_EXT_FIELDS = ["isPartOf", "isMemberOfCollection"]

    def self.collect_other_datastreams(rof)
      # need to populate the rels-ext, the properties, and (maybe) the content
      rels = {}
      RELS_EXT_FIELDS.each do |field|
        next unless rof[field]
        rels[field] = rof.delete(field)
      end
      rof['rels-ext'] = rels

      rof['properties'] = ROF::Utility.prop_ds(rof['owner'], rof['representative'], "batch_ingest")
      rof['properties-meta'] = { 'mime-type' => 'text/xml' }
      rof.delete('representative')

      if rof['file-URL']
        rof['content-meta'] = {
          'label' => rof.delete('filename'),
          'mime-type' => rof.delete('file-mime-type'),
          'URL' => rof.delete('file-URL'),
        }
      elsif rof['filename']
        rof['content-meta'] = {
          'label' => rof.delete('filename'),
          'mime-type' => rof.delete('file-mime-type')
        }
        rof['content-file'] = rof.delete('filename')
      end
      rof.delete('file-with-path')
      rof
    end
  end
end
