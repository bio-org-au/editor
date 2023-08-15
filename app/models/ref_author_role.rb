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
class RefAuthorRole < ActiveRecord::Base
  self.table_name = "ref_author_role"
  self.primary_key = "id"
  has_many :references

  def as_citation
    name.downcase =~ /editor/ ? "(ed.)" : ""
  end

  def as_excitation
    name.downcase =~ /editor/ ? "(ed.)" : ""
  end

  def self.author
    # where(name: "Author").push(order("name").limit(1).first).first
    where(name: "Author").first
  end

  def self.unknown
    where(name: "Unknown").push(order("name").limit(1).first).first
  end

  def self.options
    all.order(:name).collect { |r| [r.name, r.id] }
  end

  def self.query_form_options
    all.sort_by(&:name).collect { |n| [n.name, n.name.downcase, { class: "" }] }
  end
end
