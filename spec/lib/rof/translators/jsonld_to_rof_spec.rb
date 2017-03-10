require 'spec_helper'

module ROF
  module Translators
    # ```console
    # ssh app@sipity.library.nd.edu
    # cd /mnt/curatend-batch/production/success
    # find . -maxdepth 2 -name '*.rof' -type f | xargs grep -l <pid>
    # ```
    RSpec.describe JsonldToRof do
      describe '.call' do
        [
          'm039k358q5c',
          'zk51vd69n1r'
        ].each do |noid|
          context "with JSON-LD from NOID=#{noid} CurateND work that was ingested via the batch ingester" do
            it 'will return ROF that is a subset of the ROF used by the batch ingestor' do
              jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/#{noid}.jsonld")))
              rof_generated_via_batch = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/metadata-#{noid}.rof")))
              expected_output = Array.wrap(rof_generated_via_batch)
              actual_output = described_class.call(jsonld_from_curatend, {})
              # Quick check that top level keys are the same
              expect(actual_output.first.keys.sort).to eq(expected_output.first.keys.sort)
              actual_output.first.keys.each do |key|
                actual_metadata = normalize(actual_output.first.fetch(key))
                expected_metadata = normalize(expected_output.first.fetch(key))
                expect(actual_metadata).to eq(expected_metadata)
              end
              comparer = ROF::CompareRof.new(actual_output, expected_output, skip_rels_ext_context: true)
              expect(comparer.compare_rights).to eq(0)
              expect(comparer.compare_rels_ext).to eq(0)
              expect(comparer.compare_metadata).to eq(0)
              expect(comparer.compare_everything_else).to eq(0)
            end
          end
        end

        # Responsible for normalizing a Hash or non-Hash
        def normalize(input)
          if input.is_a?(Hash)
            returning_hash = {}
            input.keys.sort.each do |key|
              raw_value = input[key]
              next if key == '@context' # Because Sipity's ROF context was messed up
              Array.wrap(raw_value).each do |value|
                returning_hash[key] ||= []
                if value.is_a?(Hash)
                  hash = {}
                  value.keys.sort.each do |sorted_key|
                    hash[sorted_key] ||= []
                    Array.wrap(value[sorted_key]).sort.each do |sorted_value|
                      hash[sorted_key] << sorted_value.gsub("\n", "")
                    end
                  end
                  value = hash
                else
                  value.gsub!("\n", "")
                end
                returning_hash[key] << value
              end
              returning_hash[key] = returning_hash[key].sort if returning_hash[key].respond_to?(:sort)
            end
            returning_hash
          else
            Array.wrap(input).map { |obj| obj.gsub("\n", '') }
          end
        end
      end
    end
  end
end
