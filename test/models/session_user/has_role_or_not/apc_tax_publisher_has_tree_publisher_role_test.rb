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

# Test fixtures are intact
class SessionUserAPCTaxPublisherHasTreePublisherRoleTest < ActiveSupport::TestCase

  test "apc tax publisher user has tax publisher role" do
    user = users(:apc_tax_publisher)
    role = roles(:tree_publisher)
    session_user = SessionUser.new(username: user.user_name, full_name: "#{user.given_name} #{user.family_name}", groups: 'login')
    assert(session_user.with_role?(role.name), "Expecting #{user.user_name} user to be a #{role.name}")
  end
end
