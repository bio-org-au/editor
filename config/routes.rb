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
Rails.application.routes.draw do
  resources :batches
  match "/feedback", as: "feedback", to: "feedback#index", via: :get
  match "/ping", as: "ping_service", to: "services#ping", via: :get
  match "services", as: "services", to: "services#index", via: :get

  resources :name_tag_names, only: [:show, :post, :create, :new]
  match "name_tag_names/:name_id/:tag_id",
        as: "delete_name_tag_name",
        to: "name_tag_names#destroy",
        via: :delete

  resources :name_tags, only: [:show]
  resources :comments, only: [:show, :new, :edit, :create, :update, :destroy]

  match "sign_in", as: "start_sign_in", to: "sessions#new", via: :get
  match "retry_sign_in",
        as: "retry_start_sign_in", to: "sessions#retry_new", via: :get
  match "sign_in", as: "sign_in", to: "sessions#create", via: :post
  match "sign_out", as: "sign_out", to: "sessions#destroy", via: :delete
  match "sign_out",
        as: "sign_out_get_for_firefox_bug", to: "sessions#destroy", via: :get
  match "throw_invalid_authenticity_token",
        to: "sessions#throw_invalid_authenticity_token", via: :get

  match "/search", as: "search", to: "search#search", via: :get
  match "/search/index", as: "search_index", to: "search#search", via: :get
  match "/search/tree", as: "tree", to: "search#tree", via: :get
  match "/search/preview", as: "search_preview", to: "search#preview", via: :get
  match "/search/extras/:extras_id",
        as: "search_extras", to: "search#extras", via: :get

  resources :instance_notes,
            only: [:show, :new, :edit, :create, :update, :destroy]

  match "instances/for_name_showing_reference",
        as: "typeahead_for_name_showing_references",
        to: "instances#typeahead_for_name_showing_references",
        via: :get

  match "instances/for_synonymy",
        as: "typeahead_for_synonymy",
        to: "instances#typeahead_for_synonymy",
        via: :get

  match "instances/for_name_showing_reference_to_update_instance",
        as: "typeahead_for_name_showing_references_to_update_instance",
        to: "instances#typeahead_for_name_showing_references_to_update_instance",
        via: :get

  match "instances/create_cited_by",
        as: "create_cited_by", to: "instances#create_cited_by", via: :post
  match "instances/create_cites_and_cited_by",
        as: "create_cites_and_cited_by",
        to: "instances#create_cites_and_cited_by",
        via: :post
  match "instances/:id/reference",
        as: "change_instance_reference",
        to: "instances#change_reference",
        via: :patch
  match "instances/:id/standalone/copy",
        as: "copy_standalone", to: "instances#copy_standalone", via: :post
  resources :instances, only: [:new, :create, :update, :destroy]
  match "instances/:id",
        as: "instance_show",
        to: "instances#show",
        via: :get,
        defaults: { tab: "tab_show_1" }
  match "instances/:id/tab/:tab",
        as: "instance_tab", to: "instances#tab", via: :get

  match "name/refresh_name_path/:id", as: "refresh_name_path", to: "names#refresh_name_path_field", via: :post
  match "name/refresh/:id", as: "refresh_name", to: "names#refresh", via: :get
  match "name/refresh/children/:id",
        as: "refresh_children_name",
        to: "names#refresh_children",
        via: :post
  match "names/typeaheads/for_unpub_cit/index",
        as: "names_typeahead_for_unpub_cit",
        to: "names/typeaheads/for_unpub_cit#index",
        via: :get

  match "names/typeahead_on_full_name",
        as: "names_typeahead_on_full_name",
        to: "names#typeahead_on_full_name",
        via: :get

  match "names/name_parent_suggestions",
        as: "name_name_parent_suggestions",
        to: "names#name_parent_suggestions",
        via: :get

  match "names/name_family_suggestions",
        as: "name_name_family_suggestions",
        to: "names#name_family_suggestions",
        via: :get

  match "suggestions/name/hybrid_parent",
        as: "name_hybrid_parent_suggestions",
        to: "names#hybrid_parent_suggestions",
        via: :get

  match "suggestions/name/cultivar_parent",
        as: "name_cultivar_parent_suggestions",
        to: "names#cultivar_parent_suggestions",
        via: :get

  match "suggestions/name/duplicate",
        as: "name_duplicate_suggestions",
        to: "names#duplicate_suggestions",
        via: :get

  match "suggestions/workspace/parent_name",
        as: "workspace_parent_name_suggestions",
        to: "names/typeaheads/for_workspace_parent_name#index",
        via: :get

  match "names/rules",
        as: "name_rules",
        to: "names#rules",
        via: :get

  match "names/new_row/:type",
        as: "name_new_row",
        to: "names#new_row",
        via: :get,
        type: /scientific|scientific_family|phrase|hybrid.*formula|hybrid-formula-unknown-2nd-parent|cultivar-hybrid|cultivar|other/
  match "names/:id/tab/:tab", as: "name_tab", to: "names#tab", via: :get
  match "names/:id/tab/:tab/as/:new_category",
        as: "name_edit_as_category", to: "names#edit_as_category", via: :get
  match "names/:id/copy", as: "name_copy", to: "names#copy", via: :post
  resources :names, only: [:new, :create, :update, :destroy]
  match "names/:id",
        as: "name_show",
        to: "names#show",
        via: :get,
        defaults: { tab: "tab_details" }
  match "names_delete",
        as: "names_deletes",
        to: "names_deletes#confirm",
        via: :delete

  match "names/duplicate/:id/transfer/dependents/:dependent_type/to/master",
        as: "name_transfer_dependents",
        to: "names#transfer_dependents",
        via: :post

  match "names/duplicate/transfer/all/dependents/:dependent_type/to/master",
        as: "name_transfer_all_dependents",
        to: "names#transfer_all_dependents",
        via: :post

  match "authors/typeahead_on_abbrev",
        as: "authors_typeahead_on_abbrev",
        to: "authors#typeahead_on_abbrev", via: :get
  match "authors/typeahead_on_name",
        as: "authors_typeahead_on_name",
        to: "authors#typeahead_on_name", via: :get
  match "authors/typeahead/on_name/duplicate_of/:id",
        as: "authors_typeahead_on_name_duplicate_of_current",
        to: "authors#typeahead_on_name_duplicate_of_current", via: :get
  match "authors/new_row",
        as: "author_new_row", to: "authors#new_row", via: :get
  match "authors/new/:random_id",
        as: "new_author_with_random_id", to: "authors#new", via: :get
  match "authors/:id/tab/:tab", as: "author_tab", to: "authors#tab", via: :get
  resources :authors, only: [:new, :create, :update, :destroy]
  match "authors/:id", as: "author_show",
        to: "authors#show",
        via: :get, defaults: { tab: "tab_show_1" }

  resources :orchids, only: [:new, :create, :update, :destroy]
  match "orchids/:id/tab/:tab", as: "orchid_tab", to: "orchids#tab", via: :get
  match "orchids/:id", as: "orchid_update", to: "orchids#update", via: :post
  resources :orchids_names, only: [:new, :create, :update, :destroy]
  match "orchids/new_row",
        as: "orchid_new_row", to: "orchids#new_row", via: :get
  match "orchids/new/:random_id",
        as: "new_orchid_with_random_id", to: "orchids#new", via: :get

  match "orchids/parent_suggestions",
        as: "orchid_parent_suggestions",
        to: "orchids#parent_suggestions",
        via: :get

  match "orchids/create/preferred/matches",
        as: "create_preferred_matches",
        to: "orchids_batch#create_preferred_matches", via: :post

  match "orchids/create/instances/for/preferred/matches",
        as: "create_instances_for_preferred_matches",
        to: "orchids_batch#create_instances_for_preferred_matches", via: :post

  match "orchids/add/instances/to/draft/tree",
        as: "add_instances_to_draft_tree",
        to: "orchids_batch#add_instances_to_draft_tree", via: :post

  match "orchids_batch_index", as: "orchids_batch_index",
        to: "orchids_batch#index", via: :get

  match "orchids/batch/progress", as: "orchids_batch_progress",
        to: "orchids_batch#submit", via: [:post]

  match "orchids/batch/clear", as: "orchids_batch_clear", to: "orchids_batch#clear", via: :get
  match "orchids/batch/jobs/lock", as: "orchids_batch_jobs_lock", to: "orchids_batch#lock", via: :post
  match "orchids/batch/enable/add", as: "orchids_batch_enable_add", to: "orchids_batch#enable_add", via: :post
  match "orchids/batch/disable/add", as: "orchids_batch_disable_add", to: "orchids_batch#disable_add", via: :post
  match "orchids/batch/unlock", as: "orchids_batch_unlock", to: "orchids_batch#unlock", via: :post
  match "orchids/batch/work/on/excluded", as: "orchids_batch_work_on_excluded", to: "orchids_batch#work_on_excluded", via: :post
  match "orchids/batch/work/on/accepted", as: "orchids_batch_work_on_accepted", to: "orchids_batch#work_on_accepted", via: :post

  match "trees/:id/tab/:tab", as: "tree_tab", to: "trees#tab", via: :get

  resources :tree_versions, only: [:new, :create, :update, :destroy]
  match "tree_versions/:id/tab/:tab", as: "tree_version_tab", to: "tree_versions#tab", via: :get

  match "tree_version_elements/:element_link/tab/:tab", as: "tree_version_element_tab", to: "tree_version_elements#tab", via: :get

  match "tree_elements/:id/tab/:tab", as: "tree_element_tab", to: "tree_elements#tab", via: :get

  match "references/typeahead/on_citation/duplicate_of/:id",
        as: "references_typeahead_on_citation_duplicate_of_current",
        to: "references#typeahead_on_citation_duplicate_of_current", via: :get
  match "references/typeahead/on_citation/exclude/:id",
        as: "references_typeahead_on_citation_with_exclusion",
        to: "references#typeahead_on_citation_with_exclusion", via: :get
  match "references/typeahead/on_citation",
        as: "references_typeahead_on_citation",
        to: "references#typeahead_on_citation", via: :get
  match "references/typeahead/on_citation/for_duplicate/:id",
        as: "references_typeahead_on_citation_for_duplicate",
        to: "references#typeahead_on_citation_for_duplicate", via: :get
  match "references/typeahead/on_citation/for_parent",
        as: "references_typeahead_on_citation_for_parent",
        to: "references#typeahead_on_citation_for_parent", via: :get
  match "references/new_row",
        as: "reference_new_row", to: "references#new_row", via: :get
  resources :references, only: [:new, :create, :update, :destroy]
  match "references/:id",
        as: "reference_show",
        to: "references#show",
        via: :get, defaults: { tab: "tab_show_1" }
  match "references/:id/tab/:tab",
        as: "reference_tab",
        to: "references#tab",
        via: :get,
        defaults: { tab: "tab_show_1" }
  match "references/:id/copy",
        as: "copy_reference",
        to: "references#copy",
        via: :post

  match "/admin", as: "admin", to: "admin#index", via: :get
  match "/admin/throw", as: "throw", to: "admin#throw", via: :get

  match "help/index", to: "help#index", via: :get
  match "help/instance_models",
        to: "help#instance_models", as: "instance_models", via: :get
  match "help/ref_type_rules",
        to: "help#ref_type_rules", as: "ref_type_rules", via: :get
  match "help/typeaheads", to: "help#typeaheads", as: "typeaheads", via: :get
  match "history/2021", to: "history#y2021", as: "history_2021", via: :get
  match "history/2020", to: "history#y2020", as: "history_2020", via: :get
  match "history/2019", to: "history#y2019", as: "history_2019", via: :get
  match "history/2018", to: "history#y2018", as: "history_2018", via: :get
  match "history/2017", to: "history#y2017", as: "history_2017", via: :get
  match "history/2016", to: "history#y2016", as: "history_2016", via: :get
  match "history/2015", to: "history#y2015", as: "history_2015", via: :get
  resources :instance_types, only: [:index]

  match "/set_include_common_and_cultivar",
        to: "search#set_include_common_and_cultivar",
        as: "set_include_common_and_cultivar",
        via: :post

  match "trees/ng/:template", as: "tree_ng", to: "trees#ng", via: :get

  match "trees/:id/remove_name_placement",
        as: "tree_remove_name",
        to: "trees#remove_name_placement",
        via: :delete

  match "trees/:id/place_name",
        as: "tree_place_name",
        to: "trees#place_name",
        via: [:patch, :post]

  match "trees/:id/replace_placement",
        as: "tree_replace_placement",
        to: "trees#replace_placement",
        via: [:patch, :post]

  match "trees/workspace/current",
        as: "toggle_current_workspace",
        to: "trees/workspaces/current#toggle",
        via: :post

  match "trees/update_comment",
        as: "tree_update_comment",
        to: "trees#update_comment",
        via: :post

  match "trees/update_distribution",
        as: "tree_update_distribution",
        to: "trees#update_distribution",
        via: :post

  match "trees/update_tree_parent",
        as: "tree_update_parent",
        to: "trees#update_tree_parent",
        via: :post


  match "trees/update_excluded",
        as: "tree_update_excluded",
        to: "trees#update_excluded",
        via: :post

  match "trees/new_draft",
        as: "trees_new_draft",
        to: "trees#new_draft",
        via: :get

  match "trees/create_draft",
        as: "trees_create_draft",
        to: "trees#create_draft",
        via: :post

  match "trees/edit_draft",
        as: "trees_edit_draft",
        to: "trees#edit_draft",
        via: :get

  match "trees/update_draft",
        as: "trees_update_draft",
        to: "trees#update_draft",
        via: :post

  match "trees/publish_draft",
        as: "trees_publish_draft",
        to: "trees#publish_draft",
        via: :get

  match "trees/publish",
        as: "trees_publish",
        to: "trees#publish_version",
        via: :post

  match "trees/reports",
        as: "trees_reports",
        to: "trees#reports",
        via: :get

  match "trees/update_synonymy",
        as: "trees_update_synonymy",
        to: "trees#update_synonymy",
        via: :post

  match "trees/update_synonymy_by_instance",
        as: "trees_update_synonymy_by_instance",
        to: "trees#update_synonymy_by_instance",
        via: :post

  match "search/reports",
        as: "search_reports",
        to: "search#reports",
        via: :get

  match "batch",
        as: "batch_index",
        to: "batches#index",
        via: :get

  match "password",
        as: "edit_password",
        to: "passwords#edit",
        via: :get

  match "password",
        as: "update_password",
        to: "passwords#update",
        via: :post

  match "/trees/show/cas", as: "show_cas", to: "trees#show_cas", via: :get
  match "/trees/run/cas", as: "run_cas", to: "trees#run_cas", via: :get
  match "/trees/show/diff", as: "show_diff", to: "trees#show_diff", via: :get
  match "/trees/run/diff", as: "run_diff", to: "trees#run_diff", via: :get
  match "/trees/show/valrep", as: "show_valrep", to: "trees#show_valrep", via: :get
  match "/trees/run/valrep", as: "run_valrep", to: "trees#run_valrep", via: :get

  resources :loader_batches
  match "loader_batches/:id/tab/:tab", as: "loader_batch_tab", to: "loader/batches#tab", via: :get
  resources :loader_names
  match "loader_names/:id/tab/:tab", as: "loader_name_tab", to: "loader/names#tab", via: :get
  match "batch_reviews/:id/tab/:tab", as: "batch_review_tab", to: "loader/batch/reviews#tab", via: :get
  match "batch_reviews", as: "create_batch_review", to: "loader/batch/reviews#create", via: :post
  match "batch_reviews", as: "update_batch_review", to: "loader/batch/reviews#update", via: :put
  match "batch_reviews", as: "batch_review", to: "loader/batch/reviews#show", via: :get
  match "/batch_reviews/:id", as: "delete_batch_review", to: "loader/batch/reviews#destroy", via: :delete
  #resources :batch_reviews
  match "batch_review_periods", as: "create_batch_review_period", to: "loader/batch/review_periods#create", via: :post
  match "batch_review_periods", as: "review_period", to: "loader/batch/review_periods#show", via: :get
  match "batch_review_periods/:id/tab/:tab", as: "review_period_tab", to: "loader/batch/review_periods#tab", via: :get
  match "batch_review_periods/:id", as: "update_review_period", to: "loader/batch/review_periods#update", via: :patch

  match "/clear-connections", as: "clear_connections", to: "services#clear_connections", via: :get
  root to: "search#search"
  match "/*random", to: "search#search", via: [:get, :post, :delete, :patch]
end
