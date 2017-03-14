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
          '2j62s467216',
          'js956d59913',
          'xg94hm53h0c',
          '0g354f18610',
          '2v23vt16z2z',
          'h989r21069m',
          'cr56n01253w',
          'm039k358q5c',
          'zk51vd69n1r',
          'nk322b9161g',
          'p8418k7430d'
        ].each do |noid|
          context "with JSON-LD from NOID=#{noid} CurateND work that was ingested via the batch ingester" do
            it 'will return ROF that is a subset of the ROF used by the batch ingestor' do
              rof_generated_via_batch = normalize_rof(noid)

              jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/#{noid}.jsonld")))
              expected_output = Array.wrap(rof_generated_via_batch)
              actual_output = described_class.call(jsonld_from_curatend, {})
              keys = (actual_output.first.keys + expected_output.first.keys).uniq
              expected_rof = {}
              actual_rof = {}
              keys.each do |key|
                actual_metadata = normalize(actual_output.first.fetch(key, {}))
                actual_rof[key] = actual_metadata

                expected_metadata = normalize(expected_output.first.fetch(key, {}))
                expected_rof[key] = expected_metadata
                # We may have {} for one, and [] for another. In this case, both are empty, so we'll skip.
                next if actual_metadata.empty? && expected_metadata.empty?
                expect(actual_metadata).to eq(expected_metadata), "Mismatch on #{key}.\n\tJSON-LD: #{actual_metadata.inspect}\n\tROF: #{expected_metadata.inspect}"
              end
              comparer = ROF::CompareRof.new(actual_rof, expected_rof, skip_rels_ext_context: true)
              expect(comparer.compare_rights).to eq(0)
              expect(comparer.compare_rels_ext).to eq(0)
              expect(comparer.compare_metadata).to eq(0)
              expect(comparer.compare_everything_else).to eq(0)
            end
          end
        end

        def normalize_rof(noid)
          path_to_rof = File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld_to_rof/#{noid}.rof"))

          # Normalizing some of the @context entries to reflect JSON-LD entries
          if path_to_rof.include?('"ths": "http://id.loc.gov/vocabulary/relators/"')
            path_to_rof.gsub!('"ths": "http://id.loc.gov/vocabulary/relators/"', '"mrel": "http://id.loc.gov/vocabulary/relators/"')
            path_to_rof.gsub!('"ths:', '"mrel:')
          end
          rof = JSON.load(path_to_rof)
          # Removing @id as they are superflous
          rof[0]['metadata'].delete('@id') if rof[0].key?('metadata')
          rof[0]['rels-ext'].delete('@id') if rof[0].key?('rels-ext')
          rof
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
                      hash[sorted_key] << normalize_string(sorted_value.dup)
                    end
                  end
                  value = hash
                else
                  normalize_string(value)
                end
                returning_hash[key] << value
              end
              begin
                returning_hash[key] = returning_hash[key].sort if returning_hash[key].respond_to?(:sort)
              rescue ArgumentError
                returning_hash[key]
              end
              # next unless returning_hash[key].present?
              if returning_hash[key]
                returning_hash[key] = returning_hash[key].reject(&:empty?)
                returning_hash.delete(key) if returning_hash[key].empty?
              end
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
