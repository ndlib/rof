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

  spec.add_dependency "rdf"
  spec.add_dependency "rdf-rdfxml"
  spec.add_dependency "rdf-aggregate-repo"
  spec.add_dependency "rdf-turtle"
  spec.add_dependency 'rdf-rdfa'
  spec.add_dependency "rdf-isomorphic"
  spec.add_dependency "json-ld"
  spec.add_dependency 'ebnf'
  spec.add_dependency 'rdf-xsd'

  spec.add_dependency "mime-types"
  spec.add_dependency "rubydora", "~> 1.8.1"
  spec.add_dependency "noids_client"
  spec.add_dependency "rsolr", "~> 1.1.2"
  spec.add_dependency 'deprecation', '~> 0.1'
  spec.add_dependency 'nokogiri'

  spec.add_development_dependency "fasterer"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'equivalent-xml'
  spec.add_development_dependency "bundler" "~>1.17.3"

end
