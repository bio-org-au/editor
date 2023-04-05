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

#   Add instance to draft taxonomy for a raw loader_name
class Loader::Name::DraftTaxonomyAdder::PlacerOrReplacer::Replacer
  attr_reader :added, :declined, :errors, :result
  
  # replacer = Replacer.new(preferred_match, @draft, @tree_version_element, @user, @job)
  def initialize(preferred_match, draft, tree_version_element, user, job)
    @preferred_match = preferred_match
    @loader_name = preferred_match.loader_name
    @draft = draft
    @tree_version_element = tree_version_element
    @user = user
    @job = job
    @added = @declined = @errors = 0
    @result = false
  end

  def replace
    Rails.logger.debug("replace: #{@tree_version_element.inspect}")
    Rails.logger.debug("replace: @tree_version_element.instance_id: #{@tree_version_element.tree_element.instance_id}")
    Rails.logger.debug("replace: calling Tree::Workspace::Replacement.new for instance: #{@preferred_match.standalone_instance_id}")
    replacement = Tree::Workspace::Replacement.new(username: @user,
                                                 target: @tree_version_element,
                                                 parent: parent_tve(@preferred_match),
                                                 instance_id: @preferred_match.standalone_instance_id,
                                                 excluded: @preferred_match.excluded?,
                                                 profile: profile)
    @response = replacement.replace
    log_to_table("Replace #{@preferred_match.loader_name.simple_name}, id: #{@preferred_match.loader_name.id}, seq: #{@preferred_match.loader_name.seq}")
    @preferred_match.drafted = true
    @preferred_match.save!
    @added = 1
    @result = true
  rescue RestClient::ExceptionWithResponse => e
    @errors = 1
    raise
  end

  def status
    return [@added, @declined, @errors, @result]
  end

  private

  def parent_tve(preferred_match)
    @draft.name_in_version(preferred_match.name.parent)
  end

  # I did try to use the Tree::ProfileData class, 
  # but it couldn't find the comment_key or distribution_key
  # without new methods and (more importantly) it requires 
  # a @current_user, which the batch job doesn't have.
  def profile
    hash = {}
    unless @loader_name.comment.blank?
      hash['APC Comment'] = { value: @loader_name.comment,
                              updated_by: @user,
                              updated_at: Time.now.utc.iso8601}
    end
    unless @loader_name.distribution.blank?
      hash['APC Dist.'] =
        { value: @loader_name.distribution.split(' | ').join(', '),
          updated_by: @user,
          updated_at: Time.now.utc.iso8601
        }
    end
    hash
  end

  def debug(msg)
    Rails.logger.debug(
      "Loader::Name::DraftTaxonomyAdder::PlaceOrReplace::Replacer: #{msg}")
  end

  def log_to_table(payload)
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end
end
