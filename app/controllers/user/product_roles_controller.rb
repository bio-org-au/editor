# frozen_string_literal: true

#   Copyright 2025 Australian National Botanic Gardens
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
# 2025-04-01 11:51:01.723 [fyi] r6editor Completed 200 OK in 29ms (Views: 13.8ms | ActiveRecord: 9.8ms | Allocations: 18493) (pid:44559)
# 2025-04-01 11:51:03.214 [fyi] r6editor Started POST "/nsl/editor/user_product_roles" for ::1 at 2025-04-01 11:51:03 +1100 (pid:44559)
# 2025-04-01 11:51:03.231 [omg] r6editor SyntaxError (/Users/gclarke/anbg/rails/nedruby/app/controllers/users/product_roles_controller.rb:105: syntax error, unexpected `end'):

# app/controllers/users/product_roles_controller.rb:105: syntax error, unexpected `end' (pid:44559)
# 2025-04-01 11:51:27.482 [fyi] r6editor Started POST "/nsl/editor/user_product_roles" for ::1 at 2025-04-01 11:51:27 +1100 (pid:44559)
# 2025-04-01 11:51:27.618 [omg] r6editor AbstractController::ActionNotFound (The action 'create' could not be found for Users::ProductRolesController):

class User::ProductRolesController < ApplicationController
  before_action :find_upr, only: %i[destroy]

  # POST 
  def create
    @upr = User::ProductRole.create(user_product_role_params, current_user.username)
  rescue StandardError => e
    @error = e.to_s
    logger.error("User::ProductRolesController#create:rescuing exception #{@error}")
    render "create_error", status: :unprocessable_content
  end

  def destroy
    @upr.destroy
  rescue StandardError => e
    @error = e.to_s
    logger.error("User::ProductRolesController#destroy:rescuing exception #{@error}")
    render "destroy_error", status: :unprocessable_content
  end

  def choose_product_for_role
  end

  private

  def find_upr
    @upr = User::ProductRole.find([params[:user_id], params[:product_role_id]])
  end

  def user_product_role_params
    params.require(:user_product_role).permit(:user_id, :product_role_id)
  end
end
