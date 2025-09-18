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

class NoRoleUserCanShowValidationTabForAPCDraftTest < ActionController::TestCase
  tests TreesController

  # r6editor Started GET "/nsl/editor/trees/show/valrep" 
  # r6editor Processing by TreesController#show_valrep as JS
  test "user with no role cannot show validation tab for APC draft" do
    user = users(:no_role)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    get(:show_valrep,
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: apc_draft,
                    groups: ["login"]})
    assert_response :forbidden, 'User with no role should not be able to show validation tab for APC draft'
  end
end

