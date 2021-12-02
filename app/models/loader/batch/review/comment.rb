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
# Loader BatchReviewComment entity
class Loader::Batch::Review::Comment < ActiveRecord::Base
  strip_attributes
  self.table_name = "batch_review_comment"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :batch_review, class_name: "Loader::Batch::Review",
             foreign_key: "batch_review_id"
  alias_attribute :review, :batch_review
  belongs_to :batch_review, class_name: "Loader::Batch::Review",
             foreign_key: "batch_review_id"
  validates :comment, presence: true

  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    'Review Period'
  end

  def allow_delete?
    true
  end

  # The table isn't in all schemas, so check it's there
  def self.exists?
    begin 
      BatchReviewPeriod.all.count
    end
    true
  rescue => e
    false
  end

  def fresh?
    false
  end

  def record_type
    'BatchReviewComment'
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    #set_defaults
    save
  end

  def update_if_changed(params, username)
    if has_changes_to_save?
      logger.debug("changes_to_save: #{changes_to_save.inspect}")
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end
end
  
