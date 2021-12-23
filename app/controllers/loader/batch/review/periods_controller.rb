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
class Loader::Batch::Review::PeriodsController < ApplicationController
  before_action :find_review_period, only: [:show, :destroy, :tab, :update]

  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
    set_tab
    set_tab_index
    @take_focus = params[:take_focus] == 'true'
    calendar_events
    render "show", layout: false
  end

  alias tab show



  def calendar
    calendar_events
  end

  def calendar_events
    @review_days = []
    start_date = @review_period.start_date
    end_date = @review_period.end_date || start_date + 30
    (start_date..end_date).each do |day|
      case 
      when day === Date.today
      css_class = 'today'
      when day < Date.today
      css_class = 'past-day'
      else
      css_class = 'review-day'
      end
      @review_days.push(
        OpenStruct.new(name: "#{css_class}",start_time: Date.parse(day.to_s))
      )
    end
    #@review_days.push(OpenStruct.new(name: 'today',start_time: Date.today))
  end
  private :calendar_events

  # POST /review_periods
  def create
    @batch_review_period = ::Loader::Batch::Review::Period.create(review_period_params,
                                               current_user.username)
    render "create.js"
  rescue => e
    logger.error("Controller:Loader::Batch::Review::PeriodsController#create:rescuing exception #{e}")
    @error = e.to_s
    render "create_error.js", status: :unprocessable_entity
  end

  # POST /batch_reviews
  def update
    @message = @review_period.update_if_changed(review_period_params,
                                                current_user.username)
    render "update"
  rescue => e
    logger.error("Loader::Batch::Review.update:rescuing exception #{e}")
    @error = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def destroy
    @batch_review.destroy
  end

  private

  def find_review_period
    @review_period = Loader::Batch::Review::Period.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the batch review record."
    redirect_to batch_review_periods_path
  end

  def review_period_params
    params.require(:loader_batch_review_period).permit(:id, :name, :start_date, :end_date, :batch_review_id)
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
end
