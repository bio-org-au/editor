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
class Search::Loader::Batch::Stack::FieldRule
  RULES = {
    "name:" => { where_clause: "lower(batch_name) like ? ",
                 trailing_wildcard: true,
                 order: "order_by" },
    "batch-id:" => { multiple_values: true,
                     where_clause: "batch_id = ? ",
                     multiple_values_where_clause: " batch_id in (?)",
                     order: "order_by" },
    "batch-ids:" => { multiple_values: true,
                      where_clause: " batch_id = ?",
                      multiple_values_where_clause: " batch_id in (?)",
                      order: "order_by" },
  }.freeze
end
