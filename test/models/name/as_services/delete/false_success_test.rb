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

# Single name model test.
class NameAsServicesDeleteFalseSuccessTest < ActiveSupport::TestCase
  setup do
    stub_request(:delete, /#{sub1}.*[0-9]{9,}#{sub2}.*/)
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" =>
                         "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: body, headers: {})
  end

  def body
    {
      "ok": false,
      "errors": [
        "some silly error"
      ]

    }.to_json
  end

  def sub1
    "nsl.services.rest.name.apni"
  end

  def sub2
    ".api.delete.apiKey=test-api-key.reason=666"
  end

  test "url" do
    name_id = names(:name_to_delete).id
    name = Name::AsServices.find(name_id)
    assert_raise(RuntimeError, "Should raise exception.") do
      name.delete_with_reason("666 this is the reason.....")
    end
  end
end
