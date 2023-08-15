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
class Tree::Workspace::Placement < ActiveType::Object
  attribute :instance_id, :integer
  attribute :parent_element_link, :string
  attribute :excluded, :boolean
  attribute :username, :string
  attribute :profile, :hash
  attribute :version_id, :integer

  validates :instance_id, presence: true
  # validates :parent_element_link, presence: true
  validates :username, presence: true
  validates :version_id, presence: true

  def place
    url = build_url
    payload = { instanceUri: instance_url,
                parentElementUri: parent_element_link,
                excluded: excluded,
                profile: profile,
                versionId: version_id }
    logger.info "Calling #{url} with #{payload}"
    raise errors.full_messages.first unless valid?

    RestClient.put(url, payload.to_json,
                   { content_type: :json, accept: :json })
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Tree::Workspace::Placement RestClient::ExceptionWithResponse error: #{e.message}")
    raise
  rescue StandardError => e
    Rails.logger.error("Tree::Workspace::Placement other error: #{e}")
    raise
  end

  def build_url
    Tree::AsServices.placement_url(username, parent_element_link.blank?)
  end

  def instance_url
    Tree::AsServices.instance_url(instance_id)
  end
end

# From the Services log:
# =====================
# apni-editor is running as gclarke
# login took 6ms
# checking gclarke has role treebuilder
# get json http://localhost:8080/api/current-identity?uri=http%3A%2F%2Fid.biodiversity.org.au%2Finstance%2Fapni%2F51366428
# result status is 400 [action:placeElement,
#                       status:400,
#                       ok:false,
#                       error:Name Dendrobium aemulum x Dendrobium kingianum of rank Species is not below rank Species of Dendrobium aemulum.]
#

# From the Editor log for the same error:
# ======================================
# r6editor [gclarke] Calling http://localhost:9093/nsl/services/api/treeElement/placeElement?apiKey=dev-apni-editor&as=gclarke with {:instanceUri=>"http://id.biodiversity.org.au/instance/apni/51366428", :parentElementUri=>"/tree/51365924/51362490", :excluded=>false, :profile=>{"APC Dist."=>{:value=>"NSW", :updated_by=>"gclarke", :updated_at=>"2020-09-08T04:54:59Z"}}, :versionId=>51365924} (pid:36088)
# r6editor [gclarke] Tree::Workspace::Placement error: 400 Bad Request (pid:36088)
# r6editor [gclarke] OrchidsBatchController#add_instances_to_draft_tree: 400 Bad Request (pid:36088)
# r6editor [gclarke] /Users/greg/.gem/jruby/2.5.7/gems/rest-client-2.1.0/lib/restclient/abstract_response.rb:249:in `exception_with_response'
# ....stacktrace.....
