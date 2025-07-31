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
  class ProductItemConfigTest < ActiveSupport::TestCase
    def setup
      @product_item_config = product_item_config(:ecology_pic)  # Assuming fixtures are set up
    end

    # Test associations
    test "should belong to product" do
      assert @product_item_config.product.is_a?(::Product)
    end

    test "should belong to profile_item_type" do
      assert @product_item_config.profile_item_type.is_a?(Profile::ProfileItemType)
    end

    test "should have many profile_items" do
      profile_item1 = profile_item(:ecology_pi)
      profile_item2 = profile_item(:notes_pi)
      assert_respond_to @product_item_config, :profile_items
    end

    # Test validations
    test "should be valid with valid attributes" do
      assert @product_item_config.valid?
    end

    test "should not be valid without product_id" do
      @product_item_config.product_id = nil
      assert_not @product_item_config.valid?
      assert_includes @product_item_config.errors[:product_id], "can't be blank"
    end

    test "should not be valid without profile_item_type_id" do
      @product_item_config.profile_item_type_id = nil
      assert_not @product_item_config.valid?
      assert_includes @product_item_config.errors[:profile_item_type_id], "can't be blank"
    end

    test "order by sort_order asc" do    
      product_item_config = Profile::ProductItemConfig.all
      product_item_config_sort_orders = product_item_config.collect{|p| p.sort_order.to_i}
      assert_equal product_item_config_sort_orders, product_item_config_sort_orders.sort{|x,y| x <=> y}
    end
  end
end
