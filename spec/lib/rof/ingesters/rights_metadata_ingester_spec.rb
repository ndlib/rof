require 'spec_helper'

module ROF
  module Ingesters
    describe RightsMetadataIngester do
      it "works with simple cases" do
        item = {"rights" => {"read-groups" => ["restricted", "abc"],
                             "read" => ["joe"],
                             "edit" => ["anna"],
                             "edit-groups" => ["admins"]
        }}
        expected_content = %q{<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human type="title"/>
    <human type="description"/>
    <machine type="uri"/>
  </copyright>
  <access type="discover">
    <human/>
    <machine/>
  </access>
  <access type="read">
    <human/>
    <machine>
      <person>joe</person>
      <group>restricted</group>
      <group>abc</group>
    </machine>
  </access>
  <access type="edit">
    <human/>
    <machine>
      <person>anna</person>
      <group>admins</group>
    </machine>
  </access>
  <embargo>
    <human/>
    <machine/>
  </embargo>
</rightsMetadata>
}
        expect(RightsMetadataIngester.call(item: item)).to eq(expected_content)
      end

      it "handles embargo dates" do
        item = {"rights" => {"read-groups" => ["public"],
                             "edit" => ["rbalekai"],
                             "embargo-date" => "2015-01-01"
               }}
        expected_content = %q{<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human type="title"/>
    <human type="description"/>
    <machine type="uri"/>
  </copyright>
  <access type="discover">
    <human/>
    <machine/>
  </access>
  <access type="read">
    <human/>
    <machine>
      <group>public</group>
    </machine>
  </access>
  <access type="edit">
    <human/>
    <machine>
      <person>rbalekai</person>
    </machine>
  </access>
  <embargo>
    <human/>
    <machine>
      <date>2015-01-01</date>
    </machine>
  </embargo>
</rightsMetadata>
}
        expect(RightsMetadataIngester.call(item: item)).to eq(expected_content)
      end
    end
  end
end
