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
# Query target param lets us decide if it is a "defined query" or not,
# and if it is, which one.
class Search::ParsedDefinedQuery
  attr_reader :defined_query,
              :target_button_text

  DEFINED_QUERIES = {
    "references_with_instances" => "references-name-full-synonymy",
    "references_names_full_synonymy" => "references-name-full-synonymy",
    "references_+_instances" => "references-name-full-synonymy",
    "references_with_novelties" => "references-with-novelties",
    "references_accepted_names_for_id" => "references-accepted-names-for-id",
    "references_shared_names" => "references-shared-names",
    "instance_is_cited" => "instance-is-cited",
    "instance_is_cited_by" => "instance-is-cited-by",
    "audit" => "audit",
    "review" => "audit",
    "activity" => "audit",
    "changed_tree_elements" => "changed-tree-elements",
  }.freeze

  def initialize(query_target)
    @query_target = query_target.downcase.gsub(", ", "_").gsub(" ", "_")
    parse_query_target
  end

  def debug(s)
    Rails.logger.debug("Search::ParsedDefinedQuery: #{s}")
  end

  def parse_query_target
    query_target_downcase = @query_target.downcase
    if DEFINED_QUERIES.key?(query_target_downcase)
      debug("'#{query_target_downcase}' recognized as a defined query.")
      @defined_query = DEFINED_QUERIES[query_target_downcase]
      @target_button_text = @query_target.capitalize
    else
      debug("'#{query_target_downcase}' NOT recognized as a defined query.")
      @defined_query = false
      @target_button_text = ""
    end
  end
end
