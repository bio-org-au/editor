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
class CannotUpdateStandaloneToDupPrimEvenWOverrides < ActionController::TestCase
  tests InstancesController
  def setup
    @instance = instances(:casuarina_inophloia_by_mueller)
    assert @instance.instance_type == instance_types(:secondary_reference)
    @target = instances(:casuarina_inophloia_by_mueller_and_bailey)
    assert @target.instance_type == instance_types(:tax_nov)
    @request.headers["Accept"] = "application/javascript"
  end

  test "ed cannot update standalone inst 2 xtra primary even with overrides" do
    put(:update,
        params: { id: @instance.id,
                  instance: { "reference_id" => @target.reference_id,
                              "instance_type_id" => @target.instance_type_id,
                              "page" => @target.page,
                              "duplicate_instance_override" => "1",
                              "multiple_primary_override" => "1" } },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert Instance.find(@instance.id).name_id == @target.name_id
    check_assertions
  end

  def check_assertions
    assert_response 422, "Response should be 422, unprocessable entity."
    es = "Multiple errors"
    assert_match(/#{es}/,
                 response.body,
                 "Expected multiple errors message did not appear")
    es = "already exists with the same reference, type and page."
    assert_match(/#{es}/,
                 response.body,
                 "Expected error message did not appear")
    es = "Saving this instance would result in multiple primary instances"
    es += " for the same name."
    assert_match(/#{es}/,
                 response.body,
                 "Expected error message did not appear")
  end
end
