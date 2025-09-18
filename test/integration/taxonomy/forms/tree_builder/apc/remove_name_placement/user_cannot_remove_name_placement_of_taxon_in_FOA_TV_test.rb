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
class TaxFormsTreeBuilderAPCUserCannotRemoveNamePlacementForTaxonOnFOADraftTest < ActionController::TestCase
  tests TreesController

  #r6editor Started DELETE "/nsl/editor/trees/723297/remove_name_placement" for ::1 at 2025-07-18 11:51:43 +1000 (pid:642)
  #r6editor Processing by TreesController#remove_name_placement as JS (pid:642)
  #r6editor Parameters: {"authenticity_token"=>"[FILTERED]",
  #                      "remove_placement"=>{"taxon_uri"=>"/tree/52410589/52410645",
  #                                           "delete"=>""},
  #                                           "cancel_remove_placement"=>{"delete"=>""},
  #                      "id"=>"723297"}
  test "APC tree builder user cannot remove name placement of taxon on FOA draft" do
    user = users(:apc_tax_builder)
    foa_draft = tree_versions(:foa_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    delete(:remove_name_placement,
         params: {"remove_placement"=>{"taxon_uri"=>tve.element_link,
                                       "delete"=>"",
                                       "cancel_remove_placement"=>{"delete"=>""}
                                      },
                  "id" => tve.id
                 },
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: foa_draft,
                    groups: ["login"]})
    assert_response :forbidden, 'APC tree builder should not be able to remove placement from FOA draft'
    assert_match 'You are not authorized to remove names from FOA draft', response.body,
      "Expecting Not authorized message"
  end
end
