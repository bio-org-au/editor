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
class TaxFormsTreeBuilderAPCUserCanUpdateExcludedForTaxonOnAPCDraftTest < ActionController::TestCase
  tests TreesController

  def setup
    stub_request(:post, %r{http:..localhost:90...nsl.services.api.treeElement.editElementStatus.apiKey=test-api-key.as=apc-tax-builder}).
  with(
    body: "{\"taxonUri\":null,\"excluded\":null}",
    headers: {
	  'Accept'=>/json/,
    'Accept-Encoding'=>/.*/,
    'Content-Length'=>/.*/,
    'Content-Type'=>/json/,
    'Host'=>/localhost:.*/,
	  'User-Agent'=>/ruby/
    }).
  to_return(status: 200, body: "", headers: {})
  end

  # r6editor Started POST "/nsl/editor/trees/update_excluded" for ::1 at 2025-07-17 09:44:34 +1000 (pid:642)
  # r6editor Processing by TreesController#update_excluded as */* (pid:642)
  # r6editor Parameters: {"excluded"=>"false", "taxonUri"=>"/tree/52410589/52410612"} (pid:642)
  test "APC tree builder user can update excluded for taxon on APC draft" do
    user = users(:apc_tax_builder)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    post(:update_excluded,
         params: {"update_parent"=>{"taxonUri"=>tve.element_link,
                                    "excluded"=>"false"}
                 },
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: apc_draft,
                    groups: ["login"]})
    assert_response :success, 'APC tree builder should be able to update excluded on APC draft entry'
    assert_no_match 'Error', response.body, "Not expecting an error message"
  end
end
