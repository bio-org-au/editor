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

# Single Reference model test.
class ReferencePartNoEditionAllowedTest < ActiveSupport::TestCase
  test "reference part no edition allowed" do
    reference = references(:simple)
    reference.save!
    assert reference.valid?, "Should start out valid"
    reference.ref_type = ref_types(:part)
    reference.save!
    assert reference.valid?, "Part should be valid"
    reference.edition = "xyz"
    assert_raises ActiveRecord::RecordInvalid,
                  "A reference part with a edition should be invalid" do
      reference.save!
    end
    assert_equal :edition,
                 reference.errors.first.attribute,
                 "Error should be on 'edition'"
    assert_equal "is not allowed for a Part",
                 reference.errors.first.message,
                 "Incorrect error message"
  end
end
