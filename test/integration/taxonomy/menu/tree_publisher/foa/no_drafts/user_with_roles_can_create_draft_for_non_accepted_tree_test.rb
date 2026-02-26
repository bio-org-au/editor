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

# Test that users with product roles can see "Create draft taxonomy"
# for non-accepted trees like FOA.
#
# The condition in _taxonomy_menu.html.erb:
#   current_registered_user.roles.present? ||
#   (current_registered_user.roles.blank? && tree.accepted_tree)
#
# Users with product roles (roles.present?) should see the create draft
# link for any tree they have permission to create drafts for, regardless
# of the tree's accepted_tree status.
class TreePublisherWithRolesCanCreateDraftForNonAcceptedTreeTest < ActionController::TestCase
  tests SearchController

  def setup
    # Ensure no draft versions exist for FOA tree for this test case
    draft_tree_version = tree_versions(:foa_draft_version)
    draft_tree_version.published = true
    draft_tree_version.save!
  end

  test "FOA tree publisher with roles sees create draft for FOA (non-accepted tree)" do
    # FOA has accepted_tree: false, but user has product roles
    user = users(:foa_tax_publisher)
    get(:search,
        params: {},
        session: {username: user.user_name,
                  user_full_name: user.full_name,
                  groups: ["login"]})
    assert_response :success
    assert_select "a#create-draft-taxonomy-menu-link",
                  /Create draft taxonomy for FOA/,
                  "Should show Create Draft Taxonomy link for FOA even though it's a non-accepted tree, because user has roles."
  end
end
