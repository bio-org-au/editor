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
class NamesDelete < ActiveType::Object
  attribute :name_id, :integer
  attribute :reason, :string
  attribute :extra_info, :string
  after_initialize :default_values

  validates :name_id, presence: true
  validates :reason, presence: true
  validates :extra_info,
            if: :reason_is_other?,
            presence: { message: "can't be blank when you choose 'Other'." }

  def possible_reasons
    ["Name does not exist",
     "Name is represented elsewhere in NSL",
     "Name has not been applied to Australian taxa",
     "Name is an autonym that has not yet been established",
     "Other"]
  end

  def assembled_reason
    if extra_info.blank?
      reason
    else
      "#{reason}; #{extra_info}"
    end
  end

  private

  def default_values
    self.reason ||= "for some reason"
  end

  def reason_is_other?
    reason.present? && reason.strip.match(/\Aother\z/i)
  end
end
