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

# Single Search model test.
class SearchParsedRequestCountTest < ActiveSupport::TestCase
  test "search parse query count" do
    query_string = "count"
    params = ActiveSupport::HashWithIndifferentAccess
             .new(query_target: "name",
                  canonical_query_target: "name",
                  query_string: query_string)
    parsed_request = Search::ParsedRequest.new(params)
    assert parsed_request.count, "This should be parsed as a count query."
    assert !parsed_request.list, "This should not be parsed as a list query."
    assert_match(/\Aname\z/,
                 parsed_request.target_table,
                 "This should be parsed as a query on the name table.")
    assert !parsed_request.limited,
           "This should be parsed as a query with no limit."
    assert_equal parsed_request.limit,
                 0,
                 "This should be parsed as a query with a limit of 0."
    assert !parsed_request.common_and_cultivar,
           "This should be parsed as a query excluding common and cultivars."
    assert parsed_request.where_arguments.blank?,
           "This should be parsed as a query with no where arguments."
  end
end
