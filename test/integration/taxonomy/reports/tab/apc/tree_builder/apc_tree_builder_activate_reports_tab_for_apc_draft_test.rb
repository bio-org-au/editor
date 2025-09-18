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

class APCTreeBuilderCanActivateTreeReportsTabForAPCDraft < ActionController::TestCase
  tests TreesController

  # r6editor Started GET "/nsl/editor/trees/reports" for ::1 at 2025-07-21 16:39:27 +1000
  # r6editor Processing by TreesController#reports as JS
  test "APC tree builder can activate tree reports tab for APC draft" do
    user = users(:apc_tax_builder)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    get(:reports,
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: apc_draft,
                    groups: ["login"]})
    assert_response :success, 'APC tree builder should be able to activate reports tab for APC draft'
  end
end

