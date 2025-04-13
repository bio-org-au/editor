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
# Period end_date needs processing when arriving as 3-part parameter from GUI
module Loader::Batch::Review::Period::DigestEndDate
  extend ActiveSupport::Concern

  # The end_date params need extra validation because we
  #   include_blank: true
  # in the date_select options and this allows
  # a range of invalid cases e.g. missing day, missing month, missing year
  # and also the special case of all selects being blank which means no end_date.
  #
  # We also have to handle the case of dates like 30-Feb-2025 being entered.
  def assign_end_date_if_changed(params)
    if end_date_blank?(params)
      self.end_date = nil if end_date_blank?(params)
    elsif end_date_part_is_missing?(params)
      raise "End date is incomplete"
    else
      date_s = end_date_parts_to_string(params)
      self.end_date = Date.parse(date_s) unless end_date.to_s == date_s
    end
  rescue Date::Error => e
    handle_end_date_error(e, date_s)
  end

  def end_date_blank?(params)
    params["end_date(3i)"].blank? && params["end_date(2i)"].blank? && params["end_date(1i)"].blank?
  end

  def end_date_part_is_missing?(params)
    params["end_date(3i)"].blank? || params["end_date(2i)"].blank? || params["end_date(1i)"].blank?
  end

  def end_date_parts_to_string(params)
    year = params["end_date(1i)"]
    month = format("%02d", params["end_date(2i)"])
    day = format("%02d", params["end_date(3i)"])
    "#{year}-#{month}-#{day}"
  end

  def handle_end_date_error(err, date_s)
    logger.error(err.to_s)
    message = "Invalid end date: #{date_s}"
    raise message
  end
end
