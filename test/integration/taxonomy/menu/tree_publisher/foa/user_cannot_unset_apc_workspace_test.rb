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
# This is arguably a less important test - that a user cannot unset a workspace tree
# version for tree they have no access to (what harm would happen if they could UNset it is the 
# point) - but the test is here as part of a suite of
# tests I'm setting up for this change in permissions.
class TreePublisherFoaUserCannotUnsetWorkspaceTest < ActionController::TestCase
  tests Trees::Workspaces::CurrentController

  test "foa tree publisher cannot unset apc workspace version" do
    user = users(:foa_tax_publisher)
    draft = tree_versions(:apc_draft_version)
    post(:toggle,
         params: {id: draft.id},
         format: :js,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    groups: ["login"],
                    draft: draft})
    assert_response :forbidden, 'Should not be able to remove current workspace draft setting'
    assert_not_nil session[:draft], 'Should not have unset the session draft'
  end
end
