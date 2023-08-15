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

#  Tree services
class Tree::AsServices
  # Services
  API_KEY = "apiKey=#{Rails.configuration.try('api_key')}"

  SERVICES_ADDRESS = Rails.configuration.try("services")
  CLIENT_SIDE_SERVICES = Rails.configuration.try("services_clientside_root_url")
  PLACEMENT_PATH = "api/treeElement/placeElement"
  TOP_PLACEMENT_PATH = "api/treeElement/placeTopElement"
  REPLACE_ELEMENT = "api/treeElement/replaceElement"
  REPARENT_ELEMENT = "api/treeElement/changeParentElement"
  REMOVE_PLACEMENT = "api/treeElement/removeElement"
  UPDATE_PROFILE = "api/treeElement/editElementProfile"
  UPDATE_EXCLUDED = "api/treeElement/editElementStatus"
  CREATE_VERSION = "api/tree/createVersion"
  PUBLISH_VERSION = "api/treeVersion/publish"

  DIFF_LINK = "treeVersion/diff"
  VAL_LINK = "treeVersion/validate"
  SYN_LINK = "tree/eventReport"
  VAL_SYN_LINK = "tree/checkCurrentSynonymy"
  SYN_UPDATE_LINK = "tree-element/update-synonymy-by-event"
  SYN_UPDATE_INST_LINK = "tree-element/update-synonymy-by-instance"

  # Mapper
  MAPPER_API_URL = Rails.configuration.try("nsl_linker") || Rails.configuration.x.mapper_api.try("url")
  MAPPER_API_VERSION = Rails.configuration.x.mapper_api.try("version") || 1
  MAPPER_PWD = Rails.configuration.x.mapper_api.try("password")
  MAPPER_USER = Rails.configuration.x.mapper_api.try("username")

  def self.placement_url(username, top)
    if top
      "#{SERVICES_ADDRESS}#{TOP_PLACEMENT_PATH}?#{API_KEY}&as=#{username}"
    else
      "#{SERVICES_ADDRESS}#{PLACEMENT_PATH}?#{API_KEY}&as=#{username}"
    end
  end

  def self.reparent_placement_url(username)
    "#{SERVICES_ADDRESS}#{REPARENT_ELEMENT}?#{API_KEY}&as=#{username}"
  end

  def self.replace_placement_url(username)
    "#{SERVICES_ADDRESS}#{REPLACE_ELEMENT}?#{API_KEY}&as=#{username}"
  end

  def self.remove_placement_url(username)
    "#{SERVICES_ADDRESS}#{REMOVE_PLACEMENT}?#{API_KEY}&as=#{username}"
  end

  def self.preferred_link_url_v1(instance_id)
    "#{MAPPER_API_URL}broker/preferredLink?nameSpace=#{ShardConfig.name_space.downcase}&objectType=instance&idNumber=#{instance_id}"
  end

  def self.preferred_link_url_v2(instance_id)
    "#{MAPPER_API_URL}preferred-link/instance/#{ShardConfig.name_space.downcase}/#{instance_id}"
  end

  def self.profile_url(username)
    "#{SERVICES_ADDRESS}#{UPDATE_PROFILE}?#{API_KEY}&as=#{username}"
  end

  def self.excluded_url(username)
    "#{SERVICES_ADDRESS}#{UPDATE_EXCLUDED}?#{API_KEY}&as=#{username}"
  end

  def self.create_version_url(username)
    "#{SERVICES_ADDRESS}#{CREATE_VERSION}?#{API_KEY}&as=#{username}"
  end

  def self.publish_version_url(username)
    "#{SERVICES_ADDRESS}#{PUBLISH_VERSION}?#{API_KEY}&as=#{username}"
  end

  def self.add_instance_identifier_url_v1(instance_id)
    "#{MAPPER_API_URL}admin/addIdentifier?#{API_KEY}&#{add_identity_param_string(instance_id)}"
  end

  def self.add_identity_param_string(instance_id)
    "nameSpace=#{ShardConfig.name_space.downcase}&objectType=instance&idNumber=#{instance_id}&versionNumber=&uri="
  end

  def self.add_instance_identifier_url_v2(instance_id)
    "#{MAPPER_API_URL}add/instance/#{ShardConfig.name_space.downcase}/#{instance_id}"
  end

  def self.instance_url(instance_id)
    url = MAPPER_API_VERSION == 1 ? preferred_link_url_v1(instance_id) : preferred_link_url_v2(instance_id)
    response = RestClient.get(url, { content_type: :json, accept: :json })
    json = JSON.parse(response.body, object_class: OpenStruct)
    json.link
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Tree::AsServices instance_url rest_client_exception error: #{e.response}")
    add_instance_link(instance_id) if e.response.code == 404
  rescue StandardError => e
    Rails.logger.error("Tree::AsServices instance_url other error: #{e}")
    raise
  end

  # Mostly this won't get called because the services will pick up a new instance and add the URI before this is needed.
  # This will most probably happen if the services are busy, or the update polling is paused.
  def self.add_instance_link(instance_id)
    if MAPPER_API_VERSION == 1
      add_instance_link_v1(instance_id)
    else
      add_instance_link_v2(instance_id)
    end
  end

  def self.add_instance_link_v1(instance_id)
    url = add_instance_identifier_url_v1(instance_id)
    response = RestClient.put(url, {}.to_json, { content_type: :json, accept: :json })
    json = JSON.parse(response.body, object_class: OpenStruct)
    json.preferredURI
  rescue StandardError => e
    Rails.logger.error("Tree::AsServices add_instance_link_v1 error: #{e.response}")
    raise
  end

  def self.add_instance_link_v2(instance_id)
    jwt = mapper_auth
    url = add_instance_identifier_url_v2(instance_id)
    response = RestClient.put(url, {}.to_json,
                              { content_type: :json, accept: :json, authorization: "Bearer #{jwt.access_token}" })
    json = JSON.parse(response.body, object_class: OpenStruct)
    json.uri
  rescue RestClient::ExceptionWithResponse => e
    tag = "Tree::AsServices.add_instance_link_v2"
    Rails.logger.warn("#{tag} error: #{e.response}")
    raise unless e.response.code == 401

    Rails.logger.warn("#{tag} rescuing a 401 error, will log into mapper")
    jwt = force_mapper_auth
    response = RestClient.put(url, {}.to_json,
                              { content_type: :json, accept: :json, authorization: "Bearer #{jwt.access_token}" })
    json = JSON.parse(response.body, object_class: OpenStruct)
    json.uri
  rescue StandardError => e
    Rails.logger.error("Tree::AsServices add_instance_link_v2 error: #{e}")
    raise
  end

  def self.mapper_auth
    # using a class variable because we need a singleton instance variable to
    # keep this. Login should only be called
    # when we don't have the tokens
    $jwt ||= Tree::AsServices.mapper_login
    $jwt
  end

  def self.force_mapper_auth
    $jwt = Tree::AsServices.mapper_login
    $jwt
  end

  def self.mapper_login
    if MAPPER_USER
      url = "#{MAPPER_API_URL}login"
      payload = { username: MAPPER_USER, password: MAPPER_PWD }.to_json
      Rails.logger.info("Logging into mapper via url: #{url}.")
      response = RestClient.post(url, payload, { content_type: :json, accept: :json })
      JSON.parse(response.body, object_class: OpenStruct)
    end
  rescue StandardError => e
    Rails.logger.error("Tree::AsServices mapper_login error: Can't log in #{e}")
    raise
  end

  def self.diff_link(v1, v2)
    "#{CLIENT_SIDE_SERVICES}#{DIFF_LINK}?v1=#{v1}&v2=#{v2}&embed=true"
  end

  def self.syn_link(tree)
    "#{CLIENT_SIDE_SERVICES}#{SYN_LINK}?treeId=#{tree}&embed=true"
  end

  def self.syn_update_link(username)
    "#{CLIENT_SIDE_SERVICES}#{SYN_UPDATE_LINK}?#{API_KEY}&as=#{username}"
  end

  def self.update_synonymy(events, username)
    url = syn_update_link(username)
    Rails.logger.info "calling #{url}"
    RestClient.post(url, events, { accept: :json })
  end

  def self.syn_update_inst_link(username)
    "#{CLIENT_SIDE_SERVICES}#{SYN_UPDATE_INST_LINK}?#{API_KEY}&as=#{username}"
  end

  def self.update_synonymy_by_instance(instances, username)
    url = syn_update_inst_link(username)
    Rails.logger.info "calling #{url}"
    RestClient.post(url, instances, { accept: :json })
  end

  def self.val_syn_link(tree_version_id)
    "#{CLIENT_SIDE_SERVICES}#{VAL_SYN_LINK}?treeVersionId=#{tree_version_id}&embed=true"
  end

  def self.val_link(version)
    "#{CLIENT_SIDE_SERVICES}#{VAL_LINK}?version=#{version}&embed=true"
  end
end
