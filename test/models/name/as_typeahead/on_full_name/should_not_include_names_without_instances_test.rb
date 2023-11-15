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
class NameTAOnFullNameSuggsShldNotInclNamesWOInstTest < ActiveSupport::TestCase
  test "name on full name suggestions shd not incl names without instances" do
    suggestions = Name::AsTypeahead::OnFullName
                  .new(term: "a name without instances")
                  .suggestions
    assert(suggestions.is_a?(Array), "suggestions should be an array")
    assert(suggestions.empty?,
           'suggestions for "a name without instances" should be empty')
  end
end
