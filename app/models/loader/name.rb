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
  include PreferredMatch
  include SortKeyBulkChanges
  include Adder
  include SeqCalculator
  NA = "N/A"

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

  validates :record_type, presence: true
  validate :validate_family_record
  validates :family, presence: true
  validates :simple_name, presence: true
  validates :simple_name_as_loaded, presence: true
  validates :full_name, presence: true

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
  before_validation :set_in_batch_note_defaults
  before_save :compress_whitespace, :consider_sort_key

  def fresh?
    created_at > 1.hour.ago
  end

  def display_as
    "Loader Name"
  end

  def has_parent?
    !parent_id.blank?
  end

  def update_if_changed(params, username)
    # strip_attributes is in place and should make this unnecessary
    # but it's not working in the way I expect
    params.keys.each { |key| params[key] = nil if params[key] == "" }
    assign_attributes(params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  def set_in_batch_note_defaults
    return unless record_type == "in-batch-note"

    self.simple_name_as_loaded = NA
    self.family = NA if family.blank?
    self.simple_name = NA if simple_name.blank?
    self.full_name = simple_name
  end

  def compress_whitespace
    simple_name.squish!
    full_name.squish!
  end

  def consider_sort_key
    if loader_batch.use_sort_key_for_ordering
      set_sort_key
    else
      self.sort_key = nil
    end
  end

  def set_sort_key
    normalise_sort_key unless sort_key.blank?
    if sort_key.blank?
      case record_type
      when "accepted"
        self.sort_key = "#{family.downcase}.family.#{record_type}.#{simple_name.downcase}"
      when "excluded"
        self.sort_key = "#{family.downcase}.family.#{record_type}.#{simple_name.downcase}"
      when "synonym"
        self.sort_key = "#{parent.sort_key}.a-syn.#{synonym_sort_key_tail}"
      when "misapplied"
        self.sort_key = "#{parent.sort_key}.b-mis.z-mis"
      when "heading"
        self.sort_key = if rank.blank? || rank.downcase == "family"
                          "#{family.downcase}.family"
                        else
                          "aaa-rank-#{rank}-heading"
                        end
      when "in-batch-note"
        self.sort_key = in_batch_note_sort_key if sort_key.blank?
      else
        self.sort_key = "aaaaaa-unexpected-record-type-#{record_type}"
      end
    end
  rescue StandardError => e
    puts e
    puts "set_sort_key: record_type: #{record_type}; rank: #{rank}; family: #{family}"
    raise
  end

  def normalise_sort_key
    self.sort_key = sort_key.downcase unless sort_key == sort_key.downcase
  end

  def in_batch_note_sort_key
    if family == NA && simple_name == NA
      "aaaa-in-batch-note"
    elsif simple_name == NA
      "#{family.downcase}.family.a.in-batch-note"
    else
      "#{family.downcase}.family.accepted.#{simple_name.downcase}.x.in-batch-note"
    end
  end

  def synonym_sort_key_tail
    case synonym_type
    when "isonym"
      "a-isonym"
    when "orthographic variant"
      "b-orth-var"
    when "basionym"
      "c-basionym"
    when "replaced synonym"
      "d-replaced-syn"
    when "alternative name"
      "e-alt-name"
    when "nomenclatural synonym"
      "f-nom-syn"
    when "taxonomic synonym"
      "g-tax-syn"
    when "doubtful pro parte taxonomic synonym"
      "g-tax-syn"
    when "doubtful-taxonomic-synonym"
      "g-tax-syn"
    when "pro parte taxonomic synonym"
      "g-tax-syn"
    else
      "x-is-unknown-#{synonym_type}"
    end
  end

  def name_match_no_primary?
    false
  end

  def orth_var?
    return false if name_status.blank?

    name_status.downcase.match(/\Aorth/)
  end

  def no_further_processing?
    no_further_processing == true || parent&.no_further_processing == true
  end

  def brief_inspect
    "id: #{id}; simple_name: #{simple_name}"
  end

  def child?
    !parent_id.blank?
  end

  def has_name_review_comments?
    name_review_comments.size > 0
  end

  def reviewer_comments(scope = "any")
    name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select { |comment| comment.reviewer.role.name == Loader::Batch::Review::Role::NAME_REVIEWER }
      .select { |comment| comment.context == scope || scope == "any" }
  end

  def reviewer_comments?(scope = "any")
    reviewer_comments(scope).size > 0
  end

  def compiler_comments(scope = "any")
    name_review_comments
      .includes(batch_reviewer: [:batch_review_role])
      .select { |comment| comment.reviewer.role.name == Loader::Batch::Review::Role::COMPILER }
      .select { |comment| comment.context == scope || scope == "any" }
  end

  def compiler_comments?(scope = "any")
    compiler_comments(scope).size > 0
  end

  def self.record_to_flush_results
    r = OpenStruct.new
    r.record_type = "accepted"
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
    if ary.size > 1 && ary.select { |r| r.record_type == "accepted" }.size > 1
      ary.pop until ary[-1].record_type == "accepted"
      ary.pop
    end
    ary
  end

  def names_simple_or_full_name_matching
    ::Name.where(["simple_name = ? or full_name = ?",
                  simple_name, simple_name])
          .where(duplicate_of_id: nil)
          .joins(:name_type).where(name_type: { scientific: true })
          .order("simple_name, name.id")
  end

  def names_simple_or_full_name_matching_allow_for_ms
    ::Name.where(["simple_name = ? or full_name = ? or simple_name = ? or full_name = ?",
                  simple_name, simple_name, simple_name + " MS", simple_name + " MS"])
          .where(duplicate_of_id: nil)
          .joins(:name_type).where(name_type: { scientific: true })
          .order("simple_name, name.id")
  end

  # Tried this - much slower, not sure why given Name is set up for lower(f_unaccent()) searches
  def names_unaccent_simple_name_matching
    ::Name.where(
      ["lower(f_unaccent(simple_name)) = lower(f_unaccent(?))", simple_name]
    )
          .where(duplicate_of_id: nil)
          .joins(:name_type).where(name_type: { scientific: true })
          .order("simple_name, name.id")
  end

  def matches(type: :strict)
    if type == :strict
      # names_simple_or_full_name_matching
      # names_unaccent_simple_name_matching # 20 x slower
      names_simple_or_full_name_matching_allow_for_ms
    elsif type == :cultivar
      matches_tweaked_for_cultivar
    elsif type == :phrase
      matches_tweaked_for_phrase_name
    else
      throw "Unknown type of matches requested: #{type}'"
    end
  end

  def accepted?
    record_type == "accepted"
  end
  alias_attribute :standalone?, :accepted?

  def synonym?
    record_type == "synonym"
  end

  def misapplied?
    record_type == "misapplied"
  end
  alias_attribute :misapp?, :misapplied?

  def heading?
    record_type == "heading"
  end

  def in_batch_note?
    record_type == "in-batch-note"
  end

  def excluded?
    record_type == "excluded"
  end

  def likely_phrase_name?
    simple_name =~ /Herbarium/ || simple_name =~ /sp\./ || simple_name =~ /[0-9][0-9][0-9]/
  end

  # Simple name match, but ignoring herbarium string and parentheses
  # Also, no requirement for scientific name type
  def matches_tweaked_for_phrase_name
    ::Name.where([
                   "regexp_replace(simple_name,'[)(]','','g') = regexp_replace(regexp_replace(?,' [A-z][A-z]* Herbarium','','i'),'[)(]','','g')", simple_name
                 ])
          .where(duplicate_of_id: nil)
          .order("simple_name, name.id")
  end

  def likely_cultivar?
    simple_name =~ /'/
  end

  # No requirement for scientific name type
  def matches_tweaked_for_cultivar
    ::Name.where(simple_name: simple_name)
          .where(duplicate_of_id: nil)
          .order("simple_name, name.id")
  end

  def synonym_without_synonym_type?
    synonym? & synonym_type.blank?
  end

  # r relationship
  # i instance
  # t type
  # i id
  def riti
    return nil if accepted?
    return nil if excluded?

    return InstanceType.find_by_name("misapplied").id if misapplied?

    if taxonomic?
      return InstanceType.find_by_name("pro parte taxonomic synonym").id if pp?

      return InstanceType.find_by_name("taxonomic synonym").id

    elsif nomenclatural?
      return InstanceType.find_by_name("pro parte nomenclatural synonym").id if pp?

      return InstanceType.find_by_name("nomenclatural synonym").id

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
    synonym_type == "taxonomic synonym"
  end

  def nomenclatural?
    synonym_type == "nomenclatural synonym"
  end

  def pp?
    partly == "p.p."
  end

  # This is different to the default name search
  def self.bulk_operations_search(name_string)
    ns = name_string.downcase.gsub("*", "%")
    Loader::Name.where([Constants::BULK_OPERATIONS_WHERE_FRAG,
                        ns, ns, ns, ns, ns, ns])
  end

  def self.simple_name_search(name_string)
    bulk_operations_search(name_string)
  end

  # This is used in bulk jobs
  def self.family_string_search(family_string)
    fam = family_string.downcase.gsub("*", "%")
    Loader::Name.where(["lower(family) like lower(?) ", fam])
  end

  # This is used in bulk jobs
  def self.acc_string_search(acc_string)
    name = acc_string.downcase.gsub("*", "%")
    Loader::Name.where(["(record_type = 'accepted' and lower(simple_name) like lower(?))  or
                        (exists (select null from loader_name parent
                                  where parent.id = loader_name.parent_id
                                    and parent.record_type = 'accepted'
                                    and lower(parent.simple_name) like lower(?)))", name, name])
  end

  # This is used in bulk jobs
  def self.exc_string_search(exc_string)
    name = exc_string.downcase.gsub("*", "%")
    Loader::Name.where(["(record_type = 'excluded' and lower(simple_name) like lower(?))  or
                        (exists (select null from loader_name parent
                                  where parent.id = loader_name.parent_id
                                    and parent.record_type = 'excluded'
                                    and lower(parent.simple_name) like lower(?)))", name, name])
  end

  def self.accepted_or_excluded_search
    Loader::Name.where("record_type in ('accepted','excluded')")
  end

  def self.create(params, username)
    loader_name = Loader::Name.new(params)
    loader_name.seq = calc_seq(params) if consider_seq(params)
    loader_name.created_manually = true
    if loader_name.loader_batch_id.blank?
      loader_name.loader_batch_id = find(params[:parent_id])
                                    .loader_batch_id
    end
    loader_name.doubtful = false
    raise loader_name.errors.full_messages.first.to_s unless loader_name.save_with_username(username)

    loader_name
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

  def new_child(base_seq = seq)
    loader_name = Loader::Name.new
    loader_name.parent_id = id
    loader_name.simple_name = loader_name.full_name = nil
    loader_name.family = family
    loader_name.loader_batch_id = loader_batch_id
    loader_name.seq = base_seq + 1
    loader_name.created_manually = true
    loader_name
  end

  def new_synonym(base_seq: seq)
    loader_name = new_child(base_seq)
    loader_name.record_type = "synonym"
    unless sort_key.blank?
      loader_name.sort_key = sort_key + ".a-synonym." + "user-to-complete"
    end
    loader_name
  end

  def new_misapp(base_seq: seq)
    loader_name = new_child(base_seq)
    loader_name.record_type = "misapplied"
    unless sort_key.blank?
      loader_name.sort_key = sort_key + ".b-misapp." + "user-to-complete"
    end
    loader_name
  end

  def record_type_as_context
    case record_type
    when "misapplied" then "synonymy"
    when "synonym" then "synonymy"
    when "accepted" then "main"
    else "unknown"
    end
  end

  def preferred_match?
    preferred_matches.size > 0
  end

  def preferred_match
    return nil unless preferred_match?

    throw "more than one preferred match" unless preferred_matches.size == 1
    preferred_matches.first
  end

  def self.create_instance_for(taxon_s, authorising_user, search)
    records = errors = 0
    @ref = Reference.find(REF_ID)
    search.order(:seq).each do |match|
      creator = match.instance_creator_for_preferred_matches(authorising_user)
      creator.create
      records += creator.created || 0
      errors += creator.errors || 0
    end
    entry = "Job finished: create instance for preferred matches for '#{taxon_s}', #{authorising_user}; records created: #{records}; errors: #{errors}"
    OrchidProcessingLog.log(entry, "job controller")
    [records, errors]
  end

  def match_for_name_id(name_id)
    loader_name_matches.where(name_id: name_id)
  end

  def misapp_html
    return unless misapp? && original_text.present?

    Rails::Html::FullSanitizer.new.sanitize(original_text)
  end

  def validate_family_record
    return if rank.blank?
    return unless rank.downcase == "family"

    return if simple_name == family

    errors.add(:simple_name, "must match family name for a family")
  end
end
