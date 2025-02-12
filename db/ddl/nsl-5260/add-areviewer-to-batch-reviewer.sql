insert into batch_reviewer (user_id,
       org_id, batch_review_role_id, batch_review_period_id
     )
select u.id, org.id, r.id, p.id
  from org
  join users u
    on 1=1
  join batch_review_role r
    on 1=1
  join batch_review_period p
    on 1=1
 where u.name      = 'areviewer'
   and org.abbrev = 'PERTH' 
   and r.name = 'name reviewer'
   and p.id = (select min(id)
                 from batch_review_period 
                where batch_review_id = (select min(id)
                                           from batch_review
                                          where loader_batch_id = (select id
                                                                     from loader_batch
                                                                    where name = 'APC 2022 Updates')
                                        )
              )
;
