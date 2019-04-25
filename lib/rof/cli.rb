require 'benchmark'
require 'rof/compare_rof'
require 'json'
require 'rubydora'
require 'rof/ingest'
require 'rof/translators'
require 'rof/utility'
module ROF
  module CLI
    # Ingest the file `fname` that is a level 0 rof file. It may contain any
    # number of fedora objects; they will be delt with in the order they appear
    # in the file. Any external files (except fname) are searched for using the
    # `search_path` array of directories. If `fedora` is present, it is a hash
    # having the keys `url`, `user`, and `password`. Omitting `fedora` has the
    # effect of verifying the format of `fname`.
    #
    # All output is sent to `outfile`.
    #
    # Returns the number of errors.
    def self.ingest_file(fname, search_paths = [], outfile = STDOUT, fedora = nil, bendo = nil)
      items = ROF::Utility.load_items_from_json_file(fname, outfile)
      ingest_array(items, search_paths, outfile, fedora, bendo)
    end

    # @param [NilClass, String, #write] outfile - where should we write things
    # @see .with_outfile_handling for details on outfile
    def self.ingest_array(items, search_paths = [], outfile = STDOUT, fedora = nil, bendo = nil)
      fedora = Rubydora.connect(fedora) if fedora
      item_count = 1
      error_count = 0
      verb = fedora.nil? ? 'Verifying' : 'Ingesting'
      with_outfile_handling(outfile) do |writer|
        overall_benchmark = Benchmark.measure do
          items.each do |item|
            begin
              writer.write("#{item_count}. #{verb} #{item['pid']} ...")
              item_count += 1
              individual_benchmark = Benchmark.measure do
                ROF.Ingest(item, fedora, search_paths, bendo)
              end
              writer.write("ok. %0.3fs\n" % individual_benchmark.real)
            rescue Exception => e
              error_count += 1
              writer.write("error. #{e}\n")
              # TODO(dbrower): add option to toggle displaying backtraces
              if e.backtrace
                writer.write(e.backtrace.join("\n\t"))
                writer.write("\n")
              end
            end
          end
        end
        writer.write("Total time %0.3fs\n" % overall_benchmark.real)
        writer.write("#{error_count} errors\n")
      end
      error_count
    end

    # Responsible for loading the given :fname into an array of items, the processing
    # those items via the :filter, and finally writing results to the :output
    #
    # @param [#process] filter - the object that processes the items loaded from the fname
    # @param [String] fname - the filename from which to load items
    # @param [NilClass, String, #write] outfile - where should we write things
    # @see .with_outfile_handling for details on outfile
    # @return void
    def self.filter_file(filter, fname, outfile = STDOUT)
      items = ROF::Utility.load_items_from_json_file(fname, STDERR)
      result = filter.process(items)
      with_outfile_handling(outfile) do |writer|
        writer.write(JSON.pretty_generate(result))
      end
    end

    # convert OSF archive tar.gz to rof file
    # @param [String] project_file - The path to the OSF Project file
    # @param [Hash] config
    # @param [NilClass, String, #write] outfile - where should we write things
    # @see .with_outfile_handling for details on outfile
    def self.osf_to_rof(project_file, config = {}, outfile = STDOUT)
      osf_projects = ROF::Utility.load_items_from_json_file(project_file, outfile)
      result = ROF::Translators::OsfToRof.call(osf_projects[0], config)
      with_outfile_handling(outfile) do |writer|
        writer.write(JSON.pretty_generate(result))
      end
    end

    # Convert the given fedora PIDs to ROF JSON document
    # @param [Array] pids - The path to the OSF Project file
    # @param [Hash] config
    # @param [NilClass, String, #write] outfile - where should we write things
    # @see .with_outfile_handling for details on outfile
    def self.fedora_to_rof(pids, config = {}, outfile = STDOUT)
      result = ROF::Translators::FedoraToRof.call(pids, config)
      with_outfile_handling(outfile) do |writer|
        writer.write(JSON.pretty_generate(result))
      end
    end

    # Convert the given CSV to ROF JSON document
    # @param [String] csv - The contents of a CSV file
    # @param [Hash] config
    # @param [NilClass, String, #write] outfile - where should we write things
    # @see .with_outfile_handling for details on outfile
    # @see ROF::Translators::CsvToRof.call
    def self.csv_to_rof(csv, config = {}, outfile = STDOUT)
      result = ROF::Translators::CsvToRof.call(csv, config)
      with_outfile_handling(outfile) do |writer|
        writer.write(JSON.pretty_generate(result))
      end
    end

    # Convert the given JSON-LD to ROF JSON document
    # @param [Hash] jsonld - contents of a CSV file
    # @param [Hash] config
    # @param [NilClass, String, #write] outfile - where should we write things
    # @see .with_outfile_handling for details on outfile
    # @see ROF::Translators::JsonldToRof.call
    def self.jsonld_to_rof(jsonld, config = {}, outfile = STDOUT)
      result = ROF::Translators::JsonldToRof.call(jsonld, config)
      with_outfile_handling(outfile) do |writer|
        writer.write(JSON.pretty_generate(result))
      end
    end

    # compare two rofs
    # @param [String] file1 - path to "left" file in the comparison
    # @param [String] file2 - path to "right" file in the comparison
    # @param [#write] outfile - where to write any errors (default STDOUT)
    # @return [Integer] number of comparisons that failed. If 0, then the two given files are logically equal
    # @todo Should the outfile default to STDERR
    def self.compare_files(file1, file2, outfile = STDOUT)
      fedora_rof = ROF::Utility.load_items_from_json_file(file1, outfile)
      bendo_rof =  ROF::Utility.load_items_from_json_file(file2, outfile)

      ROF::CompareRof.fedora_vs_bendo(fedora_rof, bendo_rof, outfile)
    end

    # Provides a normalized handling of outfiles:
    #
    # @param [NilClass, String, #write] outfile - The IO point that we will write to
    # @yieldparam [#write] writer - An object that can be written to
    def self.with_outfile_handling(outfile)
      need_close = false
      # use outfile is_a String
      if outfile.is_a?(String)
        outfile = File.open(outfile, 'w')
        need_close = true
      elsif outfile.nil?
        outfile = File.open('/dev/null', 'w')
        need_close = true
      end
      yield(outfile)
    ensure
      outfile.close if outfile && (need_close || outfile.respond_to?(:close))
    end
  end
end
