## Generation Notes:
##   This file was generated via the commitment:install generator. You are free
##   and expected to change this file.
if ENV['COV'] || ENV['COVERAGE'] || ENV['TRAVIS']
  if ENV['TRAVIS']
    require 'simplecov'
    SimpleCov.start do
      formatter(
        SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter])
      )
    end
  elsif ENV['COV'] || ENV['COVERAGE']
    require 'simplecov'
    SimpleCov.start
  end
end
