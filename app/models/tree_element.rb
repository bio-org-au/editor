# frozen_string_literal: true

require 'open-uri'

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

#  A tree element - holds the taxon information
class TreeElement < ActiveRecord::Base
  self.table_name = "tree_element"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  belongs_to :instance, class_name: "Instance"

  belongs_to :name, class_name: "Name"

  has_many :tree_version_elements,
           foreign_key: "tree_element_id"

  has_and_belongs_to_many :tede_dist_entries,
                          class_name: "DistEntry",
                          join_table: "tree_element_distribution_entries",
                          foreign_key: "tree_element_id"

  def self.dist_options
    DistEntry.all.sort do |a, b|
      a.sort_order <=> b.sort_order
    end.collect(&:display)
  end

  def distribution_value
    profile[distribution_key]["value"]
  end

  def distribution?
    distribution_key.present?
  end

  def distribution_key
    profile_key(/Dist/)
  end

  def dist_options_disabled
    disabled_options = []
    all = DistEntry.all
    for n in tede_dist_entries.collect(&:region)
      disabled_options.concat(all.find_all {|opt| opt.dist_region.name == n}.collect(&:display))
    end
    disabled_options
  end

  def current_dist_options
    tede_dist_entries.collect(&:display)
  end

  def construct_distribution_string
    tede_dist_entries
        .sort {|a, b| a.dist_region.sort_order <=> b.dist_region.sort_order}
        .collect(&:entry)
        .join(', ')
  end

  def comment?
    comment_key.present?
  end

  def comment_key
    profile_key(/Comment/)
  end

  def comment_value
    profile[comment_key]["value"]
  end

  def profile_value(key_string)
    key = profile_key(key_string)
    if key
      profile[key]["value"]
    else
      ""
    end
  end

  def profile_key(pkey)
    return nil unless profile.present?

    if pkey.is_a? String then
      profile.keys.find {|key| key == pkey}
    elsif pkey.is_a? Regexp then
      profile.keys.find {|key| key =~ pkey}
    else 
      raise 'Not a string or a regexp....'
    end
  end

  #def profile_key_via_regex(key_regex)
    #profile.keys.find {|key| key_regex =~ key} if profile.present?
  #end

  def distribution
    profile[distribution_key]
  end

  def comment
    profile[comment_key]
  end

  # note: deliberatly using the update_all method because allows convenient use of jsonb_set 
  # note: no validation
  # note: applies sql directly
  def update_distribution_directly(new_dist_s, user)
    TreeElement.where(id: self.id).update_all(%Q(profile = jsonb_set(profile,'{"#{distribution_key}","value"}','"#{new_dist_s}"')))
    TreeElement.where(id: self.id).update_all(%Q(profile = jsonb_set(profile,'{"#{distribution_key}","updated_by"}','"#{user}"')))
    TreeElement.where(id: self.id).update_all(%Q(profile = jsonb_set(profile,'{"#{distribution_key}","updated_at"}',to_jsonb(to_char(now()::timestamp,'YYYY-MM-DD"T"HH24:MI:SS+#{utc_offset_s}')))))
  end

  def update_comment_directly(new_comment, user)
    TreeElement.where(id: self.id).update_all(%Q(profile = jsonb_set(profile,'{"#{comment_key}","value"}','"#{new_comment}"')))
    TreeElement.where(id: self.id).update_all(%Q(profile = jsonb_set(profile,'{"#{comment_key}","updated_by"}','"#{user}"')))
    TreeElement.where(id: self.id).update_all(%Q(profile = jsonb_set(profile,'{"#{comment_key}","updated_at"}',to_jsonb(to_char(now()::timestamp,'YYYY-MM-DD"T"HH24:MI:SS+#{utc_offset_s}')))))
  end

  def utc_offset_s
    seconds_offset = Time.now.in_time_zone('Australia/Canberra').utc_offset
    hours_offset = seconds_offset/3600
    mins_offset = seconds_offset%3600
    hours_offset_s = hours_offset.to_s.rjust(2, '0')
    mins_offset_s = mins_offset.to_s.rjust(2, '0')
    utc_offset = "#{hours_offset_s}:#{mins_offset_s}"
  end

  def self.cleanup_distribution_string(s)
    s = s.split(',').collect {|s| s.strip}
         .sort_by { |s| TreeElement.region_position(s) || 99 }.uniq.join(', ') 
  end

  def self.validate_distribution_string(s)
    s.split(',').collect{|val| val.strip}.each do |val|
      raise "Invalid value: #{val}" unless DistEntry.exists?(display: val.strip)
    end
  end

  # e.g. input dist_entry 'AR (native and naturalised)'
  #      get the sort_order for AR from dist_region
  def self.region_position(dist_entry)
    DistRegion.as_hash[dist_entry.split(' ').first]
  end

  def apply_string_to_tedes
    add_missing_tedes
    remove_excess_tedes
  end

  def missing_tedes
    distribution_as_arr - tede_entries_arr
  end

  def add_missing_tedes
    missing_tedes.each { |value| add_tede(value) }
  end

  def add_tede(value)
    tede = Tree::Element::DistributionEntry.new
    tede.tree_element_id = id
    tede.dist_entry_id = DistEntry.id_for_display(value)
    tede.updated_by = @current_user&.username  || 'unknown'
    tede.save!
  end

  def excess_tedes
    tede_entries_arr - distribution_as_arr 
  end

  def remove_excess_tedes
    excess_tedes.each { |value| remove_tede(value) }
  end

  def remove_tede(value)
    tede = Tree::Element::DistributionEntry
      .find_by(tree_element_id: id,
               dist_entry_id: DistEntry.id_for_display(value))
    tede.delete
  end

  def distribution_as_arr
    distribution_value.split(',').collect {|val| val.strip}
  end

  def tede_entries_arr
    tede_dist_entries.collect {|entry| entry.display}
  end
end
