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

# Single controller test.
class UserProductRoleNeedAdminToDestroyTest < ActionController::TestCase
  tests User::ProductRolesController

  def setup
    @admin = users(:user_one)
    @user_product_role = user_product_roles(:user_one_foa_draft_profile_editor)
  end

  test "need admin to destroy user product role" do
    assert_no_difference("User::ProductRole.count") do
      post(:destroy,
           params: { "user_id" => @user_product_role.user_id,
                     "product_role_id" => @user_product_role.product_role_id
                   },
           format: :turbo_stream,
           session: { username: @admin.user_name,
                      user_full_name: "#{@admin.given_name} #{@admin.family_name}",
                      groups: [] })
      assert_response :forbidden
    end
  end
end
