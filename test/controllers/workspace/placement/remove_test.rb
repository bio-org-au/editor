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

# Tree (workspace) controller test for remove placement.
class TreePlacementRemoveTest < ActionController::TestCase
  tests ::TreesController
  setup do
    @instance = instances(:usage_of_name_to_be_placed)
    @name = names(:to_be_placed)
    @parent = names(:angophora_costata)
    @workspace = tree_version(:draft_version)
    stub_it
  end

  def stub_it
    url = "http://localhost:9090/nsl/services/api/treeElement/removeElement"
    params = "?apiKey=test-api-key&as=fred"
    body = '{"taxonUri":"tree/123/789"}'

    stub_request(:post, "#{url}#{params}")
      .with(body: body,
            headers: { "Accept" => "application/json",
                       "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Content-Length" => "27",
                       "Content-Type" => "application/json",
                       "Host" => "localhost:9090",
                       "User-Agent" => /ruby/ })
      .to_return(status: 200, body: '{"payload": {"message":"Removed"}}', headers: {})
  end

  test "remove name from workspace" do
    @request.headers["Accept"] = "application/javascript"
    delete(:remove_name_placement,
           params: { id: @workspace,
                     remove_placement: { taxon_uri: "tree/123/789",
                                         delete: "delete" } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: %w[edit treebuilder],
                      workspace: @workspace })
    assert_response :success
    assert_equal "remove_name_placement", @controller.action_name,
                 "Action should be 'remove_name_placement'"
    assert_equal "Removed", @controller.instance_variable_get(:@message)
  end
end
