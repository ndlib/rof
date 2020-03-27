# frozen_string_literal: true

require 'spec_helper'
require 'support/an_rof_filter'

module ROF
  module Filters
    describe Work do
      it_behaves_like 'an ROF::Filter'
      let(:valid_options) { {} }
      it 'handles variant work types' do
        w = Work.new

        item = { 'type' => 'Work', 'owner' => 'user1' }
        after = w.process_one_work(item)
        expect(after.first).to include('type' => 'fobject', 'af-model' => 'GenericWork')

        item = { 'type' => 'Work-Image', 'owner' => 'user1' }
        after = w.process_one_work(item)
        expect(after.first).to include('type' => 'fobject', 'af-model' => 'Image')

        item = { 'type' => 'work-image', 'owner' => 'user1' }
        after = w.process_one_work(item)
        expect(after.first).to include('type' => 'fobject', 'af-model' => 'image')

        item = { 'type' => 'Image', 'owner' => 'user1' }
        after = w.process_one_work(item)
        expect(after.first).to include('type' => 'fobject', 'af-model' => 'Image')

        item = { 'type' => 'image', 'owner' => 'user1' }
        after = w.process_one_work(item)
        expect(after.first).to include('type' => 'fobject', 'af-model' => 'Image')

        item = { 'type' => 'Other', 'owner' => 'user1' }
        after = w.process_one_work(item)
        expect(after.first).to eq(item)
      end

      it 'makes the first file be the representative' do
        w = Work.new

        item = { 'type' => 'Work', 'owner' => 'user1', 'files' => ['a.txt', 'b.jpeg'] }
        after = w.process_one_work(item)
        expect(after.length).to eq(3)
        expect(after[0]).to include('type' => 'fobject',
                                    'af-model' => 'GenericWork',
                                    'pid' => '$(pid--0)',
                                    'properties' => ROF::Utility.prop_ds('user1', '$(pid--1)'))
        expect(after[1]).to include('type' => 'fobject',
                                    'af-model' => 'GenericFile',
                                    'pid' => '$(pid--1)')
        expect(after[2]).to include('type' => 'fobject',
                                    'af-model' => 'GenericFile')
        expect(after[2]['metadata']).to include('dc:title' => 'b.jpeg')
      end

      it 'decodes files correctly' do
        w = Work.new

        item = {
          'type' => 'Work',
          'owner' => 'user1',
          'rights' => { 'edit' => ['user1'] },
          'metadata' => {
            '@context' => RdfContext,
            'dc:title' => 'Q, A Letter'
          },
          'files' => [
            'thumb',
            {
              'type' => '+',
              'owner' => 'user1',
              'files' => ['extra file.txt'],
              'rights' => { 'edit' => ['user1'] }
            }
          ]
        }
        after = w.process_one_work(item)
        expect(after.length).to eq(3)
        expect(after[0]).to include('type' => 'fobject',
                                    'af-model' => 'GenericWork',
                                    'rels-ext' => {},
                                    'pid' => '$(pid--0)')
        expect(after[1]).to include('type' => 'fobject',
                                    'af-model' => 'GenericFile',
                                    'pid' => '$(pid--1)',
                                    'content-file' => 'thumb')
        expect(after[2]).to include('type' => 'fobject',
                                    'af-model' => 'GenericFile',
                                    'content-file' => 'extra file.txt')
      end
    end

    describe 'decode_work_type' do
      [{ input: 'article', output: 'Article' },
       { input: 'dataset', output: 'Dataset' },
       { input: 'document', output: 'Document' },
       { input: 'etd', output: 'Etd' },
       { input: 'ETD', output: 'Etd' },
       { input: 'image', output: 'Image' }].each do |t|
        it 'decodes ' + t[:input] do
          w = Work.new
          result = w.decode_work_type('type' => t[:input])
          expect(result).to eq(t[:output])
        end
      end
    end

    describe 'next_label' do
      it 'assigns initial label' do
        w = Work.new
        id = w.next_label
        expect(id).to eq '$(pid--0)'
      end
    end
  end
end
