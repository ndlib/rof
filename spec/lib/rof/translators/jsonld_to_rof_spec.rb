require 'spec_helper'

module ROF
  module Translators
    RSpec.describe JsonldToRof do
      describe '.call' do
        let(:config) { {} }
        let(:jsonld_from_curatend) { JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/zk51vd69n1r.jsonld"))) }
        let(:rof_generated_via_batch) { JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/metadata-zk51vd69n1r.rof"))) }
        let(:expected_output) { [rof_generated_via_batch.detect { |node| node.fetch('af-model') == 'Etd' }] }
        context 'with JSON-LD from a CurateND work that was ingested via the batch ingester' do
          it 'will return ROF that is a subset of the ROF used by the batch ingestor' do
            actual_output = described_class.call(jsonld_from_curatend, config)
            # Quick check that top level keys are the same
            expect(actual_output.first.keys.sort).to eq(expected_output.first.keys.sort)
            actual_output.first.keys.each do |key|
              actual_metadata = normalize(actual_output.first.fetch(key))
              expected_metadata = normalize(expected_output.first.fetch(key))
              expect(actual_metadata).to eq(expected_metadata)
            end
            comparer = ROF::CompareRof.new(actual_output, expected_output, skip_rels_ext_context: true)
            expect(comparer.error_count).to eq(0)
          end
        end

        # Responsible for normalizing a Hash or non-Hash
        def normalize(input)
          return Array.wrap(input) unless input.is_a?(Hash)
          returning_hash = {}
          input.keys.sort.each do |key|
            raw_value = input[key]
            next if key == '@context' # Because Sipity's ROF context was messed up
            Array.wrap(raw_value).each do |value|
              returning_hash[key] ||= []
              if value.is_a?(Hash)
                hash = {}
                value.keys.sort.each do |sorted_key|
                  hash[sorted_key] = Array.wrap(value[sorted_key]).sort
                end
                value = hash
              end
              returning_hash[key] << value
            end
          end
          returning_hash
        end
      end
    end
  end
end
