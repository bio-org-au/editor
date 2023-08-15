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
class InstanceType < ActiveRecord::Base
  self.table_name = "instance_type"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  has_many :instances

  def self.unknown
    InstanceType.find_by(name: "[unknown]")
  end

  def name_as_a_noun
    name.gsub(/misapplied/i, "misapplication")
  end

  def misapplied?
    misapplied
  end

  def unsourced?
    unsourced
  end

  def self.info_or_help_links
    head = %(<li><a tabindex="-1" href="#" class="append-to-query-field" )
    tail = %(</a></li>)
    all.order(:name).collect do |instance_type|
      %(#{head} data-value="#{instance_type.name}">#{instance_type.name}#{tail})
    end
  end

  # For new records: just the standard set.
  def self.standalone_options
    where("standalone").where.not("deprecated")
                       .sort_by(&:name)
                       .collect { |i| [i.name, i.id] }
  end

  # For new records: just the standard set.
  def self.synonym_options
    where("citing").where.not("deprecated")
                   .where.not("unsourced")
                   .sort_by(&:name)
                   .collect { |i| [i.name, i.id] }
  end

  # For new records: just the standard set.
  def self.unpublished_citation_options
    where("unsourced").where.not("deprecated")
                      .sort_by(&:name)
                      .collect { |i| [i.name, i.id] }
  end

  # For existing records.
  # If the current instance type is not in the targetted set, then
  # these methods add it into the array.
  def standalone_options
    InstanceType.standalone_options.collect do |instance_type|
      if instance_type.standalone
        [instance_type.name, instance_type.id]
      else
        ["#{instance_type.name}  [not allowed]", instance_type.id]
      end
    end
  end

  def name_with_indefinite_article
    case name
    when "[unknown]", "autonym", "[n/a]", "excluded name",
         "invalid publication", "isonym", "orth. var"
      "an #{name}"
    else
      "a #{name}"
    end
  end

  def primaries_first
    primary_instance ? "A" : "B"
  end

  def primary?
    primary_instance == true
  end

  scope :primaries, -> { where(primary_instance: true) }

  def self.query_form_options
    all.sort_by(&:name)
       .collect { |n| [n.name, n.name.downcase, { class: "" }] }
  end

  def self.secondary_reference
    InstanceType.find_by(name: "secondary reference")
  end
end
