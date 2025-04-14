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
# Central authorisations
class Ability
  include CanCan::Ability
  # The first argument to `can` is the action you are giving the user
  # permission to do.
  # If you pass :manage it will apply to every action. Other common actions
  # here are :read, :create, :update and :destroy.
  #
  # The second argument is the resource the user can perform the action on.
  # If you pass :all it will apply to every resource. Otherwise pass a Ruby
  # class of the resource.
  #
  # The third argument is an optional hash of conditions to further filter the
  # objects.
  # For example, here the user can only update published articles.
  #
  #   can :update, Article, :published => true
  #
  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  #

  # Some users can login but have no groups allocated.
  # By default they can "read" - search and view data.
  # We could theoretically relax authentication and have these
  # authorization checks prevent non-editors changing data.
  def initialize(user)
    user ||= SessionUser.new(groups: [])
    basic_auth_1
    basic_auth_2

    edit_auth         if user.edit?
    qa_auth           if user.qa?
    admin_auth        if user.admin?
    treebuilder_auth  if user.treebuilder?
    reviewer_auth     if user.reviewer?
    batch_loader_auth if user.batch_loader?
    loader_2_tab_auth if user.loader_2_tab_loader?

    # NOTES: Broader permissions come first
    draft_editor(user) if user.with_role?('draft-editor')
    profile_editor if user.with_role?('profile-editor')
    draft_profile_editor if user.with_role?('draft-profile-editor')
  end

  def draft_profile_editor
    can :manage, :profile_v2
    can :manage_profile, Instance do |instance|
      instance.draft?
    end
    can [:create, :read], Author
    can :update, Author do |author|
      !author.referenced_in_any_instance? && author.no_other_authored_names?
    end
    can :manage, Profile::ProfileItem do |profile_item|
      profile_item.is_draft?
    end
    can [:read, :create], Profile::ProfileItem
    can :manage, Profile::ProfileItemReference do |profile_item_reference|
      profile_item_reference.profile_item.is_draft?
    end
    can :manage, Profile::ProfileText do |profile_text|
      profile_text.profile_item.is_draft?
    end
    can :manage, Profile::ProfileItemAnnotation do |profile_item_annotation|
      profile_item_annotation.profile_item.is_draft?
    end
    can :create, Reference
    can :update, Reference do |reference|
      reference.instances.blank?
    end
    can "authors", :all
    can "instances", ["tab_details", "tab_profile_v2"]
    can "menu", "new"
    can "profile_items", :all
    can "profile_item_annotations", :all
    can "profile_item_references", :all
    can "references", [
      "new_row",
      "new",
      "typeahead_on_citation_for_parent",
      "typeahead_on_citation",
      "create",
      "tab_edit_1",
      "tab_edit_2",
      "tab_edit_3",
      "update"
    ]
  end

  def draft_editor(user)
    can :create_with_product_reference, Instance
    can :copy_as_draft_secondary_reference, Instance
    can [
      :destroy,
      :manage_draft_secondary_reference,
      :synonymy_as_draft_secondary_reference,
      :unpublished_citation_as_draft_secondary_reference
    ], Instance do |instance|
      instance.draft? && instance.reference.products.pluck(:name).any?(user.product_from_roles&.name.to_s)
    end
    can "instances", "create"
    can "instances", "tab_edit"
    can "instances", "tab_edit_profile_v2"
    can "instances", "update"
    can "instances", "destroy"
    can "instances", "tab_copy_to_new_profile_v2"
    can "instances", "copy_for_profile_v2"
    can "instances", "tab_synonymy_for_profile_v2"
    can "instances", "typeahead_for_synonymy"
    can "instances", "create_cites_and_cited_by"
    can "instances", "create_cited_by"
    can "instances", "tab_unpublished_citation_for_profile_v2"
    can "names/typeaheads/for_unpub_cit", "index"
    can "names", "tab_instances_profile_v2"
  end

  def profile_editor
    can :manage, :profile_v2
    can :manage, Profile::ProfileItem
    can :manage, Profile::ProfileItemReference
    can :manage, Profile::ProfileText
    can :manage, Profile::ProfileItemAnnotation
    can "references", "typeahead_on_citation"
    can "profile_items", :all
    can "profile_item_annotations", :all
    can "profile_item_references", :all
    can "instances", "tab_details"
    can "instances", "tab_profile_v2"
  end

  def profile_v2_auth
    # can :manage, :all   # NOTES: This is not working. It breaks everything.
    can :manage, :profile_v2
    can :manage, Profile::ProfileItem
    can :manage, Profile::ProfileItemReference
    can :manage, Profile::ProfileText
    can :manage, Profile::ProfileItemAnnotation
    can "profile_items", :all
    can "profile_item_annotations", :all
    can "profile_item_references", :all
    can "profile_texts", :all
    can "instances", "tab_profile_v2"
    can "references", "typeahead_on_citation"
    can "instances", "tab_copy_to_new_profile_v2"
    can "instances", "tab_unpublished_citation_for_profile_v2"
    can "instances", "copy_for_profile_v2"
    can "instances", "tab_details"
    can "names/typeaheads/for_unpub_cit", "index"
    can "instances", "create_cited_by"
    can "instances", "create_cites_and_cited_by"
    can "instances", "create"
    can "instances", "tab_synonymy_for_profile_v2"
    can "instances", "typeahead_for_synonymy"
  end

  def basic_auth_1
    can "application",        "set_include_common_cultivars"
    can "authors",            "tab_show_1"
    can "help",               :all
    can "history",            :all
    can "instance_types",     "index"
    can "instances",          "tab_show_1"
    can "instances",          "update_reference_id_widgets"
    can "menu",               "help"
    can "menu",               "user"
    can "menu",               "admin" # config is the only option
    can "admin",              "index" # allows viewing of the config
  end

  def basic_auth_2
    can "names",              "rules"
    can "names",              "tab_details"
    can "references",         "tab_show_1"
    can "search",             :all
    can "new_search",         :all
    can "services",           :all
    can "sessions",           :all
    can "trees",              "ng"
    can "passwords",          "edit"
    can "passwords",          "show_password_form"
    can "passwords",          "password_changed"
    can "passwords",          "update"
  end

  def edit_auth
    can :manage,              Author
    can :manage,              Reference
    can [
      :create,
      :edit,
      :update,
      :destroy
    ], Instance
    can "authors",            :all
    can "comments",           :all
    can "instances",          :all
    can "instances",          "copy_standalone"
    can "instance_notes",     :all
    can "menu",               "new"
    can "name_tag_names",     :all
    can "names",              :all
    can "names_deletes",      :all
    can "references",         :all
    can "names/typeaheads/for_unpub_cit", :all
    can "loader/batch/review/mode", "switch_off"
  end

  def qa_auth
    can "de_duplicates",              :all
    can "tree_versions",             :all
    can "tree_version_elements",     :all
    can "tree_elements",             :all
    can "mode",                      :all # suspect this is no longer used
    can "tree_versions",             :all
    can "orgs",                      :all
  end

  def treebuilder_auth
    can "classification",     "place"
    can "trees",               :all
    can "workspace_values",    :all
    can "trees/workspaces/current", "toggle"
    can "names/typeaheads/for_workspace_parent_name", :all
    can "menu", "tree"
    can "tree_elements",       :all
    can "tree/elements",       :all
  end

  def admin_auth
    can "admin",              :all
    can "menu",               "admin"
    can "users",              :all
    can "user/product_roles", :all
  end

  def batch_loader_auth
    can "loader/batches",              :all
    can "loader/names",                :all
    can "loader/name/matches",         :all
    can "loader/name/match/suggestions/for_intended_tree_parent", :all
    can "loader/batch/reviews",        :all
    can "loader/batch/reviewers",      :all
    can "loader/batch/review/periods", :all
    can "loader/batch/bulk",           :all
    can "loader/batch/job_lock",       :all
    can "menu",                        "batch"
  end

  def loader_2_tab_auth
    can "loader/instances-loader-2",   :all
  end

  def reviewer_auth
    can "loader/name/review/comments",              :all
    can "loader/name/review/votes",                 :all
    can "loader/name/review/vote/in_bulk",          :all
    can "loader/batch/review/mode",                 "switch_on"
    can "loader/names",                             "show"
    can "loader/names",                             "tab_details"
    can "loader/names",                             "tab_comment"
    can "loader/names",                             "tab_vote"
  end
end
