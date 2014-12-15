require 'spec_helper'

module ROF
  module Filters
    describe DateStamp do
      before(:all) do
        @today = Date.new(2015, 1, 23)
        @today_s = "2015-01-23Z"
        @w = DateStamp.new(@today)
      end

      it "it adds a metadata section if needed" do
        items = [{
          "type" => "ABC"
        }]
        after = @w.process(items)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "type" => "ABC",
          "metadata" => {
            "@context" => ROF::RdfContext,
            "dc:dateSubmitted" => @today_s
          }
        })
      end

      it "adds a metadata relation if missing" do
        items = [{
          "type" => "BCD",
          "metadata" => {
            "dc:title" => "something"
          }
        }]
        after = @w.process(items)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "type" => "BCD",
          "metadata" => {
            "dc:title" => "something",
            "dc:dateSubmitted" => @today_s
          }
        })
      end

      it "doesn't mess with exsiting values" do
        items = [{
          "type" => "CDE",
          "metadata" => {
            "dc:title" => "anotherthing",
            "dc:dateSubmitted" => "any date"
          }
        }]
        after = @w.process(items)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "type" => "CDE",
          "metadata" => {
            "dc:title" => "anotherthing",
            "dc:dateSubmitted" => "any date"
          }
        })
      end
    end
  end
end
