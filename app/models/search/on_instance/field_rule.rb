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
class Search::OnInstance::FieldRule
  RULES = {
      "id:"                   => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
      "ids:"                  => { multiple_values: true,
                                 where_clause: " id = ? ",
                                 multiple_values_where_clause: " id in (?)" },
      "year:"                 => { where_clause: " exists (select null from
                                 reference ref where instance.reference_id =
                                 ref.id and ref.iso_publication_date like ? || '%')" },
      "date:"                 => { where_clause: " exists (select null from
                                 reference ref where instance.reference_id =
                                 ref.id and ref.iso_publication_date like ? || '%')" },
      "name:"                 => { where_clause: "exists (select null
                                 from name n
                                 where instance.name_id = n.id
                                 and lower(n.full_name) like lower(?) )",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },
      "name-exact:"           => { where_clause: "exists (select null
                                 from name n
                                 where instance.name_id = n.id
                                 and lower(n.full_name) like lower(?) )" },
      "comments:"             => { trailing_wildcard: true,
                                 leading_wildcard: true,
                                 not_exists_clause: " not exists (select null
from comment where comment.instance_id = instance.id)",
                                 where_clause: " exists (select null from
                                 comment
                                 where comment.instance_id = instance.id
                                 and lower(comment.text) like ?) " },
      "comments-by:"          => { where_clause: " exists (select null
                                 from comment
                                 where comment.instance_id = instance.id
                                 and comment.created_by like ?) " },
      "comments-exact:"       => { where_clause: " exists (select null from comment where comment.instance_id = instance.id and lower(comment.text) like ?) " },
      "bhl:"                  => { where_clause: " lower(bhl_url) like lower(?)" },
      "page:"                 => { where_clause: " lower(page) like lower(?)" },
      "page-qualifier:"       => { where_clause:
                                 " lower(page_qualifier) like lower(?)" },

      "note-key:"             => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and lower(instance_note_key.name)
                                 like lower(?) )) " },

      "notes-exact:"          => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and lower(instance_note.value)
                                 like lower(?)) " },

      "notes:"                => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and lower(instance_note.value)
                                 like lower(?)) ",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },

      "note-key-type-note:"   => { where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and lower(instance_note.value) like lower(?)
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and lower(instance_note_key.name) = 'type')) ",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },
      "apc-dist-note-matches:" => {where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and instance_note.value ~ ?
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and instance_note_key.name = 'APC Dist.')) ",
                                 convert_asterisk_to_percent: false,
                                 case_sensitive: true},
      "apc-comment-note-matches:" => {where_clause: " exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and instance_note.value ~ ?
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and instance_note_key.name = 'APC Comment')) ",
                                 convert_asterisk_to_percent: false,
                                 case_sensitive: true},
      "tree-dist-matches:" => {where_clause: " exists(select null
                 from tree t
                      join tree_version tv
                           on t.id = tv.tree_id
                      join tree_version_element tve
                           on tv.id = tve.tree_version_id
                      join tree_element te
                           on te.id = tve.tree_element_id
                where t.accepted_tree
                  and tv.id = t.current_tree_version_id
                  and te.instance_id = instance.id
                  and (te.profile -> (t.config ->> 'distribution_key') ->> 'value') ~* ?)",
                                 convert_asterisk_to_percent: false},
      "tree-comment-matches:" => {where_clause: " exists(select null
                 from tree t
                      join tree_version tv
                           on t.id = tv.tree_id
                      join tree_version_element tve
                           on tv.id = tve.tree_version_id
                      join tree_element te
                           on te.id = tve.tree_element_id
                where t.accepted_tree
                  and tv.id = t.current_tree_version_id
                  and te.instance_id = instance.id
                  and (te.profile -> (t.config ->> 'comment_key') ->> 'value') ~* ?)",
                                 convert_asterisk_to_percent: false},
      "non-tree-drafts:" => {where_clause: " draft and not exists(select null
                                 from tree_element te
                                 where te.instance_id = instance.id)"},
      "type:"                 => { where_clause: " exists (select null
                                 from instance_type
                                 where instance_type_id = instance_type.id
                                 and instance_type.name like ?) ",
                                 multiple_values: true,
                                 multiple_values_where_clause:
                                 " exists (select null
                                 from instance_type
                                 where instance_type_id = instance_type.id
                                 and instance_type.name in (?))",
                                 order: "name.full_name",
                                 join: :name },

      "ref-type:"             => { where_clause: " exists (select null
                                 from reference ref
                                 where ref.id = instance.reference_id
                                 and exists (select null
                                 from ref_type
                                 where ref_type.id = ref.ref_type_id
                                 and lower(ref_type.name) like lower(?)))",
                                 multiple_values: true,
                                 multiple_values_where_clause:
                                 " exists (select null from reference ref
                                 where ref.id = instance.reference_id
                                 and exists (select null from ref_type
                                 where ref_type.id = ref.ref_type_id
                                 and lower(ref_type.name) in (?)))" },
      "name-type:"            => { where_clause: " exists (select null
                                 from name 
                                 where name.id = instance.name_id
                                 and exists (select null
                                 from name_type
                                 where name_type.id = name.name_type_id
                                 and lower(name_type.name) like lower(?)))",
                                 multiple_values: true,
                                 multiple_values_where_clause:
                                 " exists (select null from name
                                 where name.id = instance.name_id
                                 and exists (select null from name_type
                                 where name_type.id = name.name_type_id
                                 and lower(name_type.name) in (?)))" },
      "cites-an-instance:"    => { where_clause: " cites_id is not null" },

      "is-cited-by-an-instance:" => { where_clause: " cited_by_id is not null" },
      "does-not-cite-an-instance:" => { where_clause: " cites_id is null" },
      "is-not-cited-by-an-instance:" => { where_clause: " cited_by_id is null" },
      "verbatim-name-exact:"  => { where_clause:
                                 "lower(verbatim_name_string) like lower(?) " },
      "verbatim-name:"        => { where_clause:
                                 "lower(verbatim_name_string) like lower(?)",
                                 leading_wildcard: true,
                                 trailing_wildcard: true },
      "verbatim-name-matches-full-name:" => { where_clause:
                                             " lower(verbatim_name_string) =
                                             (select lower(full_name)
                                             from name
                                             where name.id =
                                             instance.name_id) ",
                                 case_sensitive: true},

      "verbatim-name-does-not-match-full-name:" =>
    { where_clause: " lower(verbatim_name_string) != (select lower(full_name)
    from name where name.id = instance.name_id) ",
                                 case_sensitive: true},
      "is-novelty:" => { where_clause: " exists (select null
                       from instance_type
                       where instance_type_id = instance_type.id
                       and instance_type.primary_instance) " },
      "is-tax-nov-for-orth-var-name:" => { where_clause: " exists (select null
                                 from instance_type
                                 where instance_type_id = instance_type.id
                                 and instance_type.name = 'tax. nov.') and
                                 exists (select null from name
                                         where name.id = instance.name_id
                                           and exists (select null
                                                         from name_status
                                                        where name_status.id =
                                                        name.name_status_id
                                                          and name_status.name =
                                                             'orth. var.'))" },
      "species-or-below-syn-with-genus-or-above:" =>
    { where_clause:
      " instance.id in
      (
     SELECT i.id
  FROM instance i
 INNER JOIN instance ia
    ON i.cited_by_id = ia.id
 INNER JOIN name na
    ON ia.name_id = na.id
 INNER JOIN name_rank ra
    ON na.name_rank_id = ra.id
 INNER JOIN instance ib
    ON i.cites_id = ib.id
 INNER JOIN name nb
    ON ib.name_id = nb.id
 INNER JOIN name_rank rb
    ON nb.name_rank_id = rb.id
where rb.sort_order >= (select sort_order from name_rank where name = 'Species')
  and ra.sort_order <= (select sort_order from name_rank where name = 'Genus')
      )
      ",
      order: "name.full_name",
      join: :name },
      "rank:" => { where_clause: " exists (select null from
                  name n inner join name_rank nr
                  on n.name_rank_id = nr.id where instance.name_id =
                  n.id and lower(nr.name) like lower(?))",
                 order: "name.full_name" },

      "bad-relationships-974:" => { where_clause: " instance.id in (select syn.id
  from instance syn
 inner join instance standalone
    on syn.cited_by_id = standalone.id
 where syn.instance_type_id in (
    select id
      from instance_type
 where name in ('replaced synonym', 'basionym')
       )
   and standalone.instance_type_id not in (
    select id
      from instance_type
    where name in ('comb. nov.',
          'comb. et stat. nov.', 'nom. nov.', 'nom. et stat. nov.'
     )
       )
)", order: "instance.id" },
      "ref-exact:"           => { where_clause: "exists (select null
                                 from reference ref
                                 where instance.reference_id = ref.id
                                 and lower(ref.citation) like lower(?) )" },
      "parent-ref-exact:"    => { where_clause: "exists (select null
                                 from reference ref
                                 where instance.reference_id = ref.id
                                   and exists (select null from reference parent
                                                where ref.parent_id = parent.id
                                                  and lower(parent.citation) like lower(?) ))" },
      "draft:" => { where_clause: " draft " },
      "not-draft:" => { where_clause: " draft = false " },
 "syn-with-note:"    => { where_clause: " id in (select id
                                                   from instance i
                                                  where cited_by_id is not null
                                                    and exists (select null
                                                                  from instance_note n
                                                                 where n.instance_id = i.id)
                                                 )",
                           order: "instance.id" },
 "syn-with-adnot:"    => { where_clause: " id in (select id
                                                  from instance i
                                                 where cited_by_id is not null
                                                   and exists (select null
                                                                 from comment c
                                                                where c.instance_id = i.id)
                                                )",
                           order: "instance.id" },
