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
class UserUpdateSimpleTest < ActionController::TestCase
  tests UsersController

  test "update user simple" do
    @request.headers["Accept"] = "application/javascript"
    user= users(:user_two)
    patch(:update,
          params: {  id: user.id,
                     "user"=>{"name"=>"updated_name",
                              "given_name"=>"updated_given_name",
                              "family_name"=>"updated_family_name"},
                              "commit"=>"Save"},
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["admin"] })
    assert_response(:success)
    changed = User.find(user.id)
    assert_match(changed.name, "updated_name")
    assert_match(changed.given_name, "updated_given_name")
    assert_match(changed.family_name, "updated_family_name")
  end
end
