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

#  Name services
class Name::AsServices < Name
  NAME_SERVICES = Rails.configuration.try("name_services")
  def self.name_strings_url(id)
    "#{NAME_SERVICES}#{id}/api/name-strings"
  end

  def self.in_apc_url(id)
    "#{NAME_SERVICES}#{id}/api/apc"
  end

  def self.in_apni_url(id)
    "#{NAME_SERVICES}#{id}/api/apni"
  end

  def self.apni_family_url(id)
    "#{NAME_SERVICES}#{id}/api/family"
  end

  def self.delete_url(id, reason = "No longer required.")
    api_key = Rails.configuration.try("api_key")
    path = "#{id}/api/delete"
    encoded_reason = "#{ERB::Util.url_encode(reason)}"
    "#{NAME_SERVICES}#{path}?apiKey=#{api_key}&reason=#{encoded_reason}"
  end

  # Service will send back 200 even if delete fails, but will also sometimes
  # send back 404, so have to look at both.
  # The interface *should* never let a user try to delete a name that cannot be
  # deleted, so the chances of hitting a 'meaningful' error are [supposed to
  # be] small.
  # The service error messages are not suitable for showing to users. e.g.
  # "There are 1 that cite this.", raw database messages like multi-level
  # foreign key technical errors, but we get them often enough that we
  # need to pass them through to the application GUI.
  def delete_with_reason(reason)
    url = Name::AsServices.delete_url(id, reason)
    s_response = RestClient.delete(url, accept: :json)
    json = JSON.load(s_response)
    if s_response.code == 200 && json["ok"] == true
      true
    else
      log_error(url, s_response, json)
      preface = "Delete Service error:"
      raise "#{preface} #{json['errors'].try('join')} [#{s_response.code}]"
    end
  end

  def log_error(url, s_response, json)
    logger.error("Name::AsServices.delete url: #{url}")
    logger.error("Name::AsServices.delete s_response: #{s_response}")
    logger.error("Name::AsServices.delete errors: #{json['errors']}")
  end
end
