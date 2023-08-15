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

# Help controller tests.
class HelpControllerTest < ActionController::TestCase
  test "should route to help index" do
    assert_routing "/help/index", controller: "help", action: "index"
  end

  test "should get redirected unauthenticated" do
    get :index
    assert_response :redirect
  end

  test "should get index for reader" do
    get(:index,
        params: {},
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] },
        xhr: true)
    assert_response :success
  end

  test "should get index for editor" do
    get(:index,
        params: {},
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:edit] },
        xhr: true)
    assert_response :success
  end
end
