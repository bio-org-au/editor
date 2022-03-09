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
class SearchNamesWithFocusSimpleTest < ActionController::TestCase
  tests SearchController

  setup do
    @name = names(:angophora_costata)
  end

  test "search for a set of names and focus on one" do
    get(:search,
        params: { query_target: "name", query_string: "a", focus_id: @name.id },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "#search-results-summary",
                  /4[0-9] names of 4[0-9]/,
                  "Should find plenty of records for a simple search on 'a'"
    assert_select "#focus_id[value='#{@name.id}']", { count: 1 }, "One Focus"
  end
end
