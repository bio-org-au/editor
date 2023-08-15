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
# Loader Batch entity
class Loader::Batch < ActiveRecord::Base
  strip_attributes
  self.table_name = "loader_batch"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :loader_names, class_name: "Loader::Name", foreign_key: "loader_batch_id"
  has_many :batch_reviews, class_name: "Loader::Batch::Review", foreign_key: "loader_batch_id"
  belongs_to :default_reference, class_name: "Reference", foreign_key: "default_reference_id", optional: true
  alias_attribute :reviews, :batch_reviews
  validates :name, uniqueness: true, presence: true

  attr_accessor :give_me_focus, :message

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "Loader Batch"
  end

  def all_periods_of_all_reviews
    reviews.collect { |r| r.periods }.sort { |x, y| x.start_date <=> y.start_date }.flatten
  end

  def all_active_periods_of_all_reviews
    all_periods_of_all_reviews.select { |p| p.active? }
  end

  def active_reviews
    return [] if all_active_periods_of_all_reviews.empty?

    all_active_periods_of_all_reviews.collect { |period| period.review }
  end

  def active_reviews?
    !active_reviews.empty?
  end

  def self.user_reviewable(user_name)
    Loader::Batch.joins(batch_reviews: [{ review_periods: { batch_reviewers: [:user_table] } }]).where(user_table: { name: user_name }).order("name")
  end

  def self.id_of(canonical_query_target)
    Loader::Batch.where(["lower(name) = ?", canonical_query_target]).first.id
  end

  def update_if_changed(params, username)
    params[:default_reference_id] = nil if params[:default_reference_typeahead].blank?
    params.reject! { |name, _value| name == "default_reference_typeahead" }
    assign_attributes(params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end
end
