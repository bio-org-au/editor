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
  class ProfileItemAnnotationTest < ActiveSupport::TestCase
    def setup
      @profile_item_annotation = profile_item_annotation(:one_pia)
    end

    # Test associations
    test "should belong to profile_item" do
      assert_respond_to @profile_item_annotation, :profile_item
      assert_instance_of Profile::ProfileItem, @profile_item_annotation.profile_item
    end

    test "should have one product_item_config through profile_item" do
      assert_respond_to @profile_item_annotation, :product_item_config
      assert_instance_of Profile::ProductItemConfig, @profile_item_annotation.product_item_config
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @profile_item_annotation.valid?
    end

    test "should not be valid without a value" do
      @profile_item_annotation.value = nil
      assert_not @profile_item_annotation.valid?
      assert_includes @profile_item_annotation.errors[:value], "can't be blank"
    end

    test "should not allow duplicate profile_item_id" do
      duplicate_annotation = Profile::ProfileItemAnnotation.new(
        profile_item: @profile_item_annotation.profile_item,
        value: "Duplicate value"
      )
      assert_not duplicate_annotation.valid?
      assert_includes duplicate_annotation.errors[:profile_item_id], "Profile item annotation must be unique per profile item"
    end
  end
end
