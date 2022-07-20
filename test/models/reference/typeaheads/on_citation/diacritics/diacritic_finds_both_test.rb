# frozen_string_literal: true

#
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

# Single reference model test.
class RefTypeaheadOnCitDiacriticFindsBothTest < ActiveSupport::TestCase
  test "ref typeahead on citation diacritic finds both" do
    curr_ref = references(:ref_type_is_paper)
    typeahead = Reference::AsTypeahead::OnCitation.new(
      "Hultén",
      curr_ref.id
    )
    assert_equal 2, typeahead.results.length, "Expect 2 records for 'Hultén'."
    ids = typeahead.results.collect { |reference| reference[:id] }
    assert ids.include?(references(:hulten_with_diacritic).id.to_s),
           "Expecting hulten_with_diacritic"
    assert ids.include?(references(:hulten_without_diacritic).id.to_s),
           "Expecting hulten_without_diacritic"
  end
end
