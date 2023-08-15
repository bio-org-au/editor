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
# Loader Name entity
class Loader::Name::Constants
  #
  #
  # Retrieve
  #   -- matching accepted or excluded name
  #      -- synonym or misapp of matching accepted or excluded name
  #
  # do not retrieve
  #   -- non-matching accepted or excluded name
  #      -- matching synonym (or misapp)
  #
  BULK_OPERATIONS_WHERE_FRAG = <<-SQL
    (
      (
        (
          lower(simple_name) like ?
          or lower(simple_name) like 'x '||?#{' '}
          or lower(simple_name) like '('||?)
        )
        and record_type in ('accepted', 'excluded')
      )#{' '}
    or#{' '}
      (parent_id in#{' '}
        (select id#{' '}
           from loader_name#{' '}
          where (
                  (
                    lower(simple_name) like ?
                    or lower(simple_name) like 'x '||?
                    or lower(simple_name) like '('||?)#{' '}
                  )
                  and record_type in ('accepted', 'excluded')
                )
        )
  SQL
end
