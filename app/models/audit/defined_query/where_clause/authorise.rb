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
class Audit::DefinedQuery::WhereClause::Authorise
  attr_reader :sql

  def initialize(sql, user)
    debug("Start user.username: #{user.username};")

    @sql = if user.qa?
             sql
           else
             sql.where("created_by = ? or updated_by = ?",
                       user.username,
                       user.username)
           end
    debug(@sql.to_sql)
  end

  def debug(s)
    Rails.logger.debug("Audit::DefinedQuery::WhereClause::Authorise #{s}")
  end
end
