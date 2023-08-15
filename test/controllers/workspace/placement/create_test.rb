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

# Tree (workspace) controller test for create placement.
class TreePlacementCreateTest < ActionController::TestCase
  tests ::TreesController
  setup do
    @instance = instances(:usage_of_name_to_be_placed)
    @name = names(:to_be_placed)
    @parent = names(:angophora_costata)
    @workspace = tree_version(:draft_version)
    stub_it
    stub_mapper
  end

  def stub_it
    url = "#{Rails.configuration.services}api/treeElement/placeElement"
    params = "?apiKey=test-api-key&as=fred"
    # removed body from stub because the timestamps change and we can't guess that from here.    # body = '{"instanceUri":"http://localhost:7070/nsl-mapper/instance/apni/481811","parentElementUri":"tree/123/456","excluded":false,"profile":{"APC Comment":{"value":"yo","updated_by":"fred","updated_at":"2018-05-23T04:32:07Z"},"APC Dist.":{"value":"ACT,Wa","updated_by":"fred","updated_at":"2018-05-23T04:32:07Z"}},"versionId":131443681}'
    stub_request(:put, "#{url}#{params}")
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Content-Type" => "application/json",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: '{"payload": {"message":"Placed"}}', headers: {})
  end

  def stub_mapper
    uri = "#{Rails.configuration.nsl_linker}broker/preferredLink?idNumber=#{@instance.id}&nameSpace=anamespace&objectType=instance"
    stub_request(:get, uri)
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Content-Type" => "application/json",
                       "Host" => Rails.configuration.nsl_linker
                                          .sub(%r{^http://}, "")
                                          .split(%r{/})[0],
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: %({"link":"#{Rails.configuration.nsl_linker}instance/apni/481811"}), headers: {})
  end

  test "place name in workspace" do
    @request.headers["Accept"] = "application/javascript"
    patch(:place_name,
          params: { id: @workspace,
                    place_name: { name_id: @name,
                                  instance_id: @instance.id,
                                  parent_element_link: "tree/123/456",
                                  comment: "yo",
                                  distribution: %w[ACT Wa],
                                  excluded: false,
                                  version_id: @workspace.id,
                                  parent_name_typeahead_string: @parent.full_name } },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: %w[edit treebuilder],
                     workspace: @workspace })
    assert_response :success
    assert_equal "place_name", @controller.action_name,
                 "Action should be 'place_name'"
    assert_equal "Placed", @controller.instance_variable_get(:@message)
  end
end
