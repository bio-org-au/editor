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
class Search::Loader::Batch::Review::FieldRule
  RULES = {
    "name:" => { where_clause: "lower(name) like ? ",
                 trailing_wildcard: true,
                 leading_wildcard: true,
                 order: "name" },
    "id:" => { multiple_values: true,
               where_clause: "id = ? ",
               multiple_values_where_clause: " id in (?)",
               order: "name" },
    "ids:" => { multiple_values: true,
                where_clause: " id = ?",
                multiple_values_where_clause: " id in (?)",
                order: "name" },
    "batch-id:" => { where_clause: "loader_batch_id = ? ",
                     order: "name" },
  }.freeze
end
