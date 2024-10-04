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
class ProfileReferencesController < ApplicationController
  # Render the add reference form dynamically via AJAX
  def render_add_reference
    profile_item_id = params[:profile_item_id]
    reference_annotation = params[:reference_annotation] || ""
    reference_id = params[:reference_id] || ""
    instance_id = params[:instance_id] || ""
  
    # Find or initialize @instance based on the passed parameters
    @instance = Instance.find(instance_id) if instance_id.present?
  
    render partial: 'instances/tabs/add_reference', 
           locals: { profile_item_id: profile_item_id, 
                     reference_annotation: reference_annotation, 
                     reference_id: reference_id, 
                     instance: @instance }
  end
  

  def create
    profile_item_id = params[:profile_item_id] rescue nil
    reference_id = params[:reference_id].present? ? params[:reference_id] : params[:reference_id_raw]
    # reference_id = 17521
    reference_annotation = params[:reference_annotation] rescue nil  # New annotation field

    # Attempt to find an existing ProfileItemReference
    @profile_reference = Profile::ProfileItemReference.find_by(profile_item_id: profile_item_id, reference_id: reference_id)
    if @profile_reference
      Rails.logger.debug "Updating Profile Reference with profile_item_id: #{profile_item_id} and reference_id: #{reference_id}"

      @profile_reference.update(
        annotation: ActiveRecord::Base.sanitize_sql(reference_annotation),
        updated_by: current_user_id
      )
      # Build the raw SQL update query
      # sql_update_query = <<-SQL
      #   UPDATE temp_profile.profile_reference
      #   SET annotation = '#{ActiveRecord::Base.sanitize_sql(reference_annotation)}',
      #       updated_at = '#{Time.current}',
      #       updated_by = '#{current_user_id}'
      #   WHERE profile_item_id = #{ActiveRecord::Base.sanitize_sql(profile_item_id)}
      #     AND reference_id = #{ActiveRecord::Base.sanitize_sql(reference_id)};
      # SQL
  
      # # Execute the raw SQL query
      # ActiveRecord::Base.connection.execute(sql_update_query)
    else
      # Create a new ProfileReference (Profile item can have multiple profile references)
      @profile_reference = Profile::ProfileItemReference.new(
        profile_item_id: profile_item_id,
        reference_id: reference_id,
        annotation: reference_annotation,  # Assign annotation to the annotation column
        created_by: current_user_id,
        updated_by: current_user_id
      )

      if @profile_reference.save
        Rails.logger.debug "New Profile Reference ID: #{@profile_reference.id}"  # Log the ID of the newly created record
        render json: { message: 'Profile reference created successfully.', reference: @profile_reference }, status: :created
      else
        render json: { errors: @profile_reference.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end


  private

  def current_user_id
    current_user&.id || 'system'
  end
end
