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
class Name::HasDependents
  def initialize(name)
    @name = name
    identify_dependencies
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
    @name.tree_elements
  end

  def tree_version_elements
    @name.tree_elements.first.tree_version_elements
  end

  def tree_versions
    @name.tree_elements.collect do |te|
      te.tree_version_elements.collect do |tve|
        tve.tree_version
      end
    end
  end

  def trees
    @name.tree_elements.collect do |te|
      te.tree_version_elements.collect do |tve|
        tve.tree_version.tree
      end
    end.flatten
  end

  def trees_2
    @name.tree_elements.collect do |te|
      te.tree_version_elements.collect do |tve|
        tve.tree_version.tree.name + "::" +
          tve.tree_version.draft_name + "::" +
          tve.tree_version.published.to_s
      end
    end
  end

  private

  def identify_dependencies
    @children = @name.children
    debug("children: #{@children.size}")
    @second_children = @name.second_children
    debug("second children: #{@second_children.size}")
    @instances = @name.instances
    debug("instances: #{@instances.size}")
    @duplicates_of = Name.where(duplicate_of_id: @name.id)
    debug("duplicates of: #{@duplicates_of.size}")
    @tree_elements = Tree::Element.where(name_id: @name.id)
    debug("tree elements: #{@tree_elements.size}")
    @comments = @name.comments
    debug("comments: #{@comments.size}")
    @name_tag_names = @name.name_tag_names
    debug("name tag names: #{@name_tag_names.size}")
    @in_family = Name.where(family_id: @name.id)
    debug("names in family: #{@in_family.size}")
  end

  def debug(msg)
    # Rails.logger.debug('With dependents....')
    puts(msg)
  end
end
