require 'spec_helper'

describe "Ingest" do
  it "requires a fobject" do
    item = {"type" => "not fobject"}
    expect {ROF.Ingest(item)}.to raise_error(ROF::NotFobjectError)
  end
  it "requires a pid" do
    item = {"type" => "fobject"}
    expect {ROF.Ingest(item)}.to raise_error(ROF::MissingPidError)
  end
end
