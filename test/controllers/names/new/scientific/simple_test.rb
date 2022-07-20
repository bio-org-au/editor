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
class NamesNewScientificSimpleTest < ActionController::TestCase
  tests NamesController

  test "editor should be able to start a new scientific" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "scientific",
                  random_id: "123445",
                  tabIndex: "107" },
        session: {},
        xhr: true)
    assert_response :success, "Cannot start enter new scientific name"
    assert_select("h4", /New Scientific Name/)
    assert_select "input" do |inputs|
      inputs.each do |input|
        if input.to_s.match(/name-parent-typeahead/)
          assert_match "required", input.to_s, "name-parent-typeahead should be required"
        end
      end
    end
  end
end
