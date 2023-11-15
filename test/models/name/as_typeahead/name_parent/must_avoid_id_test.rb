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

# Single Name typeahead test.
class NameParentSuggestionsMustAvoidIdTest < ActiveSupport::TestCase
  test "name parent suggestions must avoid id" do
    name = names(:angophora_costata)
    typeahead =
      Name::AsTypeahead::ForParent.new(term: "angophora costata",
                                       avoid_id: name.id + 1,
                                       rank_id: name_ranks(:unranked).id)
    assert(typeahead.suggestions.is_a?(Array),
           "SUggestions should be an array")
    assert(typeahead.suggestions.size == 1,
           "SUggestions for 'angophora costata' should have 1 element")
    assert(typeahead.suggestions.first[:value].match(/Angophora costata/),
           "Suggestions should include 'Angophora costata'.")
    typeahead =
      Name::AsTypeahead::ForParent.new(term: "angophora costata",
                                       avoid_id: name.id,
                                       rank_id: name_ranks(:unranked).id)
    assert(typeahead.suggestions.is_a?(Array),
           "SUggestions should be an array")
    assert(typeahead.suggestions.empty?,
           "Suggestions for 'angophora costata' should have no elements
           since it is told to avoid Angophora costata's id.")
  end
end
