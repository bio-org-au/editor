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
class InstanceTabsNotesTest < ActionController::TestCase
  tests InstancesController
  setup do
    @triodia_in_brassard = instances(:triodia_in_brassard)
  end

  test "notes tab simple" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @triodia_in_brassard.id,
                  tab: "tab_edit_notes" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    asserts
  end

  def asserts
    asserts1
    asserts2
    asserts3
  end

  def asserts1
    assert_select "h5", "Add Note for #{@triodia_in_brassard.name.simple_name}", 
      "Needs correct heading."
    assert_select "form#new_instance_note", true, "Needs insert form."
    assert_select "form#new_instance_note" do
      assert_select "select.instance-note-key-id-select", true, "Needs select."
      assert_select "option", 11, "Needs 11 options."
      assert_select "option", /\AType\z/i, "Needs Type option."
      assert_select "option", /\ALectotype\z/i, "Needs Lectotype option."
      assert_select "option", /\ANeotype\z/i, "Needs Neotype option."
      assert_select "option", /\AText\z/i, "Needs Text option."
    end
  end

  def asserts2
    assert_select "form#new_instance_note" do
      assert_select "option", /\AComment\z/i, "Needs Comment option."
      assert_select "option", /\AEtymology\z/i, "Needs Etymology option."
      assert_select "option", /\AEPBC Advice\z/i, "Needs EPBC Advice option."
      assert_select "option", /\AEPBC Impact\z/i, "Needs EPBC Impact option."
      assert_select "option", /\AType herbarium\z/i, "Needs Type herb. option."
      assert_select "option", /\AVernacular\z/i, "Needs Vernacular option."
      assert_select "input#instance-note-create-btn", 1, "Needs create button."
    end
  end

  def asserts3
    assert_select "textarea.instance-note-value-text-area", true, "Needs text."
  end
end
