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
class Loader::Name::DraftTaxonomyAdder
  attr_reader :added, :declined, :errors

  def initialize(loader_name, draft, user, job)
    @loader_name = loader_name
    @draft = draft
    @user = user
    @job = job
  end

  def add
    @added = @declined = @errors = 0
    preflights_clear = preflights
    place_or_replace if preflights_clear
  end

  def preflights
    preflights = Preflights.new(@loader_name, @draft, @user, @job)
    preflights.check
    @declined += 1 unless preflights.clear
    preflights.clear
  end

  def place_or_replace
    placer_or_replacer = PlacerOrReplacer.new(@loader_name, @draft, @user, @job)
    placer_or_replacer.place_or_replace
    @added, @declined, @errors = placer_or_replacer.counts
    placer_or_replacer.result
  end

  def no_preferred_match
    log_to_table("#{Constants::DECLINED_INSTANCE} - no preferred match for ##{@loader_name.id} #{@loader_name.simple_name}")
    Constants::DECLINED
  end

  def heading
    log_to_table("#{Constants::DECLINED_INSTANCE} - heading entries not processed ##{@loader_name.id} #{@loader_name.simple_name}")
    Constants::DECLINED
  end

  def log_to_table(payload)
    Loader::Batch::Bulk::JobLog.new(@job_number, payload, @authorising_user).write
  rescue StandardError => e
    Rails.logger.error("Couldn't log to table: #{e}")
  end

  def record_failure(msg)
    msg.sub!(/uncaught throw /, "")
    msg.gsub!(/"/, "")
    msg.sub!(/^Failing/, "")
    Rails.logger.error("Loader::Name::AsInstanceCreator failure: #{msg}")
    log_to_table("Loader::Name::AsInstanceCreator failure: #{msg}")
  end

  def debug(msg)
    Rails.logger.debug("Loader::Name::AsInstanceCreator #{msg} #{@tag}")
  end
end

