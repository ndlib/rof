require "rof/ingest"
require "rof/version"
require "rof/cli"
require "rof/filters/label"

module ROF
end

# work around Rubydora expecting a logger
unless defined?(logger)
  def logger
    require 'logger'
    @logger ||= Logger.new(STDOUT)
  end
end