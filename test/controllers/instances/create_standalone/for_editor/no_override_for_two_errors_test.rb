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
class NoOverrideForTwoErrorsTest < ActionController::TestCase
  tests InstancesController
  def setup
    @target_instance = instances(:britten_created_angophora_costata)
    assert_equal(@target_instance.instance_type_id,
                 instance_types(:comb_nov).id,
                 "Target instance should be a comb nov.")
    @instance_params = { "instance_type_id" => instance_types(:comb_nov).id,
                         "page" => @target_instance.page,
                         "name_id" => @target_instance.name_id,
                         "reference_id" => @target_instance.reference_id,
                         "duplicate_instance_override" => "1",
                         "multiple_primary_override" => "1" }
    @request.headers["Accept"] = "application/javascript"
  end

  test "can create duplicate primary instance with override" do
    assert_no_difference("Instance.count") do
      post(:create,
           params: { instance: @instance_params },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    end
    check_assertions_1
    check_assertions_2
  end

  def check_assertions_1
    assert_response 422, "Response should be 422, unprocessable entity."
    assert_match(/Multiple errors/,
                 response.body,
                 "No mention of multiple errors")
    assert_match(/No overrides are available when there are multiple errors/,
                 response.body,
                 "No explanation that overrides are not available")
  end

  def check_assertions_2
    error_s = "Saving this instance would result in multiple primary instances"
    error_s += " for the same name."
    assert_match(/#{error_s}/,
                 response.body,
                 "Expected error message did not appear")
    error_s = "already exists with the same reference, type and page."
    assert_match(/#{error_s}/,
                 response.body,
                 "Expected error message did not appear")
  end
end
