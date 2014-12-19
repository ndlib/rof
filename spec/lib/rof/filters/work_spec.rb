require 'spec_helper'

module ROF
  module Filters
    describe Work do
      it "handles variant work types" do
        w = Work.new

        item = {"type" => "Work", "owner" => "user1"}
        after = w.process_one_work(item)
        expect(after.first).to include("type" => "fobject", "af-model" => "GenericWork")

        item = {"type" => "Work-Image", "owner" => "user1"}
        after = w.process_one_work(item)
        expect(after.first).to include("type" => "fobject", "af-model" => "Image")

        item = {"type" => "work-image", "owner" => "user1"}
        after = w.process_one_work(item)
        expect(after.first).to include("type" => "fobject", "af-model" => "image")

        item = {"type" => "Image", "owner" => "user1"}
        after = w.process_one_work(item)
        expect(after.first).to include("type" => "fobject", "af-model" => "Image")

        item = {"type" => "image", "owner" => "user1"}
        after = w.process_one_work(item)
        expect(after.first).to include("type" => "fobject", "af-model" => "Image")

        item = {"type" => "Other", "owner" => "user1"}
        after = w.process_one_work(item)
        expect(after.first).to eq(item)
      end

      it "makes the first file be the representative" do
        w = Work.new

        item = {"type" => "Work", "owner" => "user1", "files" => ["a.txt", "b.jpeg"]}
        after = w.process_one_work(item)
        expect(after.length).to eq(3)
        expect(after[0]).to include("type" => "fobject",
                                    "af-model" => "GenericWork",
                                    "pid" => "$(pid--0)",
                                    "properties" => w.properties_ds("user1", "$(pid--1)"))
        expect(after[1]).to include("type" => "fobject",
                                    "af-model" => "GenericFile",
                                    "pid" => "$(pid--1)")
        expect(after[2]).to include("type" => "fobject",
                                    "af-model" => "GenericFile")
        expect(after[2]["metadata"]).to include("dc:title" => "b.jpeg")
      end
    end
  end
end
