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

namespace :commitment do
  task :configure_test_for_code_coverage do
    ENV['COVERAGE'] = 'true'
  end
  desc "Check for code that can go faster"
  task :fasterer do
    require 'fasterer/file_traverser'
    file_traverser = Fasterer::FileTraverser.new(nil)
    file_traverser.traverse
    if file_traverser.offenses_found?
      $stderr.puts "You can make the code go faster, see above. You can add exceptions in .fasterer.yml"
      abort
    end
  end
  task :code_coverage do
    require 'json'
    # Our goal is to stay at this coverage level or higher; As the level increases, we bump up the goal
    COVERAGE_GOAL = 91
    $stdout.puts "Checking code_coverage"
    lastrun_filename = File.expand_path('../coverage/.last_run.json', __FILE__)
    if File.exist?(lastrun_filename)
      coverage_percentage = JSON.parse(File.read(lastrun_filename)).fetch('result').fetch('covered_percent').to_i
      if coverage_percentage < COVERAGE_GOAL
        abort("ERROR: Code Coverage Goal Not Met:\n\t#{coverage_percentage}%\tExpected\n\t100%\tActual")
      else
        $stdout.puts "Code Coverage Goal Met (#{COVERAGE_GOAL}%)"
      end
    else
      abort "Expected #{lastrun_filename} to exist for code coverage"
    end
  end
end

task(default: ['commitment:configure_test_for_code_coverage', :spec, 'commitment:code_coverage'])
