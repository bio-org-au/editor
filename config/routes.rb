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
  match "/search/help/:help_id",
        as: "search_help", to: "search#help", via: :get

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

  # match "tree_elements/:id/tab/:tab", as: "tree_element_tab", to: "tree_elements#tab", via: :get
  namespace :tree do
    #match "tree_elements/:id/tab/:tab", as: "element_tab", to: "elements#tab", via: :get
    match "tree_elements/profile/:id", as: "element", to: "elements#update_profile", via: :patch
  end

  #match "tree_elements/profile/:id", as: "tree_element", to: "tree_elements#update_profile", via: :patch

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
  match "history/2023", to: "history#y2023", as: "history_2023", via: :get
  match "history/2022", to: "history#y2022", as: "history_2022", via: :get
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

  namespace :loader do
    match "batches/default_reference_suggestions", as: "batches_default_reference_suggestions", to: "batches#default_reference_suggestions", via: :get
    resources :batches
    match "batches/stats/hide", as: "hide_batch_stats", to: "batches#hide_stats", via: :get
    match "batches/stats/:id", as: "batch_stats", to: "batches#stats", via: :get
    match "batches/bulk", as: "batches_bulk", to: "batch/bulk#operation", via: :post
    match "batches/processing/overview", as: "batch_processing_overview", to: "batches#processing_overview", via: :get
    match "batches/processing/overview/hide", as: "batch_processing_overview_hide", to: "batches#hide_processing_overview", via: :get
    match "batches/bulk/processing/notes", as: "batch_bulk_processing_notes", to: "batches#bulk_processing_notes", via: :get
    match "batches/bulk/processing/notes/hide", as: "batch_bulk_processing_notes_hide", to: "batches#hide_bulk_processing_notes", via: :get
    match "batches/bulk/processing/stats/hide", as: "batch_bulk_processing_stats_hide", to: "batches#hide_bulk_processing_stats", via: :get
    #namespace :batch do
      #match "/unlock", as: "loader_batch_unlock", to: "unlock", via: :post
    #end
  end
  match "loader_batches/:id/tab/:tab", as: "loader_batch_tab", to: "loader/batches#tab", via: :get
  match "loader_batch/make-default/:id", as: "make_default_batch", to: "loader/batches#make_default", via: :post
  match "loader_batch/clear-default", as: "clear_default_batch", to: "loader/batches#clear_default", via: :post
  match "loader/batch/unlock", as: "loader_batch_unlock", to: "loader/batch/job_lock#unlock", via: :post

  namespace :loader do
    resources :names, only: [:new]
    match "names/new_row", as: "name_new_row", to: "names#new_row", via: :get
    match "names/new/:random_id", as: "name_new_with_random_id", to: "names#new", via: :get
    resources :names, only: [:create, :update, :destroy]
    namespace :name do
      match "matches/create/:id", as: "matches_set", to: "matches#set", via: :patch
      match "matches/delete/all/:id", as: "matches_delete_all", to: "matches#delete_all", via: :delete
      match "matches/use/batch/default/ref/:id", as: "matches_use_batch_default_ref", to: "matches#use_batch_default_ref", via: :patch
      match "matches/:id", as: "matches", to: "matches#set", via: :post
      match "matches/add_or_remove/:id", as: "match_add_or_remove", to: "matches#create_or_delete_for_misapp", via: :post
      match "matches/taxonomy-instance/:id", as: "taxonomy_instance", to: "matches#taxonomy_instance", via: :patch
      match "matches/use-batch-default-ref-form/:id", as: "matches_use_batch_default_ref_form", to: "matches#show_batch_default_ref_form", via: :get
      match "matches/use-existing-instance-form/:id", as: "matches_use_existing_instance_form", to: "matches#use_existing_instance_form", via: :get
      #match "matches/create-and-copy-form/:id", as: "matches_create_and_copy_form", to: "matches#create_and_copy_form", via: :get
      match "matches/copy-and-append-form/:id", as: "match_copy_and_append_form", to: "matches#copy_and_append_form", via: :get
      match "matches/use-existing-instance/:id", as: "matches_use_existing_instance", to: "matches#use_existing_instance", via: :patch
      match "matches/create-and-copy/:id", as: "matches_create_and_copy", to: "matches#create_and_copy", via: :patch
      match "matches/clear-taxonomy-nomination/:id", as: "match_clear_taxonomy_nomination", to: "matches#clear_taxonomy_nomination", via: :patch
      match "matches/clear-standalone-instance/:id", as: "match_clear_standalone_instance", to: "matches#clear_standalone_instance", via: :patch
      match "matches/clear-and-delete-standalone-instance/:id", 
        as: "match_clear_and_delete_draft_standalone_instance",
        to: "matches#clear_and_delete_draft_standalone_instance", via: :patch
      match "matches/clear-relationship-instance/:id", as: "match_clear_relationship_instance", to: "matches#clear_relationship_instance", via: :patch
      match "matches/clear-and-delete-relationship-instance/:id", as: "match-clear-and-delete-relationship-instance", to: "matches#clear_and_delete_relationship_instance", via: :patch
      resources :matches, only: [:update]
    end
  end
  match "loader_names/:id/tab/:tab", as: "loader_name_tab", to: "loader/names#tab", via: :get

  match "loader_names/:id/tab/:tab/:component", as: "loader_name_review_tab", to: "loader/names#tab", via: :get, defaults: { component: 'main' }
  match "loader_names/parent_suggestions",
        as: "loader_names_parent_suggestions",
        to: "loader/names#parent_suggestions",
        via: :get

  match "batch_reviews/:id/tab/:tab", as: "batch_review_tab", to: "loader/batch/reviews#tab", via: :get
  match "batch_reviews", as: "create_batch_review", to: "loader/batch/reviews#create", via: :post
  match "batch_reviews", as: "update_batch_review", to: "loader/batch/reviews#update", via: :put
  match "batch_reviews", as: "batch_review", to: "loader/batch/reviews#show", via: :get
  match "/batch_reviews/:id", as: "delete_batch_review", to: "loader/batch/reviews#destroy", via: :delete
  #resources :batch_reviews
  match "batch_review_periods", as: "create_batch_review_period", to: "loader/batch/review/periods#create", via: :post
  match "batch_review_periods", as: "review_period", to: "loader/batch/review/periods#show", via: :get
  match "batch_review_periods/:id/tab/:tab", as: "review_period_tab", to: "loader/batch/review/periods#tab", via: :get
  match "batch_review_periods/:id", as: "update_review_period", to: "loader/batch/review/periods#update", via: :patch
  match "/batch_review_periods/:id", as: "delete_review_period", to: "loader/batch/review/periods#destroy", via: :delete

  match "users", as: "user", to: "users#show", via: :get
  match "users/:id/tab/:tab", as: "user_tab", to: "users#tab", via: :get

  match "orgs", as: "org", to: "orgs#show", via: :get
  match "orgs/:id/tab/:tab", as: "org_tab", to: "orgs#tab", via: :get

  match "batch_reviewers", as: "batch_reviewer", to: "loader/batch/reviewers#show", via: :get
  match "batch_reviewers/:id/tab/:tab", as: "batch_reviewer_tab", to: "loader/batch/reviewers#tab", via: :get
  match "batch_reviewer", as: "loader_batch_reviewers", to: "loader/batch/reviewers#create", via: :post
  match "batch_reviewer/:id", as: "delete_batch_reviewer", to: "loader/batch/reviewers#destroy", via: :delete

  match "name_review_comments", as: "create_name_review_comment", to: "loader/name/review/comments#create", via: :post
  match "name_review_comments/:id", as: "edit_name_review_comment", to: "loader/name/review/comments#edit", via: :get
  match "name_review_comments/cancel/:id", as: "cancel_edit_name_review_comment", to: "loader/name/review/comments#cancel_edit", via: :get
  match "name_review_comments", as: "update_name_review_comment", to: "loader/name/review/comments#update", via: :patch
  match "name_review_comments/delete/dialog/:id", as: "dialog_to_delete_name_review_comment", to: "loader/name/review/comments#dialog_to_delete", via: :delete
  match "name_review_comments/cancel/delete/dialog/:id", as: "cancel_dialog_to_delete_name_review_comment", to: "loader/name/review/comments#cancel_dialog_to_delete", via: :get
  match "name_review_comments/:id", as: "delete_name_review_comment", to: "loader/name/review/comments#destroy", via: :delete

  match "switch_on_review_mode", as: "switch_on_review_mode", to: "loader/batch/review/mode#switch_on", via: :post
  match "switch_off_review_mode", as: "switch_off_review_mode", to: "loader/batch/review/mode#switch_off", via: :post

  match "/clear-connections", as: "clear_connections", to: "services#clear_connections", via: :get
  root to: "search#search"
  match "/*random", to: "search#search", via: [:get, :post, :delete, :patch]
end
