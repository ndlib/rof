# frozen_string_literal: true

require 'mime-types'
require 'rof/filter'
module ROF
  module Filters
    # Expand objects of type "Work(-(.+))?" into a
    # constellation of "fobjects".
    # Makes a fobject/generic_file for each file
    # adds a depositor
    # turns original object into an fobject/$1
    # and copies the access to each fobject.
    class Work < ROF::Filter
      class NoFile < RuntimeError
      end

      def initialize(_options = {})
        @seq = 0
      end

      # wade through object list
      def process(obj_list)
        obj_list.map! { |x| process_one_work(x) }
        obj_list.flatten!
      end

      # given a single object, return a list (possibly empty) of new objects
      # to replace the one given
      def process_one_work(input_obj)
        model = decode_work_type(input_obj)
        return [input_obj] if model.nil?

        main_obj = input_to_rof(input_obj, model)

        # make the first file be the representative thumbnail
        thumb_rep = input_obj['representative'] # might be nil
        result = [main_obj]
        input_obj['files']&.each do |finfo|
          file_rof = make_file_rof(finfo, main_obj['pid'], input_obj)
          if thumb_rep.nil?
            thumb_rep = file_rof['pid']
            main_obj['properties'] = ROF::Utility.prop_ds(input_obj['owner'], thumb_rep)
          end
          result << file_rof
        end
        result
      end

      def make_file_rof(finfo, main_pid, input_obj)
        if finfo.is_a?(String)
          fname = finfo
          finfo = { 'files' => [fname] }
        else
          fname = finfo['files'].first
          raise NoFile if fname.nil?
        end
        finfo['rights'] ||= input_obj['rights']
        finfo['owner'] ||= input_obj['owner']
        finfo['bendo-item'] ||= input_obj['bendo-item']
        finfo['metadata'] ||= {
          '@context' => ROF::RdfContext
        }
        finfo['metadata']['dc:title'] ||= fname
        finfo['representative'] = nil
        finfo['rels-ext'] = { 'isPartOf' => [main_pid] }
        f_obj = input_to_rof(finfo, 'GenericFile')
        f_obj['content-file'] = fname
        mimetype = MIME::Types.of(fname)&.first&.content_type || 'application/octet-stream'
        f_obj['content-meta'] = {
          'label' => fname,
          'mime-type' => mimetype
        }
        f_obj['collections'] = finfo['collections']
        f_obj.delete_if { |_k, v| v.nil? }
        f_obj
      end

      def input_to_rof(input_obj, model)
        {
          'type' => 'fobject',
          'af-model' => model,
          'pid' => input_obj.fetch('pid') { next_label }, # only make label if needed
          'bendo-item' => input_obj['bendo-item'],
          'rights' => input_obj['rights'],
          'properties' => ROF::Utility.prop_ds(input_obj['owner'], input_obj['representative']),
          'properties-meta' => { 'mime-type' => 'text/xml' },
          'rels-ext' => input_obj.fetch('rels-ext', {}),
          'metadata' => input_obj['metadata']
        }
      end

      # Issue pid label
      def next_label
        "$(pid--#{@seq})".tap { |_| @seq += 1 }
      end

      WORK_TYPE_WITH_PREFIX_PATTERN = /^[Ww]ork(-(.+))?/.freeze

      WORK_TYPES = {
        # csv name => af-model
        'article' => 'Article',
        'dataset' => 'Dataset',
        'document' => 'Document',
        'etd' => 'Etd',
        'image' => 'Image',
        'gtar' => 'Gtar',
        'osfarchive' => 'OsfArchive'
      }.freeze

      # Given an object's type, detrmine and return its af-model
      def decode_work_type(obj)
        if obj['type'] =~ WORK_TYPE_WITH_PREFIX_PATTERN
          return 'GenericWork' if Regexp.last_match(2).nil?

          Regexp.last_match(2)
        else
          # this will return nil if key t does not exist
          work_type = obj['type'].downcase
          WORK_TYPES[work_type]
        end
      end
    end
  end
end
