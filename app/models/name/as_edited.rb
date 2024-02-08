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
class Name::AsEdited < Name::AsTypeahead
  include NameAuthorResolvable
  include NameParentResolvable
  include NameFamilyResolvable
  include NameDuplicateOfResolvable

  def self.create(params, typeahead_params, username)
    name = Name::AsEdited.new(params)
    name.resolve_typeahead_params(typeahead_params)
    create_hybrid_name_element(name)
    create_name_path(name)
    raise name.errors.full_messages.first.to_s unless name.save_with_username(username)

    name.set_names!

    name
  end

  # see NSL-2884
  def self.create_hybrid_name_element(name)
    return unless name.name_category.scientific_hybrid_formula?

    name.name_element = "#{name.parent.name_element} #{name.name_type.connector} #{name.second_parent.name_element}"
  end

  def build_hybrid_name_element
    return unless name_category.scientific_hybrid_formula?

    self.name_element = "#{parent.name_element} #{name_type.connector} #{second_parent.name_element}"
  end

  def self.create_name_path(name)
    path = ""
    path = name.parent.name_path if name.parent
    path += "/" + name.name_element.strip if name.name_element
    name.name_path = path
  end

  def update_if_changed(params, typeahead_params, username)
    params["verbatim_rank"] = nil if params["verbatim_rank"] == ""
    assign_attributes(params)
    resolve_typeahead_params(typeahead_params)
    build_hybrid_name_element
    build_name_path
    save_updates_if_changed(username)
  end

  def save_updates_if_changed(username)
    if changed?
      self.updated_by = username
      save!
      set_names!
      "Updated"
    else
      "No change"
    end
  end

  def resolve_typeahead_params(params)
    resolve_author(params, "author")
    resolve_author(params, "ex_author")
    resolve_author(params, "base_author")
    resolve_author(params, "ex_base_author")
    resolve_author(params, "sanctioning_author")
    resolve_parent(params, "parent")
    resolve_parent(params, "second_parent")
    resolve_family(params, "family")
    resolve_duplicate_of(params)
  end
end
