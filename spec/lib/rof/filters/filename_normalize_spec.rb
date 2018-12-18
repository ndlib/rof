require 'spec_helper'
require 'rof/filters/filename_normalize'
require 'support/an_rof_filter'

module ROF
  module Filters
    describe FilenameNormalize do
      it_behaves_like "an ROF::Filter"
      let(:valid_options) { {} }

      before(:all) do
        @w = FilenameNormalize.new()
      end

      it "consolidates and replaces spaces in files" do
        items = [{
          "content-meta"  => {
             "mime-type" => "application/pdf",
	     "label" => "RightsLink - Inorg. Chim. Acta.pdf",
	     "URL" => "bendo:/item/9306sx63m9v/9w032229v7d-RightsLink - Inorg. Chim. Acta.pdf"
	  }
        }]
        after = @w.process(items, false)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "content-meta"  => {
            "mime-type" => "application/pdf",
            "label" => "RightsLink-Inorg.-Chim.-Acta.pdf",
	    "URL" => "bendo:/item/9306sx63m9v/9w032229v7d-RightsLink-Inorg.-Chim.-Acta.pdf"
	  }
        })
      end

      it "subs out char outside a-zA-Z0-9+-_ range" do
        items = [{
          "content-meta" => {
             "mime-type" => "application/pdf",
	     "label" => "Rightslink®carbene.pdf",
	     "URL" => "bendo:/item/9306sx63m9v/9z902z1348c-Rightslink®carbene.pdf"
          }
        }]
        after = @w.process(items, false)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "content-meta" => {
             "mime-type" => "application/pdf",
	     "label" => "Rightslink-carbene.pdf",
	     "URL"  => "bendo:/item/9306sx63m9v/9z902z1348c-Rightslink-carbene.pdf"
          }
        })
      end

      it "preserves case in filenames" do
        items = [{
          "content-meta" => {
            "mime-type" => "application/pdf",
            "label" => "BarrettBJ042017D.pdf",
            "URL" => "bendo:/item/9306sx63m9v/9593tt46x2s-BarrettBJ042017D.pdf"
	  }
        }]
        after = @w.process(items, false)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "content-meta" => {
            "mime-type" => "application/pdf",
            "label" => "BarrettBJ042017D.pdf",
            "URL" => "bendo:/item/9306sx63m9v/9593tt46x2s-BarrettBJ042017D.pdf"
	  }
        })
      end

      it "maps accented characters" do
        items = [{
          "content-meta" => {
            "mime-type" => "application/pdf",
            "label" => "àèìòùa.pdf",
            "URL" => "bendo:/item/9306sx63m9v/àèìòùåååå™.pdf"
	  }
        }]
        after = @w.process(items, false)
        expect(after.length).to eq(1)
        expect(after.first).to eq({
          "content-meta" => {
            "mime-type" => "application/pdf",
            "label" => "aeioua.pdf",
            "URL" => "bendo:/item/9306sx63m9v/aeiouaaaa-.pdf"
	  }
        })
      end
    end
  end
end
