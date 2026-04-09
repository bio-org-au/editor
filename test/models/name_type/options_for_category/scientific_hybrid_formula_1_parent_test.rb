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
class ScientificHybridFormula1ParentTest < ActiveSupport::TestCase
  test "scientific hybrid formula 1 parent name type options" do
    current_category =
      name_categories(:scientific_hybrid_formula_unknown_2nd_parent)
    assert_equal 1,
                 NameType.options_for_category(current_category).size,
                 "Should be just 1 #{current_category.name} name type."
    assert NameType
      .options_for_category(current_category)
      .collect(&:first)
      .include?("hybrid formula unknown 2nd parent"),
           "Name type 'hybrid formula unknown 2nd parent' should be \
           a #{current_category.name} name type."
  end
end
