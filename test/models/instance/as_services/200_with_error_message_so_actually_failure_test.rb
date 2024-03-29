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
require "models/instance/as_services/error_stub_helper"

# Single instance model test.
class InstanceDeleteService200WithErrorMessageTest < ActiveSupport::TestCase
  setup do
    @id = instances(:britten_created_angophora_costata).id
    stub_request(:delete,
                 "#{action}?apiKey=test-api-key&reason=Edit")
      .with(headers: headers)
      .to_return(status: 200,
                 body: body.to_json,
                 headers: {})
  end

  def action
    "http://localhost:9090/nsl/services/rest/instance/apni/#{@id}/api/delete"
  end

  def headers
    { "Accept" => "application/json",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Host" => "localhost:9090",
      "User-Agent" => /ruby/ }
  end

  def body
    { "ok" => false, "errors" => ["some silly error"] }
  end

  test "instance delete service 200 with error message" do
    exception = assert_raise(
      UncaughtThrowError,
      "Should raise runtime exception for not deleted"
    ) do
      Instance::AsServices.delete(@id)
    end
    assert_match 'uncaught throw "Check after 3s shows record not deleted"',
                 exception.message, "Wrong message"
  end
end
