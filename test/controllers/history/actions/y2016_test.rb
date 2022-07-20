# frozen_string_literal: true

#
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
class HistoryActionsY2016Test < ActionController::TestCase
  tests HistoryController
  # setup do
  # @comment = comments(:author_comment)
  # end

  test "history actions y2016 page" do
    get("y2016",
        params: {},
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "h3",
                  /\b2016 Changes\b/,
                  "Should find heading for 2016 Changes"
    assert_select "li.list-group-item", /\b04-Jan-2016/,
                  "Should find NSL-1505 a"
    assert_select "li.list-group-item", /\bNSL-1505:/,
                  "Should find NSL-1505 b"
  end
end
