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
class NamesCreateByEditorTest < ActionController::TestCase
  tests NamesController

  setup do
    @name_status = name_statuses(:legitimate)
    @name_rank = name_ranks(:species)
    @name_type = name_types(:scientific)
    @parent = names(:a_genus)
    @parent_typeahead = names(:a_genus).full_name
    @family = names(:a_family)
    @family_typeahead = names(:a_family).full_name
    @name_element = "fred"
    stub_it
  end

  def a
    "localhost:9090"
  end

  def b
    "name-strings"
  end

  def stub_it
    stub_request(:get, %r{#{a}.nsl/services.rest.name.apni.[0-9][0-9]*.api.#{b}})
      .with(headers: { "Accept" => "text/json", "Accept-Encoding" => /.*/,
                       "User-Agent" => /rest-client.*ruby.*/ })
      .to_return(status: 200, body: %({ "class": "silly name class",
      "_links": { "permalink": [ ] }, "name_element":
      "redundant name element for id 91755", "action": "unnecessary action",
      "result": { "fullMarkedUpName": "full marked up name for id 91755",
        "simpleMarkedUpName": "simple marked up name for id 91755",
        "fullName": "full name for id 91755",
        "simpleName": "simple name for id 91755" } }).to_json, headers: {})
  end

  test "editor should be able to create name" do
    @request.headers["Accept"] = "application/javascript"
    assert_difference("Name.count") do
      post(:create,
           params: { name: { "name_status_id" => @name_status.id,
                             "name_rank_id" => @name_rank.id,
                             "name_type_id" => @name_type.id,
                             "parent_id" => @parent.id,
                             "parent_typeahead" => @parent_typeahead,
                             "family_id" => @parent.id,
                             "family_typeahead" => @family_typeahead,
                             "name_element" => @name_element } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] },
           xhr: true)
    end
  end
end
