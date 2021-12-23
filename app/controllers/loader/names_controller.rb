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
class Loader::NamesController < ApplicationController
  before_action :find_loader_name, only: [:show, :destroy, :tab]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == 'true'
    new_comment if params[:tab] =~ /\Atab_review\z/
    if @view_mode == 'review' then
      render "loader/names/review/show", layout: false
    else
      render "show", layout: false
    end
  end

  alias tab show

  def new_row
    @random_id = (Random.new.rand * 10_000_000_000).to_i
    respond_to do |format|
      format.html { redirect_to new_search_path }
      format.js {}
    end
  end

  private

  def find_loader_name
    @loader_name = Loader::Name.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the loader name record."
    redirect_to loader_names_path
  end

  def loader_name_params
    params.require(:loader_name).permit(:scientific_name)
  end

  def set_tab
    @tab = if params[:tab].present? && params[:tab] != "undefined"
             params[:tab]
           else
             "tab_details"
           end
  end

  def set_tab_index
    @tab_index = (params[:tabIndex] || "1").to_i
  end

  def new_comment
    if reviewer?
      @name_review_comment = @loader_name.name_review_comments.new(
        batch_reviewer_id: reviewer.id,
        loader_name_id: @loader_name.id,
        review_period_id: period.id)
    else
      nil
    end
  end

  def period
    @loader_name.batch.reviews&.first&.periods&.first
  end

  def reviewer?
    @loader_name.batch.reviews&.first&.periods&.first&.reviewers&.collect {|x| x.user.userid}&.include?(@current_user.username)
  end
  
  def reviewer
    @loader_name.batch.reviews&.first&.periods&.first.reviewers.select {|x| x.user.userid == @current_user.username}&.first
  end
end
