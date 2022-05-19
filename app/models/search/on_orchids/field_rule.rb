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
class Search::OnOrchids::FieldRule
  RULES = {
    "taxon:"              => { trailing_wildcard: true,
                               where_clause: " lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||? ",
                                      order: "seq"},
    "taxon-no-wildcard:"  => { where_clause: " lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?",
                                      order: "seq"},
    "old-taxon-with-syn:"      => { trailing_wildcard: true,
                               where_clause: " ((lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?) and record_type = 'accepted' and not doubtful) or (parent_id in (select id from orchids where (lower(taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?) and record_type = 'accepted' and not doubtful))",
                               order: "seq"},
    "taxon-with-syn:"      => { trailing_wildcard: true,
                               where_clause: "( (  (
            lower(taxon) like ?
          or lower(taxon) like 'x '||?
        or lower(taxon) like '('||?
          )
      and record_type = 'accepted'
    and not doubtful
        )
      or 
          parent_id in (
        select id
          from orchids
        where (
                lower(taxon) like ?
              or lower(taxon) like 'x '||?
            or lower(taxon) like '('||?
              )
          and record_type = 'accepted'
      and not doubtful
        )
      or exists (
        select null
          from orchids child
        where child.parent_id   = orchids.id
       and (
        lower(child.taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?)
        )
      or exists (
        select null
          from orchids sibling
        where sibling.parent_id = orchids.parent_id
       and (
        lower(sibling.taxon) like ? or lower(taxon) like 'x '||? or lower(taxon) like '('||?
           )
      )
  ) ",
     order: "seq"},
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? ",
                               multiple_values_where_clause: " id in (?)",
                                      order: "seq"},
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ?",
                               multiple_values_where_clause: " id in (?)",
                                      order: "seq"},
    "id-with-syn:"        => { where_clause: "id = ? or parent_id = ?",
                               order: "seq"},
    "has-parent:"         => { where_clause: "parent_id is not null",
                                      order: "seq"},
    "has-no-parent:"      => { where_clause: "parent_id is null",
                                      order: "seq"},
    "is-accepted:"        => { where_clause: "record_type = 'accepted'",
                                      order: "seq"},
    "is-syn:"             => { where_clause: "record_type = 'synonym'",
                                      order: "seq"},
    "is-misapplied:"      => { where_clause: "record_type = 'misapplied'",
                                      order: "seq"},
    "is-not-misapplied:"  => { where_clause: "record_type != 'misapplied'",
                                      order: "seq"},
    "is-hybrid-cross:"    => { where_clause: "record_type = 'hybrid_cross'",
                                      order: "seq"},
    "is-syn-but-no-syn-type:" => { where_clause: "record_type = 'synonym' and synonym_type is null",
                                      order: "seq"},
    "no-name-match:"      => { where_clause: "not exists (select null from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "some-name-match:"    => { where_clause: "exists (select null from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name))" ,
                                      order: "seq"},
    "many-name-match:"    => { where_clause: "1 <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "one-name-match:"     => { where_clause: "1 =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "name-match-no-primary:"     =>   { where_clause: "0 <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific and not exists (select null from instance join instance_type on instance.instance_type_id = instance_type.id where instance_type.primary_instance and name.id = instance.name_id))) AND ( not exists ( select null from orchids_names where orchids_names.orchid_id = orchids.id )) ",
                                      order: "seq"},
    "name-match-eq:"      => { where_clause: "? =  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "name-match-gt:"      => { where_clause: "? <  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "name-match-gte:"     => { where_clause: "? <=  (select count(*) from name where (taxon = name.simple_name or alt_taxon_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "partly:"             => { where_clause: "partly is not null",
                                      order: "seq"},
    "not-partly:"         => { where_clause: "partly is null",
                                      order: "seq"},
    "taxon-sharing-name-id:" => { where_clause: " id in (select orchid_id from orchids_names where name_id in (select name_id from orchids_names group by name_id having count(*) > 1))",
                                      order: "seq"},
    "non-misapp-taxon-sharing-name-id:" => { where_clause: " id in (select orchid_id from orchids_names where name_id in (select name_id from orchids_names where orchid_id in (select id from orchids where record_type != 'misapplied') group by name_id having count(*) > 1))",
                                      order: "seq"},
    "non-misapp-taxon-sharing-name-id-not-pp:" => { where_clause: "id in (select orchid_id
  from orchids_names
 where name_id in (
    select name_id
      from (
        select orn.name_id, orn.orchid_id, o.partly, orn.relationship_instance_id ,
              coalesce(reltype.pro_parte,false) type_is_partly, reltype.name
          from orchids o
          join orchids_names orn
            on o.id                         =  orn.orchid_id
          left outer join instance_type reltype
            on orn.relationship_instance_type_id     =  reltype.id
        where o.partly is null
      and o.record_type                != 'misapplied'
          ) fred
    where type_is_partly               =  'f'
    group by name_id
having count(*)                     >  1
       ))",
                                      order: "seq"},
    "has-preferred-name:"   => { where_clause: " exists (select null from orchids_names where orchids.id = orchids_names.orchid_id)",
                                      order: "seq"},
    "has-preferred-name-without-instance:"   => { where_clause: " exists (select null from orchids_names orn where orchids.id = orn.orchid_id and orn.standalone_instance_id is null and orn.relationship_instance_id is null)",
                                      order: "seq"},
    "has-no-preferred-name:"   => { where_clause: " not exists (select null from orchids_names where orchids.id = orchids_names.orchid_id)"},
    "created-by:"=> { where_clause: "created_by = ?",
                                      order: "seq"},
    "updated-by:"=> { where_clause: "updated_by = ?",
                                      order: "seq"},
    "not-created-by:"=> { where_clause: "created_by != ?",
                                      order: "seq"},
    "not-created-by-batch:"=> { where_clause: "created_by != 'batch'",
                                      order: "seq"},
    "original-text:"=> { where_clause: "lower(original_text) like ?",
                                      order: "seq"},
    "original-text-has-×:"=> { where_clause: "lower(original_text) like '%×%'",
                                      order: "seq"},
    "original-text-has-x:"=> { where_clause: "lower(original_text) like '%×%'",
                                      order: "seq"},
    "hybrid-level:"=> { where_clause: "lower(hybrid_level) like ?",
                                      order: "seq"},
    "hybrid-level-has-value:"=> { where_clause: "hybrid_level is not null",
                                      order: "seq"},
    "hybrid-level-has-no-value:"=> { where_clause: "hybrid_level is null",
                                      order: "seq"},
    "hybrid:"=> { where_clause: "hybrid = ?",
                                      order: "seq"},
    "hybrid-has-value:"=> { where_clause: "hybrid is not null",
                                      order: "seq"},
    "hybrid-has-no-value:"=> { where_clause: "hybrid is null",
                                      order: "seq"},
    "alt-taxon-for-matching:"=> { where_clause: "lower(alt_taxon_for_matching) like ?",
                                      order: "seq"},
    "no-further-processing:"=> { where_clause: " exclude_from_further_processing or exists (select null from orchids kids where kids.parent_id = orchids.id and kids.exclude_from_further_processing) or exists (select null from orchids pa where pa.id = orchids.parent_id and pa.exclude_from_further_processing)",
                               order: "seq"},
    "is-isonym:"=> { where_clause: "isonym is not null",
                                      order: "seq"},
    "is-orth-var:"=> { where_clause: "name_status like 'orth%'",
                                      order: "seq"},
    "name-status:"=> { where_clause: "name_status like ?",
                       leading_wildcard: true,
                       trailing_wildcard: true,
                       order: "seq"},
    "name-status-empty-string:"=> { where_clause: "name_status = ''",
                       order: "seq"},
    "name-status-exact:"=> { where_clause: "name_status like ?",
                       order: "seq"},
    "notes:"=> { where_clause: "lower(notes) like ?",
                       leading_wildcard: true,
                       trailing_wildcard: true,
                       order: "seq"},
    "rank:"         => { where_clause: "lower(rank) like ?",
                                      order: "seq"},
    "not-rank:"         => { where_clause: "lower(rank) not like ?",
                                      order: "seq"},
    "rank-is-null:"         => { where_clause: "rank is null",
                                      order: "seq"},
    "nsl-rank:"         => { where_clause: "lower(nsl_rank) like ?",
                                      order: "seq"},
    "not-nsl-rank:"         => { where_clause: "lower(nsl_rank) not like ?",
                                      order: "seq"},
    "nsl-rank-is-null:"         => { where_clause: "nsl_rank is null",
                                      order: "seq"},
    "is-doubtful:"=> { where_clause: "doubtful",
                                      order: "seq"},
    "is-not-doubtful:"=> { where_clause: "not doubtful",
                                      order: "seq"},
    "excluded-with-syn:"   => { trailing_wildcard: true,
                           where_clause: " (lower(taxon) like ? and record_type = 'accepted' and doubtful) or (parent_id in (select id from orchids where lower(taxon) like ? and record_type = 'accepted' and doubtful))",
                               order: "seq"},
    "comment:"=> { where_clause: "lower(comment) like ?",
                       leading_wildcard: true,
                       trailing_wildcard: true,
                       order: "seq"},
    "in-current-taxonomy:"=> { where_clause: "orchids.id in (select distinct o.id
  from orchids_names orn
  join orchids o
    on orn.orchid_id = o.id
 where o.record_type = 'accepted'
   and orn.name_id in (
    select name_id
  from current_accepted_tree_version_vw
       )
 order by o.id)",
                       trailing_wildcard: true,
                       order: "seq"},
    "not-in-current-taxonomy:"=> { where_clause: "orchids.id in (select id from orchids where record_type = 'accepted') and orchids.id not in (select distinct o.id
  from orchids_names orn
  join orchids o
    on orn.orchid_id = o.id
 where orn.name_id in (
    select name_id
  from current_accepted_tree_version_vw
       )
 order by o.id)",
                       trailing_wildcard: true,
                       order: "seq"},
    "syn-type:" => { where_clause: "lower(synonym_type) like ?",
                                      order: "seq"},
    "manually-drafted:" => { where_clause: " id in (select orchid_id from orchids_names where manually_drafted)",
                                      order: "seq"},
    "drafted:" => { where_clause: " id in (select orchid_id from orchids_names where drafted)",
                                      order: "seq"},
    "misapp-matched-without-cross-ref:" => { where_clause: " id in (select o.id from orchids o join orchids_names orn on o.id = orn.orchid_id where o.record_type = 'misapplied' and orn.relationship_instance_id is null)",
                                             order: "seq"},
  }.freeze
end
