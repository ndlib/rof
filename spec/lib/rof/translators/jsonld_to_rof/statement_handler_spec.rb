require 'spec_helper'
require 'rof/translators/jsonld_to_rof/statement_handler'
require 'rof/translators/jsonld_to_rof/accumulator'

module ROF
  module Translators
    module JsonldToRof
      RSpec.describe StatementHandler do
        let(:accumulator) { Accumulator.new }
        let(:statement) { RDF::Statement.new(subject: rdf_subject, predicate: rdf_predicate, object: rdf_object) }
        let(:rdf_predicate) { RDF::URI.new("http://purl.org/dc/terms/title") }
        let(:rdf_object) { RDF::Literal.new("Hello World") }
        describe '.call' do
          subject { described_class.call(statement, accumulator) }
          context 'for a URI subject' do
            let(:pid) { 'abcd1234' }
            let(:rdf_subject) { RDF::URI.new("https://curate.nd.edu/show/#{pid}") }
            it 'accumulates the pid' do
              subject
              expect(accumulator.to_rof.fetch('pid')).to eq("und:#{pid}")
            end
          end
          context 'for a Node subject' do
            let(:rdf_subject) { RDF::Node.new("_b1") }
            it 'does not accumulate a pid' do
              subject
              expect(accumulator.to_rof.key?('pid')).to eq(false)
            end
          end
          context 'for a something else' do
            let(:rdf_subject) { nil }
            it 'raises an error' do
              expect { subject }.to raise_error(described_class::UnhandledRdfSubjectError)
            end
          end
        end
      end
    end
  end
end
