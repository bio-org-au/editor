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

class Loader::Name::DraftTaxonomyRemover::Remover
  attr_reader :result, :result_h

  def initialize(tree_join_record, draft, user, job)
    @tree_join_record = tree_join_record
    @draft = draft
    @user = user
    @job = job
    @result = false
    @result_h = {}
    @task_start_time = Time.now
  end

  def remove
    removement = Tree::Workspace::Removement.new(username: @user,
                                                 target: @tree_join_record)
    @response = removement.remove
    log_to_table("Remove #{@tree_join_record.element_link}, #{@tree_join_record.simple_name}, instance: #{@tree_join_record.instance_id}")
    @result_h = {removes: 1}
    @result = true
  rescue RestClient::ExceptionWithResponse => e
    @result_h = {errors: 1, errors_reasons: {"#{e.to_s}": 1}}
    raise
  end

  def status
    @result_h
  end

  private

  def debug(msg)
    Rails.logger.debug(
      "Loader::Name::DraftTaxonomyRemover::Remover: #{msg}"
    )
  end

  def log_to_table(payload)
    payload = "#{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)" if defined? @task_start_time
    Loader::Batch::Bulk::JobLog.new(@job, payload, @user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to bulk processing log table: #{e}")
  end
end
