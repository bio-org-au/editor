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

# Common-name role: edit tab is hidden for non-common (scientific) names.
class CommonNameRoleHideEditTabForScientificNameTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  test "common-name role user does not see edit tab for a scientific name" do
    @request.headers["Accept"] = "application/javascript"
    SessionUser.stub_any_instance(:with_role_for_context?, true) do
      get(:show,
          params: { id: @name.id, tab: "tab_details" },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: [] })
    end
    assert_response :success
    assert_select "a#name-edit-tab", false, "Should not show 'Edit' tab link for scientific name."
  end
end
