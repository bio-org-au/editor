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

# Instances are associated with a Reference as:
# - standalone instances for the Reference, or as
# - relationship instances that cite or are cited by those standalones.
#
# This class collects the instances associated with a single reference
# in the accepted order and sets the display attributes for each record.
#
# The collection is in the results attribute.
#
# e.g.
# reference = [find some reference]
# instances = Instance::AsArray::ForReference.new(reference)
# puts instances.results.size
#
class Instance::AsArray::ForReference < Array
  attr_reader :results

  def initialize(reference, sort_by = "name", limit = 1000, offset = 0)
    debug("init #{reference.citation}")
    @results = []
    @already_shown = []
    @reference = reference
    @count = 0
    @limit = limit
    @sort_by = sort_by
    @offset = offset || 0
    @limit += @offset if @limit < @offset
    find_instances
  end

  def debug(s)
    Rails.logger.debug("Instance::AsArray::ForReference: #{s}")
  end

  def find_instances
    debug "find_instances"
    @reference.display_as_part_of_concept
    @count = 1
    find_instances_for_ref
    @limited = true if @count > @limit
    @results
  end

  def built_query
    query = @reference
            .instances
            .joins(:name)
            .includes(name: :name_status)
            .includes(:instance_type)
            .includes(this_is_cited_by: %i[name instance_type])
    @sort_by == "page" ? query.ordered_by_page : query.ordered_by_name
  end

  def find_instances_for_ref
    built_query.each do |instance|
      if instance.cited_by_id.blank?
        if @count < @offset
          @count += 1
        elsif @count < @limit
          @count += 1
          include_standalone_instance_and_synonymy(instance)
          include_synonym(instance) unless instance.cites_this.nil?
        end
      end
      break if @count > @limit
    end
  end

  def include_standalone_instance_and_synonymy(instance)
    instance.display_within_reference
    @results.push(instance)
    instance.is_cited_by
            .each do |cited_by|
      @count += 1
      cited_by.expanded_instance_type = cited_by.instance_type.name
      @results.push(cited_by)
    end
  end

  def include_synonym(instance)
    @results.push(instance.cites_this)
    @count += 1
  end
end
