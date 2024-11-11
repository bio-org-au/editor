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
  class ProfileItemReferenceTest < ActiveSupport::TestCase
    def setup
      @profile_item_reference = profile_item_reference(:one_pir)
    end

    # Test associations
    test "should belong to profile_item" do
      assert_respond_to @profile_item_reference, :profile_item
      assert_instance_of Profile::ProfileItem, @profile_item_reference.profile_item
    end

    test "should belong to reference" do
      assert_respond_to @profile_item_reference, :reference
      assert_instance_of Reference, @profile_item_reference.reference
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @profile_item_reference.valid?
    end

    test "should not allow duplicate reference for the same profile item" do
      duplicate_profile_item_reference = Profile::ProfileItemReference.new(
        profile_item: @profile_item_reference.profile_item,
        reference: @profile_item_reference.reference
      )
      assert_not duplicate_profile_item_reference.valid?
      assert_includes duplicate_profile_item_reference.errors[:base], "Only one reference per profile item is permitted"
    end

    # Test custom method
    test "profile_item_id_reference_id should return combined ids" do
      expected_combination = "#{@profile_item_reference.profile_item_id}_#{@profile_item_reference.reference_id}"
      assert_equal expected_combination, @profile_item_reference.profile_item_id_reference_id
    end
  end
end