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

# Single instance model test.
class InstSrchCreAfterFromDropdownSimpleSingularTest < ActiveSupport::TestCase
  # New search for "42993" on instance up to 100 with field: cr-b
  test "instance search on created after from dropdown field simple singular" do
    search = Search::Base
             .new(ActiveSupport::HashWithIndifferentAccess
                  .new(query_string: "1",
                       query_target: "Activity",
                       current_user: build_edit_user))
    assert_equal Array,
                 search.executed_query.results.class,
                 "Results should be an Array"
    assert search.executed_query.results.size > 20, "Many records expected."
  end
end
