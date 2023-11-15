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
# Orchids table
class Orchid < ActiveRecord::Base
  strip_attributes
  REF_ID = 51_316_736
  attr_accessor :name_id, :instance_id

  belongs_to :parent, class_name: "Orchid", foreign_key: "parent_id", optional: true
  has_many :children,
           class_name: "Orchid",
           foreign_key: "parent_id",
           dependent: :restrict_with_exception
  has_many :orchids_name
  has_many :preferred_match, class_name: "OrchidsName", foreign_key: :orchid_id
  scope :avoids_id, ->(avoid_id) { where("orchids.id != ?", avoid_id) }

  def self.create(params, username)
    orchid = Orchid.new(params)
    orchid.id = next_sequence_id
    orchid.family = "Orchidaceae"
    raise orchid.errors.full_messages.first.to_s unless orchid.save_with_username(username)

    orchid
  end

  # Passing string to be evaluated in :if and :unless conditional options is
  # not supported.
  # Pass a symbol for an instance method, or a lambda, proc or block, instead.
  validates :synonym_type,
            presence: { if: -> { record_type == "synonym" },
                        message: "is required." }

  def display_as
    "Orchid"
  end

  def synonym?
    record_type == "synonym"
  end

  def fresh?
    false
  end

  def child?
    !parent_id.blank?
  end

  # NOTE: not case-insensitive. Perhaps should be.
  def names_simple_name_matching_taxon
    Name.where(["simple_name = ? or simple_name = ?", taxon, alt_taxon_for_matching])
        .joins(:name_type).where(name_type: { scientific: true })
        .order("simple_name, name.id")
  end

  def matches
    names_simple_name_matching_taxon
  end

  def name_match_no_primary?
    !Name.where([
                  "(name.simple_name = ? or name.simple_name = ?) and exists (select null from name_type nt where name.name_type_id = nt.id and scientific) and not exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)", taxon, alt_taxon_for_matching
                ]).empty?
  end

  def matches_with_primary
    Name.where([
                 "(name.simple_name = ? or name.simple_name = ?) and exists (select null from name_type nt where name.name_type_id = nt.id and scientific) and exists (select null from instance i join instance_type t on i.instance_type_id = t.id where i.name_id = name.id and t.primary_instance)", taxon, alt_taxon_for_matching
               ])
  end

  def no_matches_with_primary?
    matches_with_primary.empty?
  end

  def synonym_type_with_interpretation
    "#{synonym_type} #{interpreted_synonym_type_in_brackets}"
  end

  def interpreted_synonym_type_in_brackets
    case synonym_type
    when "homotypic"
      "(nomenclatural)"
    when "heterotypic"
      "(taxonomic)"
    else
      ""
    end
  end

  def has_parent?
    !parent_id.blank?
  end

  def misapp?
    misapplied?
  end

  def misapplied?
    record_type == "misapplied"
  end

  def homotypic?
    synonym_type == "homotypic" ||
      synonym_type == "nomenclatural synonym"
  end

  def nomenclatural?
    homotypic?
  end

  def heterotypic?
    synonym_type == "heterotypic" ||
      synonym_type == "taxonomic synonym"
  end

  def taxonomic?
    heterotypic?
  end

  def pp?
    partly == "p.p."
  end

  # r relationship
  # i instance
  # t type
  # i id
  def riti
    return nil if accepted?
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
      throw "The orchid is a synonym with no synonym type - please set a synonym type in 'Edit Raw' then try again."
    else
      throw "Orchid#riti cannot work out an instance type for orchid: #{id}: #{taxon} #{record_type} #{synonym_type}"
    end
    throw "Orchid#riti is stuck with no relationship instance type id for orchid: #{id}: #{taxon}"
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save
  end

  # We use a custom sequence because the data is initially loaded from a CSV file with allocated IDs.
  # This is only for subsequent records we add.
  def self.next_sequence_id
    ActiveRecord::Base.connection.execute("select nextval('orchids_seq')").first["nextval"]
  end

  def update_if_changed(params, username)
    params = empty_strings_should_be_nils(params)
    assign_attributes(params)
    if changed?
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  end

  # Empty strings as parameters for string fields are interpreted as a change.
  def empty_strings_should_be_nils(params)
    %w[hybrid, family, hr_comment, subfamily, tribe, subtribe, rank, nsl_rank, taxon,
       ex_base_author, base_author, ex_author, author, author_rank, name_status, name_comment,
       partly, auct_non, synonym_type, doubtful, hybrid_level, isonym, article_author, article_title,
       article_title_full, in_flag, author_2, title, title_full, edition, volume, page,
       year, date_, publ_partly, publ_note, note, footnote, distribution, comment,
       remark, original_text].each do |field|
      params[field] = nil if params[field] == ""
    end
    params
  end

  def ok_to_delete?
    children.empty? && orchids_name.empty?
  end

  def accepted?
    record_type == "accepted"
  end

  def hybrid_cross?
    record_type == "hybrid_cross"
  end

  def misapplied?
    record_type == "misapplied"
  end

  def doubtful?
    doubtful == true
  end

  def excluded?
    record_type == "accepted" && doubtful == true
  end

  def accepted_and_not_doubtful?
    record_type == "accepted" && doubtful != true
  end

  # This search emulates the default search for Orchids, the
  # taxon-string: search.
  def self.taxon_string_search(taxon_string)
    taxon_string_search_no_excluded(taxon_string)
  end

  def self.taxon_string_search_no_excluded(taxon_string)
    ts = taxon_string.downcase.gsub("*", "%")
    Orchid.where(["((lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?) and record_type = 'accepted' and not doubtful) or (parent_id in (select id from orchids where (lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?) and record_type = 'accepted' and not doubtful))",
                  ts, ts, ts, ts, ts, ts])
  end

  def self.taxon_string_search_for_excluded(taxon_string)
    ts = taxon_string.downcase.gsub("*", "%")
    Orchid.where(["((lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?) and record_type = 'accepted' and doubtful) or (parent_id in (select id from orchids where (lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?) and record_type = 'accepted' and doubtful))",
                  ts, ts, ts, ts, ts, ts])
  end

  def create_preferred_match(authorising_user)
    AsNameMatcher.new(self, authorising_user).find_or_create_preferred_match
  end

  def self.create_preferred_matches(taxon_s, authorising_user, work_on_accepted)
    if work_on_accepted
      create_preferred_matches_for_accepted_taxa(taxon_s, authorising_user)
    else
      create_preferred_matches_for_excluded_taxa(taxon_s, authorising_user)
    end
  end

  def self.create_preferred_matches_for_accepted_taxa(taxon_s, authorising_user)
    attempted = records = 0
    Orchid.taxon_string_search_no_excluded(taxon_s).order(:seq).each do |match|
      attempted += 1
      records += match.create_preferred_match(authorising_user)
    end
    entry = "Job finished: create preferred matches for accepted taxa matching #{taxon_s}, #{authorising_user}; attempted: #{attempted}, created: #{records}"
    OrchidProcessingLog.log(entry, "job controller")
    [attempted, records]
  end

  def self.create_preferred_matches_for_excluded_taxa(taxon_s, authorising_user)
    attempted = records = 0
    Orchid.taxon_string_search_for_excluded(taxon_s).order(:seq).each do |match|
      attempted += 1
      records += match.create_preferred_match(authorising_user)
    end
    entry = "Job finished: create preferred matches for excluded taxa matching #{taxon_s}, #{authorising_user}; attempted: #{attempted}, created: #{records}"
    OrchidProcessingLog.log(entry, "job controller")
    [attempted, records]
  end

  def self.create_instance_for_accepted_or_excluded(taxon_s, authorising_user, work_on_accepted)
    search = if work_on_accepted
               Orchid.taxon_string_search_no_excluded(taxon_s)
             else
               Orchid.taxon_string_search_for_excluded(taxon_s)
             end
    create_instance_for(taxon_s, authorising_user, search)
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

  def instance_creator_for_preferred_matches(authorising_user)
    debug("instance_creator_for_preferred_matches for: #{authorising_user}")
    @ref = Reference.find(REF_ID) if @ref.blank?
    throw "No ref with id: #{REF_ID}!" if @ref.blank?
    AsInstanceCreator.new(self, @ref, authorising_user)
  end

  # check for preferred name
  def self.add_to_tree_for(draft_tree, taxon_s, authorising_user, work_on_accepted)
    if work_on_accepted
      search = Orchid.taxon_string_search_no_excluded(taxon_s).where(record_type: "accepted").where(doubtful: false).order(:seq)
      tag = "accepted"
    else
      search = Orchid.taxon_string_search_for_excluded(taxon_s).where(record_type: "accepted").where(doubtful: true).order(:seq)
      tag = "excluded"
    end
    add_to_tree(draft_tree, taxon_s, authorising_user, search, tag)
  end

  def self.add_to_tree(draft_tree, taxon_s, authorising_user, search, tag)
    placed_tally = error_tally = preflight_stop_tally = 0
    search.each do |match|
      placer = AsTreePlacer.new(draft_tree, match, authorising_user)
      placed_tally += placer.placed_count
      error_tally += placer.error_count
      preflight_stop_tally += placer.preflight_stop_count
    end
    entry = "Job finished: add to tree for #{tag} taxa matching #{taxon_s}, #{authorising_user}; placed: #{placed_tally}, errors: #{error_tally}, preflight stops: #{preflight_stop_tally}"
    OrchidProcessingLog.log(entry, "job controller")
    [placed_tally, error_tally, preflight_stop_tally, ""]
  rescue GenusTaxonomyPlacementError => e
    logger.error(e.message)
    [placed_tally, error_tally + 1, preflight_stop_tally, e.message]
  end

  def isonym?
    return false if isonym.blank?

    true
  end

  def orth_var?
    return false if name_status.blank?

    name_status.downcase.match(/\Aorth/)
  end

  def self.name_statuses
    sql = "select name_status, count(*) total from orchids where name_status is not null group by name_status order by name_status"
    records_array = ActiveRecord::Base.connection.execute(sql)
  end

  def synonym_without_synonym_type?
    synonym? & synonym_type.blank?
  end

  def true_record_type
    if record_type == "accepted" && doubtful?
      "excluded"
    else
      record_type
    end
  end

  private

  def debug(msg)
    Rails.logger.debug("Orchid##{msg}")
  end

  def self.debug(msg)
    Rails.logger.debug("Orchid##{msg}")
  end
end
