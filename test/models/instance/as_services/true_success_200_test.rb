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
require "models/instance/as_services/success_stub_helper"

# Single instance model test.
class InstanceAsServicesTrueSuccess200Test < ActiveSupport::TestCase
  setup do
    stub_request(:delete,
                 "#{action}?apiKey=test-api-key&reason=Edit")
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" =>
                         "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200,
                 body: body_hash.to_json, headers: {})
  end

  def body_hash
    { "instance":
      { "class":
        "au.org.biodiversity.nsl.Instance",
        "_links": inner_hash,
        "instanceType": "taxonomic synonym",
        "protologue": false,
        "citation": citation,
        "citationHtml": citation },
      "action": "delete", "ok": true }
  end

  def inner_hash
    {
      "permalink": {
        "link": "http://localhost:8080/nsl/mapper/boa/instance/apni/819227",
        "preferred": true,
        "resources": 1
      }
    }
  end

  def citation
    "Leach, G.J. (1986), A Rev of the Genus Angophora (Myrtaceae). Telopea 2(6)"
  end

  def action
    "http://localhost:9090/nsl/services/rest/instance/apni/200/api/delete"
  end

  test "instance delete service true success 200" do
    # The test mock responds based on the id
    Instance::AsServices.delete(200)
    assert :success
  end
end
