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

class APCTreeBuilderUpdateSynByInstanceForAPCDraftTest < ActionController::TestCase
  tests TreesController

  def setup
    stub_request(:post, %r{http:..localhost:90...*tree-element.update-synonymy-by-instance.apiKey=test-api-key.as=apc-tax-builder}).
    with(
      headers: {
	    'Accept'=>/json/,
      'Accept-Encoding'=>/.*/,
      'Content-Length'=>/.*/,
      'Host'=>/localhost:.*/,
	    'User-Agent'=>/ruby/
      }).
    to_return(status: 200, body: "", headers: {})
  end

  # r6editor Started POST "/nsl/editor/trees/update_synonymy_by_instance" 
  # r6editor Processing by TreesController #update_synonymy_by_instance as JS
  # r6editor Parameters: {"versionId"=>"52410589", "instances"=>"612279", "update_checked_synonymy"=>""}
  test "APC tree builder can update synonymy by instance for APC draft" do
    user = users(:apc_tax_builder)
    draft = tree_versions(:apc_draft_version)
    post(:update_synonymy_by_instance,
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: draft,
                    groups: ["login"]})
    assert_response :success, 'APC tree builder should be able to update synonymy by instance for APC draft'
  end
end


