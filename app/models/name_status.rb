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
# == Schema Information
#
# Table name: name_status
#
#  id               :bigint           not null, primary key
#  deprecated       :boolean          default(FALSE), not null
#  description_html :text
#  display          :boolean          default(TRUE), not null
#  lock_version     :bigint           default(0), not null
#  name             :string(50)
#  nom_illeg        :boolean          default(FALSE), not null
#  nom_inval        :boolean          default(FALSE), not null
#  name_group_id    :bigint           not null
#  name_status_id   :bigint
#  rdf_id           :string(50)
#
# Indexes
#
#  name_status_rdfid  (rdf_id)
#  ns_unique_name     (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_g4o6xditli5a0xrm6eqc6h9gw  (name_status_id => name_status.id)
#  fk_swotu3c2gy1hp8f6ekvuo7s26  (name_group_id => name_group.id)
#
class NameStatus < ApplicationRecord
  self.table_name = "name_status"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  belongs_to :name_group
  scope :ordered_by_name, -> { order(Arel.sql(%(replace(name, '[', 'z') collate "C"))) }
  scope :not_deprecated, -> { where("not deprecated") }
  scope :not_cultivar, -> { where(" name not in ('nom. cult.', 'nom. cult., nom. alt.') ") }

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
    self.not_cultivar
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

  def self.loader_options
    self.not_cultivar
        .not_deprecated
        .ordered_by_name.collect do |n|
          [n.name]
    end
  end
end
