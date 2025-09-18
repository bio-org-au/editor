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
class TreePubFoaWDUserCanSeeMenuOptsEditDraftTest< ActionController::TestCase
  tests SearchController

  test "foa tree publisher can see menu option edit working draft" do
    user = users(:foa_tax_publisher)
    foa_draft = tree_versions(:foa_draft_version)
    get(:search,
        params: {},
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"],
                   draft: foa_draft})
    assert_response :success
    assert_select "a",
                  /FOA draft version/,
                  "Should show FOA draft version menu link."
    assert_select "a#edit-draft-taxonomy-menu-link-FOA-#{foa_draft.draft_name.gsub(/ /,'-')}",
                  /Edit FOA draft version/,
                  "Should show Edit Draft Taxonomy for FOA menu link-#{foa_draft.draft_name.gsub(/ /,'-')}"
    assert_select "a", {count: 0, text: "Edit APC draft version"}, "Should not show edit APC draft version link"
  end
end
