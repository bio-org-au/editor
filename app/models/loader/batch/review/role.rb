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
# Loader BatchReviewRole entity
class Loader::Batch::Review::Role < ActiveRecord::Base
  strip_attributes
  self.table_name = "batch_review_role"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  NAME_REVIEWER = 'name reviewer'
  COMPILER = 'compiler'
  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    'Review Role'
  end

  def allow_delete?
    true
  end

  def update_if_changed(params, username)
    self.name = params[:name]
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  # The table isn't in all schemas, so check it's there
  def self.exists?
    begin 
      BatchReviewRole.all.count
    end
    true
  rescue => e
    false
  end

  def record_type
    'BatchReviewRole'
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    #set_defaults
    save
  end

  def self.name_reviewer_role
    self.where("name = 'name reviewer'").first
  end
end
  
