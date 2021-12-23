select br.id, br.user_id, u.name, u.given_name, u.family_name,
       br.batch_review_period_id, period.name, period.start_date,
       period.end_date, br.batch_review_role_id, role.name, br.org_id,
       org.name
  from batch_reviewer br
  join users u
    on br.user_id = u.id
  join batch_review_period period
    on br.batch_review_period_id = period.id
  join org
    on br.org_id = org.id
  join batch_review_role role
    on br.batch_review_role_id = role.id;

