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
class UserDeleteUnauthorisedTest < ActionController::TestCase
  tests UsersController

  test "update user simple" do
    @request.headers["Accept"] = "application/javascript"
    user= users(:user_two)
    patch(:update,
          params: {  id: user.id,
                     "user"=>{"user_name"=>"updated_name",
                              "given_name"=>"updated_given_name",
                              "family_name"=>"updated_family_name"},
                              "commit"=>"Save"},
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    assert_response(:forbidden)
    unchanged = User.find(user.id)
    assert_match(unchanged.user_name, user.user_name)
    assert_match(unchanged.given_name, user.given_name)
    assert_match(unchanged.family_name, user.family_name)
  end
end
