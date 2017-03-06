require 'spec_helper'
require 'support/an_rof_filter'

module ROF
  module Filters
    RSpec.describe Label do
      it_behaves_like "an ROF::Filter"
      let(:valid_options) { { id_list: ids } }
      let(:ids) { ["101", "102", "103", "104", "105"] }

      context 'initialization options' do
        it 'can be initialized with a list of IDs' do
          expect { Label.new(valid_options) }.not_to raise_error
        end
        it 'can be initialized with a noid_server and pool_name' do
          noid_server = double
          pool_name = double
          expect(described_class::NoidsPool).to receive(:new).with(noid_server, pool_name)
          expect { Label.new(noid_server: noid_server, pool_name: pool_name) }.not_to raise_error
        end
        it 'will fail if not given a list of IDs nor a noid_server' do
          expect { Label.new }.to raise_error(described_class::NoPool)
        end
      end

      describe '#process' do
        before(:each) {
          @labeler = Label.new(id_list: ids)
        }

        it "ignores non-fojects" do
          list = [{"type" => "not fobject"}]
          expect(@labeler.process(list)).to eq([{"type" => "not fobject"}])
        end
        it "skips already assigned ids" do
          list = [{"type" => "fobject", "pid" => "123"}]
          expect(@labeler.process(list)).to eq([{"type" => "fobject", "pid" => "123", "bendo-item" => "123"}])
        end
        it "assignes missing pids" do
          list = [{"type" => "fobject"}]
          expect(@labeler.process(list)).to eq([{"type" => "fobject", "pid" => "101", "bendo-item" => "101"}])
        end
        it "assignes pids which are labels" do
          list = [{"type" => "fobject", "pid" => "$(zzz)"}]
          expect(@labeler.process(list)).to eq([{"type" => "fobject", "pid" => "101", "bendo-item" => "101"}])
        end
        it "resolves loops" do
          list = [{"type" => "fobject",
                   "pid" => "$(zzz)",
                   "rels-ext" => {
                      "partOf" => ["123", "$(zzz)"]
                   }}]
          expect(@labeler.process(list)).to eq([{"type" => "fobject",
                                                 "pid" => "101",
                                                 "bendo-item"=>"101",
                                                 "rels-ext" => {
                                                    "partOf" => ["123", "101"]}}])
        end
        it "handles multiple items" do
          list = [{"type" => "fobject",
                   "pid" => "$(zzz)",
                   "rels-ext" => {
                      "partOf" => ["123", "$(zzz)"]
                   }},
                  {"type" => "fobject",
                   "rels-ext" => { "memberOf" => ["$(zzz)"]}}]
          expect(@labeler.process(list)).to eq([
                {"type" => "fobject",
                 "pid" => "101",
                 "bendo-item" => "101",
                 "rels-ext" => {
                   "partOf" => ["123", "101"]
                 }},
                {"type" => "fobject",
                 "pid" => "102",
                 "bendo-item" => "101",
                 "rels-ext" => {
                   "memberOf" => ["101"]
                 }}
                ])
        end
        it "errors on undefined labels" do
          list = [{"type" => "fobject",
                   "rels-ext" => {
                      "partOf" => ["123", "$(zzz)"]
                   }}]
          expect { @labeler.process(list) }.to raise_error(Label::MissingLabel)
        end

        it "replaces labels in arrays" do
          list = ["a", "something $(b) and $(a)", "$(not a label)"]
          labels = {"a" => "abc", "b" => "qwe"}
          expect(@labeler.replace_labels(list, labels, false)).to eq(["a", "something qwe and abc", "$(not a label)"])

          hash = {"$(a)" => "this should $(b)", sym: :symbol, b: {b: "$(a) $(z)"}}
          expect(@labeler.replace_labels(hash, labels, false)).to eq({
            "$(a)" => "this should qwe",
            sym: :symbol,
            b: {b: "abc $(z)"}
          })
        end

        it "handles pids in isMemberOf" do
          list = [
            {"type" => "fobject", "pid" => "$(zzz)"},
            {"type" => "fobject", "rels-ext" => { "isMemberOfCollection" => ["$(zzz)"]}}
          ]
          expect(@labeler.process(list)).to eq([
            {"type" => "fobject", "pid" => "101", "bendo-item" =>"101"},
            {"type" => "fobject", "pid" => "102", "bendo-item" =>"101", "rels-ext" => { "isMemberOfCollection" => ["101"]}}
          ])
        end
      end
    end
  end
end
