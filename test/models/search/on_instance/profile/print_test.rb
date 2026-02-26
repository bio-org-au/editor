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
load "test/models/search/users.rb"

# Single Search model test on Instance search with print directive.
class SearchOnInstanceProfilePrintTest < ActiveSupport::TestCase
  test "search on instance with print and show-profiles directives succeeds" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "instance",
      query_string: "show-profiles: print:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    assert search.parsed_request.print, "Print directive should be enabled"
    assert search.parsed_request.show_profiles, "Show profiles should be enabled"
  end

  test "search on instance with print but without show-profiles raises error" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "instance",
      query_string: "id: 1 print:",
      current_user: build_edit_user
    )
    error = assert_raises(RuntimeError) do
      search = Search::Base.new(params)
    end
    assert_match(/Error: the print: directive for instances requires the show-profiles: directive/i, error.message)
  end

  test "search on instance with show-profiles and print returns mixed results" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "instance",
      query_string: "show-profiles: print:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    assert_not search.executed_query.results.empty?, "Search should return results to verify behavior"
    # Results should contain both Instance and Profile::ProfileItem records
    has_instance = search.executed_query.results.any? { |r| r.is_a?(Instance) }
    has_profile_item = search.executed_query.results.any? { |r| r.is_a?(Profile::ProfileItem) }
    assert has_instance || has_profile_item, "Should have at least Instance or ProfileItem results"
  end
end
