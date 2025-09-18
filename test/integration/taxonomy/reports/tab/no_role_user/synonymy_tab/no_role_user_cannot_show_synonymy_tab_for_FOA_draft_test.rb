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

class NoRoleUserCannotShowSynonymyTabForFOADraftTest < ActionController::TestCase
  tests TreesController

  # r6editor Started GET "/nsl/editor/trees/show/cas" 
  # r6editor Processing by TreesController#show_cas as JS
  test "user with no role cannot show syn tab for FOA draft" do
    user = users(:no_role)
    draft = tree_versions(:foa_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    get(:show_cas,
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: draft,
                    groups: ["login"]})
    assert_response :forbidden, 'User with no role should not be able to show syn tab for FOA draft'
    assert_match /Access Denied/i, response.body, "Expecting error message"
  end
end

