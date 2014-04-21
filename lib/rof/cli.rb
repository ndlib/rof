require 'benchmark'
require 'json'
require 'rubydora'
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
    def self.ingest_file(fname, search_paths=[], outfile=STDOUT, fedora=nil)
      items = nil
      File.open(fname, 'r') do |f|
        items = JSON.parse(f.read)
      end
      items = [items] unless items.is_a? Array
      self.ingest_array(items, search_paths, outfile, fedora)
    rescue JSON::ParserError => e
      outfile.puts("Error reading #{fname}:#{e.to_s}")
      exit!(-1)
    end

    def self.ingest_array(items, search_paths=[], outfile=STDOUT, fedora=nil)
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
              ROF.Ingest(item, fedora, search_paths)
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
    ensure
      outfile.close if outfile && need_close
    end
  end
end
