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

# I can Deduplicate a name
# I have a name I can deduplicate
#
class Name::DeDuper
  def initialize(duplicate_name)
    @duplicate = duplicate_name
    @master = @duplicate&.duplicate_of
    identify_dependencies
  end

  def preview
    overview
  end

  def overview
    result = {}
    # family members
    result[:children] = @children.size
    result[:second_children] = @second_children.size
    result[:instances] = @instances.size
    result[:duplicates_of] = @duplicates_of.size
    result[:tree_elements] = @tree_elements.size
    result[:comments] = @comments.size
    result[:name_tag_names] = @name_tag_names.size
    result[:in_family] = @in_family.size
    result
  end

  def tree_elements?
    @tree_elements.size > 0
  end

  def tree_elements
    @duplicate.tree_elements
  end

  def tree_version_elements
    @duplicate.tree_elements.first.tree_version_elements
  end

  def tree_versions
    @duplicate.tree_elements.collect do |te|
      te.tree_version_elements.collect do |tve|
        tve.tree_version
      end
    end
  end

  def trees
    @duplicate.tree_elements.collect do |te|
      te.tree_version_elements.collect do |tve|
        tve.tree_version.tree
      end
    end.flatten
  end

  def trees_2
    @duplicate.tree_elements.collect do |te|
      te.tree_version_elements.collect do |tve|
        tve.tree_version.tree.name + "::" +
          tve.tree_version.draft_name + "::" +
          tve.tree_version.published.to_s
      end
    end
  end

  def transfer_dependents(type)
    case type
    when "in_family"
      transfer_family_members
    when "children"
      transfer_children
    when "instances"
      transfer_instances
    else
      throw "Editor doesn't transfer dependent #{type}"
    end
  end

  # Family members, in this case, do not include direct children.
  def transfer_family_members
    @transferred_count = 0
    @duplicate.members.each do |family_member|
      family_member.update_attribute(:family_id, @master.id)
      family_member.update_attribute(:updated_by, "duplicate-rewiring")
      @transferred_count += 1
    end
    @transferred_count
  end

  # Children are not the same as family members.
  def transfer_children
    @transferred_count = 0
    @duplicate.children.each do |child|
      child.update_attribute(:parent_id, @master.id)
      child.update_attribute(:updated_by, "duplicate-rewiring")
      @transferred_count += 1
    end
    @transferred_count
  end

  def transfer_instances
    @transferred_count = 0
    @duplicate.instances.each do |instance|
      # unless instance.tree_elements.size > 0
      instance.update_attribute(:name_id, @master.id)
      instance.update_attribute(:updated_by, "duplicate-rewiring")
      @transferred_count += 1
      # end
    end
    @transferred_count
  end

  def notyettransfer_tree_elements
    @transferred_count = 0
    ActiveRecord::Base.transaction do
      @duplicate.tree_elements.each do |tree_element|
        tree_element.name_id = @master.id
        tree_element.name_element = @master.name_element
        tree_element.name_element = @master.name_element
        tree_element.name_link = tree_element.name_link.sub(/#{@duplicate.id}/, @master.id)
        tree_element.simple_name = @master.simple_name
        @transferred_count += 1
      end
    end
    @transferred_count
  end

  private
  def identify_dependencies
    @children = @duplicate.children
    debug("children: #{@children.size}")
    @second_children = @duplicate.second_children
    debug("second children: #{@second_children.size}")
    @instances = @duplicate.instances
    debug("instances: #{@instances.size}")
    @duplicates_of = Name.where(duplicate_of_id: @duplicate.id)
    debug("duplicates of: #{@duplicates_of.size}")
    @tree_elements = Tree::Element.where(name_id: @duplicate.id)
    debug("tree elements: #{@tree_elements.size}")
    @comments = @duplicate.comments
    debug("comments: #{@comments.size}")
    @name_tag_names = @duplicate.name_tag_names
    debug("name tag names: #{@name_tag_names.size}")
    @in_family = Name.where(family_id: @duplicate.id)
    debug("names in family: #{@in_family.size}")
  end

  def debug(msg)
    Rails.logger.debug("Name::DeDuper: #{msg}")
  end
end
