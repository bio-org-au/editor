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
class Search::Loader::Name::FieldRule
  RULES = {
    "scientific-name:"    => { where_clause: "lower(scientific_name) like ? ",
                                 trailing_wildcard: true,
                                 leading_wildcard: true,
                                 order: "seq"},
    "batch-id:"           => { where_clause: "loader_batch_id = ? ",
                               order: "seq"},
    "batch-name:"         => { where_clause: "loader_batch_id = (select id from loader_batch where lower(name) = ?)  ",
                               order: "seq"},
    "default-batch:"      => { where_clause: "loader_batch_id = (select id from loader_batch where lower(name) = ?)  ",
                               order: "seq"},
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? ",
                               multiple_values_where_clause: " id in (?)",
                               order: "seq"},
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ?",
                               multiple_values_where_clause: " id in (?)",
                               order: "seq"},
    "has-review-comment:" => { where_clause: "exists (select null from name_review_comment nrc where nrc.loader_name_id = loader_name.id)",
                               order: "seq"},
    "has-review-comment-by:" => { where_clause: "exists (select null from name_review_comment nrc join batch_reviewer br on nrc.batch_reviewer_id = br.id join users u on br.user_id = u.id  where nrc.loader_name_id = loader_name.id and lower(u.name) = ?)",
                               order: "seq"},
    "name:"               => { trailing_wildcard: true,
                               where_clause: " lower(scientific_name) like ? or lower(scientific_name) like 'x '||? or lower(scientific_name) like '('||? ",
                                      order: "seq"},
    "name-no-wildcard:"   => { where_clause: " lower(scientific_name) like ? or lower(scientific_name) like 'x '||? or lower(scientific_name) like '('||?",
                                      order: "seq"},
    "name-with-syn:"      => { trailing_wildcard: true,
                               where_clause: " ((lower(scientific_name) like ? or lower(scientific_name) like 'x '||? or lower(scientific_name) like '('||?) and record_type = 'accepted' and unplaced is null) or (parent_id in (select id from orchids where (lower(scientific_name) like ? or lower(scientific_name) like 'x '||? or lower(scientific_name) like '('||?) and record_type = 'accepted' and unplaced is null))",
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
    "no-name-match:"      => { where_clause: "not exists (select null from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "some-name-match:"    => { where_clause: "exists (select null from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name))" ,
                                      order: "seq"},
    "many-name-match:"    => { where_clause: "1 <  (select count(*) from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "one-name-match:"     => { where_clause: "1 =  (select count(*) from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))" ,
                                      order: "seq"},
    "name-match-no-primary:"     =>   { where_clause: "0 <  (select count(*) from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific and not exists (select null from instance join instance_type on instance.instance_type_id = instance_type.id where instance_type.primary_instance and name.id = instance.name_id))) AND ( not exists ( select null from loader_name_match where loader_name_match.loader_name_id = loader_name.id )) ",
                                      order: "seq"},
    "name-match-eq:"      => { where_clause: "? =  (select count(*) from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "name-match-gt:"      => { where_clause: "? <  (select count(*) from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "name-match-gte:"     => { where_clause: "? <=  (select count(*) from name where (scientific_name = name.simple_name or alt_name_for_matching = name.simple_name) and exists (select null from name_Type nt where name.name_type_id = nt.id and nt.scientific))",
                                      order: "seq"},
    "partly:"             => { where_clause: "partly is not null",
                                      order: "seq"},
    "not-partly:"         => { where_clause: "partly is null",
                                      order: "seq"},
    "name-sharing-name-id:" => { where_clause: " id in (select loader_name_id from loader_name_match where name_id in (select name_id from loader_name_match group by name_id having count(*) > 1))",
                                      order: "seq"},
    "non-misapp-name-sharing-name-id:" => { where_clause: " id in (select loader_name_id from loader_name_match where name_id in (select name_id from loader_name_match where loader_name_id in (select id from orchids where record_type != 'misapplied') group by name_id having count(*) > 1))",
                                      order: "seq"},
    "non-misapp-name-sharing-name-id-not-pp:" => { where_clause: "id in (select loader_name_id
  from loader_name_match
 where name_id in (
    select name_id
      from (
        select orn.name_id, orn.loader_name_id, o.partly, orn.relationship_instance_id ,
              coalesce(reltype.pro_parte,false) type_is_partly, reltype.name
          from orchids o
          join loader_name_match orn
            on o.id                         =  orn.loader_name_id
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
    "has-preferred-name:"   => { where_clause: " exists (select null from loader_name_match where loader_name.id = loader_name_match.loader_name_id)",
                                      order: "seq"},
    "has-preferred-name-without-instance:"   => { where_clause: " exists (select null from loader_name_match orn where loader_name.id = orn.loader_name_id and orn.standalone_instance_id is null and orn.relationship_instance_id is null)",
                                      order: "seq"},
    "has-no-preferred-name:"   => { where_clause: " not exists (select null from loader_name_match where loader_name.id = loader_name_match.loader_name_id)"},
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
    "alt-name-for-matching:"=> { where_clause: "lower(alt_scientific_name_for_matching) like ?",
                                      order: "seq"},
    "no-further-processing:"=> { where_clause: " no_further_processing or exists (select null from loader_name kids where kids.parent_id = loader_name.id and kids.no_further_processing) or exists (select null from orchids pa where pa.id = orchids.parent_id and pa.no_further_processing)",
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
    "is-doubtful:"=> { where_clause: "doubtful is not null",
                                      order: "seq"},
    "is-not-doubtful:"=> { where_clause: "doubtful is null",
                                      order: "seq"},
    "excluded-with-syn:"   => { trailing_wildcard: true,
                           where_clause: " (lower(scientific_name) like ? and excluded) or (parent_id in (select id from orchids where lower(scientific_name) like ? and record_type = 'accepted' and excluded))",
                               order: "seq"},
    "comment:"=> { where_clause: "lower(comment) like ?",
                       leading_wildcard: true,
                       trailing_wildcard: true,
                       order: "seq"},
    "in-current-taxonomy:"=> { where_clause: "loader_name.id in (select distinct o.id
  from loader_name_match orn
  join loader_name o
    on orn.loader_name_id = o.id
 where o.record_type = 'accepted'
   and orn.name_id in (
    select name_id
  from current_accepted_tree_version_vw
       )
 order by o.id)",
                       trailing_wildcard: true,
                       order: "seq"},
    "not-in-current-taxonomy:"=> { where_clause: "loader_name.id in (select id from orchids where record_type = 'accepted') and loader_name.id not in (select distinct o.id
  from loader_name_match orn
  join loader_name o
    on orn.loader_name_id = o.id
 where orn.name_id in (
    select name_id
  from current_accepted_tree_version_vw
       )
 order by o.id)",
                       trailing_wildcard: true,
                       order: "seq"},
    "syn-type:" => { where_clause: "lower(synonym_type) like ?",
                                      order: "seq"},
    "manually-drafted:" => { where_clause: " id in (select loader_name_id from loader_name_match where manually_drafted)",
                                      order: "seq"},
    "drafted:" => { where_clause: " id in (select loader_name_id from loader_name_match where drafted)",
                                      order: "seq"},
    "misapp-matched-without-cross-ref:" => { where_clause: " id in (select o.id from orchids o join loader_name_match orn on o.id = orn.loader_name_id where o.record_type = 'misapplied' and orn.relationship_instance_id is null)",
                                             order: "seq"},

  }.freeze
end
