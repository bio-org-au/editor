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

class ProfileItemReferencesControllerTest < ActionController::TestCase
  def setup
    @profile_item = profile_item(:ecology_pi)
    @reference = references(:section_with_heyland_author_different_from_parent)
    @user_product_role = user_product_roles(:user_one_foa_draft_profile_editor)
    @valid_params = {
      profile_item_reference: {
        reference_id: @reference.id,
        annotation: 'New Annotation',
        profile_item_id: @profile_item.id
      }
    }
    @session = { username: "uone", user_full_name: "Fred Jones", groups: ["edit", "foa"] }
  end

  test "should create profile item reference successfully" do
    post :create, params: @valid_params, session: @session, xhr: true
    assert_response :success
    assert_equal "Saved", assigns(:message)
    assert_template :create
  end

  test "should fail to create profile item reference for the same reference" do
    Profile::ProfileItemReference.create(
      reference_id: @reference.id,
      annotation: '1st Annotation',
      created_by: "tester",
      created_at: Time.current,
      updated_by: "tester",
      updated_at: Time.current,
      profile_item_id: @profile_item.id
    )

    post :create,
        params: {
          profile_item_reference: {
            reference_id: @reference.id,
            annotation: '2nd Annotation',
            profile_item_id: @profile_item.id
          }
        }, session: @session, xhr: true

    assert_response :unprocessable_entity
    assert_match "Only one reference per profile item is permitted", assigns(:message)
    assert_template :create_failed
  end

  test "should fail to create profile item reference when there is no enough permission granted to db" do
    Profile::ProfileItemReference.stub_any_instance(:save!, -> { raise PG::InsufficientPrivilege, "ERROR: permission denied for table \"profile_item_references\"" }) do
      post :create,
          params: {
            profile_item_reference: {
              reference_id: @reference.id,
              annotation: '2nd Annotation',
              profile_item_id: @profile_item.id
            }
          }, session: @session, xhr: true

      assert_response :unprocessable_entity
      assert_match "Error creating profile item reference: ERROR: permission denied for table \"profile_item_references\"", assigns(:message)
      assert_template :create_failed
    end
  end

  test "should update profile item reference" do
    Profile::ProfileItemReference.create(
      reference_id: @reference.id,
      annotation: '1st Annotation',
      created_by: "tester",
      created_at: Time.current,
      updated_by: "tester",
      updated_at: Time.current,
      profile_item_id: @profile_item.id
    )

    put :update,
        params: {
          reference_id: @reference.id,
          profile_item_id: @profile_item.id,
          profile_item_reference: {
            annotation: "Updated Annotation"
          }
        }, session: @session, xhr: true
    assert_response :success
    assert_equal "Updated", assigns(:message)
    assert_template :update
  end

  test "should not update profile item reference when no changes" do
    Profile::ProfileItemReference.create(
      reference_id: @reference.id,
      annotation: '1st Annotation',
      created_by: "tester",
      created_at: Time.current,
      updated_by: "tester",
      updated_at: Time.current,
      profile_item_id: @profile_item.id
    )

    put :update,
        params: {
          reference_id: @reference.id,
          profile_item_id: @profile_item.id,
          profile_item_reference: {
            annotation: "1st Annotation"
          }
        }, session: @session, xhr: true

    assert_response :success
    assert_equal "No change", assigns(:message)
    assert_template :update
  end

  test "should destroy profile item reference" do
    Profile::ProfileItemReference.create(
      reference_id: @reference.id,
      annotation: '1st Annotation',
      created_by: "tester",
      created_at: Time.current,
      updated_by: "tester",
      updated_at: Time.current,
      profile_item_id: @profile_item.id
    )
    delete :destroy,
          params: {
            reference_id: @reference.id,
            profile_item_id: @profile_item.id,
          }, session: @session, xhr: true
    assert_response :success
    assert_equal "Deleted profile item reference.", assigns(:message)
    assert_template :destroy
  end

  test "should handle error when destroy fails" do
    Profile::ProfileItemReference.create(
      reference_id: @reference.id,
      annotation: '1st Annotation',
      created_by: "tester",
      created_at: Time.current,
      updated_by: "tester",
      updated_at: Time.current,
      profile_item_id: @profile_item.id
    )

    Profile::ProfileItemReference.stub_any_instance(:destroy, false) do
      delete :destroy,
          params: {
            reference_id: @reference.id,
            profile_item_id: @profile_item.id,
          }, session: @session, xhr: true
      assert_response :unprocessable_entity
      assert_template :destroy_failed
    end
  end
end
