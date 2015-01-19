require 'spec_helper'

module ROF
  module Filters
    describe Collections do
      before(:all) do
        @w = Collections.new
      end

      it "it skips items with no pid" do
        items = [{
          "type" => "ABC"
        }]
        after = @w.process(items)
        expect(after).to eq({})
      end

      it "handles an item belonging to no collections" do
        items = [{
          "pid" => "test:1"
        }]
        after = @w.process(items)
        expect(after).to eq({})
      end

      it "handles an item belonging to one collection" do
        items = [{
          "pid" => "test:1",
          "collections" => ["A"]
        }]
        after = @w.process(items)
        expect(after).to eq({"A" => ["test:1"]})
      end

      it "handles an item belonging to two collections" do
        items = [{
          "pid" => "test:1",
          "collections" => ["A", "B"]
        }]
        after = @w.process(items)
        expect(after).to eq({
          "A" => ["test:1"],
          "B" => ["test:1"]})
      end

      it "handles many items" do
        items = [
          {"pid" => "test:1",
           "collections" => ["A", "B"]},
        {"pid" => "test:2",
         "collections" => ["B"]},
        {"pid" => "test:3"},
        {"pid" => "test:4",
         "collections" => ["C"]}]
        after = @w.process(items)
        expect(after).to eq({
          "A" => ["test:1"],
          "B" => ["test:1", "test:2"],
          "C" => ["test:4"]})
      end
    end
  end
end
