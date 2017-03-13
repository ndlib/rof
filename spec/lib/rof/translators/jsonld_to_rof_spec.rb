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
          'zk51vd69n1r',
          'nk322b9161g',
          'p8418k7430d'
        ].each do |noid|
          context "with JSON-LD from NOID=#{noid} CurateND work that was ingested via the batch ingester" do
            it 'will return ROF that is a subset of the ROF used by the batch ingestor' do
              rof = File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/#{noid}.rof"))
              jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/#{noid}.jsonld")))
              rof_generated_via_batch = JSON.load(rof)
              expected_output = Array.wrap(rof_generated_via_batch)
              actual_output = described_class.call(jsonld_from_curatend, {})
              keys = (actual_output.first.keys + expected_output.first.keys).uniq
              keys.each do |key|
                actual_metadata = normalize(actual_output.first.fetch(key, {}))
                expected_metadata = normalize(expected_output.first.fetch(key, {}))
                # We may have {} for one, and [] for another. In this case, both are empty, so we'll skip.
                next if actual_metadata.empty? && expected_metadata.empty?
                expect(actual_metadata).to eq(expected_metadata), "Mismatch on #{key}.\n\tJSON-LD: #{actual_metadata.inspect}\n\tROF: #{expected_metadata.inspect}"
              end
              comparer = ROF::CompareRof.new(actual_output, expected_output, skip_rels_ext_context: true)
              expect(comparer.compare_rights).to eq(0)
              expect(comparer.compare_rels_ext).to eq(0)
              expect(comparer.compare_metadata).to eq(0)
              expect(comparer.compare_everything_else).to eq(0)
            end
          end
        end

        # @todo For any key with an empty array, delete that key
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
                      hash[sorted_key] << normalize_string(sorted_value)
                    end
                  end
                  value = hash
                else
                  normalize_string(value)
                end
                returning_hash[key] << value
              end
              returning_hash[key] = returning_hash[key].sort if returning_hash[key].respond_to?(:sort)
            end
            returning_hash
          else
            Array.wrap(input).map { |obj| normalize_string(obj) }
          end
        end

        def normalize_string(input)
          # Forcing escaped unicode hexadecimal to the "human" readable format
          input.gsub!(/\\u([0-F]{4})/) { '' << Regexp.last_match[1].to_i(16) }
          input.gsub!("\n", '')
          input
        end
      end
    end
  end
end
