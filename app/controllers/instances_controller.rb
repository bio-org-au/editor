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

#   Controls instances.
class InstancesController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_action :find_instance, only: [:show, :tab, :destroy]
  # todo refactor validation error checks to not rely on a copied string comparison as this is very fragile
  CONCEPT_WARNING = "Validation failed: You are trying to change an accepted concept's synonymy."

  # GET /instances/1
  # GET /instances/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    logger.debug("InstancesController::show")
    @tab = tab_or_default_tab
    @tab_index = (params[:tabIndex] || "1").to_i
    @tabs_to_offer = tabs_to_offer
    # Really only need to do this if the "class" tab is chosen.
    unless @working_draft.blank?
      @tree_version_element = @working_draft.name_in_version(@instance.name)
      @parent_tve = find_a_parent(@instance.name)
    end
    @accepted_tve = @instance.name.accepted_tree_version_element
    @take_focus = params[:take_focus] == 'true'
    render "show", layout: false
  end

  alias tab show

  # Create the lesser version of relationship instance.
  def create_cited_by
    logger.debug("create_cited_by")
    resolve_unpub_citation_name_id(instance_params[:name_id],
                                   instance_name_params[:name_typeahead])
    if instance_params[:name_id].blank?
      render_create_error("You must choose a name.", "instance-name-typeahead")
    elsif instance_params[:instance_type_id].blank?
      render_create_error("You must choose an instance type.",
                          "instance_instance_type_id")
    else
      create(instance_params, "create_unpub")
    end
  rescue => e
    render_create_error(e.to_s, "instance-name-typeahead")
  end

  # Create full synonymy instance.
  def create_cites_and_cited_by
    logger.debug("create_cites_and_cited_by")
    if instance_params[:cites_id].blank?
      render_cites_id_error
    elsif instance_params[:cited_by_id].blank?
      render_cited_by_id_error
    elsif instance_params[:instance_type_id].blank?
      render_instance_type_id_error
    else
      create(build_the_params, "create")
    end
  end

  # Core create action.
  # Sometimes we need to massage the params (safely) before calling this create.
  def create(the_params = instance_params, view_to_render = "create")
    @instance = Instance.new(the_params)
    check_for_overrides
    @instance.save_with_username(current_user.username)
    render view_to_render
  rescue ActiveRecord::RecordNotUnique
    handle_not_unique
  rescue => e
    handle_other_errors(e)
  end

  def check_for_overrides
    @instance.concept_warning_bypassed =
      instance_params[:concept_warning_bypassed] == "1"
    @instance.multiple_primary_override =
      instance_params[:multiple_primary_override] == "1"
    @instance.duplicate_instance_override =
      instance_params[:duplicate_instance_override] == "1"
    prevent_double_overrides
  end
  private :check_for_overrides

  def prevent_double_overrides
    if @instance.multiple_primary_override &&
        @instance.duplicate_instance_override
      @instance.multiple_primary_override = false
      @instance.duplicate_instance_override = false
    end
  end
  private :prevent_double_overrides

  # Copy an instance with its citations
  def copy_standalone
    logger.debug("copy_standalone")
    current_instance = Instance::AsCopier.find(params[:id])
    current_instance.multiple_primary_override =
      instance_params[:multiple_primary_override] == "1"
    current_instance.duplicate_instance_override =
      instance_params[:duplicate_instance_override] == "1"
    @instance = current_instance.copy_with_citations_to_new_reference(
      instance_params, current_user.username
    )
    @message = "Instance was copied"
    render "instances/copy_standalone/success"
  rescue => e
    handle_other_errors(e,'instances/copy_standalone/error')
  end

  def handle_not_unique
    @message = "Error: duplicate record"
    render "create_error", status: :unprocessable_entity
  end
  private :handle_not_unique

  def handle_other_errors(e, file_to_render = "create_error")
    logger.debug('handle_other_errors')
    errors = ErrorAsArrayOfMessages.new(e).error_array
    if errors.size <= 1
      @allow_bypass = errors.first.match(/\A#{CONCEPT_WARNING}\z/)
      @multiple_primary_override = errors.first.match(/#{Instance::MULTIPLE_PRIMARY_WARNING}\z/) ? true : false
      @duplicate_instance_override = errors.first.match(/#{Instance::DUPLICATE_INSTANCE_WARNING}\z/) ? true : false
    end
    @message = errors
    render file_to_render, status: :unprocessable_entity
  end
  private :handle_other_errors

  # PUT /instances/1
  # PUT /instances/1.json
  def update
    @instance = Instance::AsEdited.find(params[:id])
    @message = @instance.update_if_changed(instance_params,
                                           current_user.username)
    render "update"
  rescue => e
    handle_other_errors(e, 'update_error')
  end

  # PUT /instances/reference/1
  # PUT /instances/reference/1.json
  # Changing the reference for an instance is a special case -
  # there may/will exist denormalised ids in dependent instances.
  # We have to temporarily bypass some validations to sort it out.
  def change_reference
    @message = "No change"
    @instance = Instance.find(params[:id])
    @instance.assign_attributes(instance_params)
    make_back_door_changes if @instance.changed?
    render "update"
  rescue => e
    logger.error(e.to_s)
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def make_back_door_changes
    @instance_back_door = InstanceBackDoor.find(params[:id])
    @instance_back_door.change_reference(instance_params,
                                         current_user.username)
    @message = "Updated"
  end

  # DELETE /instances/1
  def destroy
    @instance.delete_as_user(current_user.username)
  rescue => e
    logger.error("Instance#destroy exception: #{e}")
    @message = e.to_s
    render "destroy_error", status: 422
  end

  def typeahead_for_synonymy
    instances = Instance::AsTypeahead::ForSynonymy.new(params[:term],
                                                       params[:name_id])
    render json: instances.results
  end

  # Expect instance id - of the instance user is updating.
  # Synonym Edit tab.
  def typeahead_for_name_showing_references_to_update_instance
    typeahead = Instance::AsTypeahead::ForNameShowingReferences.new(params)
    render json: typeahead.references
  end

  private

  def find_instance
    @instance = Instance.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the instance."
    redirect_to instances_path
  end

  def instance_params
    params.require(:instance).permit(:instance_type,
                                     :name_id,
                                     :reference_id,
                                     :instance_type_id,
                                     :verbatim_name_string,
                                     :page,
                                     :cites_id,
                                     :cited_by_id,
                                     :bhl_url,
                                     :concept_warning_bypassed,
                                     :multiple_primary_override,
                                     :duplicate_instance_override,
                                     :draft,
                                     :parent_id)
  end

  def instance_name_params
    params.require(:instance).permit(:name_id, :name_typeahead)
  end

  def tab_or_default_tab
    if params[:tab] && !params[:tab].blank? && params[:tab] != "undefined"
      params[:tab]
    else
      "tab_show_1"
    end
  end

  # Different types of instances require different sets of tabs.
  def tabs_to_offer
    offer = %w(tab_show_1 tab_edit tab_edit_notes)
    if @instance.simple?
      offer << "tab_synonymy"
      offer << "tab_unpublished_citation"
      offer << "tab_classification"
      offer << "tab_profile_details" if @instance.profile?
      offer << "tab_edit_profile" if @instance.profile? && @instance.show_apc?
    end
    offer << "tab_comments"
    offer << "tab_copy_to_new_reference" if offer_tab_copy_to_new_ref?
    offer
  end

  def offer_tab_copy_to_new_ref?
    @instance.simple? &&
      params["row-type"] == "instance_as_part_of_concept_record"
  end

  def render_create_error(base_error_string, focus_id)
    @instance = Instance.new
    @instance.errors.add(:base, base_error_string)
    @message = base_error_string
    render "create_error", locals: { focus_on_this_id: focus_id }
  end

  def render_cites_id_error
    render_create_error(
      "You must choose an instance.",
      "instance-instance-for-name-showing-reference-typeahead"
    )
  end

  def render_cited_by_id_error
    render_create_error(
      "Please refresh the tab.",
      "instance-instance-for-name-showing-reference-typeahead"
    )
  end

  def render_instance_type_id_error
    render_create_error(
      "You must choose an instance type.",
      "instance_instance_type_id"
    )
  end

  def cites_and_cited_by
    [Instance.find(instance_params[:cites_id]),
     Instance.find(instance_params[:cited_by_id])]
  end

  def build_the_params
    cites, cited_by = cites_and_cited_by
    build_them(cites, cited_by)
  end

  def build_them(cites, cited_by)
    { name_id: cites.name.id,
      cites_id: cites.id,
      cited_by_id: cited_by.id,
      reference_id: cited_by.reference.id,
      instance_type_id: instance_params[:instance_type_id],
      verbatim_name_string: instance_params[:verbatim_name_string],
      bhl_url: instance_params[:bhl_url],
      draft: instance_params[:draft],
      page: instance_params[:page] }
  end

  def resolve_unpub_citation_name_id(name_id, name_typeahead)
    return unless instance_params[:name_id].blank?
    params[:instance][:name_id] = Name::AsResolvedTypeahead::ForUnpubCitationInstance.new(name_id, name_typeahead).value
  end

  def find_a_parent(parent)
    while parent
      parent_tve = @working_draft.name_in_version(parent)
      return parent_tve if parent_tve
      parent = parent.parent
    end
    @working_draft.tree_version_elements.order(tree_element_id: 'asc').first
  end
end
