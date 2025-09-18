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
class TaxFormsTreePublisherAPCUserCannotPlaceNameOnFOADraftTest < ActionController::TestCase
  tests TreesController

  # r6editor Started POST "/nsl/editor/trees/513991/place_name" for ::1 at 2025-07-18 15:38:05 +1000 (pid:96312)
  # r6editor Processing by TreesController#place_name as JS (pid:96312)
  # r6editor Parameters: {"authenticity_token"=>"[FILTERED]",
  #                       "place_name"=>{"instance_id"=>"513991",
  #                                      "comment"=>"jhiuh",
  #                                      "distribution"=>["NSW"],
  #                                      "parent_name_typeahead_string"=>"Angophora bakeri E.C.Hall",
  #                                      "parent_element_link"=>"/tree/52410589/52410645",
  #                                      "version_id"=>"52410589",
  #                                      "place"=>""},
  #                       "id"=>"513991"}
  test "APC tree publisher user cannot place name on FOA draft" do
    user = users(:apc_tax_publisher)
    foa_draft = tree_versions(:foa_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    # Raising this exception means it got as far as calling the API
    # The processing after calling the API, based on what the API returns
    # (in our case, that's from a stub) is complex.  No need to simulate all that.
    post(:place_name,
         params: {"place_name"=>{"instance_id"=>12345,
                                       "comment"=>"blah",
                                       "distribution"=>["NSW"],
                                       "parent_name_typeahead_string"=>"Angophora bakeri E.C.Hall",
                                       "parent_element_link"=>"/tree/52410589/52410645",
                                       "version_id"=>foa_draft.id,
                                       "place"=>""},
                  "id" => tve.id
                 },
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: foa_draft,
                    groups: ["login"]})
    assert_response :forbidden, "Should be forbidden"
    assert_match /access denied/i, response.body,
      "Expecting Not authorized message"
  end
end

