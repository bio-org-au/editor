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
    user ||= User.new(groups: [])
    basic_auth_1
    basic_auth_2
    edit_auth if user.edit?
    qa_auth if user.qa?
    # TODO: remove this - NSL-2007
    apc_auth if user.apc?
    admin_auth if user.admin?
    treebuilder_auth if user.treebuilder?
    orchids_matcher_auth if user.orchids_matcher?
    reviewer_auth if user.reviewer?
    batch_loader_auth if user.batch_loader?
  end

  def basic_auth_1
    can "application",        "set_include_common_cultivars"
    can "authors",            "tab_show_1"
    can "orchids",            "tab_show_1"
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
    can "passwords",          "update"
  end

  def edit_auth
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
    can "batches",                   :all
    can "tree_versions",             :all
    can "tree_version_elements",     :all
    can "tree_elements",             :all
    can "mode",                      :all # suspect this is no longer used
    can "tree_versions",             :all
    can "users",                       :all
    can "orgs",                        :all
  end

  # TODO: remove this - NSL-2007
  def apc_auth
    can "apc",                "place"
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
  end

  def batch_loader_auth
    can "loader/batches",              :all
    can "loader/names",                :all
    can "loader/name/matches",         :all
    can "loader/batch/reviews",        :all
    can "loader/batch/reviewers",      :all
    can "loader/batch/review/periods", :all
    can "loader/batch/bulk",           :all
    can "loader/batch/job_lock",       :all
  end

  def orchids_matcher_auth
    can "orchids",                     :all
    can "orchids_batch",               :all
    can "orchids_names",               :all
  end

  def reviewer_auth
    can "loader/name/review/comments", :all
    can "loader/batch/review/mode",    "switch_on"
    can "loader/names",                "show"
    can "loader/names",                "tab_details"
    can "loader/names",                "tab_comment"
  end
end
