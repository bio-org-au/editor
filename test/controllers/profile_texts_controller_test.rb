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

class ProfileTextsControllerTest < ActionController::TestCase
  def setup
    @instance = instances(:gaertner_created_metrosideros_costata)
    
    @session = { username: "fred", user_full_name: "Fred Jones", groups: ["edit", "foa"] }
  end

  test "should create profile text" do
    product_item_config = product_item_config(:ecology_pic)

    profile_items = Profile::ProfileItem.where(profile_object_rdf_id: "text", product_item_config_id: product_item_config.id)
    profile_items.destroy_all if profile_items

    assert_difference "Profile::ProfileItem.count", 1 do
      assert_difference "Profile::ProfileText.count", 1 do
        post :create, params: {
          profile_item: {
            instance_id: @instance.id,
            product_item_config_id: product_item_config.id,
            profile_object_rdf_id: product_item_config.profile_item_type.profile_object_type.rdf_id
          },
          profile_text: {
            value: "New profile text",
            value_md: "New profile text"
          }
        }, session: @session, xhr: true
      end
    end

    assert_response :success
    assert_equal "Saved", assigns(:message)
    assert_template :create
  end

  # Test create action failure when profile text already exists
  test "should not create duplicate profile text" do
    product_item_config = product_item_config(:ecology_pic)
    post :create, params: {
      profile_item: {
        instance_id: @instance.id,
        product_item_config_id: product_item_config.id,
        profile_object_rdf_id: product_item_config.profile_item_type.profile_object_type.rdf_id
      },
      profile_text: {
        value: "Existing profile text",
        value_md: "Existing profile text"
      }
    }, session: @session, xhr: true

    assert_response :unprocessable_entity
    assert_equal "Profile text already exists", assigns(:message)
    assert_template :create_failed
  end

  test "should update profile text" do
    profile_item = profile_item(:ecology_pi)
    profile_text = profile_item.profile_text
    put :update, 
          params: {
            id: profile_text.id,
            profile_text: {value_md: "Updated profile text value"},
            profile_item: {id: profile_item.id}
          }, session: @session, xhr: true

    assert_response :success
    assert_equal "Updated", assigns(:message)
    assert_equal profile_text.reload.value_md, assigns(:profile_text).value_md
    assert_equal profile_item, assigns(:profile_item)
    assert_template :update
  end

  test "should handle update failure" do
    profile_item = profile_item(:ecology_pi)
    profile_text = profile_item.profile_text

    Profile::ProfileText.stub_any_instance(:update, false) do
      put :update, 
          params: {
            id: profile_text.id,
            profile_text: {value_md: "Updated profile text value"},
            profile_item: {id: profile_item.id}
          }, session: @session, xhr: true
    end
    assert_response :unprocessable_entity
    assert_equal "Not updated", assigns(:message)
    assert_equal profile_text, assigns(:profile_text)
    assert_equal profile_item, assigns(:profile_item)
    assert_template :update_failed
  end
end
