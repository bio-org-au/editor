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
#
# Note: 
#   xhr: true
#
# stopped this error in test: 
#
# ActionController::InvalidCrossOriginRequest: Security warning: 
#   an embedded <script> tag on another site requested protected JavaScript.
class TaxFormsUserWithNoRoleCannotReplacePlacementOnFOADraftTest < ActionController::TestCase
  tests TreesController

# r6editor Started PATCH "/nsl/editor/trees/612279/replace_placement" for ::1 at 2025-07-17 15:34:26 +1000 (pid:642)
# r6editor Processing by TreesController#replace_placement as JS (pid:642)
# Parameters: {"authenticity_token"=>"[FILTERED]", 
 #             "move_placement"=>{"element_link"=>"/tree/52410589/52410631",
 #                                "instance_id"=>"612279",
 #                                "comment"=>"Subspecies are recognised in this species in Euclid... ",
 #                                "parent_name_typeahead_string"=>"Angophora Cav.",
 #                                "parent_element_link"=>"/tree/52410589/51230780",
 #                                "update"=>""},
 #            "id"=>"612279"}
  test "user with no role cannot replace placement for taxon on FOA tree draft" do
    user = users(:no_role)
    foa_draft = tree_versions(:foa_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    patch(:replace_placement,
         params: {"move_placement"=>{"element_link"=>tve.element_link,
                                     "instance_id"=>"12345",
                                     "comment"=>"xyz comment",
                                     "parent_name_typeahead_string"=>"Angophora Cav.",
                                     "parent_element_link"=> tve.element_link,
                                     "update"=>""},
                   "id"=>"612279"},
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: foa_draft,
                    groups: ["login"]})
    assert_response :forbidden, 'APC tree publisher should be not able to replace_placement on FOA draft entry'
    assert_match 'Access Denied', response.body, "Expecting Access Denied message"

  end
end



