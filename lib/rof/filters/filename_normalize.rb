require 'rof/filter'
require 'active_support/core_ext/string/inflections'

module ROF
  module Filters
    # Make Filename and its label URL-legal
    class FilenameNormalize < ROF::Filter
      def initialize(options = {})
      end

      def process(obj_list)
        # We need to map access with pid to rels-ext predicates
        obj_list.map! do |obj|
          if obj.key?('content-meta')
            if obj['content-meta'].key?('label')
	      file_renamed = rename_file(obj['content-meta']['label'],  make_url_friendly(obj['content-meta']['label']))
	      if file_renamed
                obj['content-meta']['label'] = make_url_friendly(obj['content-meta']['label'])
	      end
            end
            if obj['content-meta'].key?('URL')
              obj['content-meta']['URL'] = File.join(File.dirname(obj['content-meta']['URL']), make_url_friendly(File.basename(obj['content-meta']['URL'])))
            end
          end
          obj
        end
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
        return false if old_name == new_name
        begin
	  job_dir = ENV.fetch('JOBPATH', '.')
          File.rename(File.join(job_dir ,old_name), File.join(job_dir ,new_name))
        rescue StandardError=>e
          STDERR.puts "\tError: #{e}"
        end
	return true
      end
    end
  end
end
