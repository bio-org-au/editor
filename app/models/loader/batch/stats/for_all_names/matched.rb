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

# Batch Statistics report
# Returns a hash
class Loader::Batch::Stats::ForAllNames::Matched
  def initialize(core_search)
    @core_search = core_search
  end

  def report
    { accepted_with_preferred_match: accepted_with_preferred_match,
      excluded_with_preferred_match: excluded_with_preferred_match,
      synonym_with_preferred_match: synonym_with_preferred_match,
      misapplied_with_preferred_match: misapplied_with_preferred_match,
      total_with_preferred_match: total_with_at_least_one_preferred_match,
      misapplied_preferred_matches: misapplied_preferred_matches }
  end

  def accepted_with_preferred_match
    @core_search.where("record_type = 'accepted'")
                .joins(:loader_name_matches)
                .count
  end

  def excluded_with_preferred_match
    @core_search.where("record_type = 'excluded'")
                .joins(:loader_name_matches)
                .count
  end

  def synonym_with_preferred_match
    @core_search.where("record_type = 'synonym'")
                .joins(:loader_name_matches)
                .count
  end

  def misapplied_with_preferred_match
    @core_search.where("record_type = 'misapplied'")
                .where("exists
                      (select null
                         from loader_name_match match
                        where loader_name.id = match.loader_name_id)").count
  rescue StandardError => e
    e.to_s
  end

  def total_with_at_least_one_preferred_match
    @core_search.where("exists
                      (select null
                         from loader_name_match match
                        where loader_name.id = match.loader_name_id)").count
  rescue StandardError => e
    e.to_s
  end

  def misapplied_preferred_matches
    @core_search.where("record_type = 'misapplied'")
                .where(" not no_further_processing ")
                .joins(:loader_name_matches)
                .count
  end
end
