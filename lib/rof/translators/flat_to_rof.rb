require 'rof/translator'
require 'rof/utility'
require('json')

module ROF::Translators
  class FlatToRof < ROF::Translator
    def self.call(flat_list, _config = {})
      result = flat_list.map do |item|
        result = {}
        result['pid'] = item.find_first('pid')
        result['type'] = item.find_first('rof-type')
        result['af-model'] = item.find_first('af-model')

        b = item.find_first('bendo-item')
        result['bendo-item'] = b unless b.nil?

        result['properties'] = ROF::Utility.prop_ds(
          item.find_first('owner'),
          item.find_first('representative'),
          item.find_first('depositor')
        )
        result['properties-meta'] = { 'mime-type' => 'text/xml' }

        furl = item.find_first('file-url')
        fname = item.find_first('filename')
        if furl
          result['content-meta'] = {
            'label' => fname,
            'mime-type' => item.find_first('file-mime-type'),
            'URL' => furl
          }
        elsif fname
          result['content-meta'] = {
            'label' => fname,
            'mime-type' => item.find_first('file-mime-type')
          }
          result['content-file'] = fname
        end

        rels = {}
        add_rels_ext = lambda do |source, target|
          x = item.find_all(source)
          xx = x.select { |v| v =~ /^und:/ } # only keep pids
          rels[target] = xx unless xx.empty?
        end
        add_rels_ext.call('isPartOf', 'isPartOf')
        add_rels_ext.call('isMemberOfCollection', 'isMemberOfCollection')
        add_rels_ext.call('read-person', 'hasViewer')
        add_rels_ext.call('read-group', 'hasViewerGroup')
        add_rels_ext.call('edit-person', 'hasEditor')
        add_rels_ext.call('edit-group', 'hasEditorGroup')
        result['rels-ext'] = rels

        # rightsMetadata
        rights = {}
        add_rights = lambda do |source, target|
          x = item.find_all(source)
          x = x.first if source == 'embargo-date' && !x.nil?
          rights[target] = x unless x.nil? || x.empty?
        end
        add_rights.call('read-person', 'read')
        add_rights.call('read-group', 'read-groups')
        add_rights.call('edit-person', 'edit')
        add_rights.call('edit-group', 'edit-groups')
        add_rights.call('embargo-date', 'embargo-date')
        result['rights'] = rights unless rights.empty?

        # descMetadata
        md = collect_metadata(item)
        result['metadata'] = md unless md.empty?

        result
      end
    end

    def self.collect_metadata(item)
      # pull any fields of the form XXX:YYY into
      # a metadata section and add a "@context" key
      metadata = {}
      item.each_field do |field, v|
        next unless field =~ /([^:]+):.+/
        vv = v.map { |x| ROF::Utility.DecodeDoubleCaret(x) }
        metadata[field] = vv.length == 1 ? vv.first : vv
      end
      # TODO(dbrower): check there are no unknown namespaces?
      metadata['@context'] = ROF::RdfContext unless metadata.empty?
      metadata
    end
  end
end
