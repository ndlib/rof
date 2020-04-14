require 'spec_helper'

module ROF
  module Translators
    # ```console
    # ssh app@sipity.library.nd.edu
    # cd /mnt/curatend-batch/production/success
    # find . -maxdepth 2 -name '*.rof' -type f | xargs grep -l <pid>
    # ```
    RSpec.describe JsonldToRof do
      describe 'DLTP-999 regression' do
        it 'converts @graph > @id keys to pid' do
          jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/DLTP-999/pr76f190f54.jsonld")))
          output = described_class.call(jsonld_from_curatend, {})
          expect(output.size).to eq(1) # We have one item
          expect(output.first.fetch('pid')).to eq('und:pr76f190f54')
          expect(output.first['rights'].fetch('embargo-date')).to eq("2016-11-16")
        end
      end

      describe 'DLTP-1007 regression' do
        it 'converts representative XML correctly' do
          jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/DLTP-1007/remediated-z029p269r94.jsonld")))
          output = described_class.call(jsonld_from_curatend, {})
          expect(output.size).to eq(1)
          properties = output.first.fetch('properties')
          expect(properties).to include('<representative>und:z603qv36b1d</representative>')
        end
      end

      describe 'DLTP-1015 regression verification' do
        it 'converts bendo-item, embargo-date, representative and alephNumber to string' do
          jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/DLTP-1015/dltp1015.jsonld")))
          output = described_class.call(jsonld_from_curatend, {})
          expect(output.size).to eq(1)
          object = output.first
          expect(object.fetch('properties')).to include('<representative>und:representative123</representative>')
          expect(object.fetch('rights').fetch('embargo-date')).to eq("2016-11-16")
          expect(object.fetch('metadata').fetch('nd:alephIdentifier')).to eq("aleph123")
          expect(object.fetch('bendo-item')).to eq("bendo123")
        end
      end

      describe 'DLTP-1021 regression verification' do
        context 'for non-ETDs' do
          it 'does not have blank nodes for dc:contributor' do
            jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/DLTP-1021/dltp-1021-document.jsonld")))
            expect(jsonld_from_curatend["@graph"]["nd:afmodel"]).to eq('Document')
            output = described_class.call(jsonld_from_curatend, {})
            expect(output.size).to eq(1)
            object = output.first
            expect(object.fetch('metadata').fetch('dc:contributor')).to eq(['Ilan Stavans'])
          end
        end
        context 'for ETDs' do
          it 'keeps the blank nodes for dc:contributor' do
            jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/DLTP-1021/dltp-1021-etd.jsonld")))
            expect(jsonld_from_curatend["@graph"].last['nd:afmodel']).to eq('Etd')
            output = described_class.call(jsonld_from_curatend, {})
            expect(output.size).to eq(1)
            object = output.first
            expect(object.fetch('metadata').fetch('dc:contributor')).to eq([
              { "dc:contributor" => ["Dr. Spock"], "ms:role" => ["Committee Member"] },
              { "dc:contributor" => ["Dr. Quinn"], "ms:role" => ["Committee Chair"] },
              { "dc:contributor" => ["Dr. Zhivago"], "ms:role" => ["Committee Member"] }
            ])
          end
        end
      end

      describe 'jsonld-translation regression verification' do
        it 'discards content, thumbnail, and mimetype' do
          jsonld_from_curatend = JSON.load(File.read(File.join(GEM_ROOT, "spec/fixtures/jsonld-translation/5h73pv65x8x.jsonld")))
          output = described_class.call(jsonld_from_curatend, {})
          expect(output.size).to eq(1)
          object = output.first
          expect(object.fetch('characterization')).to be_a(String)
          expect(object.fetch('characterization')).to eq(jsonld_from_curatend.fetch('nd:characterization'))

          # Checking that we don't include the following keys.
          json_doc = JSON.dump(object)
          ['content', 'thumbnail',  'mimetype'].each do |key|
            value = "#{key.upcase}_SHOULD_NOT_BE_IN_ROF"
            expect(json_doc).not_to include(value)
          end
        end
      end

      describe '::REGEXP_FOR_A_CURATE_RDF_SUBJECT' do
        it 'handles data as expected' do
          [
            ["https://curate.nd.edu/downloads/abcd123", nil],
            ["http://curate.nd.edu/downloads/abcd123", nil],
            ["http://curatepprd.nd.edu/downloads/abcd123", nil],
            ["http://curatepprd.nd.edu/show/abcd123", "abcd123"],
            ["https://curatepprd.nd.edu/show/abcd123", "abcd123"],
            ["https://curatepprd.library.nd.edu/show/abcd123", "abcd123"],
            ["https://curate.nd.edu/show/abcd123", "abcd123"],
            ["http://curate.nd.edu/show/abcd123", "abcd123"],
            ["http://mycurate.nd.edu/show/abcd123", nil],
            ["http://curate.nd.edu/show/abcd123/extra", 'abcd123'],
          ].each do |input, expected|
            input =~ described_class::REGEXP_FOR_A_CURATE_RDF_SUBJECT
            expect($1).to eq(expected)
          end
        end
      end

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
          '5h73pv66f5t',
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
