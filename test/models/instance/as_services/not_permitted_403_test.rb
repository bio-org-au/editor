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

# Single instance model test.
class InstanceDeleteServiceNotPermitted403Test < ActiveSupport::TestCase
  setup do
    raw = { action: "delete", instance: {}, ok: false,
            errors: ["Not permitted."] }
    stub_request(:delete,
                 "#{action}?apiKey=test-api-key&reason=Edit")
      .with(headers: headers)
      .to_return(status: 403, body: raw.to_json, headers: {})
  end

  def action
    "http://localhost:9090/nsl/services/rest/instance/apni/403/api/delete"
  end

  def headers
    { "Accept" => "application/json",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Host" => "localhost:9090",
      "User-Agent" => /ruby/ }
  end

  test "instance delete service not permitted 403" do
    exception = assert_raise(
      RuntimeError,
      "Should raise runtime exception for not permitted"
    ) do
      # The test mock service determines response based on the id
      Instance::AsServices.delete(403)
    end
    assert_match "from Services: 403 Forbidden", exception.message, "Wrong message"
  end
end
