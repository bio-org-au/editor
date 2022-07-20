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

# Single author model test.
class AuthorAsTAHOnNameOllegaardFindsDiacriticTooTest < ActiveSupport::TestCase
  test "author ollegaard finds diacritic too test" do
    results = Author::AsTypeahead.on_name("Ollegaard")
    assert_equal 2, results.size, "Expecting 2 records for 'Ollegard'."
    ids = results.collect { |author| author[:id] }
    assert ids.include?(authors(:ollegaard_without_diacritic).id.to_s),
           "Expecting ollegaard without diacritic"
    assert ids.include?(authors(:ollegaard_with_leading_diacritic).id.to_s),
           "Expecting ollegaard with leading diacritic"
  end
end
