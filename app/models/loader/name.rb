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
# Loader Name entity
class Loader::Name < ActiveRecord::Base
  strip_attributes
  self.table_name = "loader_name"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  def self.for_batch(batch_id)
    if batch_id.nil? || batch_id == -1
      where("1=1")    
    else
      where("loader_batch_id = ?", batch_id)
    end
  end

  belongs_to :loader_batch, class_name: "Loader::Batch", foreign_key: "loader_batch_id"
  alias_attribute :batch, :loader_batch

  has_many :name_review_comments, class_name: "Loader::Name::Review::Comment", foreign_key: "loader_name_id"
  has_many :children,
           class_name: "Loader::Name",
           foreign_key: "parent_id",
           dependent: :restrict_with_exception

  belongs_to :parent,
           class_name: "Loader::Name",
           foreign_key: "parent_id"

  attr_accessor :give_me_focus, :message

  # before_create :set_defaults # rails 6 this was not being called before the validations
  before_save :compress_whitespace

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    'Loader Name'
  end

  def has_parent?
    !parent_id.blank?
  end

  def matches
    []
  end

  def loader_name_match
    nil
  end

  def name_match_no_primary?
    false
  end

  def orth_var?
    return false if name_status.blank?
    name_status.downcase.match(/\Aorth/)
  end

  def exclude_from_further_processing?
    false
  end

  def child?
    !parent_id.blank?
  end
end
