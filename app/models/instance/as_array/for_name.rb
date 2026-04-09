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

# Instances are associated with a Name as:
# - standalone instances for the Name, or as
# - relationship instances that cite or are cited by those standalones.
#
# This class collects the instances associated with a single name
# in the accepted order and sets the display attributes for each record.
#
# The collection is in the results attribute.
#
# e.g.
# name = [find some name]
# instances = Instance::AsArray::ForName.new(name)
# puts instances.results.size
#
class Instance::AsArray::ForName < Array
  attr_reader :results

  NO_YEAR = ""

  def initialize(name)
    @results = []
    @already_shown = []
    sorted_instances(name.instances.includes([{ reference: :author }, :instance_type])).each do |instance|
      if instance.standalone?
        show_standalone_instance(instance)
      else
        show_relationship_instance(name, instance)
      end
    end
  end

  def debug(s)
    Rails.logger.debug("Instance::AsArray::ForName: #{s}")
  end

  def sorted_instances(instances)
    instances.to_a.sort { |i1, i2| sort_fields(i1) <=> sort_fields(i2) }
  end

  # Sort order:
  # 1. Draft status (non-drafts before drafts)
  # 2. Whether instance has a year (dated before undated within same draft group)
  # 3. Year (chronologically, earliest first)
  # 4. Primary instance type first
  # 5. ISO publication date
  # 6. Author name (alphabetically)
  #
  # This ensures undated instances stay within their draft/non-draft group:
  # - Undated non-draft instances sort immediately after dated non-drafts
  # - Undated draft instances sort immediately after dated drafts
  # - draft instances are instance.draft? or profile_item.draft?
  def sort_fields(instance)
    ref = instance.reference
    year = ref.year || parent_attr(ref, :year)
    iso_date = ref.iso_publication_date || parent_attr(ref, :iso_publication_date)

    [
      draft_sort_order(instance),             # "A" (non-draft) or "B" (draft)
      dated_first(year),                      # 0 (has year) or 1 (no year)
      year || NO_YEAR,                        # 2026 or ""
      instance.instance_type.primaries_first, # "A" (primary instance) or "B" (non-primary)
      iso_date || NO_YEAR,                    # "2026-01-01" or ""
      author_name(instance).downcase          # "authorname, g." or "x" (if nil)
    ]
  end

  # NOTES: Handle references that inherit publication metadata from a parent reference in the hierarchy.
  def parent_attr(reference, attribute)
    reference.try(:parent).try(attribute)
  end

  def dated_first(year)
    year.present? ? 0 : 1
  end

  # NOTES: Non-drafts sort before drafts (A < B)
  # Replaced the instance.draft? with instance.draft_for_sorting?
  # (so we don't change the existing instance.draft? logic, which maybe used elsewhere in the codebase)
  def draft_sort_order(instance)
    instance.draft_for_sorting? ? "B" : "A"
  end

  def author_name(instance)
    instance.reference.author.try("name") || "x"
  end

  def show_standalone_instance(instance)
    debug("show_standalone_instance #{instance.id}")
    standalone_instance_records(instance).each do |one_instance|
      one_instance.show_primary_instance_type = true
      one_instance.consider_taxo = true
      @results.push(one_instance)
    end
  end

  # Work on a single standalone instance starts here.
  # - display the instance as part of a concept
  # - find all child instances using the cited_by_id column
  #   (all instances that say they are cited by the standalone instance)
  #   - display these relationship instances as cited_by the standalone instance
  def standalone_instance_records(instance)
    debug("show_standalone_instance_records #{instance.id}")
    results = [instance.display_as_part_of_concept]
    records_cited_by_standalone(instance)
      .each do |cited_by_original_instance|
        cited_by_original_instance.expanded_instance_type =
          cited_by_original_instance.instance_type.name
        cited_by_original_instance.display_as = "instance-is-cited-by"
        results.push(cited_by_original_instance)
      end
    results
  end

  def records_cited_by_standalone(instance)
    debug("records_cited_by_standalone for instance #{instance.id}")
    Instance.joins(:instance_type, :name, :reference)
            .joins("left outer join instance cites on instance.cites_id = cites.id")
            .joins("left outer join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
            .joins("inner join name_status ns on name.name_status_id = ns.id")
            .includes(:instance_type)
            .where(cited_by_id: instance.id)
            .in_synonymy_order
            .order("reference.iso_publication_date,lower(name.full_name)")
  end

  def show_relationship_instance(name, instance)
    citing_instance = instance.this_is_cited_by
    return if @already_shown.include?(citing_instance.id)

    relationship_instance_records(name, citing_instance).each do |element|
      element.consider_taxo = false
      @results.push(element)
    end
    @already_shown.push(citing_instance.id)
  end

  # NSL-536: If instance name is not the subject name then
  # do not show the instance type.
  def relationship_instance_records(name, instance)
    results = [instance.display_as_citing_instance_within_name_search]
    records_cited_by_relationship(instance)
      .each do |cited_by_original_instance|
      next unless cited_by_original_instance.name.id == name.id

      cited_by_original_instance.expanded_instance_type =
        cited_by_original_instance.instance_type.name
      results.push(with_display_as(cited_by_original_instance))
    end
    results
  end

  def with_display_as(instance)
    debug("with_display_as for instance #{instance.id}")
    instance.display_as = if instance.misapplied?
                            "cited-by-relationship-instance"
                          else
                            "cited-by-relationship-instance-name-only"
                          end
    instance
  end

  def records_cited_by_relationship(instance)
    debug("records_cited_by_relationship for instance #{instance.id}")
    Instance.joins(:instance_type, :name, :reference)
            .joins("left outer join instance cites on instance.cites_id = cites.id")
            .joins("left outer join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
            .joins("inner join name_status ns on name.name_status_id = ns.id")
            .where(cited_by_id: instance.id)
            .in_synonymy_order
  end
end
