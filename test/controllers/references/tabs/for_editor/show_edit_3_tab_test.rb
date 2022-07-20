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

# Single reference controller test.
class ReferenceEditorShowEdit3Test < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:a_book)
  end

  test "should show editor reference edit 3 tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_edit_3" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_select "li.active a#reference-edit-3-tab",
                  /Edit\.\.\./,
                  "Should show 'Edit...' tab."
    assert_select "form", true
    assert_select "input#reference_doi", true
    assert_select "input#reference_isbn", true
    assert_select "input#reference_issn", true
    assert_select "input#reference_bhl_url", true
    assert_select "input#reference_tl2", true
  end
end
