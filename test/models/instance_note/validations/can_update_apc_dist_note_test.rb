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

# Single instance note model test.
class InstanceNoteCanUpdateApcDistNoteTest < ActiveSupport::TestCase
  test "can update instance apc dist note" do
    apc_dist_note_key = InstanceNoteKey.find_by_name("APC Dist.")
    note = InstanceNote.where(instance_note_key_id: apc_dist_note_key.id)
                       .first
    note.value = "#{note.value}x"
    assert note.valid?, "Updated APC Dist. instance note shd still be valid"
    note.save!
  end
end
