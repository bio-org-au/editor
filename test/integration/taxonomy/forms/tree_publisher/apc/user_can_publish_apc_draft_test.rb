# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require "test_helper"

# Single search controller test.
#
# Note: 
#   xhr: true
#
# stopped this error in test: 
#
# ActionController::InvalidCrossOriginRequest: Security warning: 
#   an embedded <script> tag on another site requested protected JavaScript.
class TaxFormsTreePubAPCUserCanPublishAPCDraftTest < ActionController::TestCase
  tests TreeVersionsController

  def setup
    # sample response from dev
    response = %q({"action":"publish","status":{"enumType":"org.springframework.http.HttpStatus","name":"OK"},"ok":true,"payload":{"class":"au.org.biodiversity.nsl.TreeVersion","_links":{"permalinks":[{"link":"http://localhost:9094/tree/51798490","preferred":true,"resources":1}]},"audit":null,"versionNumber":51798490,"draftName":"Australian Plant Census List 103, p.p.","tree":{"class":"au.org.biodiversity.nsl.Tree","_links":{"permalinks":[{"link":"http://localhost:9094/tree/apni/APC","preferred":true,"resources":1}]},"audit":null,"name":"APC"},"firstOrderChildren":[{"displayHtml":"<data><scientific><name data-id='54717'><element>Plantae<\u002felement> <authors><author data-id='3882' title='Haeckel, Ernst Heinrich Philipp August'>Haeckel<\u002fauthor><\u002fauthors><\u002fname><\u002fscientific><name-status class=\"legitimate\">, legitimate<\u002fname-status> <citation><ref data-id='52462'><ref-section><author>Council of Heads of Australasian Herbaria<\u002fauthor> <year>(2012)<\u002fyear>, <par-title><i>Australian Plant Census<\u002fi><\u002fpar-title><\u002fref-section><\u002fref><\u002fcitation><\u002fdata>","elementLink":"http://localhost:9094/nsl-mapper/tree/51798490/51209397","nameLink":"http://localhost:9094/nsl-mapper/name/apni/54717","instanceLink":"http://localhost:9094/nsl-mapper/instance/apni/738442","excluded":false,"depth":1,"synonymsHtml":"<synonyms><\u002fsynonyms>"}]},"autocreate":true})
    stub_request(:put, /http:..localhost:90...nsl.services.api.treeVersion.publish.apiKey=test-api-key.as=apc-tax-publisher/).
  with(
    body: "{\"versionId\":146236284,\"logEntry\":\"xyz\",\"nextDraftName\":\"zyz\"}",
    headers: {
	  'Accept'=>'application/json',
	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
	  'Content-Length'=>'62',
	  'Content-Type'=>'application/json',
	  'Host'=>/localhost/,
	  'User-Agent'=>/ruby/
    }).
  to_return(status: 200, body: response, headers: {})


  end

  # Started POST "/nsl/editor/tree_versions/publish" for 
  # Processing by TreeVersionsController#publish as JS (pid:15335)
  # Parameters: {"version_id"=>"51798490",
  #              "draft_log"=>"Updates resulting from Australian Plant Census List 108, p.p. (Banksia).\n",
  #              "next_draft_name"=>"Australian Plant Census List 108"}
  test "APC tree publisher user can publish APC draft" do
    user = users(:apc_tax_publisher)
    apc_draft = tree_versions(:apc_draft_version)
    post(:publish,
         params: {"version_id"=> apc_draft.id, "next_draft_name"=>'zyz', "draft_log"=>'xyz'},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"],
                   draft: apc_draft})
    assert_response :success
  end
end
