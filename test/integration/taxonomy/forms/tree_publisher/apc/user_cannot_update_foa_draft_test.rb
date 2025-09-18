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
class TaxFormsTreePubAPCUserCannotUpdateFOADraftTest < ActionController::TestCase
  tests TreeVersionsController

  test "APC tree publisher user cannot update FOA draft" do
    user = users(:apc_tax_publisher)
    foa_draft = tree_versions(:foa_draft_version)
    post(:update_draft,
         params: {"version_id"=> foa_draft.id, "draft_name"=>'zyz', "draft_log"=>'xyz'},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"],
                   draft: foa_draft})
    assert_response :forbidden, 'Should not be allowed'
    assert_match /Access Denied\! Please contact the admin for proper permissions/,
      response.body, "Expecting Access Denied message"
  end
end
