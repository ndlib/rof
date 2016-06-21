require 'benchmark'
require 'json'
require 'rubydora'
require 'rof/ingest'
require 'rof/collection'
require 'rof/get_from_fedora'
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
    def self.ingest_file(fname, search_paths=[], outfile=STDOUT, fedora=nil, bendo=nil)
      items = self.load_items_from_file(fname, outfile)
      self.ingest_array(items, search_paths, outfile, fedora, bendo)
    end

    def self.ingest_array(items, search_paths=[], outfile=STDOUT, fedora=nil, bendo=nil)
      need_close = false
      if outfile == nil
        outfile = File.open("/dev/null", "w")
        need_close = true
      end
      if fedora
        fedora = Rubydora.connect(fedora)
      end
      item_count = 1
      error_count = 0
      verb = fedora.nil? ? "Verifying" : "Ingesting"
      overall_benchmark = Benchmark.measure do
        items.each do |item|
          begin
            outfile.write("#{item_count}. #{verb} #{item["pid"]} ...")
            item_count += 1
            individual_benchmark = Benchmark.measure do
              ROF.Ingest(item, fedora, search_paths, bendo)
            end
            outfile.write("ok. %0.3fs\n" % individual_benchmark.real)
          rescue Exception => e
            error_count += 1
            outfile.write("error. #{e.to_s}\n")
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

    def self.filter_file(filter, fname, outfile=STDOUT)
      items = self.load_items_from_file(fname, STDERR)
      self.filter_array(filter, items, outfile)
    end

    def self.filter_array(filter, items, outfile=STDOUT)
      # filter will transform the items array in place
      result = filter.process(items)
      outfile.write(JSON.pretty_generate(result))
    end

    # retrieve fedora object and convert to ROF
    def self.convert_to_rof(pid, fedora=nil, outfile=STDOUT, config)
      # open output file if needed
      need_close = false
      # what is the use case for the /dev/null option???
      outfile = "/dev/null" unless outfile
      # use outfile is_a String
      if outfile != STDOUT
        outfile = File.open(outfile , "w")
        need_close = true
      end

      fedora_data =  ROF::FedoraToRof.GetFromFedora(pid, fedora, config)
      outfile.write(JSON.pretty_generate(fedora_data))
    ensure
      outfile.close if outfile && need_close
    end

    protected

    def self.load_items_from_file(fname, outfile)
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
