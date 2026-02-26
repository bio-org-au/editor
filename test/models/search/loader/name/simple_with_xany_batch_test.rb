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
class SearchLoaderNameWithXanyBatchTest < ActiveSupport::TestCase
  test "search loader name with xany-batch" do
    params = ActiveSupport::HashWithIndifferentAccess.new(query_target:
                                                          "loader_names",
                                                          query_string:
                                                          "* xany-batch:",
                                                          current_user:
                                                          build_edit_user)

    error = assert_raises(RuntimeError) do
      Search::Base.new(params)
    end
    assert_match(/Cannot search this target for: xany-batch:/i, error.message)
  end
end
