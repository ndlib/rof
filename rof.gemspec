# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rof/version'

Gem::Specification.new do |spec|
  spec.name          = "rof"
  spec.version       = ROF::VERSION
  spec.authors       = [
    "Jeremy Friesen"
  ]
  spec.email         = ["jeremy.n.friesen@gmail.com"]
  spec.description   = %q{Raw Object Format}
  spec.summary       = %q{Raw Object Format}
  spec.homepage      = "https://github.com/ndlib/rof"
  spec.license       = "APACHE2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rdf", "~> 2.0.1"
  spec.add_dependency "rdf-rdfxml"
  # constrain rdf-turtle since the newer version wants rdf 2.2
  spec.add_dependency "rdf-turtle", '~> 2.0.0'
  spec.add_dependency "rdf-isomorphic"
  spec.add_dependency "json-ld", "~> 2.0.0"
  spec.add_dependency "mime-types", "~> 2.4"
  spec.add_dependency "rubydora", "~> 1.8.1"
  spec.add_dependency "noids_client"
  spec.add_dependency 'deprecation', '~> 0.1'
  spec.add_dependency 'nokogiri', '~> 1.6.8.1' # Need this version for older rubies
  # only needed because we use ruby < 2.2.2 in production and that doesn't play
  # nice with rails 5
  spec.add_dependency 'activesupport', '< 5.0'
  spec.add_dependency 'ebnf', '< 1.0.2'
  # adding this only because bundler selects version 2.1 and it breaks things
  spec.add_dependency 'rdf-xsd', '~> 2.0.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'equivalent-xml'
end
