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
    "simple-name:" => { where_clause: "(lower(simple_name) like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id         = loader_name.parent_id
       and lower(parent.simple_name) like ?)
        or exists (
        select null
          from loader_name child
        where child.parent_id   = loader_name.id
       and lower(child.simple_name) like ?)
        or exists (
        select null
          from loader_name sibling
        where sibling.parent_id = loader_name.parent_id
       and lower(sibling.simple_name) like ?)",
           trailing_wildcard: true,
           order: "seq"},
    "simple-name-as-loaded:" => { where_clause: "(lower(simple_name_as_loaded) like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id         = loader_name.parent_id
       and lower(parent.simple_name_as_loaded) like ?)
        or exists (
        select null
          from loader_name child
        where child.parent_id   = loader_name.id
       and lower(child.simple_name_as_loaded) like ?)
        or exists (
        select null
          from loader_name sibling
        where sibling.parent_id = loader_name.parent_id
       and lower(sibling.simple_name_as_loaded) like ?)",
           trailing_wildcard: true,
           order: "seq"},
    "batch-id:"           => { where_clause: "loader_batch_id = ? ",
                               order: "seq"},
    "batch-name:"         => { where_clause: "loader_batch_id = (select id from loader_batch where lower(name) = ?)  ",
                               order: "seq"},
    "default-batch:"      => { where_clause: "loader_batch_id = (select id from loader_batch where lower(name) = ?)  ",
                               order: "seq"},
    "id:"                 => { multiple_values: true,
                               where_clause: "id = ? or parent_id = ? ",
                               multiple_values_where_clause: " id in (?)",
                               order: "seq"},
    "ids:"                => { multiple_values: true,
                               where_clause: " id = ? or parent_id = ?",
                               multiple_values_where_clause: " id in (?)",
                               order: "seq"},
    "raw-id:"                 => { multiple_values: true,
                               where_clause: "raw_id = ? or parent_raw_id = ? ",
                               multiple_values_where_clause: " raw_id in (?) or parent_raw_id in (?)",
                               order: "seq"},

    "has-review-comment:" => 
    { where_clause: "exists (
        select null
          from name_review_comment nrc
     where nrc.loader_name_id = loader_name.id) 
                     or exists (
        select null
          from name_review_comment pnrc
     where pnrc.loader_name_id = loader_name.parent_id
                     )
                     or exists (
        select null
          from name_review_comment pnrc
     where pnrc.loader_name_id in (select id from loader_name child where loader_name.id = child.parent_id)
                     )
                     or exists (
        select null
          from name_review_comment pnrc
     where pnrc.loader_name_id in (select id from loader_name sibling where loader_name.parent_id = sibling.parent_id)
                     )
      ",
      order: "seq"},

   "has-review-comment-by:" => 
    { where_clause: "exists (
        select null
          from name_review_comment nrc
          join batch_reviewer br
            on nrc.batch_reviewer_id = br.id
          join users u
            on br.user_id = u.id
     where nrc.loader_name_id = loader_name.id 
       and lower(u.name)      = ?)
     or exists (
        select null
          from name_review_comment pnrc
          join batch_reviewer br
            on pnrc.batch_reviewer_id = br.id
          join users u
            on br.user_id = u.id
     where pnrc.loader_name_id = loader_name.parent_id
       and lower(u.name)      = ?)
     or exists (
        select null
          from name_review_comment cnrc
          join batch_reviewer br
            on cnrc.batch_reviewer_id = br.id
          join users u
            on br.user_id = u.id
     where cnrc.loader_name_id in (select id from loader_name child where loader_name.id = child.parent_id)
       and lower(u.name)      = ?)
     or exists (
        select null
          from name_review_comment snrc
          join batch_reviewer br
            on snrc.batch_reviewer_id = br.id
          join users u
            on br.user_id = u.id
     where snrc.loader_name_id in (select id from loader_name sibling where loader_name.parent_id = sibling.parent_id)
       and lower(u.name)      = ?)
      ",
      order: "seq"},

    "review-comment:" => 
    { where_clause: "exists (
        select null
          from name_review_comment nrc
     where nrc.loader_name_id = loader_name.id
     and lower(nrc.comment) like ?
                     ) 
                     or exists (
        select null
          from name_review_comment pnrc
     where pnrc.loader_name_id = loader_name.parent_id
     and lower(pnrc.comment) like ?
                     ) 
                     or exists (
        select null
          from name_review_comment cnrc
     where cnrc.loader_name_id in (select id from loader_name child where loader_name.id = child.parent_id)
     and lower(cnrc.comment) like ?
                     )
                     or exists (
        select null
          from name_review_comment snrc
     where snrc.loader_name_id in (select id from loader_name sibling where loader_name.parent_id = sibling.parent_id)
     and lower(snrc.comment) like ?
                     ) 
      ",
      leading_wildcard: true,
      trailing_wildcard: true,
      order: "seq"},

   "comment-type:" => 
    { where_clause: "exists (
        select null
          from name_review_comment nrc
               join name_review_comment_type nrct
               on nrc.name_review_comment_type_id = nrct.id
     where nrc.loader_name_id = loader_name.id
     and lower(nrct.name) like ?
                     ) 
                     or exists (
        select null
          from name_review_comment pnrc
               join name_review_comment_type pnrct
               on pnrc.name_review_comment_type_id = pnrct.id
     where pnrc.loader_name_id = loader_name.parent_id
     and lower(pnrct.name) like ?
                     ) 
                     or exists (
        select null
          from name_review_comment cnrc
               join name_review_comment_type cnrct
               on cnrc.name_review_comment_type_id = cnrct.id
     where cnrc.loader_name_id in (select id from loader_name child where loader_name.id = child.parent_id)
     and lower(cnrct.name) like ?
                     )
                     or exists (
        select null
          from name_review_comment snrc
               join name_review_comment_type snrct
               on snrc.name_review_comment_type_id = snrct.id
     where snrc.loader_name_id in (select id from loader_name sibling where loader_name.parent_id = sibling.parent_id)
     and lower(snrct.name) like ?
                     ) 
      ",
      leading_wildcard: true,
      trailing_wildcard: true,
      order: "seq"},
   "simple-name-not-like:" => { where_clause: "(lower(simple_name) not like '%'||?||'%')"},
   "family:" => { where_clause: "(lower(family) like ?)"},
   "family-id:" => { where_clause: "(lower(family) like (select lower(simple_name) from loader_name where id = ?))"},
    "record-type:" => { where_clause: " record_type = ?",
                               order: "seq"},
    "excluded:" => { where_clause: " record_type = 'excluded' ",
                               order: "seq"},
    "not-excluded:" => { where_clause: " record_type != 'excluded' ",
                               order: "seq"},

    "remark:" => { where_clause: "(lower(remark_to_reviewers) like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id         = loader_name.parent_id
       and lower(parent.remark_to_reviewers) like ?)
        or exists (
        select null
          from loader_name child
        where child.parent_id   = loader_name.id
       and lower(child.remark_to_reviewers) like ?)
        or exists (
        select null
          from loader_name sibling
        where sibling.parent_id = loader_name.parent_id
       and lower(sibling.remark_to_reviewers) like ?)",
           leading_wildcard: true,
           trailing_wildcard: true,
           order: "seq"},

    "higher-rank-comment:" => { where_clause: "(lower(higher_rank_comment) like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id         = loader_name.parent_id
       and lower(parent.higher_rank_comment) like ?)
        or exists (
        select null
          from loader_name child
        where child.parent_id   = loader_name.id
       and lower(child.higher_rank_comment) like ?)
        or exists (
        select null
          from loader_name sibling
        where sibling.parent_id = loader_name.parent_id
       and lower(sibling.higher_rank_comment) like ?)",
           leading_wildcard: true,
           trailing_wildcard: true,
           order: "seq"},

      "distribution:" => 
       { where_clause: "(lower(distribution) like ?)
          or exists (
          select null
            from loader_name parent
          where parent.id = loader_name.parent_id
         and lower(parent.distribution) like ?)",
       leading_wildcard: true,
       trailing_wildcard: true,
       order: "seq"},

    "distribution-not:" =>
           { where_clause: "(lower(distribution) not like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id = loader_name.parent_id
       and lower(parent.distribution) not like ?)",
        leading_wildcard: true,
        trailing_wildcard: true,
        order: "seq"},

    "no-distribution:" => { 
        where_clause: " record_type = 'accepted' and (distribution is null or distribution = '') 
        or exists (
        select null
          from loader_name parent
        where parent.id = loader_name.parent_id
       and record_type= 'accepted'
       and (distribution is null or distribution = ''))",
        order: "seq"},

    "name:"               => { trailing_wildcard: true,
                               where_clause: " lower(scientific_name) like ? or lower(scientific_name) like 'x '||? or lower(scientific_name) like '('||? ",
                                      order: "seq"},
    "name-no-wildcard:"   => { where_clause: " lower(scientific_name) like ? or lower(scientific_name) like 'x '||? or lower(scientific_name) like '('||?",
                                      order: "seq"},
    "name-with-syn:"      => { trailing_wildcard: true,
                                      where_clause: " ((lower(scientific_name) like ?
                                   or lower(scientific_name) like 'x '||?
                                   or lower(scientific_name) like '('||?)
                                  and record_type = 'accepted'
                                  and unplaced is null)
                                   or (parent_id in (
                                  select id
                                    from orchids
                                    where (lower(scientific_name) like ?
                                      or lower(scientific_name) like 'x '||?
                                      or lower(scientific_name) like '('||?)
                                      and record_type = 'accepted'
                                  and unplaced is null))",
                               order: "seq"},
    "id-with-syn:"        => { where_clause: "id = ? or parent_id = ?",
                               order: "seq"},
    "has-parent:"         => { where_clause: "parent_id is not null",
                                      order: "seq"},
    "has-no-parent:"      => { where_clause: "parent_id is null",
                                      order: "seq"},
    "accepted:"        => { where_clause: "record_type = 'accepted'",
                                      order: "seq"},
    "excluded:"        => { where_clause: "record_type = 'excluded'",
                                      order: "seq"},
    "syn:"             => { where_clause: "record_type = 'synonym'",
                                      order: "seq"},
    "misapplied:"      => { where_clause: "record_type = 'misapplied'",
                                      order: "seq"},
    "not-misapplied:"  => { where_clause: "record_type != 'misapplied'",
                                      order: "seq"},
    "hybrid:"    => { where_clause: "hybrid_flag = 'hybrid'",
                                      order: "seq"},
    "intergrade:"    => { where_clause: "hybrid_flag = 'intergrade'",
                                      order: "seq"},
    "mso-normal:"    => { where_clause: "hybrid_flag = 'MsoNormal'",
                                      order: "seq"},
    "syn-but-no-syn-type:" => { where_clause: "record_type = 'synonym' and synonym_type is null",
                                      order: "seq"},
    "no-name-match:" => { where_clause: "not exists (
        select null
          from name
        where (loader_name.simple_name = name.simple_name
               or
               loader_name.simple_name = name.full_name)
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))",
                                      order: "seq"},
    "no-name-match-unscientific:" => { where_clause: "not exists (
        select null
          from name
        where (loader_name.simple_name = name.simple_name
               or
               loader_name.simple_name = name.full_name))",
                                      order: "seq"},
     "no-name-match-unaccent:" => { where_clause: "loader_name.id in (select id
  from loader_name
 where lower(f_unaccent(simple_name)) in (
        select lower(f_unaccent(ln.simple_name))
          from loader_name ln
        except (
            select lower(f_unaccent(n.simple_name))
              from name n
            union all
            select lower(f_unaccent(n.full_name))
          from name n
          )
       ) ) ",
                           order: "seq"},
    "some-name-match:" => { where_clause: "exists (
                              select null
                                from name
                                where (loader_name.simple_name = name.simple_name
                               or loader_name.simple_name = name.full_name)
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))",
                               order: "seq"},
    "some-name-match-unscientific:" => { where_clause: "exists (
                              select null
                                from name
                                where (loader_name.simple_name = name.simple_name
                               or loader_name.simple_name = name.full_name)
          and not exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))",
                               order: "seq"},
    "many-name-match:" => { where_clause: "1 < (
        select count(*)
          from name
        where (loader_name.simple_name = name.simple_name
               or 
               loader_name.simple_name = name.full_name)
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))",
                                      order: "seq"},
    "many-name-match-unaccent:"    => { where_clause: "loader_name.id in (select id
  from loader_name
 where lower(f_unaccent(simple_name)) in
(select l_fa_sn from
    (
    select lower(f_unaccent(n.simple_name)) l_fa_sn, 'name' tab
                      from name n
    union all
    select distinct lower(f_unaccent(ln.simple_name)) l_fa_sn, 'loader' tab
                      from loader_name ln
     where loader_batch_id = (select id from loader_batch where lower(name) = ?)  
    )  fred
group by l_fa_sn
having count(*) > 2
))" ,
  order: "seq"},
  "one-name-match:" => { where_clause: "1 = (
      select count(*)
        from name
      where loader_name.simple_name = name.simple_name
        and exists (
          select null
            from name_Type nt
          where name.name_type_id       = nt.id
     and nt.scientific))",
                         order: "seq"},
         "name-match-no-primary:" => { where_clause: "0 < (
      select count(*)
        from name
      where loader_name.simple_name          = name.simple_name
        and exists (
          select null
            from name_Type nt
          where name.name_type_id                = nt.id
            and nt.scientific
            and not exists (
              select null
                from instance
                join instance_type
                  on instance.instance_type_id        = instance_type.id
              where instance_type.primary_instance
     and name.id                          = instance.name_id)))
     AND ( not exists (
      select null
        from loader_name_match
   where loader_name_match.loader_name_id = loader_name.id )) ",
                         order: "seq"},
          "name-match-eq:" => { where_clause: "? = (
      select count(*)
        from name
        where loader_name.simple_name = name.simple_name
          and exists (
          select null
            from name_Type nt
            where name.name_type_id       = nt.id
      and nt.scientific))",
                                      order: "seq"},
           "name-match-gt:" => { where_clause: "? < (
        select count(*)
          from name
        where loader_name.simple_name = name.simple_name
          and exists (
            select null
              from name_Type nt
            where name.name_type_id       = nt.id
       and nt.scientific))",
                                      order: "seq"},
           "name-match-gte:" => { where_clause: "? <= (
        select count(*)
          from name
        where loader_name.simple_name = name.simple_name
          and exists (
            select null
              from name_Type nt
            where name.name_type_id       = nt.id
       and nt.scientific))",
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
"use-batch-default-ref:" => { where_clause: " exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and loader_name_match.use_batch_default_reference)",
                           order: "seq"},
