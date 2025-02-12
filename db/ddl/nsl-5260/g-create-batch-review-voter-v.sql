create or replace view 
batch_review_voter_v
as
select br.id batch_review_id,
       br.name batch_review,
       brp.id batch_review_period_id,
       brp.name batch_review_period,
       org.id org_id,
       org.name org,
       users.name user_name
  from batch_review br
  join batch_review_period brp
    on br.id = brp.batch_review_id
  join batch_reviewer brr
    on brp.id = brr.batch_review_period_id
  join users 
    on brr.user_id = users.id
  join org
    on brr.org_id = org.id
  join org_batch_review_voter obrv
    on org.id = obrv.org_id
       and 
       br.id = obrv.batch_review_id
;

grant select on batch_review_voter_v to webapni;
