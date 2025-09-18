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

# Single search controller test.
class TaxoInstanceTreeBuilderAPCCannotSeeFOATreeTab < ActionController::TestCase
  tests InstancesController

  test "apc tree builder cannot see instance tree tab for FOA version" do
    user = users(:apc_tax_builder)
    foa_draft = tree_versions(:foa_draft_version)
    instance = instances(:triodia_in_brassard)
    get('tab',
        params: {id: "#{instance.id}", tab: 'tab_classification', "row-type": 'instance_record'},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login"],
                   draft: foa_draft})
    assert_response :success, "Tree tab request should be successful"
    assert_no_match 'data-tab-name="tab_classification" href="#">Tree</a>',
                    response.body, "Tab Classification should not be in the response"
    assert_no_match '<form', response.body, 'Tab should not contain a form'
    assert_match 'You are not authorised', response.body, 'User should see message about missing permissions'
  end
end
