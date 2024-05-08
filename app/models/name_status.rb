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
class NameStatus < ActiveRecord::Base
  self.table_name = "name_status"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  belongs_to :name_group
  scope :ordered_by_name, -> { order(Arel.sql(%(replace(name, '[', 'z') collate "C"))) }
  scope :not_deprecated, -> { where("not deprecated") }

  NA = "[n/a]"

  has_many :names

  def self.default
    find_by(name: "legitimate")
  end

  def legitimate?
    name == "legitimate"
  end

  def manuscript?
    name == "manuscript"
  end

  def na?
    name =~ %r{\A\[n/a\]\z}
  end

  def unknown?
    name =~ /\A\[unknown\]\z/
  end

  def bracketed_non_legitimate_status
    legitimate? ? "" : "[#{name_without_brackets}]"
  end

  def name_without_brackets
    name.delete("[").gsub(/]/, "")
  end

  def name_for_instance_display
    legitimate? || na? ? "" : name
  end

  def for_inline_display
    legitimate? || na? ? "" : ", #{name}"
  end

  def name_for_instance_display_within_reference
    legitimate? || na? || unknown? ? "" : name
  end

  def name_and_comma_for_instance_display
    legitimate? || na? || unknown? ? "" : ", #{name}"
  end

  def show_name_for_instance_display_within_reference?
    !(legitimate? || na? || unknown?)
  end

  def self.not_applicable
    find_by(name: NA)
  end

  def self.options_for_category(name_category)
    if name_category.scientific?
      scientific_options
    elsif name_category.cultivar_hybrid?
      na_default_and_deleted_options
    elsif name_category.cultivar?
      na_default_and_deleted_options
    else
      na_option
    end
  end

  def self.query_form_options
    all.ordered_by_name.collect do |n|
      [n.name, "status: #{n.name.downcase}"]
    end
  end

  def self.scientific_options
    where(" name not in ('nom. cult.', 'nom. cult., nom. alt.') ")
      .not_deprecated
      .ordered_by_name.collect do |n|
        [n.name, n.id]
      end
  end

  def self.na_option
    where(" name = '[n/a]' ").collect do |n|
      [n.name, n.id]
    end
  end

  def self.na_default_and_deleted_options
    where(" name = '[n/a]' or name = '[default]' or name = '[deleted]' ")
      .order("name").collect do |n|
        [n.name, n.id]
      end
  end
end
