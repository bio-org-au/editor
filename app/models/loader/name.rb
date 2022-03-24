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

  scope :avoids_id, ->(avoid_id) { where("loader_name.id != ?", avoid_id) }

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

  has_many :loader_name_matches, class_name: "Loader::Name::Match", foreign_key: "loader_name_id"
  alias_attribute :preferred_matches, :loader_name_matches

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

  def names_simple_or_full_name_matching_taxon_scientific
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

  def matches(type: :strict)
    if type == :strict
      names_simple_or_full_name_matching_taxon_scientific
    elsif type == :cultivar
      matches_tweaked_for_cultivar
    elsif type == :phrase
      matches_tweaked_for_phrase_name
    else
      throw "Unknown type of matches requested: #{type}'"
    end
  end

  def accepted?
    record_type == 'accepted'
  end
  alias_attribute :standalone?, :accepted?

  def synonym?
    record_type == 'synonym'
  end

  def likely_phrase_name?
    simple_name =~ /Herbarium/ || simple_name =~ /sp\./ || simple_name =~ /[0-9][0-9][0-9]/ 
  end

  # Simple name match, but ignoring herbarium string and parentheses
  # Also, no requirement for scientific name type
  def matches_tweaked_for_phrase_name
    ::Name.where(["regexp_replace(simple_name,'[)(]','','g') = regexp_replace(regexp_replace(?,' [A-z][A-z]* Herbarium','','i'),'[)(]','','g')", simple_name])
      .order("simple_name, name.id")
  end

  def likely_cultivar?
    simple_name =~ /'/
  end

  # No requirement for scientific name type
  def matches_tweaked_for_cultivar
    ::Name.where(simple_name: simple_name).order("simple_name, name.id")
  end

  def misapplied?
    record_type == 'misapplied'
  end
  alias_attribute :misapp?, :misapplied?

  def synonym_without_synonym_type?
    synonym? & synonym_type.blank?
  end

  # r relationship
  # i instance
  # t type
  # i id
  def riti
    return nil if accepted?
    return InstanceType.find_by_name('misapplied').id if misapplied?
    if taxonomic?
      if pp?
        return InstanceType.find_by_name('pro parte taxonomic synonym').id
      else
        return InstanceType.find_by_name('taxonomic synonym').id
      end
    elsif nomenclatural?
      if pp?
        return InstanceType.find_by_name('pro parte nomenclatural synonym').id
      else
        return InstanceType.find_by_name('nomenclatural synonym').id
      end
    elsif InstanceType.where(name: synonym_type).size == 1
      return InstanceType.find_by_name(synonym_type).id
    elsif synonym_type.blank?
      throw "The loader-name is a synonym with no synonym type - please set a synonym type in 'Edit Raw' then try again."
    else
      throw "LoaderName#riti cannot work out an instance type for loader-name: #{id}: #{simple_name} #{record_type} #{synonym_type}"
    end
    throw "LoaderName#riti is stuck with no relationship instance type id for loader-name: #{id}: #{simple_name}"
  end

  def taxonomic?
    synonym_type == 'taxonomic synonym'
  end

  def nomenclatural?
    synonym_type == 'nomenclatural synonym'
  end

  def pp?
    partly == 'p.p.'
  end

  # This search emulates the default search for Loader Name, the 
  # name-string: search.
  def self.name_string_search(name_string)
    self.name_string_search_no_excluded(name_string)
  end

  def self.name_string_search_no_excluded(name_string)
    ns = name_string.downcase.gsub(/\*/,'%')
    Loader::Name.where([ "((lower(simple_name) like ? or lower(simple_name) like 'x '||? or lower(simple_name) like '('||?) and record_type = 'accepted' and not doubtful) or (parent_id in (select id from loader_name where (lower(simple_name) like ? or lower(simple_name) like 'x '||? or lower(simple_name) like '('||?) and record_type = 'accepted' and not doubtful))",
                   ns, ns, ns, ns, ns, ns])
  end


  def self.create(params, username)
    loader_name = Loader::Name.new(params)
    loader_name.created_manually = true
    loader_name.loader_batch_id = self.find(params[:parent_id]).loader_batch_id if loader_name.loader_batch_id.blank?
    loader_name.doubtful = false
    loader_name.full_name = loader_name.simple_name
    if loader_name.save_with_username(username)
      loader_name
    else
      raise loader_name.errors.full_messages.first.to_s
    end
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    set_defaults
    save
  end

  def set_defaults
    self.simple_name_as_loaded = simple_name
  end

  def ok_to_delete?
    children.empty? && loader_name_matches.empty?
  end

  def new_child
    loader_name = Loader::Name.new
    loader_name.parent_id = id
    loader_name.simple_name = nil
    loader_name.full_name = nil
    loader_name.family = family
    loader_name.seq = seq + 1
    loader_name.created_manually = true
    loader_name
  end

  def new_synonym
    loader_name = new_child
    loader_name.record_type = 'synonym'
    loader_name
  end

  def new_misapp
    loader_name = new_child
    loader_name.record_type = 'misapplied'
    loader_name
  end

  def record_type_as_context
    case record_type
      when 'misapplied' then 'synonymy'
      when 'synonym' then 'synonymy'
      when 'accepted' then 'main'
      else 'unknown'
    end
  end

  def main_entry?
    record_type == 'accepted'
  end

  def self.create_preferred_matches(name_s, batch_id, authorising_user, work_on_accepted)
    #if work_on_accepted
      self.create_preferred_matches_for_accepted_taxa(name_s, batch_id, authorising_user)
    #else
      #self.create_preferred_matches_for_excluded_taxa(name_s, batch_id, authorising_user)
    #end
      #
  end


  def self.create_preferred_matches_for_accepted_taxa(name_s, batch_id, authorising_user)
    attempted = records = 0
    self.name_string_search_no_excluded(name_s).where(loader_batch_id: batch_id).order(:seq).each do |loader_name|
      attempted += 1
      records += loader_name.create_preferred_match(authorising_user)
    end
    entry = "Task finished: create preferred matches for accepted taxa matching #{name_s}, #{authorising_user}; attempted: #{attempted}, created: #{records}"
    BulkProcessingLog.log(entry, 'job controller')
    return attempted, records
  end

  def self.create_preferred_matches_for_excluded_taxa(name_s, batch_id, authorising_user)
    attempted = records = 0
    Orchid.taxon_string_search_for_excluded(name_s).order(:seq).each do |match|
      attempted += 1
      records += match.create_preferred_match(authorising_user)
    end
    entry = "Task finished: create preferred matches for excluded taxa matching #{name_s}, #{authorising_user}; attempted: #{attempted}, created: #{records}"
    BulkProcessingLog.log(entry, 'job controller')
    return attempted, records
  end

  def create_preferred_match(authorising_user)
    AsNameMatcher.new(self, authorising_user).find_or_create_preferred_match
  end

  def true_record_type
    if record_type == 'accepted' && doubtful?
      'excluded'
    else
      record_type
    end
  end

end
