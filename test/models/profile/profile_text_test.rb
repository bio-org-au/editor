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

module Profile
  class ProfileTextTest < ActiveSupport::TestCase
    def setup
      @profile_text = profile_text(:one_pt)
    end

    # Test associations
    test "should have one profile_item" do
      assert_respond_to @profile_text, :profile_item
    end

    test "should have one product_item_config through profile_item" do
      assert_respond_to @profile_text, :product_item_config
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @profile_text.valid?
    end

    test "should not be valid without value_md" do
      @profile_text.value_md = nil
      assert_not @profile_text.valid?
      assert_includes @profile_text.errors[:value_md], "can't be blank"
    end

    test "should not be valid without value" do
      @profile_text.value = nil
      assert_not @profile_text.valid?
      assert_includes @profile_text.errors[:value], "can't be blank"
    end
  end
end