"use-existing-instance:" => { where_clause: " exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and loader_name_match.standalone_instance_id is not null
   and not loader_name_match.copy_append_from_existing_use_batch_def_ref)",
                           order: "seq"},
"copy-and-append:" => { where_clause: " exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and loader_name_match.standalone_instance_id is not null
   and loader_name_match.copy_append_from_existing_use_batch_def_ref)",
                           order: "seq"},
 "no-nomination:" => { where_clause: " loader_name.record_type = 'accepted' and exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and not loader_name_match.use_batch_default_reference
   and loader_name_match.standalone_instance_id is null)",
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
    "hybrid-flag:"=> { where_clause: "hybrid_flag like ?",
                                      order: "seq"},
    "no-hybrid-flag:"=> { where_clause: "hybrid_flag is null",
                                      order: "seq"},
    "no-further-processing:"=> { where_clause: " no_further_processing or exists (select null from loader_name kids where kids.parent_id = loader_name.id and kids.no_further_processing) or exists (select null from orchids pa where pa.id = orchids.parent_id and pa.no_further_processing)",
                               order: "seq"},
    "isonym:"=> { where_clause: "isonym is not null",
                                      order: "seq"},
    "orth-var:"=> { where_clause: "name_status like 'orth%'",
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
    "no-rank:"         => { where_clause: "rank is null",
                                      order: "seq"},
    "nsl-rank:"         => { where_clause: "lower(nsl_rank) like ?",
                                      order: "seq"},
    "not-nsl-rank:"         => { where_clause: "lower(nsl_rank) not like ?",
                                      order: "seq"},
    "no-nsl-rank:"         => { where_clause: "nsl_rank is null",
                                      order: "seq"},
    "doubtful:"=> { where_clause: "doubtful is not null",
                                      order: "seq"},
    "not-doubtful:"=> { where_clause: "doubtful is null",
                                      order: "seq"},
    "excluded-with-syn:"   => { trailing_wildcard: true,
                           where_clause: " (lower(scientific_name) like ? and record_type = 'excluded') or (parent_id in (select id from loader_name where lower(scientific_name) like ? and record_type = 'excluded'))",
                               order: "seq"},

    "comment:" =>
     { where_clause: "(lower(comment) like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id = loader_name.parent_id
       and lower(parent.comment) like ?)
        or exists (
        select null
          from loader_name child
        where child.parent_id = loader_name.id
       and lower(child.comment) like ?)
        or exists (
        select null
          from loader_name sibling
        where sibling.parent_id = loader_name.parent_id
       and lower(sibling.comment) like ?)",
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
"created-manually:" => { where_clause: "created_manually" },
  }.freeze
end
