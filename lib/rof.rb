require "rof/ingest"
require "rof/version"
require "rof/cli"
require "rof/access"
require "rof/collection"
require "rof/utility"
require "rof/rdf_context"
require "rof/translators"
require "rof/filters"

module ROF
end

# work around Rubydora expecting a logger
unless defined?(logger)
  def logger
    require 'logger'
    @logger ||= Logger.new(STDOUT)
  end
end
