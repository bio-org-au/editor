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
class NamesDeletesController < ApplicationController
  # Confirm user wants to delete the name
  # Then delete it via a service call
  def confirm
    @names_delete = NamesDelete.new(names_delete_params)
    raise "Not confirmed" unless @names_delete.save! # i.e. confirmed

    delete_via_service(names_delete_params)
    render partial: "ok"
  rescue StandardError => e
    logger.error("Exception deleting name: #{e}")
    assemble_error_message(e)
    render partial: "error"
  end

  private

  def delete_via_service(names_delete_params)
    @name = Name::AsServices.find(names_delete_params[:name_id])
    @name.update_attribute(:updated_by, current_user.username)
    raise "Not saved" unless @name.delete_with_reason(
      @names_delete.assembled_reason
    )
  end

  def assemble_error_message(err)
    @message = err.to_s
    return if err.try("http_body").nil?

    json = JSON.parse err.http_body
    return if json["errors"].blank?

    @message += ": "
    @message += json["errors"].join(";")
  rescue StandardError => e
    logger.error("Exception assembling the error message: #{e}")
    @message += " (Problem assembling the error message: #{e})"
  end

  def build_form
    @name_delete = NameDelete.new
    @no_searchbar = true
    @no_search_result_details = true
    @no_menus = true
  end

  def names_delete_params
    params.require(:names_delete).permit(:name_id, :reason, :extra_info)
  end
end
