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

# Single Search model test.
class SearchOnAuthorCommentsByCaseInsensitiveTest < ActiveSupport::TestCase
  test "search on author comments by case insensitive" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "author",
      query_string: "comments-by: GREG",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    assert !search.executed_query.results.empty?,
           "Authors with comments by GREG expected for case insensitive test."
  end
end
