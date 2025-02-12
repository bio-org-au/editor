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

#  A workspace or DraftVersion is an unpublished copy of a tree that can be edited.
# == Schema Information
#
# Table name: tree_version
#
#  id                  :bigint           not null, primary key
#  created_by          :string(255)      not null
#  draft_name          :text             not null
#  lock_version        :bigint           default(0), not null
#  log_entry           :text
#  published           :boolean          default(FALSE), not null
#  published_at        :timestamptz
#  published_by        :string(100)
#  created_at          :timestamptz      not null
#  previous_version_id :bigint
#  tree_id             :bigint           not null
#
# Foreign Keys
#
#  fk_4q3huja5dv8t9xyvt5rg83a35  (tree_id => tree.id)
#  fk_tiniptsqbb5fgygt1idm1isfy  (previous_version_id => tree_version.id)
#
class Tree::DraftVersion < ActiveRecord::Base
  self.table_name = "tree_version"
  self.primary_key = "id"
  default_scope { where(published: false) }

  belongs_to :tree,
             class_name: "Tree"

  has_many :tree_version_elements,
           foreign_key: "tree_version_id",
           class_name: "TreeVersionElement"

  def name
    name
  end

  def name_in_version(name)
    tree_version_elements.joins(:tree_element)
                         .where(tree_element: { name: name }).first
  end

  def self.create(tree_id, from_version_id, draft_name, draft_log, default_draft, username)
    url = Tree::AsServices.create_version_url(username)
    payload = { treeId: tree_id,
                fromVersionId: from_version_id,
                draftName: draft_name,
                log: draft_log,
                defaultDraft: default_draft }
    logger.info "Calling #{url} with #{payload}"
    RestClient::Request.execute(method: :put,
                                url: url,
                                payload: payload.to_json,
                                headers: { content_type: :json, accept: :json },
                                timeout: 360)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Tree::DraftVersion RestClient::ExceptionWithResponse error: #{e}")
    raise
  rescue StandardError => e
    Rails.logger.error("Tree::DraftVersion other error: #{e}")
    raise
  end

  def publish(username, next_draft_name)
    url = Tree::AsServices.publish_version_url(username)
    payload = { versionId: id,
                logEntry: log_entry,
                nextDraftName: next_draft_name }
    logger.info "Calling #{url} with #{payload}"
    RestClient.put(url, payload.to_json,
                   { content_type: :json, accept: :json })
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Tree::DraftVerson RestClient::ExceptionWithResponse error: #{e}")
    raise
  rescue StandardError => e
    Rails.logger.error("Tree::DraftVerson other error: #{e}")
    raise
  end

  def last_update
    tree_version_elements.order(updated_at: :desc).first
  end
end
