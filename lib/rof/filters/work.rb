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
      def process_one_work(input_record)
        model = decode_work_type(input_record)
        return [input_record] if model.nil?

        work_record = create_work_record(input_record, model)

        # make the first file be the representative thumbnail
        thumb_rep = input_record.find_first('representative') # might be nil

        result = [work_record]
        input_record.find_all('files')&.each do |finfo|
          file_record = create_file_record(finfo, work_record, input_record)
          if thumb_rep.nil?
            thumb_rep = file_record.fin_first('pid')
            work_record.set('representative', thumb_rep)
          end
          result << file_record
        end
        result
      end

      def create_file_record(rec, work_record, _input_record)
        file_rec = ROF::Utility.DecodeDoubleCaret(rec)
        if file_rec.is_a?(String)
          fname = file_rec
          target = Flat.new
        else
          fname = file_rec.delete('files')&.first
          raise NoFile if fname.nil?

          target = Flat.from_hash(file_rec)
         end
        target.add('pid', next_label) unless target.find_first('pid')
        target.set('rof-type', 'fobject')
        target.set('af-model', 'GenericFile')
        target.add_if_missing('owner', work_record.find_all('owner'))
        target.add_if_missing('bendo-item', work_record.find_first('bendo-item'))
        target.add_if_missing('dc:title', fname)
        target.add_if_missing('file-mime-type', MIME::Types.of(fname).first&.content_type || 'application/octet-stream')
        target.add_if_missing('depositor', 'batch_ingest')
        target.add('isPartOf', work_record.find_first('pid'))
        target.add('content-file', fname)

        target.add_if_missing('rights', work_record.find_all('rights'))
        target
      end

      def create_work_record(input_record, model)
        result = Flat.new
        result.add('type', 'fobject')
        result.add('af-model', model)
        result.add('pid', input_record.find_first('pid') || next_label)
        result.add('bendo-item', input_record.find_first('bendo-item'))
        result.add('owner', input_record.find_all('owner'))
        result.add('depositor', input_record.find_all('depositor'))
        result.add('representative', input_record.find_all('representative'))
        # result['rights'] = input_obj['rights']
        # result['rels-ext'] = input_obj.fetch('rels-ext', {})
        # result['metadata'] = input_obj['metadata']
        result
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
        t = obj.find_first('type')
        if t =~ WORK_TYPE_WITH_PREFIX_PATTERN
          return 'GenericWork' if Regexp.last_match(2).nil?

          Regexp.last_match(2)
        else
          # this will return nil if key t does not exist
          work_type = t.downcase
          WORK_TYPES[work_type]
        end
      end
    end
  end
end
