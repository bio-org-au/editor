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
class TaxFormsTreePubAPCUserCanCreateAPCDraftTest < ActionController::TestCase
  tests TreeVersionsController

  def setup
    response_body = %Q({"payload":{"draftName":"blah","versionNumber":#{tree_versions(:apc_draft_version).id}}})
    stub_request(:put, %r{http:..localhost:90...nsl.services.api.tree.createVersion.apiKey=test-api-key&as=apc-tax-publisher}).
  with(
    body: "{\"treeId\":\"460813214\",\"fromVersionId\":null,\"draftName\":\"abcde name\",\"log\":\"abcde log\",\"defaultDraft\":null}",
    headers: {
	  'Accept'=>/json/,
    'Accept-Encoding'=>/.*/,
    'Content-Length'=>/.*/,
    'Content-Type'=>/json/,
    'Host'=>/localhost:.*/,
	  'User-Agent'=>/ruby/
    }).
  to_return(status: 200, body: response_body, headers: {})
  end

  test "APC tree publisher user can create APC draft" do
    user = users(:apc_tax_publisher)
    apc_tree = trees(:APC)
    post(:create_draft,
         params: {"tree_id"=>apc_tree.id, "draft_name"=>"abcde name", "draft_log"=>"abcde log"},
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    groups: ["login"]})
    assert_response :success
  end
end
