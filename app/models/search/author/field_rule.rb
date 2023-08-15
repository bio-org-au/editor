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
class Search::Author::FieldRule
  RULES = {
    "is-a-duplicate:" => { where_clause: " duplicate_of_id is not null" },
    "is-not-a-duplicate:" => { where_clause: " duplicate_of_id is null" },
    "has-abbrev:" => { where_clause: " abbrev is not null" },
    "has-no-abbrev:" => { where_clause: " abbrev is null" },
    "has-name:" => { where_clause: " name is not null" },
    "has-no-name:" => { where_clause: " name is null" },
    "has-authored-name:" => { where_clause: " exists (select null from
                               name where name.author_id = author.id) " },
    "has-ex-authored-name:" \
                            => { where_clause: " exists (select null from
                               name where name.ex_author_id = author.id) " },
    "has-ex-base-authored-name:" \
                                 => { where_clause: " exists (select null from
                               name where name.ex_base_author_id = author.id) " },
    "has-base-authored-name:" \
                              => { where_clause: " exists (select null from
                               name where name.base_author_id = author.id) " },
    "has-sanctioned-name:" \
                           => { where_clause: " exists (select null from
                               name where name.sanctioning_author_id = author.id) " },
    "has-any-authored-name:" \
                             => { where_clause: " exists (select null from
                               name where name.author_id = author.id
                               or name.base_author_id = author.id
                               or name.ex_author_id = author.id
                               or name.ex_base_author_id = author.id
                               or name.sanctioning_author_id = author.id) " },
    "comments:" => { trailing_wildcard: true,
                     leading_wildcard: true,
                     where_clause: " exists (select null from
                               comment where comment.author_id =
                               author.id and lower(comment.text)
                               like lower(?) ) ",
                     not_exists_clause: " not exists (select null
from comment where comment.author_id = author.id)" },
    "comments-by:" => { where_clause: " exists (select null from
                               comment where comment.author_id =
                               author.id and lower(comment.created_by)
                               like lower(?) ) " },
    "full-name:" => { leading_wildcard: true,
                      trailing_wildcard: true,
                      where_clause: "lower(full_name) like lower(?)" },
    "name:" => { tokenize: true,
                 where_clause:
                               " lower(f_unaccent(name))
                               like lower(f_unaccent(?))" },
    "abbrev:" => { tokenize: true,
                   where_clause:
                               " lower(f_unaccent(abbrev))
                               like lower(f_unaccent(?)) " },
    "name-or-abbrev:" => { leading_wildcard: true,
                           trailing_wildcard: true,
                           tokenize: true,
                           where_clause: "lower(f_unaccent(name))
                               like lower(f_unaccent(?)) or
                               lower(f_unaccent(abbrev))
                               like lower(f_unaccent(?)) " },
    "name-exact:" => { where_clause: "lower(name) like lower(?)" },
    "abbrev-exact:" => { where_clause: "lower(abbrev) like lower(?)" },
    "full-name-exact:" => { where_clause: "lower(full_name) like lower(?)" },
    "comments-exact:" => { where_clause: " exists (select null from
                               comment where comment.author_id = author.id
                               and lower(comment.text) like lower(?) ) " },
    "notes-exact:" => { where_clause: " lower(notes) like lower(?) " },
    "ipni-id:" => { where_clause: "lower(ipni_id) like lower(?) " },
    "id:" => { multiple_values: true,
               where_clause: "id = ? ",
               multiple_values_where_clause: " id in (?)" },
    "ids:" => { multiple_values: true,
                where_clause: " id = ?",
                multiple_values_where_clause: " id in (?)" },
    "duplicate-of-id:" => { where_clause: "duplicate_of_id = ? " },
    "notes:" => { where_clause: " lower(notes) like lower(?) " },
    "missed-diacritics:" => { where_clause: " (exists (
    select null
      from regexp_split_to_table(unaccent(name),'') x
    where ascii(x) not between 1 and 127
   and length(name)   > 0
       )
    or exists (
    select null
      from regexp_split_to_table(unaccent(abbrev),'') x
    where ascii(x) not between 1 and 127
   and length(abbrev) > 0
       )) " },
  }.freeze
end