"note-updated-by:"   => { where_clause: " exists (select null from instance_note n where n.instance_id = instance.id and lower(n.updated_by) like ?) "},
"note-has-carriage-return:"   => { where_clause: " exists (select null from instance_note n where n.instance_id = instance.id and n.value like '%' || chr(13) || '%') "},
"verbatim-name-matches-full-name-ignoring-hybrid-x:" => { where_clause:" id in (select i.id
from instance i 
       join name n
       on i.name_id = n.id 
  where regexp_replace(lower(n.full_name),' x ',' ','g') = regexp_replace(lower(i.verbatim_name_string),' x ',' ','g'))"},
"verbatim-name-matches-full-name-ignoring-orth-var:" => { where_clause:" id in (select i.id
from instance i 
       join name n
       on i.name_id = n.id 
  where regexp_replace(lower(n.full_name),' orth. var. ',' ','g') = regexp_replace(lower(i.verbatim_name_string),' orth. var. ',' ','g'))"},
"name-status:" => { where_clause:%Q[ instance.id in (select i.id from instance i join name n on i.name_id = n.id join name_status ns on n.name_status_id = ns.id and lower(ns.name) = lower(?))]},
"name-status-not:" => { where_clause:%Q[ id in (select i.id from instance i join name n on i.name_id = n.id join name_status ns on n.name_status_id = ns.id and lower(ns.name) != lower(?))]},
  }.freeze

  def self.resolve(field)
    if InstanceNoteKey.string_has_embedded_note_key?(field)
      hash = Hash.new 
      key = field.sub(/#{InstanceNoteKey::NOTE_MATCHES}/i,%q[]).gsub(/-/,%( ))
      hash[field] = {where_clause: %Q( exists (select null
                                 from instance_note
                                 where instance_id = instance.id
                                 and instance_note.value ~ ?
                                 and exists (select null
                                 from instance_note_key
                                 where instance_note_key_id =
                                 instance_note_key.id
                                 and lower(instance_note_key.name) = lower('#{key}')))),
                                 convert_asterisk_to_percent: false,
                                 case_sensitive: true}
      return hash[field]
    else
      RULES[field]
    end
  end
end
