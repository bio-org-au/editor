# frozen_string_literal: true

#
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
class HistoryAuthorizationsY2016UnauthenticatedTest < ActionController::TestCase
  tests HistoryController

  test "history y2016 should get redirected unauthenticated" do
    get("for_year", params: { "year" => "2016" }, xhr: true)
    assert_match(/alert.'Your session may have expired./, response.body)
    assert_match(/expired. Please reload the whole page before continuing.'.;/,
                 response.body)
  end
end
