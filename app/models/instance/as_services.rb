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
class Instance::AsServices < Instance
  def self.name_strings_url(id)
    "#{Rails.configuration.try('name_services')}#{id}/api/name-strings"
  end

  def self.tag
    "Instance::AsServices"
  end

  # Service will send back 200 even if delete fails, but will also sometimes
  # send back 404, so have to look at both. Sigh.
  #
  # (PMc Note) Actually...A 404 is sent if the target is not found, but
  # when the target of the delete *is* found but you can't delete it because
  # it is referenced, you get a 403 Forbidden. Looking at it again we should 
  # possibly return 409 conflict... don't you love interpreting standards (RFC 7231)
  #
  # The interface *should* never let a user try to delete an instance
  # that cannot be deleted, so the chances of hitting a 'meaningful' error
  # should be small but experience has shown this happens.
  # The service error messages are not always good for showing to users, but
  # users need to see them, so we attribute them.
  #
  # RestClient throws exceptions for 403, 404 type errors and we handle those
  # based on the structured response to extract a meaningful message.
  #
  #
  #
  #
  # No, actually, the deleting agent should return an error when the requested 
  # action fails, and this delete request is still silently failing to delete
  # as I test the code now.  Silent failure results in unreliable engineering, 
  # however dressed up. Fail loudly is the principle.  GUIs guide users in what
  # they can do, but the application has to protect the data regardless.
  #
  # Noting that Services sends poorly phrased errors such as:
  #   "There are 1 instances that say this cites it."
  # The Editor shows the Services error to the user for transparency.
  def self.delete(id)
    instance = Instance.find_by(id: id)
    url = delete_uri(id)
    response = RestClient.delete(url, accept: :json)

    delay = Rails.configuration.try('instance_delete_delay_seconds') || 3
    logger.info("#{tag} sleeping #{delay}sec before checking services delete")
    sleep(delay)

    records = Instance.where(id: id)
      .where(instance_type_id: instance.try(:instance_type_id)).reload
    throw "Check after #{delay}s shows record not deleted" unless records.blank?
  rescue RestClient::ExceptionWithResponse => rest_client_exception
    case rest_client_exception.response.code
    when 403
      logger.error("#{tag} 403 from Services delete ##{instance.try('id')}")
      raise " from Services: #{rest_client_exception}" 
    when 404
      logger.error("#{tag} 404 from Services delete ##{instance.try('id')}")
      logger.error("Editor will now delete instance #{instance.try('id')}")
      instance.try('destroy')
      logger.info("Instance destroyed or didn't exist")
    else
      logger.error("#{tag}.delete unexpected response #{rest_client_exception.response.code} on ##{instance.id}")
      logger.error("Instance::AsServices.delete exception for url: #{url}")
      raise " from Services: #{rest_client_exception}" 
    end
  rescue
    logger.error("#{tag}.delete exception for url: #{url}")
    raise
  end

  def self.delete_uri(id)
    api_key = Rails.configuration.try('api_key')
    host_path = "#{Rails.configuration.try('services')}rest/instance/apni/#{id}/api/delete"
    "#{host_path}?apiKey=#{api_key}&reason=Edit"
  end
end
