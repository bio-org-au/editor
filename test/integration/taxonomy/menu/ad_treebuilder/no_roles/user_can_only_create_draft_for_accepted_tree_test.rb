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

# Test that AD treebuilder users without product roles can only see
# "Create draft taxonomy" for accepted trees.
#
# The condition in _taxonomy_menu.html.erb:
#   current_registered_user.roles.present? ||
#   (current_registered_user.roles.blank? && tree.accepted_tree)
#
# This means users without product roles should only see the create draft
# link for trees where accepted_tree is true (e.g., APC) and not for
# non-accepted trees (e.g., FOA).
class AdTreebuilderNoRolesCanOnlyCreateDraftForAcceptedTreeTest < ActionController::TestCase
  tests SearchController

  def setup
    # Ensure no draft versions exist for this test case
    TreeVersion.update_all(published: true)
  end

  test "AD treebuilder without roles sees create draft for APC (accepted tree)" do
    # APC has accepted_tree: true
    get(:search,
        params: {},
        session: {username: "ad-treebuilder-no-roles",
                  user_full_name: "AD Treebuilder No Roles",
                  groups: ["treebuilder"]})
    assert_response :success
    assert_select "a#create-draft-taxonomy-menu-link",
                  /Create draft taxonomy for APC/,
                  "Should show Create Draft Taxonomy link for APC (accepted tree)."
  end

  test "AD treebuilder without roles does not see create draft for FOA (non-accepted tree)" do
    # FOA has accepted_tree: false
    get(:search,
        params: {},
        session: {username: "ad-treebuilder-no-roles",
                  user_full_name: "AD Treebuilder No Roles",
                  groups: ["treebuilder"]})
    assert_response :success
    assert_select "a",
                  {count: 0, text: /Create draft taxonomy for FOA/},
                  "Should NOT show Create Draft Taxonomy link for FOA (non-accepted tree)."
  end
end
