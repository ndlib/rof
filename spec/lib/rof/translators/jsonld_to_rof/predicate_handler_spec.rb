require 'spec_helper'
require 'rof/translators/jsonld_to_rof/predicate_handler'
module ROF
  module Translators
    module JsonldToRof
      RSpec.describe PredicateHandler do
        around do |spec|
          # Ensuring that we preserve duplication of
          previous_registry = described_class.send(:registry)
          described_class.send(:clear_registry!)
          described_class.register('https://library.nd.edu/ns/terms/') do |handler|
            handler.map('accessRead', to: ['rights', 'read'])
          end
          described_class.register('http://purl.org/dc/terms/') do |handler|
            handler.namespace_prefix('dc:')
            handler.map('dateTime', to: ['nested', 'dateTime'])
            handler.within(['metadata'])
          end
          described_class.register('http://www.ndltd.org/standards/metadata/etdms/1.1/') do |handler|
            handler.within(['ms:degree'])
            handler.namespace_prefix('ms:')
            handler.map('block-key') do |object, accumulator|
              accumulator.add_predicate_location_and_value('from-block', object)
            end
            handler.map('something', to: ['metadata', 'ms:something'], force: true)
            handler.map('something', to: ['another', 'somewhere'])
          end
          spec.run
          described_class.send(:clear_registry!, previous_registry)
        end

        describe '.call' do
          let(:object) { 'my-object' }
          let(:accumulator) { Accumulator.new }

          it 'handles multiple map imperatives' do
            described_class.call('http://www.ndltd.org/standards/metadata/etdms/1.1/something', object, accumulator)
            expect(accumulator.to_rof).to eq({
              "metadata" => { "ms:something" => [object] },
              "ms:degree" => { "another" => { "ms:somewhere" => [object] } }
            })
          end

          it 'handles force option' do
            described_class.call('https://library.nd.edu/ns/terms/accessRead', object, accumulator)
            expect(accumulator.to_rof).to eq({ "rights" => { "read" => ["my-object"] } })
          end

          it 'handles the block option' do
            described_class.call('http://www.ndltd.org/standards/metadata/etdms/1.1/block-key', 'value' , accumulator)
            expect(accumulator.to_rof).to eq({ "from-block" => ["value"] })
          end

          it 'handles mixture of implicit and explicit terms using within and namespace_prefix' do
            described_class.call('http://purl.org/dc/terms/title', 'my-title', accumulator)
            described_class.call('http://purl.org/dc/terms/dateTime', 'my-dateTime', accumulator)
            expect(accumulator.to_rof).to eq({
              "metadata" => { "dc:title" => ["my-title"], "nested" => { "dc:dateTime" => ["my-dateTime"] } }
            })
          end

          context 'with an unregistred url' do
            it 'will raise an exception' do
              expect do
                expect { described_class.call('http://the.unhandled.com', 'my-title', accumulator) }.to raise_error(described_class::UnhandledPredicateError)
              end.not_to change { accumulator.to_rof }
            end
          end
        end
      end
    end
  end
end
