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
class InstanceForFoaShowMostTabsTest < ActionController::TestCase
  tests InstancesController
  setup do
    Rails.configuration.profile_v2_aware = true
    @instance = instances(:gaertner_created_metrosideros_costata)
    @product_item_config = product_item_config(:ecology_pic)
    @profile_item = profile_item(:ecology_pi)
    @request.headers["Accept"] = "application/javascript"

    get(:show,
        params: { id: @instance.id,
                  tab: "tab_profile_v2" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["foa"] })
  end

  def asserts
    asserts1
    asserts2
    asserts3
    asserts4
    asserts5
    asserts6
    asserts7
    asserts8
  end

  def asserts1
    assert_response :success
    assert_select "a#instance-profile-v2-tab",
                   /FOA/
                   "Should not show 'FOA Profile' tab link"
    assert_select "h4",
                   @product_item_config.display_html,
                   "Should show the product item config display_html"
  end

  def asserts2
    assert_select "li.active a#instance-show-tab",
                  /Details/,
                  "Shows 'Details' tab link."
  end

  def asserts3
    assert_select "a#instance-edit-tab",
                  false,
                  "Does not show 'Edit' tab link."
    assert_select "a#instance-edit-notes-tab",
                  false,
                  "Does not show 'Notes' tab link."
  end

  def asserts4
    assert_select "a#instance-cite-this-instance-tab",
                  false,
                  "Does not show 'Syn' tab link."
    assert_select "a#unpublished-citation-tab",
                  false,
                  "Does not show 'Unpub' tab link."
    assert_select "a#instance-apc-placement-tab",
                  false,
                  "Should not show 'APC' tab link."
  end

  def asserts5
    assert_select "a#instance-comments-tab",
                  false,
                  "Does not show 'Adnot' tab link."
    assert_select "a#instance-copy-to-new-reference-tab",
                  false,
                  "Should not show 'Copy' tab link."
  end

  def asserts6
    @product = @profile_item.product
    @product.update(name: "not foa")
    assert_response :success
    assert_select "a#instance-profile-v2-tab",
                   /FOA/
                   "Should not show 'FOA Profile' tab link"
    assert_select "#message_no_product_configs",
                   "There are no product or product configs setup yet.",
                   "Should show a message"
  end

  def asserts7
    Instance.delete_all
    assert_response :success
    assert_select "a#instance-profile-v2-tab",
                   /FOA/
                   "Should not show 'FOA Profile' tab link"
    assert_select "#message_no_product_configs",
                   "There are no product or product configs setup yet.",
                   "Should show a message"
  end

  def asserts8
    Rails.configuration.profile_v2_dropdown_ui = true
    assert_select "select#item_type",
                   true
                   "Should show a dropdown of the available product item configs when flag is on"

    assert_select "h4",
      false,
      "Should not display profile items immediately"

    Rails.configuration.profile_v2_dropdown_ui = false
    assert_select "select#item_type",
                  false
                  "Should not show a dropdown of the available product item configs when flag is off"

    assert_select "h4",
      @product_item_config.display_html,
      "Should show the product item config display_html"
  end

end
