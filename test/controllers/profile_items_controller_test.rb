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

class ProfileItemsControllerTest < ActionController::TestCase
  
  def setup
    @profile_item = profile_item(:ecology_pi)
    @session = { username: "fred", user_full_name: "Fred Jones", groups: ["edit", "foa"] }
  end

  test "should destroy profile item and set message" do
    assert_difference("Profile::ProfileItem.count", -1) do
      delete :destroy, params: { id: @profile_item.id }, session: @session, xhr: true
    end
    assert_response :success
    assert_equal "Deleted profile item.", assigns(:message)
  end

  test "should set instance variables" do
    delete :destroy, params: { id: @profile_item.id }, session: @session, xhr: true
    assert_equal @profile_item, assigns(:profile_item)
    assert_equal @profile_item.product_item_config, assigns(:product_item_config)
    assert_equal @profile_item.instance_id, assigns(:instance_id)
  end

  test "should set product item config" do
    delete :destroy, params: { id: @profile_item.id }, session: @session, xhr: true
    assert_equal @profile_item.product_item_config, assigns(:product_item_config)
  end

  test "should handle error when destroy fails" do
    Profile::ProfileItem.stub_any_instance(:destroy!, false) do
      delete :destroy, params: { id: @profile_item.id }, session: @session, xhr: true
      assert_equal @profile_item.destroy!, false
      assert_equal "Error deleting profile item: Not saved", assigns(:message)
      assert_response :unprocessable_entity
      assert_template :destroy_failed
    end
  end

  test "#index to set instance variables" do
    get :index, params: { instance_id: @profile_item.instance_id }, session: @session, xhr: true
    assert_equal @profile_item.instance, assigns(:instance)
  end
end
