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

#   Create a preferred match for a loader_name record
class Loader::Name::MakeOneMatchTask
  def initialize(loader_name, user, job_number)
    debug("initialize Loader::Name::AsPreferredMatcher; job: #{job_number}")
    debug("loader_name: #{loader_name}; user: #{user}")
    @loader_name = loader_name
    @user = user
    @job_number = job_number
  end

  def create
    matcher = Loader::Name::MakeOneMatch.new(@loader_name, @user, @job_number)
    matcher.find_or_create_preferred_match
  end

  def no_further_processing
    log("Declined - no further processing")
    {declines: 1, decline_reasons: {no_further_processing: 1} }
  end

  attr_reader :created, :errors

  def log_create_action(count)
    entry = "Create preferred match counted #{count} #{'record'.pluralize(count)}"
    log(entry)
  end

  def log(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @user).write
  end

  def scientific_name
    @loader_name.scientific_name
  end

  def record_failure(msg)
    msg.sub!("uncaught throw ", "")
    msg.gsub!('"', "")
    msg.sub!(/^Failing/, "")
    Rails.logger.error("Loader::Name::AsPreferredMatcher failure: #{msg}")
    log("Loader::Name::AsPreferredMatcher failure: #{msg}")
  end

  def debug(msg)
    Rails.logger.debug("Loader::Name::AsPreferredMatcher #{msg} #{@tag}")
  end
end
