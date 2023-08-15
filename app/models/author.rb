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
# Author entity: name strings and abbreviation strings for individuals or
# groups of individuals who have authored a reference or authorised a name.
class Author < ActiveRecord::Base
  include AuditScopable
  include AuthorValidations
  include AuthorScopes
  strip_attributes
  self.table_name = "author"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  attr_accessor :display_as, :give_me_focus, :message

  has_many :references
  has_many :instances, through: :references
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id", optional: true

  has_many :names
  has_many :ex_names, foreign_key: "ex_author_id", class_name: "Name"
  has_many :base_names, foreign_key: "base_author_id", class_name: "Name"
  has_many :ex_base_names,
           foreign_key: "ex_base_author_id",
           class_name: "Name"
  has_many :sanctioned_names,
           foreign_key: "sanctioning_author_id",
           class_name: "Name"

  belongs_to :duplicate_of, class_name: "Author", foreign_key: "duplicate_of_id", optional: true
  has_many :duplicates,
           -> { order("name") },
           class_name: "Author",
           foreign_key: "duplicate_of_id",
           dependent: :restrict_with_error
  has_many :comments

  scope :lower_abbrev_equals,
        ->(string) { where("lower(abbrev) = lower(?) ", string) }

  DEFAULT_DESCRIPTOR = "n" # for name
  DEFAULT_ORDER_BY = "name asc "

  # before_create :set_defaults # rails 6 this was not being called before the validations
  before_save :compress_whitespace

  def save_with_username(username)
    self.created_by = self.updated_by = username
    set_defaults
    save
  end

  def name_and_or_abbrev
    if name.present? && abbrev.present?
      "#{name} | #{abbrev}"
    elsif name.present?
      name.to_s
    else
      abbrev.to_s
    end
  end

  def master_of
    Author.where(duplicate_of_id: id)
  end

  def duplicate?
    !duplicate_of_id.blank?
  end

  def abbrev_if_possible
    abbrev || "[No abbreviation - id: #{id}]"
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def anchor_id
    "Author-#{id}"
  end

  def unknown
    name == "-"
  end

  def known
    !unknown
  end

  def set_defaults
    self.namespace_id = Namespace.default.id if namespace_id.blank?
  end

  # TODO: replace with calls to squish!
  def compress_whitespace
    self.name = name.gsub(/ +/, " ") unless name.nil?
    self.abbrev = abbrev.gsub(/ +/, " ") unless abbrev.nil?
  end

  def citation
    abbrev || "[no author citation]"
  end

  def name_for_citation
    case name
    when /\A-\z/
      ""
    else
      name.strip.to_s
    end
  end

  def can_be_deleted?
    references.size.zero? &&
      duplicates.size.zero? &&
      names.size.zero? &&
      no_other_authored_names?
  end

  def no_other_authored_names?
    base_names.size.zero? &&
      ex_names.size.zero? &&
      ex_base_names.size.zero? &&
      sanctioned_names.size.zero?
  end

  def normalised_name
    Author.find_by_sql(["select f_unaccent(name) as normalised_name from author where id = ?",
                        id]).first["normalised_name"]
  end

  def normalised_abbrev
    Author.find_by_sql(["select f_unaccent(abbrev) as normalised_abbrev from author where id = ?",
                        id]).first["normalised_abbrev"]
  end
end
