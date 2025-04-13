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
class SearchLoaderBatchReviewSimpleTest < ActionController::TestCase
  tests SearchController

  test "can search for batch reviews" do
    get(:search,
        params: { query_target: "batch reviews", query_string: "*" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:login, :"batch-loader"] })
    assert_response :success
    assert_select "#search-results-summary",
                  /\b[0-9] records\b/,
                  "Should find records for an author wildcard search"
    assert_select "a.show-details-link", /WG Review for Batch One/,"Should find WG Review for Batch One"
    assert_select "a.show-details-link", /WG Review for Batch Two/,"Should find WG Review for Batch Two"
  end
end
