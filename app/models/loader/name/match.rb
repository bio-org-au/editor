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
class Loader::Name::Match < ActiveRecord::Base
  strip_attributes
  self.table_name = "loader_name_match"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  belongs_to :loader_name, class_name: "Loader::Name", foreign_key: "loader_name_id"
  belongs_to :name, class_name: "::Name", foreign_key: "name_id"
  belongs_to :instance
  belongs_to :instance_type, foreign_key: :relationship_instance_type_id, optional: true
  belongs_to :standalone_instance, class_name: "::Instance",
                                   foreign_key: "standalone_instance_id", optional: true
  belongs_to :relationship_instance, class_name: "::Instance",
                                     foreign_key: "relationship_instance_id", optional: true
  belongs_to :source_for_copy, class_name: "::Instance",
                               foreign_key: "source_for_copy_instance_id", optional: true
  validates :loader_name_id, uniqueness: true,
                             unless: proc { |a| a.loader_name.record_type == "misapplied" }
  validate :misapp_pref_matches_from_only_one_name

  before_destroy :can_destroy?

  def misapp_pref_matches_from_only_one_name
    return unless self.loader_name.misapplied?

    return if Loader::Name::Match.where(loader_name_id: loader_name_id)
                                 .where.not(name_id: name_id)
                                 .count == 0

    errors.add :base,
      "Misapplications cannot select matches from more than one name"
  end

  # how does this work when reversing?
  def choice_must_match_details
    if instance_choice_confirmed == true &&
       !(use_batch_default_reference ||
         standalone_instance_id.present?)
      errors.add("Choice must be batch default ref or an identified instance")
    elsif instance_choice_confirmed == false &&
          (use_batch_default_reference ||
           standalone_instance_id.present?)
      errors.add("Choice has been made, so must be noted")
    end
  end

  def can_destroy?
    throw :abort
  end

  def old_taxonomy_choice_made?
    use_batch_default_reference ||
      standalone_instance_id.present?
  end

  def using_default_ref?
    use_batch_default_reference == true
  end

  def using_existing_instance?
    use_existing_instance == true
  end

  def standalone?
    throw "standalone? what does this mean?"
    !standalone_instance_id.blank? && !copy_append_from_existing_use_batch_def_ref
  end

  def standalone_instance?
    standalone_instance_id.present?
  end

  def relationship_instance?
    relationship_instance_id.present?
  end

  def copy_and_append?
    copy_append_from_existing_use_batch_def_ref
  end

  def current_taxonomy_instance_choice
    if use_batch_default_reference
      "Use the batch default reference"
    elsif copy_append_from_existing_use_batch_def_ref
      "Copy and append"
    elsif standalone_instance_id.present?
      "Use an existing instance"
    else
      "No choice made"
    end
  end

  def current_taxonomy_instance_choice_details
    if use_batch_default_reference
      "create a draft instance based on the batch default reference"
    elsif copy_append_from_existing_use_batch_def_ref
      "create a draft instance for the default reference, attach synonyms from a selected source instance, then append loader details, including synonyms (but not duplicates of sourced synonyms), distribution and comment."
    elsif standalone_instance_id.present?
      "don't create an instance"
    else
      ""
    end
  end

  def taxonomy_choice_made?
    instance_choice_confirmed == true
  end

  def show_default_reference?
    use_batch_default_reference || copy_append_from_existing_use_batch_def_ref
  end

  def undo_taxonomic_choice
    self.standalone_instance_id = nil
    self.standalone_instance_found = false
    self.standalone_instance_created = false
    self.use_batch_default_reference = false
    self.use_existing_instance = false
    self.copy_append_from_existing_use_batch_def_ref = false
    self.relationship_instance_id = nil
    self.relationship_instance_created = false
    self.relationship_instance_found = false
    self.instance_choice_confirmed = false
    self.source_for_copy_instance_id = nil
  end

  def note_standalone_instance_found(instance)
    throw "Already noted as found" if standalone_instance_found
    throw "Already noted as created" if standalone_instance_created

    self.standalone_instance_id = instance.id
    self.standalone_instance_found = true
    self.updated_by = "job for #{@user}"
    save!
  end

  def clear_relationship_instance
    throw "cannot clear relationship" unless can_do_relationship_instance?
    throw "has standalone" if has_standalone?

    self.relationship_instance_id = nil
    self.relationship_instance_created = false
    self.relationship_instance_found = false
    self.instance_choice_confirmed = false
    self.source_for_copy_instance_id = nil
  end

  def can_do_relationship_instance?
    loader_name.synonym? ||
      loader_name.misapp?
  end

  def has_standalone?
    standalone_instance_id.present? ||
      standalone_instance_found ||
      standalone_instance_created
  end

  def excluded?
    loader_name.excluded? || loader_name.parent&.excluded?
  end

  # Tree ops can occur outside the loader
  # 
  # This method checks whether the name is on a draft
  #
  # If not, it removes the drafted flag.
  def verify_drafted_flag
    Rails.logger.debug('verify_drafted_flag')
    return 'Verified' if really_drafted?
    self.drafted = false
    self.save!
    return 'Not verified - drafted flag was removed'
  end

  def really_drafted?
    TreeJoinV.draft.where("instance_id = ?", standalone_instance_id).present?
  end
end
