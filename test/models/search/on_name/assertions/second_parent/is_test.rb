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
load "models/search/users.rb"

# Single Search model test for Name search.
class SearchOnNameAssertionSecondParentIsTest < ActiveSupport::TestCase
  test "name asertion is a second parent" do
    search = Search::Base.new(ActiveSupport::HashWithIndifferentAccess.new(
                                query_target: "name",
                                query_string: "is-a-second-parent:",
                                current_user: build_edit_user
                              ))
    assert !search.executed_query.results.empty?,
           "Should find name that is a parent."
  end
end
