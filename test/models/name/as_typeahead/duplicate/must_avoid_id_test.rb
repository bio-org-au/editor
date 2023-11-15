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
class NameDuplicateSuggestionsMustAvoidIdTest < ActiveSupport::TestCase
  test "name duplicate suggestions must avoid id test" do
    name = names(:angophora_costata)
    suggestions = Name::AsTypeahead.duplicate_suggestions(
      "angophora costata",
      name.id
    )
    assert(suggestions.is_a?(Array), "suggestions should be an array")
    assert(suggestions.empty?,
           'suggestions for "angophora costata" should have no elements')
  end
end
