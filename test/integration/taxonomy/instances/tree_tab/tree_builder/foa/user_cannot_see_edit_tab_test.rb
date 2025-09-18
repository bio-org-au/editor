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
class TaxoInstanceTreeBuilderFoaCannotSeeEditTab < ActionController::TestCase
  tests InstancesController

  test "foa tree builder cannot see instance edit tab" do
    user = users(:foa_tax_builder)
    foa_draft = tree_versions(:foa_draft_version)
    instance = instances(:triodia_in_brassard)
    assert_routing "/instances/1/tab/tree",
                   controller: "instances",
                   action: "tab",
                   id: "1",
                   tab: "tree"
    get('tab',
        params: {id: "#{instance.id}", tab: 'edit_tab'},
        format: :js,
        xhr: true,
        session: { username: user.user_name,
                   user_full_name: user.full_name,
                   groups: ["login", "xedit"],
                   draft: foa_draft})
    assert_response :forbidden, "Tree builder should not see Edit tab"
  end
end

#2025-07-07 12:27:06.964 [fyi] r6editor Started GET "/nsl/editor/instances/513986/tab/tab_show_1?format=js&tabIndex=1102&row-type=instance_record&instance-type=standalone&rowType=instance_record&take_focus=false" for ::1 at 2025-07-07 12:27:06 +1000 (pid:16127)
#2025-07-07 12:27:06.979 [fyi] r6editor Processing by InstancesController#tab as JS (pid:16127)
#2025-07-07 12:27:06.979 [fyi] r6editor Parameters: {"tabIndex"=>"1102", "row-type"=>"instance_record", "instance-type"=>"standalone", "rowType"=>"instance_record", "take_focus"=>"false", "id"=>"513986", "tab"=>"tab_show_1"} (pid:16127)

