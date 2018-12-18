require 'rof/filter'
require 'active_support/core_ext/string/inflections'

module ROF
  module Filters
    # Make Filename and its label URL-legal
    class FilenameNormalize < ROF::Filter
      def initialize(options = {})
      end

      # Adjust the content labels and URL of all items in the obj_list.
      # If move_files is true, then also try to rename the files in the filesystem.
      def process(obj_list, move_files=true)
        nerr = 0
        # We need to map access with pid to rels-ext predicates
        obj_list.map! do |obj|
          content_meta = obj.fetch('content-meta', nil)
          next obj if content_meta.nil?
          label = content_meta.fetch('label', nil)
          if !label.nil?
            content_meta['label'] = make_url_friendly(label)
          end
          url = content_meta.fetch('URL', nil)
          if !url.nil?
            old_name = File.basename(url)
            new_name = make_url_friendly(old_name)
            content_meta['URL'] = File.join(File.dirname(url), new_name)
            if old_name != new_name && move_files
              begin
                rename_file(old_name, new_name)
              rescue StandardError => e
                # in case of an error, try to keep going so we can report as many
                # errors as possible. And then raise an error at the end.
                STDERR.puts "\tError: #{e}"
                nerr += 1
              end
            end
          end
          obj
        end
        if nerr > 0
          raise "Problem Renaming Files"
        end
        obj_list
      end

      # make_url_friendly is identical to ActiveSupport::Inflector.parameterize
      # except that it preserves case
      def make_url_friendly(string, sep = '-')
        # replace accented chars with their ascii equivalents
        parameterized_string = ::ActiveSupport::Inflector.transliterate(string)
        # Turn unwanted chars into the separator
        parameterized_string.gsub!(/[^a-zA-Z0-9\-_.]+/, sep)
        unless sep.nil? || sep.empty?
          re_sep = Regexp.escape(sep)
          # No more than one of the separator in a row.
          parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
          # Remove leading/trailing separator.
          parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
        end
        parameterized_string
      end

      # rename file associated with label
      # If JOBPATH is defined, use that directory as a base;
      # otherwise, start in the current directory
      # Send exception errors to STDERR for calling task to handle.
      def rename_file(old_name, new_name)
        job_dir = ENV.fetch('JOBPATH', '.')
        File.rename(File.join(job_dir, old_name), File.join(job_dir, new_name))
      end
    end
  end
end
