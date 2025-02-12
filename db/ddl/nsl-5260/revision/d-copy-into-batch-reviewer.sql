insert into batch_reviewer
(id,
 user_id,
 org_id,
 batch_review_role_id,
 batch_review_id,
 active,
 lock_version,
 created_at,
 created_by,
 updated_at,
 updated_by)
select 
 id,
 user_id,
 org_id,
 batch_review_role_id,
 (select brp.batch_review_id from batch_review_period brp where brp.id = batch_review_period_id),
 active,
 lock_version,
 created_at,
 created_by,
 updated_at,
 updated_by
from old_batch_reviewer;


