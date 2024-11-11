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
  class ProductTest < ActiveSupport::TestCase
    def setup
      @product = product(:foa)
    end

    # Test associations
    test "should have many product_item_configs" do
      assert_respond_to @product, :product_item_configs
      assert @product.product_item_configs.is_a?(ActiveRecord::Associations::CollectionProxy)
    end

    test "should have many profile_items through product_item_configs" do
      assert_respond_to @product, :profile_items
    end

    test "should belong to reference" do
      assert_respond_to @product, :reference
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @product.valid?
    end

    test "should not be valid without a name" do
      @product.name = nil
      assert_not @product.valid?
      assert_includes @product.errors[:name], "can't be blank"
    end

    # Test optional association
    test "should allow nil reference" do
      @product.reference = nil
      assert @product.valid?
    end
  end
end
