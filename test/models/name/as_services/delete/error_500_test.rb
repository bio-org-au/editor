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
class NameAsServicesDeleteError500Test < ActiveSupport::TestCase
  setup do
    stub_request(:delete, "#{s1}#{s2}")
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" =>
                       "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 500, body: "", headers: {})
  end

  def s1
    "http://localhost:9090/nsl/services/rest/name/apni/540036697/"
  end

  def s2
    "api/delete?apiKey=test-api-key&reason=500%20this%20is%20the%20reason....."
  end

  test "url" do
    name_id = names(:name_to_delete).id
    name = Name::AsServices.find(name_id)
    assert_raise(RestClient::InternalServerError, "Should raise exception") do
      name.delete_with_reason("500 this is the reason.....")
    end
  end
end
