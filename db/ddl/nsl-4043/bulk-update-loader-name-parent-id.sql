update loader_name 
set parent_id = (select id from loader_name parent where parent.raw_id = loader_name.parent_raw_id and parent.loader_batch_id = loader_name.loader_batch_id)
where loader_name.parent_raw_id is not null;
