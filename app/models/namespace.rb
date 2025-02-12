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
# == Schema Information
#
# Table name: namespace
#
#  id               :bigint           not null, primary key
#  description_html :text
#  lock_version     :bigint           default(0), not null
#  name             :string(255)      not null
#  rdf_id           :string(50)
#
# Indexes
#
#  namespace_rdfid               (rdf_id)
#  uk_eq2y9mghytirkcofquanv5frf  (name) UNIQUE
#
class Namespace < ActiveRecord::Base
  self.table_name = "namespace"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"

  has_many :references, foreign_key: "namespace_id"
  has_many :names, foreign_key: "namespace_id"
  has_many :instances, foreign_key: "namespace_id"

  def self.default
    Namespace.first
  end
end
