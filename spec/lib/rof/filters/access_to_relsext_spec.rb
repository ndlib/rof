require 'spec_helper'
require 'rof/filters/access_to_relsext'
require 'support/an_rof_filter'

RSpec.describe ROF::Filters::AccessToRelsext do
  it_behaves_like "an ROF::Filter"
  let(:access_to_relsext){ nil }
  let(:valid_options) { {} }

  describe '#process' do
    subject { described_class.new.process(original_object_list) }
    let(:original_object_list) do
      [
        { "rights" => {
            "read-groups" => ["bogus", "registered" ],
            "edit" => [
            "non-pid",
            "und:pid"],
            "embargo-date"=> "2016-12-25",
            "edit-groups" => ["und:editgrouppid"]
          }
        }
      ]
    end
    context 'maps to relsext' do
      it 'will map access to relsext' do
        expected_object_list = [
          {
            "rights" => {
            "read-groups" => ["bogus", "registered"],
            "edit" => [
                "non-pid",
                "und:pid"],
            "embargo-date"=> "2016-12-25",
            "edit-groups" => ["und:editgrouppid"]
            },
           "rels-ext" => {
              "hasEditor" => ["und:pid"],
              "hasEditorGroup"=> ["und:editgrouppid"]
           }
          }
        ]
        expect(subject).to eq(expected_object_list)
      end
    end


  end
end
