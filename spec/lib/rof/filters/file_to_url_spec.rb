require 'spec_helper'

module ROF
  module Filters
    describe FileToUrl do
      before(:all) do
        @w = FileToUrl.new
      end

      it "skips rof objects which don't have bendo-items" do
        items = [{
          "type" => "ABC"
        }]
        after = @w.process(items)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "type" => "ABC"
        })
      end

      it "skips rof object which don't have a content-file" do
        items = [{
          "type" => "ABC",
          "bendo-item" => "12345"
        },
        {
          "bendo-item" => "12345",
          "thumbnail-content" => "a_file.png"
        }]
        after = @w.process(items)
        expect(after.length).to eq(2)
        expect(after.first).to eq({
          "type" => "ABC",
          "bendo-item" => "12345"
        })
        expect(after.last).to eq({
          "bendo-item" => "12345",
          "thumbnail-content" => "a_file.png"
        })
      end

      it "converts content files into URLs" do
        items = [{
          "bendo-item" => "12345",
          "content-file" => "a/file.txt"
        },{
        "bendo-item" => "12345",
        "content-file" => "b/file.png",
        "content-meta" => {
          "mime-type" => "image/png"
        }}]
        after = @w.process(items)
        expect(after.length).to eq(2)
        expect(after.first).to eq({
          "bendo-item" => "12345",
          "content-meta" => {
            "URL" => "bendo:/item/12345/a/file.txt"
          }
        })
        expect(after.last).to eq({
          "bendo-item" => "12345",
          "content-meta" => {
            "mime-type" => "image/png",
            "URL" => "bendo:/item/12345/b/file.png"
          }
        })
      end
    end
  end
end
