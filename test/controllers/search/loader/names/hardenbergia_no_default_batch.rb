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
class SearchLoaderNameHardenbergiaNoDefaultBatchTest < ActionController::TestCase
  tests SearchController

  test "can search for loader names" do
    get(:search,
        params: { query_target: "loader names", query_string: "Hardenbergia violacea:" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:ogin, :"atch-loader"] })
    assert_response :success
    assert_select "#search-results-summary",
                  /Please set a default batch/,
                  "Should be asked to set a default batch"
  end
end
