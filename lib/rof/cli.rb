require 'benchmark'
require 'rof/compare_rof'
require 'json'
require 'rubydora'
require 'rof/ingest'
require 'rof/collection'
require 'rof/translators'
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
      items = load_items_from_json_file(fname, outfile)
      ingest_array(items, search_paths, outfile, fedora, bendo)
    end

    def self.ingest_array(items, search_paths = [], outfile = STDOUT, fedora = nil, bendo = nil)
      need_close = false
      if outfile.nil?
        outfile = File.open('/dev/null', 'w')
        need_close = true
      end
      fedora = Rubydora.connect(fedora) if fedora
      item_count = 1
      error_count = 0
      verb = fedora.nil? ? 'Verifying' : 'Ingesting'
      overall_benchmark = Benchmark.measure do
        items.each do |item|
          begin
            outfile.write("#{item_count}. #{verb} #{item['pid']} ...")
            item_count += 1
            individual_benchmark = Benchmark.measure do
              ROF.Ingest(item, fedora, search_paths, bendo)
            end
            outfile.write("ok. %0.3fs\n" % individual_benchmark.real)
          rescue Exception => e
            error_count += 1
            outfile.write("error. #{e}\n")
            # TODO(dbrower): add option to toggle displaying backtraces
            if e.backtrace
              outfile.write(e.backtrace.join("\n\t"))
              outfile.write("\n")
            end
          end
        end
      end
      outfile.write("Total time %0.3fs\n" % overall_benchmark.real)
      outfile.write("#{error_count} errors\n")
      error_count
    ensure
      outfile.close if outfile && need_close
    end

    def self.filter_file(filter, fname, outfile = STDOUT)
      items = load_items_from_json_file(fname, STDERR)
      filter_array(filter, items, outfile)
    end

    def self.filter_array(filter, items, outfile = STDOUT)
      # filter will transform the items array in place
      result = filter.process(items)
      outfile.write(JSON.pretty_generate(result))
    end

    # convert OSF archive tar.gz to rof file
    def self.osf_to_rof(config, outfile = STDOUT)
      osf_projects = load_items_from_json_file(config['project_file'], outfile) if config.key?('project_file')
      rof_data = ROF::Translators::OsfToRof.osf_to_rof(config, osf_projects[0])
      outfile.write(JSON.pretty_generate(rof_data))
    end

    # compare two rofs
    def self.compare_files(file1, file2, outfile = STDOUT, _fedora, _bendo)
      fedora_rof = load_items_from_json_file(file1, outfile)
      bendo_rof =  load_items_from_json_file(file2, outfile)

      ROF::CompareRof.fedora_vs_bendo(fedora_rof, bendo_rof, outfile)
    end

    protected

    def self.load_items_from_json_file(fname, outfile = STDERR)
      items = nil
      File.open(fname, 'r:UTF-8') do |f|
        items = JSON.parse(f.read)
      end
      items = [items] unless items.is_a? Array
      items
    rescue JSON::ParserError => e
      outfile.puts("Error reading #{fname}:#{e}")
      exit!(1)
    end
  end
end
