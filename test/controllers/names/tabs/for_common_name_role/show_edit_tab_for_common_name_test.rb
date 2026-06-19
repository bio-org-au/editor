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

# Common-name role: edit tab and restricted name type options for a common name.
class CommonNameRoleShowEditTabForCommonNameTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:argyle_apple)
  end

  test "common-name role user sees edit tab and common-only name type options for a common name" do
    @request.headers["Accept"] = "application/javascript"
    SessionUser.stub_any_instance(:with_role_for_context?, true) do
      get(:show,
          params: { id: @name.id, tab: "tab_edit" },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: [] })
    end
    assert_response :success
    assert_select "a#name-edit-tab", true, "Should show 'Edit' tab link for common name."
    assert_select "select#name-type-selector", true,
                  "Should render name type select via the show_prompt branch."
    assert_select "select#name-type-selector option", {count: 1},
                  "Should show only the common name type option, not the full other-category list."
  end
end
