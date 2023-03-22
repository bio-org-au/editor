# frozen_string_literal: true

#   Copyright 2019 Australian National Botanic Gardens
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
class Password < ActiveType::Object
  attribute :current_password, :string
  validates :current_password, presence: true
  attribute :new_password, :string
  validates :new_password, presence: true
  attribute :new_password_confirmation, :string
  validates :new_password_confirmation, presence: true
  attribute :username, :string
  attribute :user_cn, :string

  def save!
    validate_arguments
    change_password
    true
  rescue => e
    # Hide the params because they contain password
    Rails.logger.error("Error changing password: #{e.to_s.sub(/ for .*/,'...')}")
    @error = e.to_s.sub(/ for .*/,'...')
    false
  end

  def error
    @error ||= ''
  end

  private

  def validate_arguments
    raise "No current password entered" if current_password.blank? 
    raise "No new password entered" if new_password.blank? 
    raise "Please also re-type the new password." if new_password_confirmation.blank? 
    unless new_password == new_password_confirmation
      raise "The new password doesn't match the re-typed new password."
    end
    unless new_password != current_password
      raise "The new password is the same as the current password you entered."
    end
    raise "The new password is not long enough." if new_password.size < 8
    raise "The new password is too long." if new_password.size > 50
    if Rails.configuration.try('ldap_via_active_directory')
      raise "The new password must contain at least one upper-case character A-Z." unless new_password.match(/[[:upper:]]/)
      raise "The new password must contain at least one lower-case character a-z." unless new_password.match(/[[:lower:]]/)
      raise "The new password must contain at least one symbol or digit." unless new_password.match(/[\d\W]/) # a digit or non-word char
    end
  end

  def change_password
    ldap = Ldap.new
    ldap.username = username
    ldap.password = current_password
    ldap.user_cn = user_cn
    raise 'current password is wrong' unless ldap.verify_current_password
    ldap.change_password(username, new_password,random_seed)
  end

  def random_seed
    (0...8).map { (97 + rand(26)).chr }.join
  end
end
