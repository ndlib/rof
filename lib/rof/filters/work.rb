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

      def initialize(options = {})
        @file_name = options.fetch(:file_name)
        @utility = ROF::Utility.new
      end
      attr_reader :file_name

      # wade through object list
      def process(obj_list)
        @utility.set_workdir(file_name)
        obj_list.map! { |x| process_one_work(x) }
        obj_list.flatten!
      end

      # given a single object, return a list (possibly empty) of new objects
      # to replace the one given
      def process_one_work(input_obj)
        model = @utility.decode_work_type(input_obj)
        return [input_obj] if model.nil?

        main_obj = set_main_obj(input_obj, model)

        result = [main_obj]
        result = make_thumbnail(result, main_obj, input_obj) unless input_obj['files'].nil?
        result
      end

      # make the first file be the representative thumbnail
      def make_thumbnail(result, main_obj, input_obj)
        thumb_rep = nil
        input_obj['files'].each do |finfo|
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
          mimetype = MIME::Types.of(fname)
          mimetype = mimetype.empty? ? 'application/octet-stream' : mimetype.first.content_type
          f_obj = {
            'type' => 'fobject',
            'af-model' => 'GenericFile',
            'pid' => finfo['pid'],
            'bendo-item' => finfo['bendo-item'],
            'rights' => finfo['rights'],
            'properties' => ROF::Utility.prop_ds(finfo['owner']),
            'properties-meta' => {
              'mime-type' => 'text/xml'
            },
            'rels-ext' => {
              'isPartOf' => [main_obj['pid']]
            },
            'content-file' => fname,
            'content-meta' => {
              'label' => fname,
              'mime-type' => mimetype
            },
            'collections' => finfo['collections'],
            'metadata' => finfo['metadata']
          }
          f_obj.delete_if { |_k, v| v.nil? }
          if thumb_rep.nil?
            thumb_rep = f_obj['pid']
            if thumb_rep.nil?
              thumb_rep = @utility.next_label
              f_obj['pid'] = thumb_rep
            end
            main_obj['properties'] = ROF::Utility.prop_ds(input_obj['owner'], thumb_rep)
          end
          result << f_obj
        end
        result
      end

      def set_main_obj(input_obj, model)
        result = {}

        result['type'] = 'fobject'
        result['af-model'] = model
        result['pid'] = input_obj.fetch('pid', @utility.next_label)
        result['bendo-item'] = input_obj['bendo-item']
        result['rights'] = input_obj['rights']
        result['properties'] = ROF::Utility.prop_ds(input_obj['owner'])
        result['properties-meta'] = { 'mime-type' => 'text/xml' }
        result['rels-ext'] = input_obj.fetch('rels-ext', {})
        result['metadata'] = input_obj['metadata']
        result
      end
    end
  end
end
