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
class InstancesDeleteForEditorTest < ActionController::TestCase
  tests InstancesController

  setup do
    @instance = instances(:triodia_in_brassard)
    @reason = "Edit"
    stub_it
  end

  def a
    "http://localhost:9090/nsl/services/rest/instance/apni/#{@instance.id}"
  end

  def b
    "/api/delete"
  end

  def c
    "?apiKey=test-api-key&reason=#{@reason}"
  end

  def stub_it
    stub_request(:delete, "#{a}#{b}#{c}")
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: { "ok" => true }.to_json, headers: {})
  end

  test "editor should be able to delete instance" do
    @request.headers["Accept"] = "application/javascript"
    # This calls a service, so in Test, no record is actually deleted!
    delete(:destroy,
           params: { id: @instance.id },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    # Editor has to call on services to delete an instance.
    # In test we just stub that call, so no delete happens.
    # Editor checks to see if Services (silently!) fails
    # to delete the instance, then raises an exception if not deleted, so
    # that's what happens in test.  Hence a 422 in test.
    assert_response(422)
  end
end
