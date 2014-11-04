require "rof/ingest"
require "rof/version"
require "rof/cli"
require "rof/access"
require "rof/namespaces"
require "rof/translate_csv"
require "rof/filters/label"
require "rof/filters/work"

module ROF
end

# work around Rubydora expecting a logger
unless defined?(logger)
  def logger
    require 'logger'
    @logger ||= Logger.new(STDOUT)
  end
end
