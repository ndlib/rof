require 'mime-types'

module ROF
  # A few common utility methods
  class Utility
    def initialize
      @seq = 0
    end

    WORK_TYPE_WITH_PREFIX_PATTERN = /^[Ww]ork(-(.+))?/

    # Strictly speaking, a Collection is not a Work-
    # it's included here to cull out and pass down
    # the batch processing pipeline

    WORK_TYPES = {
      # csv name => af-model
      'article' => 'Article',
      'dataset' => 'Dataset',
      'document' => 'Document',
      'collection' => 'Collection',
      'etd' => 'Etd',
      'image' => 'Image'
    }.freeze

    # Given an object's type, detrmine and return its af-model
    def decode_work_type(obj)
      if obj['type'] =~ WORK_TYPE_WITH_PREFIX_PATTERN
        return 'GenericWork' if Regexp.last_match(2).nil?
        Regexp.last_match(2)
      else
        # this will return nil if key t does not exist
        work_type = obj['type'].downcase
        WORK_TYPES[work_type]
      end
    end

    # Issue pid label
    def next_label
      "$(pid--#{@seq})".tap { |_| @seq += 1 }
    end

    # set 'properties'
    def self.prop_ds(owner, representative = nil)
      s = %(<fields><depositor>batch_ingest</depositor>
				<owner>#{owner}</owner>)
      if representative
        s += "<representative>#{representative}</representative>\n</fields>\n"
      else
        s += "</fields>\n"
      end
      s
    end
  end
end
