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
  alias_attribute :review_comments, :name_review_comments
  has_many :children,
           class_name: "Loader::Name",
           foreign_key: "parent_id",
           dependent: :restrict_with_exception

  belongs_to :parent,
           class_name: "Loader::Name",
           foreign_key: "parent_id",
           optional: true

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

  def update_if_changed(params, username)
    # strip_attributes is in place and should make this unnecessary
    # but it's not working in the way I expect
    params.keys.each { |key| params[key] = nil if params[key] == '' } 
    assign_attributes(params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def compress_whitespace
    self.simple_name.squish!
    self.full_name.squish!
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
    no_further_processing == true
  end

  def child?
    !parent_id.blank?
  end

  def has_name_review_comments?
    name_review_comments.size > 0
  end

  def reviewer_comments(scope = 'any')
    name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select {|comment| comment.reviewer.role.name == Loader::Batch::Review::Role::NAME_REVIEWER}
      .select {|comment| comment.context == scope || scope == 'any'}
  end

  def reviewer_comments?(scope = 'any')
    reviewer_comments(scope).size > 0
  end

  def compiler_comments(scope = 'any')
    name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select {|comment| comment.reviewer.role.name == Loader::Batch::Review::Role::COMPILER}
      .select {|comment| comment.context == scope || scope == 'any'}
  end

  def compiler_comments?(scope = 'any')
    compiler_comments(scope).size > 0
  end

  def excluded?
    excluded == true
  end

  def self.record_to_flush_results
    r = OpenStruct.new
    r.record_type = 'accepted'
    r.id = -1
    r.flushing = true
    r
  end

  # Aim: Avoid displaying an accepted record without its full context of
  # trailing synonyms.
  #
  # Assumptions: The set of records contains accepted records followed by all
  # synonyms until the end of the set - the last accepted record in the set may
  # not have all its syonyms following it in the set - because of the limit
  # applied to the query.
  #
  # If there is only one accepted record in the set, then all synonyms will 
  # be there.
  #
  # An accepted record is a "main" or non-synonym record in this model.
  #
  # Only need to trim if the result set is larger than the limit - that rule
  # is applied before here.
  #
  # Algorithm: remove records from the end of the result set until you reach an 
  # accepted record, then remove that accepted record, but only if there's
  # more than one accepted record in the set
  #
  def self.trim_results(results)
    ary = results.to_ary
    if ary.size > 1 && ary.select {|r| r.record_type == 'accepted'}.size > 1
      until ary[-1].record_type == 'accepted'
        ary.pop
      end
      ary.pop
    end
    ary
  end

  def names_simple_or_full_name_matching_taxon
    ::Name.where(
      ["simple_name = ? or full_name = ?",
       simple_name, simple_name])
        .joins(:name_type).where(name_type: {scientific: true})
        .order("simple_name, name.id")
  end

  def names_unaccent_simple_name_matching_taxon
    ::Name.where(
      ["lower(f_unaccent(simple_name)) like lower(f_unaccent(?))", simple_name])
        .joins(:name_type).where(name_type: {scientific: true})
        .order("simple_name, name.id")
  end

  def matches
    names_simple_or_full_name_matching_taxon
  end

  def accepted?
    record_type == 'accepted'
  end

  def synonym?
    record_type == 'synonym'
  end

  def likely_phrase_name?
    simple_name =~ /Herbarium/ || simple_name =~ /sp\./ || simple_name =~ / f\./ 
  end

  def matches_tweaked_for_phrase_name
    ::Name.where(["regexp_replace(simple_name,'[)(]','','g') = regexp_replace(regexp_replace(?,' [A-z][A-z]* Herbarium','','i'),'[)(]','','g')", simple_name])
  end
end
