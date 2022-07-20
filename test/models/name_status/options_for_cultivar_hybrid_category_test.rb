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

# Nam status options test.
class OptionsForCultivarHybridCategoryTest < ActiveSupport::TestCase
  test "should include [deleted]" do
    assert NameStatus
      .options_for_category(name_categories(:cultivar_hybrid))
      .collect(&:first)
      .include?("[deleted]"),
           'Cultivar hybrid name status options should include "[deleted]"'
  end

  test "should include [default]" do
    assert NameStatus
      .options_for_category(name_categories(:cultivar_hybrid))
      .collect(&:first)
      .include?("[default]"),
           'Cultivar hybrid name status options should include "[default]"'
  end

  test "should include  [n/a]" do
    assert NameStatus
      .options_for_category(name_categories(:cultivar_hybrid))
      .collect(&:first)
      .include?("[n/a]"),
           'Cultivar hybrid category name status options should include "[n/a]"'
  end

  test "should have only two entries" do
    assert_equal 3,
                 NameStatus
                   .options_for_category(name_categories(:cultivar_hybrid))
                   .size,
                 "Wrong no of name status options for cultivar hybrid category"
  end
end
