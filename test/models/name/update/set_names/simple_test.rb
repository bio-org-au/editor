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

# Single Name model test.
class NameUpdateSetNamesSimpleTest < ActiveSupport::TestCase
  setup do
    @name = names(:a_species)
    stub_request(:get, "#{address}#{@name.id}/api/name-strings")
      .with(headers: { "Accept" => "text/json",
                       "Accept-Encoding" =>
                       "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "User-Agent" => /rest-client.*ruby.*/ })
      .to_return(status: 200, body: %({ "class": "silly name class",
    "_links": {
        "permalink": [ ]
    },
    "name_element": "redundant name element for id #{@name.id}",
    "action": "unnecessary action",
    "result": {
        "fullMarkedUpName": "full marked up name for id #{@name.id}",
        "simpleMarkedUpName": "simple marked up name for id #{@name.id}",
        "fullName": "full name for id #{@name.id}",
        "simpleName": "simple name for id #{@name.id}"
    } }), headers: {})
  end

  def address
    "http://localhost:9090/nsl/services/rest/name/apni/"
  end

  test "name update set names simple" do
    @name.name_element = "xyz"
    @name.save!
    @name.set_names!
    updated_name = Name.find(@name.id)
    assert_equal "full name for id #{@name.id}",
                 @name.full_name,
                 "Full name not set - make sure the test mock server running."
    assert_equal "full name for id #{@name.id}",
                 updated_name.full_name,
                 "Full name not set"
    assert_equal "full marked up name for id #{@name.id}",
                 updated_name.full_name_html,
                 "Full name html not set"
    assert_equal "simple name for id #{@name.id}",
                 updated_name.simple_name,
                 "Simple name not set"
    assert_equal "simple marked up name for id #{@name.id}",
                 updated_name.simple_name_html,
                 "Simple name html not set"
  end
end
