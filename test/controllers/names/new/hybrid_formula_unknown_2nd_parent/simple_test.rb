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
class NamesNewScientHybridFormulaUnk2ParSimpleTest < ActionController::TestCase
  tests NamesController

  test "editor start new scientific hybrid formula unk 2nd parent" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "hybrid formula unknown 2nd parent",
                  random_id: "123445",
                  tabIndex: "107" },
        session: {},
        xhr: true)
    assert_response :success,
                    "Cannot open form for a new scientific hybrid formula
                    unknown 2nd parent name"
    assert_select("h4", /New Scientific Hybrid Formula Unknown 2nd Parent Name/)
  end
end
