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
# Loader NameReviewVote entity
class Loader::Name::Review::Vote < ActiveRecord::Base
  strip_attributes
  self.table_name = "name_review_vote"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :loader_name, class_name: "Loader::Name",
                           foreign_key: "loader_name_id"
  belongs_to :batch_review, class_name: "Loader::Batch::Review",
                                   foreign_key: "batch_review_id"
  belongs_to :batch_reviewer, class_name: "Loader::Batch::Reviewer",
                              foreign_key: "batch_reviewer_id"
  belongs_to :org

  alias_method :reviewer, :batch_reviewer

  validates :vote, inclusion: { in: [ true, false ] }

  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "Name Review Vote"
  end

  def allow_delete?
    false
  end

  def can_be_deleted?
    true # for now
  end

  def record_type
    "NameReviewVote"
  end

  def save_with_username(username)
    Rails.logger.debug("save_with_username")
    self.created_by = self.updated_by = username
    # set_defaults
    save!
  end

  def update_if_changed(params, username)
    assign_attributes(params)
    if has_changes_to_save?
      logger.debug("changes_to_save: #{changes_to_save.inspect}")
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def vote_as_yes_no
    if vote 
      'Agreed'
    else
      'Not agreed'
    end
  end
end
