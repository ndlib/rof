require 'mime-types'

module ROF
  # Called from ROF::Work.process_one_work
  # Can assume type fobject, af-model Collection
  class Collection
    class NoFile < RuntimeError
    end
    def self.process_one_collection(input_obj, utility)
      # set the required fields
      result = set_required_fields(input_obj, utility)
      result = make_images(result, input_obj)
      result
    end

    # Set the fields that must be there
    def self.set_required_fields(obj, utility)
      result = {}
      result['type'] = 'fobject'
      result['af-model'] = 'Collection'
      result['rights'] = obj['rights']
      result['metadata'] = obj['metadata']
      result['pid'] = obj.fetch('pid', utility.next_label)
      result['rels-ext'] = obj['rels-ext']
      result['properties'] = ROF::Utility.prop_ds(obj['owner'])
      result['properties-meta'] = { 'mime-type' => 'text/xml' }
      result
    end

    # If collection included a file, create launch image and thumbnaile
    def self.make_images(subtotal, obj)
      return subtotal if obj['files'].nil?

      # verify source image is present in job dir
      image_source = File.join(Dir.pwd, obj['files'][0])

      # attempt to create a launch page image and thumbnail
      # exit if either fails
      unless File.exist?(image_source)
        STDERR.print("ROF:Collection.make_images: file  ", image_source, " does not exist.\n")
        raise NoFile
      end
      create_images(subtotal, image_source)
    end

    def self.create_images(obj, image_source)
      launch_img = make_launch(image_source)
      thumb_img = make_thumb(image_source)
      raise NoFile if launch_img.nil? || thumb_img.nil?
      obj['content-file'] = File.basename(launch_img)
      obj['content-meta'] = { 'mime-type' => find_file_mime(launch_img) }
      obj['thumbnail-file'] = File.basename(thumb_img)
      obj['thumbnail-meta'] = { 'mime-type' => find_file_mime(thumb_img) }
      obj
    end

    # make collections launch page image
    def self.make_launch(src_image)
      options = ' -resize 350x350 '

      dest_image = mk_dest_img_name(src_image, '-launch')
      unless run_convert(src_image, dest_image, options)
        STDERR.print("ROF:Collection.mk_launch: failed on file  ", src_image, ".\n")
        return nil
      end
      dest_image
    end

    # make thumbnail
    def self.make_thumb(src_image)
      options = ' -resize 256x256 '

      dest_image = mk_dest_img_name(src_image, '-thumb')
      unless run_convert(src_image, dest_image, options)
        STDERR.print("ROF:Collection.mk_thumb: failed on file  ", src_image, ".\n")
        return nil
      end
      dest_image
    end

    def self.run_convert(src_image, dest_image, options)
      command = set_convert_path + ' ' + src_image + options + ' ' + dest_image
      Kernel.system(command)
    end

    # figure out where ImageMagick is installed
    # (assumes brew path on MacOS, binary RPM path on Linux).
    def self.set_convert_path
      host_os = RbConfig::CONFIG['sitearch']

      return '/usr/local/bin/convert' if host_os.include? 'darwin'
      '/usr/bin/convert'
    end

    # given source image, create destination name for conversion
    # keep same mime type - use dumb mime type determination
    def self.mk_dest_img_name(src_img, dest_name)
      dest_part = src_img.split('.')
      dest_img = dest_part[0] + dest_name
      dest_img = dest_img + '.' + dest_part[1] if dest_part.length == 2
      dest_img
    end

    # extract file extension and determine mime/type.
    def self.find_file_mime(filename)
      MIME::Types.of(filename).first.content_type
    end
  end
end
