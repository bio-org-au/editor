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
  class ProfileItemTypeTest < ActiveSupport::TestCase
    def setup
      @profile_item_type = profile_item_type(:ecology_pit)
    end

    # Test associations
    test "should belong to profile_object_type" do
      assert_respond_to @profile_item_type, :profile_object_type
      assert_instance_of Profile::ProfileObjectType, @profile_item_type.profile_object_type
    end

    test "should have many product_item_configs" do
      assert_respond_to @profile_item_type, :product_item_configs
      assert @profile_item_type.product_item_configs.is_a?(ActiveRecord::Associations::CollectionProxy)
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @profile_item_type.valid?
    end

    test "should not be valid without a name" do
      @profile_item_type.name = nil
      assert_not @profile_item_type.valid?
      assert_includes @profile_item_type.errors[:name], "can't be blank"
    end
  end
end
