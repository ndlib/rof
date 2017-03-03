require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "./spec/**/*_spec.rb"
    ENV['COVERAGE'] = 'true'
  end
  task default: :spec
rescue LoadError
  $stdout.puts "RSpec failed to load; You won't be able to run tests."
end
