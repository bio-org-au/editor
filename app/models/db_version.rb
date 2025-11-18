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
# Table name: db_version
#
#  id      :bigint           not null, primary key
#  version :integer          not null
#
class DbVersion < ApplicationRecord
  # Really "Schema Version"

  self.table_name = "db_version"
  self.primary_key = "id"

  def self.current
    DbVersion.first[:version]
  rescue StandardError => e
    Rails.logger.error("Problem detecting current schema version.")
    Rails.logger.error("Exception: #{e}")
    "[Problem finding version: #{e}]"
  end
end
