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

# Test User can sign in.
class NewSessionKnownUserUpperCaseNoNewUserRecordTest < ActionController::TestCase
  tests SearchController

  def setup
    @known_user = users(:user_one)
  end

  test "new session for known user upper case does not create user record" do
    assert_no_difference("User.count") do
      get(:search,
          params: {},
          session: { username: @known_user.user_name.upcase,
                     user_full_name: "#{@known_user.given_name} #{@known_user.family_name}",
                     groups: [:login] })
      assert_response :success
    end
    assert assigns(:current_registered_user), "Current registered user should be assigned"
    reg_user = assigns(:current_registered_user)
    assert reg_user.user_name == @known_user.user_name, "Registered user not set correctly"
  end
end
