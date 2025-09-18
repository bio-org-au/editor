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

class APCTreePublisherRunChangesReportForFOADraftTest < ActionController::TestCase
  tests TreesController

  def setup
  end

  # r6editor Started GET "/nsl/editor/trees/run/diff" 
  # r6editor Processing by TreesController#run_diff as JS
  test "APC tree publisher run changes report for FOA draft" do
    user = users(:apc_tax_publisher)
    draft = tree_versions(:foa_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    get(:run_diff,
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: draft,
                    groups: ["login"]})
    assert_response :forbidden, 'APC tree publisher should not be able to run changes report for FOA draft'
  end
end

