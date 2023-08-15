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
class InstancesCreateCitesAndCitedByByEdDupErrTest < ActionController::TestCase
  tests InstancesController
  def setup
    @instance_1 = instances(:gaertner_created_metrosideros_costata)
    @instance_2 = instances(:britten_created_angophora_costata)
    @instance_type = instance_types(:synonym)
    @request.headers["Accept"] = "application/javascript"
  end

  test "create duplicate cites and cited by instance should be error" do
    assert_no_difference("Instance.count") do
      post(:create,
           params: { instance: { "cites_id" => @instance_1.id,
                                 "cited_by_id" => @instance_2.id,
                                 "name_id" => @instance_1.name.id,
                                 "reference_id" => @instance_2.reference.id,
                                 "instance_type_id" => @instance_type.id,
                                 "page" => "xx,20,1000" } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    end
    check_assertions
  end

  def check_assertions
    assert_response 422, "Response should be 422, unprocessable entity."
    # NOTE: this assertion failed in upgraded to Rails 7
    # assert_match(/already exists with the same reference, type and page/,
    #            response.body,
    #            "Unexpected error message part 1")
    assert_match(/A name cannot be placed in synonymy twice/,
                 response.body,
                 "Unexpected error message part 2")
  end
end
