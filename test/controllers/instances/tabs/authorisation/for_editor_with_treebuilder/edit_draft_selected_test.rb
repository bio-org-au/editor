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

# Single controller test.
class InstEditTabForEditWithTreeBuilderAndDraftTest < ActionController::TestCase
  tests InstancesController
  setup do
    @triodia_in_brassard = instances(:triodia_in_brassard)
    @draft_tree_version = tree_versions(:apc_draft_version)
  end

  test "should include as a draft checkbox for edit" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @triodia_in_brassard.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   draft: @draft_tree_version,
                   groups: ["edit", "treebuilder"] })
    assert_response :success
    assert_match 'on page', @response.body, "Missing: 'on page'"
    assert_match 'as a draft', @response.body, "Missing: 'as a draft'"
  end
end
