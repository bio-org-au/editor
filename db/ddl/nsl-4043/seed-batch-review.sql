insert into batch_review (loader_batch_id, name) select id, name || ' Review' from loader_batch;
