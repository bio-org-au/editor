
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
 where u.name      = 'trev'
   and org.abbrev = 'ATH';

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
 where u.name      = 'jgrey'
   and org.abbrev = 'QH';
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
 where u.name      = 'tpogacar'
   and org.abbrev = 'RBGV';
