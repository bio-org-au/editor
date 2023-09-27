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
class Loader::Name::DraftTaxonomyAdder::PlacerOrReplacer::Placer
  attr_reader :added, :declined, :errors, :result

  def initialize(preferred_match, draft, user, job)
    @preferred_match = preferred_match
    @loader_name = preferred_match.loader_name
    @draft = draft
    @preferred_match = preferred_match
    @user = user
    @job = job
    @added = @declined = @errors = 0
    @result = false
    @task_start_time = Time.now
  end

  def place
    placement = Tree::Workspace::Placement.new(username: @user,
                                               parent_element_link: parent_tve(@preferred_match),
                                               instance_id: @preferred_match.standalone_instance_id,
                                               excluded: @loader_name.excluded?,
                                               profile: profile,
                                               version_id: @draft.id)
    @response = placement.place
    log_to_table("Place #{@loader_name.simple_name}, id: #{@loader_name.id}, seq: #{@loader_name.seq}")
    @preferred_match.drafted = true
    @preferred_match.save!
    @added = 1
    @result = true
  rescue RestClient::ExceptionWithResponse => e
    @errors = 1
    raise
  end

  def status
    [@added, @declined, @errors, @result]
  end

  private

  def parent_tve(preferred_match)
    @draft.name_in_version(preferred_match.name.parent).element_link
  rescue => e
    raise "Error identifying tree parent"
  end

  # I did try to use the Tree::ProfileData class,
  # but it couldn't find the comment_key or distribution_key
  # without new methods and (more importantly) it requires
  # a @current_user, which the batch job doesn't have.
  def profile
    hash = {}
    unless @loader_name.comment.blank?
      hash["APC Comment"] = { value: @loader_name.comment,
                              updated_by: @user,
                              updated_at: Time.now.utc.iso8601 }
    end
    unless @loader_name.distribution.blank?
      hash["APC Dist."] =
        { value: @loader_name.distribution.split(" | ").join(", "),
          updated_by: @user,
          updated_at: Time.now.utc.iso8601 }
    end
    hash
  end

  def debug(msg)
    Rails.logger.debug(
      "Loader::Name::DraftTaxonomyAdder::PlaceOrReplace::Placer: #{msg}"
    )
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
