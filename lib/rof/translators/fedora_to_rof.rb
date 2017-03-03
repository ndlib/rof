module ROF
  module Translators
    module FedoraToRof
      # @param pids [Array] Fedora PIDs
      # @param fedora [nil, Hash] Hash with connection information (e.g. URL, User)
      # @param outfile [String, (#write, #close)] A String that is interpretted as a path to a file. Else an IO object responding to #write and #close
      # @param config [Hash]
      # @return Void
      def self.fedora_to_rof(pids, fedora = nil, outfile = STDOUT, config = {})
        need_close = false
        # use outfile is_a String
        if outfile.is_a?(String)
          outfile = File.open(outfile, 'w')
          need_close = true
        end

        # wrap the objects inside a JSON list
        result = []
        pids.each do |pid|
          result << ROF::FedoraToRof.GetFromFedora(pid, fedora, config)
        end
        outfile.write(JSON.pretty_generate(result))
      ensure
        outfile.close if outfile && need_close
      end
    end
  end
end
