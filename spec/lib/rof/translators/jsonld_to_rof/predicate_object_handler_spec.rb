require 'spec_helper'
require 'rof/translators/jsonld_to_rof/predicate_object_handler'

module ROF
  module Translators
    module JsonldToRof
      RSpec.describe PredicateObjectHandler do
        let(:accumulator) { Accumulator.new }
        let(:rdf_predicate) { RDF::URI.new("http://purl.org/dc/terms/title") }
        describe '.call' do
          subject { described_class.call(rdf_predicate, rdf_object, accumulator) }
          context 'for an RDF::URI' do
            let(:rdf_object) { RDF::URI.new("http://curate.nd.edu/show/1234") }
            it 'accumulates the value' do
              subject
              expect(accumulator.to_rof.fetch('metadata').fetch('dc:title')).to eq(['und:1234'])
            end
          end
          context 'for an RDF::Literal' do
            let(:rdf_object) { RDF::Literal.new("Hello World") }
            it 'accumulates the value' do
              subject
              expect(accumulator.to_rof.fetch('metadata').fetch('dc:title')).to eq(['Hello World'])
            end
          end
          context 'for an RDF::Node' do
            let(:rdf_subject) { RDF::Node.new('_b0') }
            let(:rdf_object) { RDF::Node.new('_b0') }
            let(:rdf_predicate) { RDF::URI.new("http://www.ndltd.org/standards/metadata/etdms/1.1/") }
            it 'expands the blank nodes already accumulated values' do
              statement = RDF::Statement.new(subject: rdf_object, predicate: RDF::URI.new('http://www.ndltd.org/standards/metadata/etdms/1.1/name'), object: RDF::Literal.new('Awesome Sauce'))
              accumulator.add_blank_node(statement)
              subject
              expect(accumulator.to_rof.fetch('metadata').fetch('ms:degree')).to eq([{ "ms:name" => ['Awesome Sauce'] }])
            end
          end

          context 'for an unhandled object type' do
            let(:rdf_object) { double }
            it 'raises an error' do
              expect { subject }.to raise_error(described_class::UnknownRdfObjectTypeError)
            end
          end
        end
      end
    end
  end
end
