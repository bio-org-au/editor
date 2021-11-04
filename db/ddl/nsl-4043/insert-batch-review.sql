insert into batch_review (name,loader_batch_id) values ('A Review', (select max(id) from loader_batch));
