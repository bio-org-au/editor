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
class TreePublisherApcTaxoNoDraftMenuOptions < ActionController::TestCase
  tests SearchController
  def setup
    # We needto have no draft versions for this test case
    draft_tree_version = tree_versions(:apc_draft_version)
    draft_tree_version.published = true
    draft_tree_version.save!
  end

  test "APC tree publisher has taxonomy menu options when no draft" do
    user = users(:apc_tax_publisher)
    get(:search,
        params: {},
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"] })
    assert_response :success
    assert_select "a", {count: 0, text: "APC draft version"}, "Should not show APC draft version"
    assert_select "a", {count: 0, text: "FOA draft version"}, "Should not show FOA draft version"
    assert_select "a#create-draft-taxonomy-menu-link",
                  /Create draft taxonomy/,
                  "Should show Create Draft Taxonomy menu link."
  end
end
