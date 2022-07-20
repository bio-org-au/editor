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

# Name type options for category test.
class OtherTest < ActiveSupport::TestCase
  test "other name type options" do
    current_category = name_categories(:other)
    assert_equal 5,
                 NameType.options_for_category(current_category).size,
                 "Should be just 5 #{current_category} name types."
    assert NameType.options_for_category(current_category)
                   .collect(&:first).include?("common"),
           "Common should be an #{current_category} name type."
    assert NameType.options_for_category(current_category)
                   .collect(&:first).include?("informal"),
           "Informal should be an #{current_category} name type."
    assert NameType.options_for_category(current_category)
                   .collect(&:first).include?("[n/a]"),
           "[n/a] should be an #{current_category} name type."
    assert NameType.options_for_category(current_category)
                   .collect(&:first).include?("[default]"),
           "[default] should be an #{current_category} name type."
    assert NameType.options_for_category(current_category)
                   .collect(&:first).include?("[unknown]"),
           "[unknown] should be an #{current_category} name type."
  end
end
