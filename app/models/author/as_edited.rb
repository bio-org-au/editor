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
# Author Editing
# == Schema Information
#
# Table name: author
#
#  id               :bigint           not null, primary key
#  abbrev           :string(100)
#  created_by       :string(255)      not null
#  date_range       :string(50)
#  full_name        :string(255)                              DEPRECATED - Use extra_information
#  lock_version     :bigint           default(0), not null
#  name             :string(1000)
#  notes            :string(1000)
#  source_id_string :string(100)
#  source_system    :string(50)
#  updated_by       :string(255)      not null
#  uri              :text
#  valid_record     :boolean          default(FALSE), not null
#  created_at       :timestamptz      not null
#  updated_at       :timestamptz      not null
#  duplicate_of_id  :bigint
#  ipni_id          :string(50)
#  namespace_id     :bigint           not null
#  source_id        :bigint
#  extra_information :string(255)
#
# Indexes
#
#  auth_source_index             (namespace_id,source_id,source_system)
#  auth_source_string_index      (source_id_string)
#  auth_system_index             (source_system)
#  author_abbrev_index           (abbrev)
#  author_name_index             (name)
#  uk_9kovg6nyb11658j2tv2yv4bsi  (abbrev) UNIQUE
#  uk_rd7q78koyhufe1edfb2rgfrum  (uri) UNIQUE
#
# Foreign Keys
#
#  fk_6a4p11f1bt171w09oo06m0wag  (duplicate_of_id => author.id)
#  fk_p0ysrub11cm08xnhrbrfrvudh  (namespace_id => namespace.id)
#
class Author::AsEdited < Author::AsTypeahead
  include AuthorAuthorResolvable
  AED = "Author::AsEdited:"
  def self.create(params, typeahead_params, username)
    author = Author::AsEdited.new(params)
    author.resolve_typeahead_params(typeahead_params)
    raise author.errors.full_messages.first.to_s unless author.save_with_username(username)

    author
  end

  def update_if_changed(params, typeahead_params, username)
    # strip_attributes is in place and should make this unnecessary
    # but it's not working in the way I expect
    params.keys.each { |key| params[key] = nil if params[key] == "" }
    assign_attributes(params)
    resolve_typeahead_params(typeahead_params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def resolve_typeahead_params(params)
    resolve_author(params, "duplicate_of", self)
  end
end
