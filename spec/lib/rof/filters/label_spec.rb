# frozen_string_literal: true

require 'spec_helper'
require 'support/an_rof_filter'

module ROF
  module Filters
    RSpec.describe Label do
      it_behaves_like 'an ROF::Filter'
      let(:valid_options) { { id_list: ids } }
      let(:ids) { %w[101 102 103 104 105] }

      context 'initialization options' do
        it 'can be initialized with a list of IDs' do
          expect { Label.new(valid_options) }.not_to raise_error
        end
        it 'can be initialized with a noid_server and pool_name' do
          noid_server = double
          pool_name = double
          expect(described_class::NoidsPool).to receive(:new).with(noid_server, pool_name)
          expect { Label.new(noids: { noid_server: noid_server, pool_name: pool_name }) }.not_to raise_error
        end
        it 'will fail if not given a list of IDs nor a noid_server' do
          expect { Label.new }.to raise_error(described_class::NoPool)
        end
      end

      describe '#process' do
        before(:each) do
          @labeler = Label.new(id_list: ids)
        end

        it 'ignores non-fojects' do
          list = [Flat.from_hash('rof-type' => 'not fobject')]
          expect(@labeler.process(list)).to eq([Flat.from_hash('rof-type' => 'not fobject')])
        end
        it 'skips already assigned ids' do
          list = [Flat.from_hash('rof-type' => 'fobject', 'pid' => '123')]
          expect(@labeler.process(list)).to eq([Flat.from_hash('rof-type' => 'fobject', 'pid' => '123', 'bendo-item' => '123')])
        end
        it 'assignes missing pids' do
          list = [Flat.from_hash('rof-type' => 'fobject')]
          expect(@labeler.process(list)).to eq([Flat.from_hash('rof-type' => 'fobject', 'pid' => '101', 'bendo-item' => '101')])
        end
        it 'assignes pids which are labels' do
          list = [Flat.from_hash('rof-type' => 'fobject', 'pid' => '$(zzz)')]
          expect(@labeler.process(list)).to eq([Flat.from_hash('rof-type' => 'fobject', 'pid' => '101', 'bendo-item' => '101')])
        end
        it 'resolves loops' do
          list = [Flat.from_hash('rof-type' => 'fobject',
                                 'pid' => '$(zzz)',
                                 'isPartOf' => ['123', '$(zzz)'])]
          expect(@labeler.process(list)).to eq([Flat.from_hash('rof-type' => 'fobject',
                                                               'pid' => '101',
                                                               'bendo-item' => '101',
                                                               'isPartOf' => %w[123 101])])
        end
        it 'handles multiple items' do
          list = [Flat.from_hash('rof-type' => 'fobject',
                                 'pid' => '$(zzz)',
                                 'isPartOf' => ['123', '$(zzz)']),
                  Flat.from_hash('rof-type' => 'fobject',
                                 'isMemberOfCollection' => ['$(zzz)'])]
          expect(@labeler.process(list)).to eq([
                                                 Flat.from_hash('rof-type' => 'fobject',
                                                                'pid' => '101',
                                                                'bendo-item' => '101',
                                                                'isPartOf' => %w[123 101]),
                                                 Flat.from_hash('rof-type' => 'fobject',
                                                                'pid' => '102',
                                                                'bendo-item' => '101',
                                                                'isMemberOfCollection' => ['101'])
                                               ])
        end

        it 'handles pids in isMemberOfCollection' do
          list = [
            Flat.from_hash('rof-type' => 'fobject', 'pid' => '$(zzz)'),
            Flat.from_hash('rof-type' => 'fobject', 'isMemberOfCollection' => '$(zzz)')
          ]
          expect(@labeler.process(list)).to eq([
                                                 Flat.from_hash('rof-type' => 'fobject', 'pid' => '101', 'bendo-item' => '101'),
                                                 Flat.from_hash('rof-type' => 'fobject', 'pid' => '102', 'bendo-item' => '101', 'isMemberOfCollection' => '101')
                                               ])
        end
      end
    end
    RSpec.describe Label::NoidsPool do
      let(:noids_server_url) { 'https://noids.library.nd.edu' }
      let(:pool_name) { 'rof' }
      let(:inner_pool) { double(mint: [double], closed?: double) }
      let(:connection) { double('Noids Conneciton', get_pool: inner_pool) }
      before do
        expect(NoidsClient::Connection).to receive(:new).with(noids_server_url).and_return(connection)
        expect(connection).to receive(:get_pool).with(pool_name).and_return(inner_pool)
      end
      describe '#shift' do
        subject { described_class.new(noids_server_url, pool_name).shift }
        it "returns the first value of the inner pool's #mint method" do
          expect(subject).to eq(inner_pool.mint.first)
        end
      end
      describe '#empty?' do
        subject { described_class.new(noids_server_url, pool_name).empty? }
        it 'returns whether the inner pool is closed' do
          expect(subject).to eq(inner_pool.closed?)
        end
      end
    end
  end
end
