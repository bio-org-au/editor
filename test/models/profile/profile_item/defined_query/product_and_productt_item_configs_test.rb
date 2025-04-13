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
require 'test_helper'

class ProductAndProductItemConfigsTest < ActiveSupport::TestCase
  def setup
    @profile_item = profile_item(:ecology_pi)
    @instance = @profile_item.instance
    @product = @profile_item.product
    @product_item_config = @profile_item.product_item_config
    @product_item_config2 = product_item_config(:habitat_pic)
    @session_user = SessionUser.new(username: "testuser")

    @user = users(:user_one)
    @user.update(user_name: @session_user.username)

    Rails.configuration.profile_v2_aware = true

    SessionUser.stub_any_instance(:groups, ["foa"]) do
      @query = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs.new(@session_user, @instance)
    end
  end

  test ".initialize" do
    assert_equal @product, @query.product
    assert_equal @instance, @query.instance
  end

  test "#run_query with feature flag on" do
    product_configs_and_profile_items, product = @query.run_query

    assert_equal 2, product_configs_and_profile_items.size
    assert_equal @product, product

    product_configs_and_profile_items.each do |item|
      assert_kind_of Profile::ProductItemConfig, item[:product_item_config]
      assert_kind_of Profile::ProfileItem, item[:profile_item]
      assert_equal @instance.id, item[:profile_item].instance_id
    end
  end

  test "#run_query with feature flag on and with product_item_config_id param" do
    param = {product_item_config_id: @product_item_config.id}
    SessionUser.stub_any_instance(:groups, ["foa"]) do
      product_configs_and_profile_items, product = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs.new(@session_user, @instance, param).run_query
      assert_equal 1, product_configs_and_profile_items.size
      assert_equal @product, product

      product_configs_and_profile_items.each do |item|
        assert_kind_of Profile::ProductItemConfig, item[:product_item_config]
        assert_kind_of Profile::ProfileItem, item[:profile_item]
        assert_equal @instance.id, item[:profile_item].instance_id
      end
    end
  end

  test "#run_query to return an empty profile itme when instance is nil" do
    SessionUser.stub_any_instance(:groups, ["foa"]) do
      result = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs.new(@session_user, nil).run_query
      assert_equal result.first, []
      assert_equal result.last, @product
    end
  end

  test "#run_query to return an empty profile itme when product is nil" do
    @product.update(name: "not foa")
    SessionUser.stub_any_instance(:groups, ["foa"]) do
      result = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs.new(@session_user, @instance).run_query
      assert_equal result.first, []
      assert_nil result.last
    end
  end

  test "#run_query with feature flag off" do
    Rails.configuration.profile_v2_aware = false

    result = @query.run_query

    assert_empty result.first
    assert_equal @product, result.last
  end

  test "#run_query with rdf_id=reference params" do
    profile_item = profile_item(:ecology_pi_ref)
    SessionUser.stub_any_instance(:groups, ["foa"]) do
      product_configs_and_profile_items, product = Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs.new(@session_user, @instance, {rdf_id: "reference"}).run_query
      assert_equal 1, product_configs_and_profile_items.size
      profile_item_type = product_configs_and_profile_items.first[:product_item_config].profile_item_type
      assert_equal profile_item_type.rdf_id, "ecology.reference"
    end
  end
end
