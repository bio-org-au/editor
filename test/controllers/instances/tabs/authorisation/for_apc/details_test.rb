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
class InstanceDetailsForAPCTabTest < ActionController::TestCase
  tests InstancesController
  setup do
    @triodia_in_brassard = instances(:triodia_in_brassard)
  end
  test "should show instance details tab to apc" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @triodia_in_brassard.id, tab: "tab_show_1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["APC"] })
    assert_response :success
  end

  test "should show instance details tab even if profile item tables don't exist" do
    Rails.configuration.profile_v2_aware = false
    Instance.stub_any_instance(:profile_items, -> { raise PG::UndefinedTable, "relation \"profile_item\" does not exist" }) do
      @request.headers["Accept"] = "application/javascript"
      get(:show,
          params: { id: @triodia_in_brassard.id, tab: "tab_show_1" },
          session: { username: "fred",
                    user_full_name: "Fred Jones",
                    groups: ["APC"] })
      assert_response :success
    end
  end
end
