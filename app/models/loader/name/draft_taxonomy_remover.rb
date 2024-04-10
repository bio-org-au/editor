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

#   Add instance to draft taxonomy
class Loader::Name::DraftTaxonomyRemover
  attr_reader :result_h

  def initialize(tree_join_record, draft, user, job)
    @tree_join_record = tree_join_record
    @draft = draft
    @user = user
    @job = job
    @task_start_time = Time.now
  end

  def remove
    remover = Remover.new(@tree_join_record, @draft, @user, @job)
    remover.remove
    @result_h = remover.result_h
    remover.result
  end

  def log_to_table(payload)
    content = "#{@tree_join_record.element_link} #{payload} (elapsed: #{(Time.now - @task_start_time).round(2)}s)"
    Loader::Batch::Bulk::JobLog.new(@job_number, content, @authorising_user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't save log to bulk processing log table: #{e}")
  end

  def record_failure(msg)
    msg.sub!("uncaught throw ", "")
    msg.gsub!('"', "")
    msg.sub!(/^Failing/, "")
    Rails.logger.error("Loader::Name::AsInstanceCreator failure: #{msg}")
    log_to_table("Loader::Name::AsInstanceCreator failure: #{msg}")
  end

  def debug(msg)
    Rails.logger.debug("Loader::Name::AsInstanceCreator #{msg} #{@tag}")
  end
end
