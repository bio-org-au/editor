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
class SearchRefsDQRefSharedNamesListMT2IDTest < ActionController::TestCase
  tests SearchController

  test "reference shared names with more than 2 ref id" do
    ref_1 = references(:de_fructibus_et_seminibus_plantarum)
    ref_2 = references(:paper_by_britten_on_angophora)
    ref_3 = references(:paper_by_brassard)
    get(:search,
        params: { query_target: "references shared names",
                  query_string: "#{ref_1.id},#{ref_2.id},#{ref_3.id}" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "#search-results-summary",
                  /Exactly 2 reference IDs are expected/,
                  "Should report Reference does not exist"
  end
end
