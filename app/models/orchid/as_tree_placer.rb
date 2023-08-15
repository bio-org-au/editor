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

#  We need to place Orchids on a draft tree.
class Orchid::AsTreePlacer
  attr_reader :placed_count, :error_count, :preflight_stop_count

  ERROR = "error"
  def initialize(draft_tree, orchid, authorising_user)
    debug("Authorising user: #{authorising_user}")
    @draft_tree = draft_tree
    @draft_name = draft_tree.draft_name
    @orchid = orchid
    @authorising_user = authorising_user
    @placed_count = 0
    @error_count = 0
    @preflight_stop_count = 0
    @preflight_failed = false
    @stopped_at_preflight = 0
    preflight_checks
    @placed_count = place_or_replace unless @preflight_failed
  end

  def json_error(err)
    json = JSON.parse(err.http_body, object_class: OpenStruct)
    if json&.error
      json.error
    else
      json&.to_s || err.to_s
    end
  rescue StandardError
    err.to_s
  end

  def preflight_checks
    if @draft_tree.blank?
      @preflight_failed = true
      @preflight_error = "Please choose a draft version"
    elsif @orchid.exclude_from_further_processing?
      @preflight_failed = true
      @preflight_error = "#{@orchid.taxon} is excluded from further processing"
    elsif @orchid.preferred_match.blank?
      @preflight_failed = true
      @preflight_error = "No preferred matching name for #{@orchid.taxon}"
    elsif @orchid.orchids_name.blank? || @orchid.orchids_name.first.standalone_instance_id.blank?
      @preflight_failed = true
      @preflight_error = "No instance identified for #{@orchid.taxon}"
    elsif @orchid.orchids_name.first.drafted?
      @preflight_failed = true
      @preflight_error = "Stopping because #{@orchid.taxon} is already on the draft tree"
    elsif @orchid.orchids_name.first.manually_drafted?
      @preflight_failed = true
      @preflight_error = "Stopping because #{@orchid.taxon} is flagged as manually drafted"
    elsif @orchid.parent.try("exclude_from_further_processing?")
      @preflight_failed = true
      @preflight_error = "Parent of #{@orchid.taxon} is excluded from further processing"
    elsif @orchid.hybrid_cross?
      @preflight_failed = true
      @preflight_error = "#{@orchid.taxon} is a hybrid cross - not ready to process these"
    end
    return unless @preflight_failed

    @preflight_stop_count = 1
    log_to_table(
      "Preflight check prevented placing/replacing on tree: #{@orchid.taxon}, id: #{@orchid.id}, seq: #{@orchid.seq}: #{@preflight_error}", @authorising_user
    )
  end

  def peek
    debug("#{'peek ' * 20}")
    debug("@orchid.class: #{@orchid.class}")
    debug("@draft_tree.class: #{@draft_tree.class}")
    debug("@draft_tree.tree.config: #{@draft_tree.tree.config}")
    debug("@draft_tree.tree.config['comment_key']: #{@draft_tree.tree.config['comment_key']}")
    debug("@draft_tree.tree.config['distribution_key']: #{@draft_tree.tree.config['distribution_key']}")
  end

  # From @orchid work out the name and instance you're interested in.
  #
  # for all the preferred names/instances of the orchid
  # loop
  #   if the name is on the draft
  #     replace it
  #   else
  #     place it
  #   end
  # end
  def place_or_replace
    debug("place_or_replace")
    @orchid.orchids_name.each do |one_orchid_name|
      if one_orchid_name.standalone_instance_id.blank?
        debug "No instance, therefore cannot place this on the APC Tree."
      elsif one_orchid_name.drafted?
        debug "Stopping because already drafted."
      else
        @tree_version_element = @draft_tree.name_in_version(one_orchid_name.name)
        if @tree_version_element.present?
          debug "name is on the draft: replace it"
          return replace_name(one_orchid_name)
          # elsif one_orchid_name.name.draft_instance_id(@draft_tree).present?
          # elsif one_orchid_name.standalone_instance.name.draft_instance_id(@draft_tree) != one_orchid_name.standalone_instance.id
          # debug 'name is in the draft already'
          # replace_name(one_orchid_name)
        else
          debug "name is not on the draft: just place it"
          return place_name(one_orchid_name)
        end
      end
    end
  rescue RestClient::ExceptionWithResponse => e
    @placed_count = 0
    @error_count = 1
    @error = json_error(e)
    log_to_table("Error placing or replacing on tree: #{@orchid.taxon}, id: #{@orchid.id}: #{@error}",
                 @authorising_user)
    if inferred_rank.downcase == "genus"
      raise GenusTaxonomyPlacementError, "Stopping because failed to add genus #{@orchid.taxon}"
    end

    0
  rescue StandardError => e
    Rails.logger.error("place_or_replace: Error placing or replacing orchid on tree #{e.message}")
    log_to_table("Error placing/replacing on tree: #{@orchid.taxon}, id: #{@orchid.id}: #{e.message}",
                 @authorising_user)
    raise
  end

  def inferred_rank
    (@orchid.nsl_rank ||
     @orchid.rank ||
     @orchid&.orchids_name&.first&.name&.name_rank&.name ||
     "cannot infer rank")
  end

  def place_name(orchids_name)
    tree_version = @draft_tree
    debug("parent_element_link: #{parent_tve(orchids_name).element_link}") unless parent_tve(orchids_name).nil?
    placement = Tree::Workspace::Placement.new(username: @authorising_user,
                                               parent_element_link: parent_tve(orchids_name).try("element_link"),
                                               instance_id: orchids_name.standalone_instance_id,
                                               excluded: orchids_name.excluded?,
                                               profile: profile,
                                               version_id: @draft_tree.id)
    @response = placement.place
    log_to_table("Place #{@orchid.taxon}, id: #{@orchid.id}, seq: #{@orchid.seq}", @authorising_user)
    orchids_name.drafted = true
    orchids_name.save!
    1
  end

  def replace_name(orchids_name)
    parent_tve = parent_tve(orchids_name)
    replacement = Tree::Workspace::Replacement.new(username: @authorising_user,
                                                   target: @tree_version_element,
                                                   parent: parent_tve(orchids_name),
                                                   instance_id: orchids_name.standalone_instance_id,
                                                   excluded: orchids_name.excluded?,
                                                   profile: profile)
    @response = replacement.replace
    log_to_table("Replace #{@orchid.taxon}, id: #{@orchid.id}, seq: #{@orchid.seq}", @authorising_user)
    orchids_name.drafted = true
    orchids_name.save!
    1
  end

  def parent_tve(orchids_name)
    @draft_tree.name_in_version(orchids_name.name.parent)
  end

  def json_result(result)
    json_payload(result)&.message || result.to_s
  rescue StandardError
    result.to_s
  end

  # I did try to use the Tree::ProfileData class,
  # but it couldn't find the comment_key or distribution_key
  # without new methods and (more importantly) it requires
  # a @current_user, which the batch job doesn't have.
  def profile
    hash = {}
    unless @orchid.comment.blank?
      hash["APC Comment"] = { value: @orchid.comment,
                              updated_by: @authorising_user,
                              updated_at: Time.now.utc.iso8601 }
    end
    unless @orchid.distribution.blank?
      hash["APC Dist."] = {
        value: @orchid.distribution.split(" | ").join(", "),
        updated_by: @authorising_user,
        updated_at: Time.now.utc.iso8601
      }
    end
    hash
  end

  private

  def debug(msg)
    Rails.logger.debug("Orchid::AsTreePlacer #{msg}")
  end

  def log_to_table(entry, user)
    OrchidProcessingLog.log(entry, user)
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end
end

class GenusTaxonomyPlacementError < StandardError
  def initialize(msg = "Failed to place a genus in taxonomy.", exception_type = "custom")
    @exception_type = exception_type
    super(msg)
  end
end
