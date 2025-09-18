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
class TaxFormsTreePubFOANewDraftUserOferedFOATreeOnlyTest < ActionController::TestCase
  tests TreeVersionsController

  #<option value="5....">FOA</option>
  # comes out like this:
  # "<option value=\\\"4....\\\">FOA<\\/option>"

  test "FOA tree publisher user offered FOA tree only" do
    user = users(:foa_tax_publisher)
    get(:new_draft,
        params: {},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"]})
    assert_response :success, "This test assumes the new draft form will open for foa_tax_publisher"
    assert_dom 'form', true, 'Should be a form element'
    assert_dom 'select', true, 'Should be a select element'
    assert_dom "select:match('id', ?)", /tree_id/, true, 'Should be a tree_id select element'
    assert_dom 'option', 1, 'Should be one option element'
    assert_match(/<option value=[\\]*"#{trees(:FOA).id}[\\]*".FOA.*option>/, response.body, 'Should be an FOA tree option')
    assert_no_match(/APC/i, response.body, 'Should be no APC option')
  end
end


