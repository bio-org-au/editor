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
class TheadsOnCit4ParWks4NewRecAlsoWNoParRefTypeTest < ActiveSupport::TestCase
  test "ref th on cit 4 parent works 4 new rec also w no par ref type" do
    curr = Reference.new
    typeahead = Reference::AsTypeahead::OnCitationForParent.new(
      "*",
      curr.id,
      curr.ref_type_id
    )
    assert typeahead.results.empty?,
           "Should be no results for new record with missing ref type"
  end
end
