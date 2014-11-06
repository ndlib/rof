require 'spec_helper'

module ROF
  module Filters
    describe Label do
      let(:ids) { ["101", "102", "103", "104", "105"] }
      before(:each) {
        @labeler = Label.new(nil, id_list: ids)
      }
      it "ignores non-fojects" do
        list = [{"type" => "not fobject"}]
        expect(@labeler.process(list)).to eq([{"type" => "not fobject"}])
      end
      it "skips already assigned ids" do
        list = [{"type" => "fobject", "pid" => "123"}]
        expect(@labeler.process(list)).to eq([{"type" => "fobject", "pid" => "123"}])
      end
      it "assignes missing pids" do
        list = [{"type" => "fobject"}]
        expect(@labeler.process(list)).to eq([{"type" => "fobject", "pid" => "101"}])
      end
      it "assignes pids which are labels" do
        list = [{"type" => "fobject", "pid" => "$(zzz)"}]
        expect(@labeler.process(list)).to eq([{"type" => "fobject", "pid" => "101"}])
      end
      it "resolves loops" do
        list = [{"type" => "fobject",
                 "pid" => "$(zzz)",
                 "rels-ext" => {
                    "partOf" => ["123", "$(zzz)"]
                 }}]
        expect(@labeler.process(list)).to eq([{"type" => "fobject",
                                               "pid" => "101",
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
        expect(@labeler.process(list)).to eq([{"type" => "fobject",
                                               "pid" => "101",
                                               "rels-ext" => {
                                                  "partOf" => ["123", "101"]}},
        {"type" => "fobject",
         "pid" => "102",
         "rels-ext" => { "memberOf" => ["101"]}}])
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
    end
  end
end
