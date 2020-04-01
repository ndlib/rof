# frozen_string_literal: true

require 'spec_helper'
require 'support/an_rof_filter'

module ROF
  module Filters
    describe Work do
      it_behaves_like 'an ROF::Filter'
      let(:valid_options) { {} }
      it 'makes the first file be the representative' do
        w = Work.new

        item = Flat.from_hash('type' => 'Work', 'owner' => 'user1', 'files' => ['a.txt', 'b.jpeg'])
        after = w.process_one_work(item)
        expect(after.length).to eq(3)
        expect(after[0]).to eq(Flat.from_hash('rof-type' => 'fobject',
                                              'af-model' => 'GenericWork',
                                              'pid' => '$(pid--0)',
                                              'representative' => '$(pid--1)',
                                              'owner' => 'user1'))
        expect(after[1]).to eq(Flat.from_hash('rof-type' => 'fobject',
                                              'af-model' => 'GenericFile',
                                              'pid' => '$(pid--1)',
                                              'content-file' => 'a.txt',
                                              'dc:title' => 'a.txt',
                                              'depositor' => 'batch_ingest',
                                              'file-mime-type' => 'text/plain',
                                              'isPartOf' => '$(pid--0)',
                                              'owner' => 'user1'))
        expect(after[2]).to eq(Flat.from_hash('rof-type' => 'fobject',
                                              'dc:title' => 'b.jpeg',
                                              'af-model' => 'GenericFile',
                                              'content-file' => 'b.jpeg',
                                              'depositor' => 'batch_ingest',
                                              'file-mime-type' => 'image/jpeg',
                                              'isPartOf' => '$(pid--0)',
                                              'owner' => 'user1',
                                              'pid' => '$(pid--2)'))
      end

      it 'decodes file metadata correctly' do
        w = Work.new

        item = Flat.from_hash(
          'type' => 'Work',
          'owner' => 'user1',
          'edit-person' => 'user1',
          'dc:title' => 'Q, A Letter',
          'files' => [
            'thumb',
            '(record (type +)(owner user1)(files "extra file.txt")(edit-person user1))'
          ]
        )
        after = w.process_one_work(item)
        expect(after.length).to eq(3)
        expect(after[0]).to eq(Flat.from_hash('rof-type' => 'fobject',
                                              'af-model' => 'GenericWork',
                                              'pid' => '$(pid--0)',
                                              'owner' => 'user1',
                                              'representative' => '$(pid--1)'))
        expect(after[1]).to eq(Flat.from_hash('rof-type' => 'fobject',
                                              'af-model' => 'GenericFile',
                                              'pid' => '$(pid--1)',
                                              'content-file' => 'thumb',
                                              'dc:title' => 'thumb',
                                              'depositor' => 'batch_ingest',
                                              'file-mime-type' => 'application/octet-stream',
                                              'isPartOf' => '$(pid--0)',
                                              'owner' => 'user1'))
        expect(after[2]).to eq(Flat.from_hash('rof-type' => 'fobject',
                                              'af-model' => 'GenericFile',
                                              'content-file' => 'extra file.txt',
                                              'dc:title' => 'extra file.txt',
                                              'depositor' => 'batch_ingest',
                                              'file-mime-type' => 'text/plain',
                                              'edit-person' => 'user1',
                                              'isPartOf' => '$(pid--0)',
                                              'owner' => 'user1',
                                              'pid' => '$(pid--2)'))
      end
    end

    describe 'decode_work_type' do
      [{ input: 'Work', output: 'GenericWork' },
       { input: 'Work-Image', output: 'Image' },
       { input: 'Work-image', output: 'image' },
       { input: 'Image', output: 'Image' },
       { input: 'image', output: 'Image' },
       { input: 'Other', output: nil },
       { input: 'article', output: 'Article' },
       { input: 'dataset', output: 'Dataset' },
       { input: 'document', output: 'Document' },
       { input: 'etd', output: 'Etd' },
       { input: 'ETD', output: 'Etd' }].each do |t|
        it 'decodes ' + t[:input] do
          w = Work.new
          result = w.decode_work_type(Flat.from_hash('type' => t[:input]))
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
