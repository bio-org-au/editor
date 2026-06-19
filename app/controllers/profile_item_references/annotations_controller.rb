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
module ProfileItemReferences
  class AnnotationsController < ApplicationController
    skip_before_action :authorise

    before_action :set_profile_item_reference
    before_action :authorise_user!

    def destroy
      @profile_item = @profile_item_reference.profile_item
      @profile_item_reference.update!(annotation: nil, updated_by: current_user.username)
      @message = "Annotation deleted"
      render :delete
    rescue StandardError => e
      @message = e.to_s
      render :delete_failed, status: :unprocessable_content
    end

    private

    def authorise_user!
      raise CanCan::AccessDenied.new("Access Denied!", :manage, @profile_item_reference) unless can? :manage, @profile_item_reference
    end

    def set_profile_item_reference
      profile_item_id, reference_id = params[:id].split("_")
      @profile_item_reference = Profile::ProfileItemReference.find_by!(
        profile_item_id: profile_item_id,
        reference_id: reference_id
      )
    end
  end
end
