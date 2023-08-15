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

# Reference insert and update.
class Reference::AsEdited < Reference
  include ReferenceAuthorResolvable
  include ReferenceParentResolvable
  include ReferenceDuplicateOfResolvable

  def self.create(params, typeahead_params, username)
    reference = Reference::AsEdited.new(params)
    reference.resolve_typeahead_params(typeahead_params)
    raise reference.errors.full_messages.first.to_s unless reference.save_with_username(username)

    reference.set_citation!

    reference
  end

  def update_if_changed(params, typeahead_params, username)
    assign_attributes(empty_strings_to_nils(params))
    resolve_typeahead_params(typeahead_params)
    if changed?
      apply_change(typeahead_params, username)
    else
      "No change."
    end
  end

  def apply_change(typeahead_params, username)
    if just_setting_duplicate_of_id
      just_set_duplicate_of_id(typeahead_params, username)
    else
      self.updated_by = username
      save!
      set_citation!
      "Updated"
    end
  end

  def just_setting_duplicate_of_id
    changed_attributes.size == 1 && changed_attributes.key?("duplicate_of_id")
  end

  def just_set_duplicate_of_id(params, username)
    if params["duplicate_of_typeahead"].blank?
      update_attribute(:duplicate_of_id, nil)
      update_attribute(:updated_by, username)
      "Duplicate cleared"
    else
      update_attribute(:duplicate_of_id, params["duplicate_of_id"])
      update_attribute(:updated_by, username)
      "Duplicate set"
    end
  end

  # Empty strings as parameters for string fields are interpreted as a change.
  def empty_strings_to_nils(params)
    params.each do |key, value|
      params[key] = nil if value.instance_of?(String) && (value == "")
    end
    params
  end

  def resolve_typeahead_params(params)
    resolve_author(params)
    resolve_parent(params)
    resolve_duplicate_of(params)
  end
end
