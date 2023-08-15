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
# Field rules available for building predicates.
class Search::Reference::FieldRule
  RULES = {
    "is-a-duplicate:" => { where_clause: " duplicate_of_id is not null" },
    "is-not-a-duplicate:" => { where_clause: " duplicate_of_id is null" },
    "is-a-parent:" => { where_clause: " exists (select null from
reference child where child.parent_id = reference.id) " },
    "is-not-a-parent:" => { where_clause: " not exists (select null from
reference child where child.parent_id = reference.id) " },
    "has-no-children:" => { where_clause: " not exists (select null from
reference child where child.parent_id = reference.id) " },
    "has-no-parent:" => { where_clause: " parent_id is null" },
    "is-a-child:" => { where_clause: " parent_id is not null" },
    "is-not-a-child:" => { where_clause: " parent_id is null" },
    "is-published:" => { where_clause: " published = true" },
    "is-not-published:" => { where_clause: " not published" },

    "author-exact:" => { where_clause: " author_id in (select id from
                                 author where lower(name) like lower(?))" },

    "comments:" => { trailing_wildcard: true,
                     leading_wildcard: true,
                     where_clause: " exists (select null from
comment where comment.reference_id = reference.id and lower(comment.text)
                                 like lower(?)) ",
                     not_exists_clause: " not exists (select null
from comment where comment.reference_id = reference.id)" },

    "comments-by:" => { where_clause: " exists (select null from
comment where comment.reference_id = reference.id and comment.created_by
                                 like ?) " },
    "comments-exact:" => { where_clause: " exists (select null from
                               comment where comment.reference_id = reference.id
                               and lower(comment.text) like ? ) " },
    "edition:" => { where_clause:
                                 " lower(edition) like lower(?)" },

    "publication-date:" => { where_clause: " lower(publication_date)
                                 like lower(?)" },

    "type:" => { multiple_values: true,
                 where_clause: " ref_type_id in (select id
from ref_type where lower(name) like lower(?))",
                 multiple_values_where_clause: " ref_type_id
in (select id from ref_type where lower(name) in (?))" },
    "parent-type:" => { multiple_values: true,
                        where_clause: " exists (select null from
reference parent where parent.id = reference.parent_id and parent.ref_type_id
in (select id from ref_type where lower(name) like lower(?)) )", },

    "not-type:" => { where_clause: " ref_type_id not in (select id
from ref_type where lower(name) like lower(?))" },

    "author-role:" => { where_clause: " ref_author_role_id in
(select id from ref_author_role where lower(name) like lower(?))" },
    "title-exact:" => { where_clause: " lower(title) like lower(?)" },
    "isbn:" => { where_clause: " lower(isbn) like lower(?)" },
    "issn:" => { where_clause: " lower(issn) like lower(?)" },
    "published-location:" => { where_clause: " lower(published_location)
                                 like lower(?)" },
    "publisher:" => { where_clause:
                                 " lower(publisher) like lower(?)" },
    "volume:" => { where_clause: " lower(volume) like lower(?)" },
    "pages:" => { where_clause: " lower(pages) like lower(?)" },
    "bhl:" => { where_clause:
                                 " lower(bhl_url) like lower(?)" },
    "doi:" => { where_clause: " lower(doi) like lower(?)" },
    "tl2:" => { where_clause: " lower(tl2) like lower(?)" },

    "id:" => { multiple_values: true,
               where_clause: " id = ? ",
               multiple_values_where_clause: " id in (?)" },
    "ids:" => { multiple_values: true,
                where_clause: " id = ? ",
                multiple_values_where_clause: " id in (?)" },
    "author-id:" => { multiple_values: true,
                      where_clause: " author_id = ? ",
                      multiple_values_where_clause: " id in (?)" },
    "year:" => { multiple_values: true,
                 where_clause: " iso_publication_date like ?||'%' ",
                 multiple_values_where_clause: " substring(iso_publication_date,1,4) in (?)" },
    "after-year:" => { where_clause: " iso_publication_date > ? " },
    "before-year:" => { where_clause: " iso_publication_date < ? " },
    "published-in-or-on:" => { multiple_values: true,
                               where_clause: " iso_publication_date like ? || '%' ",
                               multiple_values_where_clause: " substring(iso_publication_date,1,4) in (?)" },
    "published-after:" => { where_clause: " iso_publication_date > ? " },
    "published-before:" => { where_clause: " iso_publication_date < ? " },
    "iso-pub-date-matches:" => { where_clause: " iso_publication_date ~ ? ",
                                 leave_asterisks: true },
    "duplicate-of-id:" => { multiple_values: true,
                            where_clause: " duplicate_of_id = ?",
                            multiple_values_where_clause:
                                 " duplicate_of_id in (?)" },

    "parent-id:" => { where_clause: " id = ? or parent_id = ?",
                      order: "case when parent_id is null then
                                 'A' else 'B' end, citation" },

    "parent-id-sort-by-volume:" => { where_clause: " id = ? or parent_id = ?",
                                     order: "case when parent_id is null then
                                 'A' else 'B' end, volume, citation" },

    "parent-id-sort-numerical-by-volume:" => { where_clause: " id = ? or parent_id = ?",
                                               order: "case when parent_id is null then
                                 'A' else 'B' end, to_number(volume,'99999999999'), citation" },

    "master-id:" => { where_clause: " id = ? or
                                 duplicate_of_id = ?" },

    "citation-exact:" => { where_clause:
                                 " lower(citation) like lower(?)" },

    "citation-text:" => { scope_: "search_citation_text_for" },

    "citation:" => { trailing_wildcard: true,
                     leading_wildcard: true, tokenize: true,
                     where_clause:
                                 " lower(citation) like lower(?) " },

    "author:" => { trailing_wildcard: true,
                   leading_wildcard: true,
                   where_clause: "author_id in
(select id from author where lower(name) like lower(?))" },

    "title:" => { trailing_wildcard: true,
                  where_clause: " lower(title) like lower(?) " },

    "notes:" => { where_clause: " lower(notes) like lower(?) " },

    "parent-ref-wrong-child-type:" => { where_clause: "reference.id in (
select r.id from reference r
inner join ref_type rt on r.ref_type_id = rt.id
inner join reference child on r.id = child.parent_id
inner join ref_type child_rt on child.ref_type_id = child_rt.id
where (rt.name,child_rt.name) not in (select xrt.name, xcrt.name
from ref_type xrt
inner join ref_type xcrt on xrt.id = xcrt.parent_id))" },
    "no-year:" => { where_clause: " iso_publication_date is null " },
    "pub-date-is-year:" => {
      where_clause: "publication_date ~ '^\\(*[0-9][0-9][0-9][0-9]\\)*$' "
    },
    "pub-date-matches:" => { where_clause: " publication_date ~* ? " },
    "has-no-direct-or-child-instances:" => { where_clause: " reference.id not in
        (select id
           from reference ref1
      where exists (
          select null
            from instance i1
      where ref1.id         = i1.reference_id
            )
          or exists (
          select null
            from reference refchild
          where refchild.parent_id = ref1.id
            and exists (
                  select null
                    from instance i2
              where i2.reference_id = refchild.id
                )
            )
        ) " },
    "language:" => { multiple_values: true,
                     where_clause: " language_id = (select id from language where lower(name) = lower(?) ) ",
                     multiple_values_where_clause: " language_id in (select id from language where lower(name) in (?))" },
    "not-language:" => { multiple_values: true,
                         where_clause: " language_id != (select id from language where lower(name) = lower(?) ) ",
                         multiple_values_where_clause: " language_id not in (select id from language where lower(name) in (?))" },
    "no-publication-date:" => { where_clause: " publication_date is null " },
  }.freeze
end
