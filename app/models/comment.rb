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
class Comment < ActiveRecord::Base
  self.table_name = "comment"
  self.primary_key = "id"
  self.sequence_name = "hibernate_sequence"
  strip_attributes
  belongs_to :author, optional: true
  belongs_to :instance, optional: true
  belongs_to :name, optional: true
  belongs_to :reference, optional: true
  validate :validate_only_one_parent
  validates :text, presence: true

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update!(attributes)
  end

  def update_attributes_with_username(attributes, username)
    update_attributes_with_username!(attributes, username)
  rescue StandardError
    false
  end

  # Must have exactly one parent key
  def validate_only_one_parent
    parents = 0
    parents += 1 if author_id.present?
    parents += 1 if instance_id.present?
    parents += 1 if name_id.present?
    parents += 1 if reference_id.present?
    if parents.zero?
      errors.add(:base, "do not know which record this comment is for.")
    elsif parents > 1
      errors.add(:base, "cannot be attached to more than one record.")
    end
  end
end
