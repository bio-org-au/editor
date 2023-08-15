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
#   Maps the help and examples for specific search targets to
#   file locations.
class Search::Help::PageMappings
  attr_reader :partial

  def initialize(params, view_mode)
    debug("Start for #{params[:help_id]}")
    @partial = if view_mode == ::ViewMode::REVIEW
                 REVIEW_MAP[params[:help_id]]
               else
                 MAP[params[:help_id]]
               end
  end

  def debug(s)
    Rails.logger.debug("Search::Extras::Mapper #{s}")
  end

  MAP = {
    "reference-search-help" => "references/advanced_search/help",
    "name-search-help" => "names/advanced_search/help",
    "name-plus-instances-search-help" => "names/advanced_search/help",
    "author-search-help" => "authors/advanced_search/help",
    "instance-search-help" => "instances/advanced_search/help",
    "tree-search-help" => "trees/advanced_search/help",
    "review-search-help" => "audits/advanced_search/help",
    "references-accepted-names-search-help" =>
    "references/advanced_search/with_novelties/help",
    "references-names-full-synonymy-search-help" =>
    "references/advanced_search/names_full_synonymy/help",
    "reference-search-examples" => "references/advanced_search/examples",
    "name-search-examples" => "names/advanced_search/examples",
    "name-plus-instances-search-examples" => "names/advanced_search/examples",
    "author-search-examples" => "authors/advanced_search/examples",
    "instance-search-examples" => "instances/advanced_search/examples",
    "tree-search-examples" => "trees/advanced_search/examples",
    "review-search-examples" => "audits/advanced_search/examples",
    "references-accepted-names-search-examples" =>
    "references/advanced_search/with_novelties/examples",
    "references-names-full-synonymy-search-examples" =>
    "references/advanced_search/names_full_synonymy/examples",
    "name-search-advanced" => "names/advanced_search/advanced",
    "reference-search-advanced" => "references/advanced_search/advanced",
    "references-with-novelties-search-advanced" =>
    "references/advanced_search/with_novelties/advanced",
    "references-names-full-synonymy-search-advanced" =>
    "references/advanced_search/names_full_synonymy/advanced",
    "author-search-advanced" => "authors/advanced_search/advanced",
    "instance-search-advanced" => "instances/advanced_search/advanced",
    "tree-search-advanced" => "trees/advanced_search/advanced",
    "review-search-advanced" => "audits/advanced_search/advanced",
    "references-shared-names-search-help" =>
    "references/advanced_search/shared_names/help",
    "references-shared-names-search-examples" =>
    "references/advanced_search/shared_names/examples",
    "references-shared-names-search-advanced" =>
    "references/advanced_search/shared_names/advanced",
    "orchids-search-help" => "orchids/advanced_search/help",
    "orchids-search-examples" => "orchids/advanced_search/examples",
    "orchid-processing-logs-search-help" => "orchid_processing_logs/advanced_search/help",
    "orchid-processing-logs-search-examples" => "orchid_processing_logs/advanced_search/examples",
    "loader-batch-search-help" => "loader/batches/help/fields",
    "loader-batch-search-examples" => "loader/batches/help/examples",
    "loader-batch-stack-search-help" => "loader/batch/stacks/help/fields",
    "loader-batch-stack-search-examples" => "loader/batch/stacks/help/examples",
    "loader-name-search-help" => "loader/names/help/fields",
    "loader-name-search-examples" => "loader/names/help/examples",
    "batch-review-search-help" => "loader/batch/reviews/help/fields",
    "batch-review-search-examples" => "loader/batch/reviews/help/examples",
    "batch-reviewer-search-help" => "loader/batch/reviewers/help/fields",
    "batch-reviewer-search-examples" => "loader/batch/reviewers/help/examples",
    "bulk-processing-logs-search-help" => "bulk_processing_logs/help/fields",
    "bulk-processing-logs-search-examples" => "bulk_processing_logs/help/examples",
    "user-search-help" => "users/help/fields",
    "user-search-examples" => "users/help/examples",
    "org-search-help" => "orgs/help/fields",
    "org-search-examples" => "orgs/help/examples",
  }.freeze

  REVIEW_MAP = {
    "loader-batch-search-help" => "loader/batches/help/review_fields",
    "loader-batch-search-examples" => "loader/batches/help/review_examples",
    "loader-name-search-help" => "loader/names/help/review_fields",
    "loader-name-search-examples" => "loader/names/help/review_examples",
  }.freeze
end
