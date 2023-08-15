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
class HybridFormulaFirstParentChangeTest < ActionController::TestCase
  tests NamesController

  setup do
    stub_it
    @hybrid_formula = names(:hybrid_formula)
    @new_first_parent = names(:angophora_costata)
    @nfp_typeahead_string = "Angophora costata (Gaertn.) Britten | Species"
    @request.headers["Accept"] = "application/javascript"
    @expected_name_element = "costata x another-species"
    @expected_name_path = "Plantae/Magnoliophyta/a_family/a_genus/thingbb/#{@expected_name_element}"
  end
  def a
    "localhost:9090"
  end

  def b
    "name-strings"
  end

  def stub_it
    stub_request(:get, %r{#{a}.nsl/services.rest.name.apni.[0-9]*.api.#{b}})
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

  test "hybrid formula 1st parent change flows to name element and name path" do
    post(:update,
         params: { name: { "parent_id" => @new_first_parent.id.to_s,
                           "parent_typeahead" => @nfp_typeahead_string },
                   id: @hybrid_formula.id },
         session: { username: "fred",
                    user_full_name: "Fred Jones",
                    groups: ["edit"] })
    assert_response :success
    sleep(2) # to allow for the asynch job
    hybrid_after_change = Name.find(@hybrid_formula.id)
    assert @hybrid_formula.name_element != hybrid_after_change.name_element,
           "Name element should change"
    assert hybrid_after_change.name_element == @expected_name_element,
           "Name element should change to '#{@expected_name_element}'"
    assert @hybrid_formula.name_path != hybrid_after_change.name_path,
           "Name path should change"
    assert hybrid_after_change.name_path == @expected_name_path,
           "Name path should change to: '#{@expected_name_path}'"
  end

  def debug(name, comment)
    puts("#{comment} full_name: #{name.full_name}")
    puts("#{comment} name_element: #{name.name_element}")
    puts("#{comment} name_path: #{name.name_path}")
  end
end
