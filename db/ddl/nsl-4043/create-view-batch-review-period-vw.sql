
create view batch_review_period_vw as
select br.*, u.name user_name, u.given_name, u.family_name,
       period.name period, period.start_date,
       period.end_date, role.name role_name, 
       org.name org
  from batch_reviewer br
  join users u
    on br.user_id = u.id
  join batch_review_period period
    on br.batch_review_period_id = period.id
  join org
    on br.org_id = org.id
  join batch_review_role role
    on br.batch_review_role_id = role.id
;
