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

class ProfileItemAnnotationsControllerTest < ActionController::TestCase
  def setup
    @user_product_role = user_product_roles(:user_one_foa_draft_profile_editor)
    @session = {
      username: "uone",
      user_full_name: "Fred Jones",
      groups: ["edit", "foa"]
    }
  end

  test "should create a profile item annotation" do
    assert_difference('Profile::ProfileItemAnnotation.count', 1) do
      profile_item = profile_item(:notes_pi)
      post :create,
          params: {
            profile_item_annotation: {
              profile_item_id: profile_item.id,
              value: "New Annotation"
            }
          }, session: @session, xhr: true
    end

    assert_equal assigns(:profile_item_annotation).value, "New Annotation"
    assert_response :success
    assert_template :create
  end

  test "should update profile item annotation" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation
    put :update, params: {
      id: profile_item_annotation.id,
      profile_item_annotation: {
        value: "Updated Annotation"
      }
    }, session: @session, xhr: true

    assert_response :success
    assert_equal profile_item_annotation.id, assigns(:profile_item_annotation).id
    assert_equal "Updated", assigns(:message)
    assert_equal "Updated Annotation", profile_item_annotation.reload.value
    assert_template :update
  end

  test "should not update if value has not changed" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation
    put :update, params: {
      id: profile_item_annotation.id,
      profile_item_annotation: {
        value: profile_item_annotation.value
      }
    }, session: @session, xhr: true

    assert_response :success
    assert_equal profile_item_annotation.id, assigns(:profile_item_annotation).id
    assert_equal "No change", assigns(:message)
    assert_template :update
  end

  test "should handle error when update fails" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation

    Profile::ProfileItemAnnotation.stub_any_instance(:update, false) do
      put :update, params: {
        id: profile_item_annotation.id,
        profile_item_annotation: {
          value: "New Value"
        }
      }, session: @session, xhr: true

      assert_response :unprocessable_content
      assert_equal profile_item_annotation.id, assigns(:profile_item_annotation).id
      assert_match "Not updated", assigns(:message)
      assert_template :update_failed
    end
  end
end
