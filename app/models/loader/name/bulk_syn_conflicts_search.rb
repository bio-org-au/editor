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
#
# Build a loader_name bulk search query based on a search string
# Based on Loader::Name::BulkSearch
#
# Don't care about accepted or excluded - the names must have a preferred match
# and if they have a preferred match we will deal with them.
#
# Only works for simple_name match
class Loader::Name::BulkSynConflictsSearch
  attr_reader :search

  def initialize(search_s, batch_id)
    @search_s = search_s
    @batch_id = batch_id
    bulk_processing_search
  end

  def bulk_processing_search
    @search = TreeJoinV
    .joins(" inner join loader_name_match on loader_name_match.name_id = tree_join_v.name_id")
    .joins(" inner join loader_name on loader_name.id = loader_name_match.loader_name_id")
    .joins(" inner join loader_batch on loader_batch.id = loader_name.loader_batch_id")
    .where(" loader_name.record_type = 'synonym' ")
    .where(" tree_join_v.published = false ")
    .where(" lower(loader_name.simple_name) like lower(?)",
           @search_s.downcase.gsub(/\*/,'%'))
    .select(" tree_join_v.element_link")
  end
end

