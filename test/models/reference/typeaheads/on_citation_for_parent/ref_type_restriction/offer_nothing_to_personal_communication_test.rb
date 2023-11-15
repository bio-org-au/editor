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
class TAOnCitn4ParRefTypeRestrictNil4PersCommun < ActiveSupport::TestCase
  test "ref typeahead on citation ref type nothing for personal comm" do
    current_reference = references(:simple)
    typeahead = Reference::AsTypeahead::OnCitationForParent.new(
      "%",
      current_reference.id,
      ref_types(:personal_communication).id
    )
    assert typeahead.results.empty?,
           "Should be no results because personal comm. takes no parent."
  end
end
