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
class TaxFormsTreePubAPCNewDraftUserOferedAPCTreeOnlyTest < ActionController::TestCase
  tests TreeVersionsController

  #<option value="51209179">APC</option>
  # comes out like this:
  # "<option value=\\\"460813214\\\">APC<\\/option>"

  test "APC tree publisher user offered apc tree only" do
    user = users(:apc_tax_publisher)
    get(:new_draft,
        params: {},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"]})
    assert_response :success, "This test assumes the new draft form will open for apc_tax_publisher"
    assert_dom 'form', true, 'Should be a form element'
    assert_dom 'select', true, 'Should be a select element'
    assert_dom "select:match('id', ?)", /tree_id/, true, 'Should be a tree_id select element'
    assert_dom 'option', 1, 'Should be one option element'
    assert_match(/<option value=[\\]*"#{trees(:APC).id}[\\]*".APC.*option>/, response.body, 'Should be an APC tree option')
    assert_no_match(/FOA/i, response.body, 'Should be no FOA option')
  end
end

