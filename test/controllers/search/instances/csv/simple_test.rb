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
class SearchInstanceCsvSimpleTest < ActionController::TestCase
  tests SearchController

  test "instance search result in csv format" do
    skip 'fails in 6.1.4'
    get(:search,
        params: { query_target: "instance",
                  query_string: "*angophora costata*",
                  format: "csv" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    s1 = "Instance ID,Name ID,Full Name,Reference ID,Reference Citation"
    s2 = ",Number of Notes,Instance notes"
    assert_match(/#{s1}#{s2}/,
                 response.body.to_s,
                 "Missing heading")
    assert_match(/Angophora costata/,
                 response.body.to_s,
                 "Missing data")
  end
end
