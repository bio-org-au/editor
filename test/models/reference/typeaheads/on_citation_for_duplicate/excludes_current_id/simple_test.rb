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

# Reference model typeahead search.
class TypeaheadsOnCitForDuplicateExcludesCurrentIdTest < ActiveSupport::TestCase
  test "reference typeahead on citation for duplicate excludes current id" do
    curr_ref = references(:simple)
    other_ref = references(:paper_by_brassard)
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new("simple",
                                                                   other_ref.id)
    assert typeahead.results.size == 1,
           "Should be at least one result for asterisk wildcard"
    assert_equal typeahead.results.first[:id].to_i,
                 curr_ref.id,
                 "The current ref should be found because it is not excluded."
    typeahead_2 = Reference::AsTypeahead::OnCitationForDuplicate.new(
      "simple", curr_ref.id
    )
    assert typeahead_2.results.empty?,
           "Should be no records found if current reference is excluded."
  end
end
