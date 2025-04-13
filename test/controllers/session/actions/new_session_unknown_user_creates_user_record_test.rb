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
class NewSessionUnknownUserCreatesUserRecordTest < ActionController::TestCase
  tests SearchController

  def setup
    @unknown_user_name = "fjones"
    @unknown_user_full_name = "Fred Jones"
  end

  test "new session for unknown user creates user record" do
    assert_difference("User.count") do
      get(:search,
          params: {},
          session: { username: @unknown_user_name,
                     user_full_name: @unknown_user_full_name,
                     groups: [:login] })
      assert_response :success
    end
    assert assigns(:current_registered_user), "Current registered user should be assigned"
    reg_user = assigns(:current_registered_user)
    assert reg_user.user_name == @unknown_user_name, "Registered user not set correctly"
  end
end
