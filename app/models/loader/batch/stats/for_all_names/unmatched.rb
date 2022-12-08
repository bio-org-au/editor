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
class Loader::Batch::Stats::ForAllNames::Unmatched
  def initialize(core_search)
    @core_search = core_search
  end

  def report
    { heading_without_preferred_match: heading_without_preferred_match,
      accepted_without_preferred_match: accepted_without_preferred_match,
      excluded_without_preferred_match: excluded_without_preferred_match,
      synonym_without_preferred_match: synonym_without_preferred_match,
      misapp_without_preferred_match: misapp_without_preferred_match,
      total_without_preferred_match: total_without_preferred_match }
  end

  def heading_without_preferred_match
    @core_search.where("record_type = 'heading'")
                .where(" not no_further_processing ")
                .where.not("exists
                (select null
                   from loader_name_match match
                  where loader_name.id = match.loader_name_id)").count
  end

  def accepted_without_preferred_match
    @core_search.where("record_type = 'accepted'")
                .where(" not no_further_processing ")
                .where.not("exists
                (select null
                   from loader_name_match match
                  where loader_name.id = match.loader_name_id)").count
  end

  def excluded_without_preferred_match
    @core_search.where("record_type = 'excluded'")
                .where(" not no_further_processing ")
                .where.not("exists
                (select null
                   from loader_name_match match
                  where loader_name.id = match.loader_name_id)").count
  end

  def synonym_without_preferred_match
    @core_search.where("record_type = 'synonym'")
                .where(" not no_further_processing ")
                .where(" not exists (select null
                         from loader_name parent
                        where loader_name.parent_id = parent.id
                          and parent.no_further_processing)")
                .where.not("exists
                      (select null
                         from loader_name_match match
                        where loader_name.id = match.loader_name_id)").count
  end

  def misapp_without_preferred_match
    @core_search.where("record_type = 'misapplied'")
                .where(" not no_further_processing ")
                .where(" not exists (select null
                        from loader_name parent
                       where loader_name.parent_id = parent.id
                         and parent.no_further_processing)")
                .where.not("exists
                     (select null
                        from loader_name_match match
                       where loader_name.id = match.loader_name_id)").count
  end

  def total_without_preferred_match
    @core_search.where(" not no_further_processing ")
                .where(" not exists (select null
                        from loader_name parent
                       where loader_name.parent_id = parent.id
                         and parent.no_further_processing)")
                .where.not("exists
                     (select null
                        from loader_name_match match
                       where loader_name.id = match.loader_name_id)").count
  end
end
