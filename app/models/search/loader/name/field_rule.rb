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
                        trailing_wildcard: true},
    "bulk-ops:" => { where_clause: "(
      (
        (
          lower(simple_name) like ?
          or lower(simple_name) like 'x '||?
          or lower(simple_name) like '('||?)
        )
        and record_type in ('accepted', 'excluded')
      )
    or
      (parent_id in
        (select id
           from loader_name
          where (
                  (
                    lower(simple_name) like ?
                    or lower(simple_name) like 'x '||?
                    or lower(simple_name) like '('||?)
                  )
                  and record_type in ('accepted', 'excluded')
                )
        )"},
    "bulk-ops-family:" => { where_clause: "(
      ( lower(simple_name) like ? and rank = 'family')
    or
      (
        (
          lower(family) like ?
          or lower(family) like 'x '||?
          or lower(family) like '('||?)
        )
        and record_type in ('accepted', 'excluded')
      )
    or
      (parent_id in
        (select id
           from loader_name
          where (
                  (
                    lower(family) like ?
                    or lower(family) like 'x '||?
                    or lower(family) like '('||?)
                  )
                  and record_type in ('accepted', 'excluded')
                )
        )"},
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
                                  trailing_wildcard: true},
    "batch-id:" => { where_clause: "loader_batch_id = ? "},
    "batch-name:" => { where_clause: "loader_batch_id in (select id from loader_batch where lower(name) like ?)  "},
    "default-batch:" => { where_clause: "loader_batch_id = (select id from loader_batch where lower(name) = ?)  "},
    "id:" => { multiple_values: true,
               where_clause: "id = ? or parent_id = ? ",
               multiple_values_where_clause: " id in (?)"},
    "ids:" => { multiple_values: true,
                where_clause: " id = ? or parent_id = ?",
                multiple_values_where_clause: " id in (?)"},
    "raw-id:" => { multiple_values: true,
                   where_clause: "raw_id = ? or parent_raw_id = ? ",
                   multiple_values_where_clause: " raw_id in (?) or parent_raw_id in (?)"},

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
      "},

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
      "},

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
      trailing_wildcard: true},

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
      trailing_wildcard: true},
    "simple-name-not-like:" => { where_clause: "(lower(simple_name) not like '%'||?||'%')" },
    "family:" => { where_clause: "(lower(family) like ?)" },
    "families:" => { where_clause: "lower(family) like ? || '%'  and lower(rank) = 'family'"},
    "family-id:" => { where_clause: "(lower(family) like (select lower(simple_name) from loader_name where id = ?))" },
    "record-type:" => { where_clause: " record_type = ?"},

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
                   trailing_wildcard: true},

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
                                trailing_wildcard: true},

    "distribution:" =>
       { where_clause: "(lower(distribution) like ?)
          or exists (
          select null
            from loader_name parent
          where parent.id = loader_name.parent_id
         and lower(parent.distribution) like ?)",
         leading_wildcard: true,
         trailing_wildcard: true},

    "distribution-not:" =>
           { where_clause: "(lower(distribution) not like ?)
        or exists (
        select null
          from loader_name parent
        where parent.id = loader_name.parent_id
       and lower(parent.distribution) not like ?)",
             leading_wildcard: true,
             trailing_wildcard: true},

    "no-distribution:" => {
      where_clause: " record_type = 'accepted' and (distribution is null or distribution = '')
        or exists (
        select null
          from loader_name parent
        where parent.id = loader_name.parent_id
       and record_type= 'accepted'
       and (distribution is null or distribution = ''))"},
    "name:" => { trailing_wildcard: true,
                 where_clause: " lower(simple_name) like ? or lower(simple_name) like 'x '||? or lower(simple_name) like '('||? "},
    "name-no-wildcard:" => { where_clause: " lower(simple_name) like ? or lower(simple_name) like 'x '||? or lower(simple_name) like '('||?"},
    "name-with-syn:" => { trailing_wildcard: true,
                          where_clause: " ((lower(simple_name) like ?
                                   or lower(simple_name) like 'x '||?
                                   or lower(simple_name) like '('||?)
                                  and record_type = 'accepted')
                                   or (parent_id in (
                                  select id
                                    from loader_name
                                    where (lower(simple_name) like ?
                                      or lower(simple_name) like 'x '||?
                                      or lower(simple_name) like '('||?)
                                      and record_type = 'accepted'))"},
    "id-with-syn:" => { where_clause: "id = ? or parent_id = ?"},
    "has-parent:" => { where_clause: "parent_id is not null"},
    "has-no-parent:" => { where_clause: "parent_id is null"},
    "accepted:" => { where_clause: "record_type = 'accepted'"},
    "excluded:" => { where_clause: "record_type = 'excluded'"},
    "not-excluded:" => { where_clause: " record_type != 'excluded' "},
    "syn:" => { where_clause: "record_type = 'synonym'"},
    "misapplied:" => { where_clause: "record_type = 'misapplied'"},
    "not-misapplied:" => { where_clause: "record_type != 'misapplied'"},
    "is-hybrid:" => { where_clause: "hybrid_flag = 'hybrid'"},
    "is-intergrade:" => { where_clause: "hybrid_flag = 'intergrade'"},
    "is-mso-normal:" => { where_clause: "hybrid_flag = 'MsoNormal'"},
    "syn-but-no-syn-type:" => { where_clause: "record_type = 'synonym' and synonym_type is null"},
    "no-name-match:" => { where_clause: "record_type not in ('heading')
     and not exists (
        select null
          from name
        where (loader_name.simple_name = name.simple_name
               or
               loader_name.simple_name = name.full_name)
          and duplicate_of_id is null
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))"},
    "no-name-match-unscientific:" => { where_clause: "record_type not in ('heading')
     and not exists (
        select null
          from name
        where duplicate_of_id is null
        and (loader_name.simple_name = name.simple_name
               or
               loader_name.simple_name = name.full_name))"},
    "no-name-match-unaccent:" => { where_clause: "record_type not in ('heading')
    and loader_name.id in (select id
  from loader_name
 where lower(f_unaccent(simple_name)) in (
        select lower(f_unaccent(ln.simple_name))
          from loader_name ln
        except (
            select lower(f_unaccent(n.simple_name))
              from name n
             where duplicate_of_id is null
            union all
            select lower(f_unaccent(n.full_name))
          from name n
           where duplicate_of_id is null
          )
       ) ) "},
    "some-name-match:" => { where_clause: "record_type not in ('heading')
        and exists (
                              select null
                                from name
                                where (loader_name.simple_name = name.simple_name
                               or loader_name.simple_name = name.full_name)
          and duplicate_of_id is null
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))"},
    "some-name-match-unscientific:" => { where_clause: "record_type not in ('heading')
      and exists (
                              select null
                                from name
                                where (loader_name.simple_name = name.simple_name
                               or loader_name.simple_name = name.full_name)
          and duplicate_of_id is null
          and not exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))"},
    "many-name-match:" => { where_clause: "record_type not in ('heading')
     and 1 < (
        select count(*)
          from name
        where (loader_name.simple_name = name.simple_name
               or
               loader_name.simple_name = name.full_name)
          and duplicate_of_id is null
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))"},
    "many-name-match-unaccent:" => { where_clause: "record_type not in ('heading')
 and loader_name.id in (select id
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
))"},
    "one-name-match:" => { where_clause: "record_type not in ('heading')
  and 1 = (
      select count(*)
        from name
      where (loader_name.simple_name = name.simple_name
             or
             loader_name.simple_name = name.full_name)
        and duplicate_of_id is null
        and exists (
          select null
            from name_Type nt
          where name.name_type_id       = nt.id
     and nt.scientific))"},
    "name-match-no-primary:" => { where_clause: " record_type != 'heading'
   and exists ( select null
             from name
                  join name_type nty
                  on name.name_type_id = nty.id
      where duplicate_of_id is null
      and (loader_name.simple_name = name.simple_name
             or
             loader_name.simple_name = name.full_name)
                  and nty.name = 'scientific'
                )
   and not exists (
                   select null
                     from name
                          join instance
                          on name.id = instance.name_id
                          join instance_type ity
                          on instance.instance_type_id = ity.id
                          join name_type nty
                          on name.name_type_id = nty.id
                    where loader_name.simple_name = name.simple_name
                      and ity.primary_instance = true
                      and nty.name = 'scientific'
          )"},
    "name-match-eq:" => { where_clause: "record_type not in ('heading')
 and ? = (
      select count(*)
        from name
      where (loader_name.simple_name = name.simple_name
             or
             loader_name.simple_name = name.full_name)
   and duplicate_of_id is null
          and exists (
          select null
            from name_Type nt
            where name.name_type_id       = nt.id
      and nt.scientific))"},
    "name-match-gt:" => { where_clause: "record_type not in ('heading')
 and ? < (
        select count(*)
          from name
      where (loader_name.simple_name = name.simple_name
             or
             loader_name.simple_name = name.full_name)
          and exists (
            select null
              from name_Type nt
            where name.name_type_id       = nt.id
       and nt.scientific))"},
    "name-match-gte:" => { where_clause: "record_type not in ('heading')
 and ? <= (
        select count(*)
          from name
      where (loader_name.simple_name = name.simple_name
             or
             loader_name.simple_name = name.full_name)
          and exists (
            select null
              from name_Type nt
            where name.name_type_id       = nt.id
       and nt.scientific))"},
    "partly:" => { where_clause: "partly is not null"},
    "not-partly:" => { where_clause: "partly is null"},
    "name-sharing-name-id:" => { where_clause: " id in (select loader_name_id from loader_name_match where name_id in (select name_id from loader_name_match group by name_id having count(*) > 1))"},
    "xnon-misapp-name-sharing-name-id:" => { where_clause: " id in (select loader_name_id from loader_name_match where name_id in (select name_id from loader_name_match where loader_name_id in (select id from orchids where record_type != 'misapplied') group by name_id having count(*) > 1))"},
    "xnon-misapp-name-sharing-name-id-not-pp:" => { where_clause: "id in (select loader_name_id
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
       ))"},
    "has-preferred-name:" => { where_clause: " exists (select null from loader_name_match where loader_name.id = loader_name_match.loader_name_id)"},
    "has-preferred-name-without-instance:" => { where_clause: " exists (select null from loader_name_match orn where loader_name.id = orn.loader_name_id and orn.standalone_instance_id is null and orn.relationship_instance_id is null)"},
    "use-batch-default-ref:" => { where_clause: " exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and loader_name_match.use_batch_default_reference)"},
    "use-existing-instance:" => { where_clause: " exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and loader_name_match.standalone_instance_id is not null
   and loader_name_match.use_existing_instance)"},
    "copy-and-append:" => { where_clause: " exists (
    select null
      from loader_name_match
 where loader_name.id = loader_name_match.loader_name_id
   and loader_name_match.instance_choice_confirmed
   and loader_name_match.copy_append_from_existing_use_batch_def_ref)"},
    "no-nomination:" => {
      where_clause: " loader_name.record_type in ('accepted','excluded')
                and exists (
                   select null
                     from loader_name_match
                   where loader_name.id = loader_name_match.loader_name_id
                     and not loader_name_match.use_batch_default_reference
                     and not copy_append_from_existing_use_batch_def_ref
                     and loader_name_match.standalone_instance_id is null)"},
    "has-no-preferred-name:" => { where_clause: " not exists (select null from loader_name_match where loader_name.id = loader_name_match.loader_name_id)" },
    "created-by:" => { where_clause: "created_by = ?"},
    "updated-by:" => { where_clause: "updated_by = ?"},
    "not-created-by:" => { where_clause: "created_by != ?"},
    "not-created-by-batch:" => { where_clause: "created_by != 'batch'"},
    "original-text:" => { where_clause: "lower(original_text) like ?"},
    "original-text-has-×:" => { where_clause: "lower(original_text) like '%×%'"},
    "original-text-has-x:" => { where_clause: "lower(original_text) like '%×%'"},
    "hybrid-flag:" => { where_clause: "hybrid_flag like ?"},
    "no-hybrid-flag:" => { where_clause: "hybrid_flag is null"},
    "no-further-processing:" => { where_clause: " no_further_processing or exists (select null from loader_name kids where kids.parent_id = loader_name.id and kids.no_further_processing) or exists (select null from loader_name pa where pa.id = loader_name.parent_id and pa.no_further_processing)"},
    "isonym:" => { where_clause: "isonym is not null"},
    "orth-var:" => { where_clause: "name_status like 'orth%'"},
    "name-status:" => { where_clause: "name_status like ?",
                        leading_wildcard: true,
                        trailing_wildcard: true},
    "name-status-empty-string:" => { where_clause: "name_status = ''"},
    "name-status-exact:" => { where_clause: "name_status like ?"},
    "notes:" => { where_clause: "lower(notes) like ?",
                  leading_wildcard: true,
                  trailing_wildcard: true},
    "rank:" => { where_clause: "lower(rank) like ?"},
    "not-rank:" => { where_clause: "lower(rank) not like ?"},
    "no-rank:" => { where_clause: "rank is null"},
    "nsl-rank:" => { where_clause: "lower(nsl_rank) like ?"},
    "not-nsl-rank:" => { where_clause: "lower(nsl_rank) not like ?"},
    "no-nsl-rank:" => { where_clause: "nsl_rank is null"},
    "doubtful:" => { where_clause: "doubtful is not null"},
    "not-doubtful:" => { where_clause: "doubtful is null"},
    "excluded-with-syn:" => { trailing_wildcard: true,
                              where_clause: " (lower(simple_name) like ? and record_type = 'excluded') or (parent_id in (select id from loader_name where lower(simple_name) like ? and record_type = 'excluded'))"},

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
       trailing_wildcard: true},

    "in-current-taxonomy:" => { where_clause: "loader_name.id in (select distinct o.id
  from loader_name_match orn
  join loader_name o
    on orn.loader_name_id = o.id
 where o.record_type = 'accepted'
   and orn.name_id in (
    select name_id
  from tree_join_v
  where accepted_tree
    and tree_version_id = current_tree_version_id
       )
 order by o.id)",
                                trailing_wildcard: true},
    "not-in-current-taxonomy:" => { where_clause: "loader_name.id in (select id from orchids where record_type = 'accepted') and loader_name.id not in (select distinct o.id
  from loader_name_match orn
  join loader_name o
    on orn.loader_name_id = o.id
 where orn.name_id in (
    select name_id
  from tree_join_v
  where accepted_tree
    and tree_version_id = current_tree_version_id
       )
 order by o.id)",
                                    trailing_wildcard: true},
    "syn-type:" => { where_clause: "lower(synonym_type) like ?"},
    "manually-drafted:" => { where_clause: " id in (select loader_name_id from loader_name_match where manually_drafted)"},
    "drafted:" => { where_clause: " id in (select loader_name_id from loader_name_match where drafted)"},
    "xmisapp-matched-without-cross-ref:" => { where_clause: " id in (select o.id from orchids o join loader_name_match orn on o.id = orn.loader_name_id where o.record_type = 'misapplied' and orn.relationship_instance_id is null)"},
    "created-manually:" => { where_clause: "created_manually" },
"syn-match-in-tree-faster-join-b:" => { where_clause: " id in (select ln.id
  from loader_name ln 
       join loader_name_match lnm
       on ln.id = lnm.loader_name_id
       join instance i
       on lnm.name_id = i.name_id 
       join taxon_mv tmv 
       on i.id = tmv.instance_id 
       join loader_batch lb
       on ln.loader_batch_id = lb.id
 where tmv.nomenclatural_status in ('legitimate','[n/a]')
   and tmv.taxonomic_status in ('accepted','excluded')
   and ln.record_type = 'synonym')"
                                     },
"syn-match-in-tree-faster-join:" => { where_clause: " id in (select ln.id
  from loader_name ln 
       join loader_name_match lnm
       on ln.id = lnm.loader_name_id
       join instance i
       on lnm.name_id = i.name_id 
       join tree_join_v tjv 
       on i.id = tjv.instance_id 
       join loader_batch lb
       on ln.loader_batch_id = lb.id
       join name 
       on tjv.name_id = name.id
       join name_status ns
       on name.name_status_id= ns.id
 where ns.name in ('legitimate','[n/a]')
   and ln.record_type = 'synonym'
   and not tjv.published)"
     },
  "name-match-in-syn:" => { where_clause: " record_type in ('accepted', 'excluded')
       and exists (
       select null
       from loader_name_match
       join name pref_name
       on loader_name_match.name_id = pref_name.id
       join instance pref_name_instance
       on pref_name_instance.name_id = loader_name_match.name_id
       join instance_type pni_type
       on pref_name_instance.instance_type_id = pni_type.id
       join tree_join_v
       on pref_name_instance.cited_by_id = tree_join_v.instance_id
       join name name_on_tree
       on tree_join_v.name_id = name_on_tree.id
       join instance tree_name_instance
       on tree_name_instance.name_id = name_on_tree.id
 WHERE (1=1)
   and loader_name.id  = loader_name_match.loader_name_id
   and not loader_name_match.drafted
   and not loader_name_match.manually_drafted
   and tree_join_v.tree_version_id = tree_join_v.current_tree_version_id
   and pni_type.synonym
   and not pni_type.pro_parte
     )"},
    "syn-clash-with-syn:" => { where_clause: "
                                 ( exists (
       select null
  from loader_name parent
  join loader_name_match parent_match
    on parent.id = parent_match.loader_name_id
  join loader_name child
    on parent.id = child.parent_id
  join loader_name_match child_match
    on child.id = child_match.loader_name_id
  join instance cmi
    on child_match.name_id = cmi.name_id
  join instance_type cmi_type
    on cmi.instance_type_id = cmi_type.id
  join instance citer
    on cmi.cited_by_id = citer.id
  join instance_type citer_type
    on citer.instance_type_id = citer_type.id
  join tree_join_v citer_tree
    on citer.id = citer_tree.instance_id
  join name cot_name
    on citer_tree.name_id = cot_name.id
 where loader_name.id = parent.id
   and parent.record_type in ('accepted', 'excluded')
   and cmi_type.relationship
   and not cmi_type.misapplied
   and not cmi_type.pro_parte
   and citer_tree.tree_version_id = current_tree_version_id
   and parent_match.name_id != cot_name.id
   and child.record_type != 'misapplied'
     )
    or  exists (
       select null
  from loader_name parent
  join loader_name_match parent_match
    on parent.id = parent_match.loader_name_id
  join loader_name child
    on parent.id = child.parent_id
  join loader_name_match child_match
    on child.id = child_match.loader_name_id
  join instance cmi
    on child_match.name_id = cmi.name_id
  join instance_type cmi_type
    on cmi.instance_type_id = cmi_type.id
  join instance citer
    on cmi.cited_by_id = citer.id
  join instance_type citer_type
    on citer.instance_type_id = citer_type.id
  join tree_join_v citer_tree
    on citer.id = citer_tree.instance_id
  join name cot_name
    on citer_tree.name_id = cot_name.id
 where loader_name.id = child.id
   and parent.record_type in ('accepted', 'excluded')
   and cmi_type.relationship
   and not cmi_type.misapplied
   and not cmi_type.pro_parte
   and citer_tree.tree_version_id = current_tree_version_id
   and parent_match.name_id != cot_name.id
   and child.record_type != 'misapplied'
     ))"},
  "any-batch:" => { where_clause: "1=1" },
  }.freeze
end
