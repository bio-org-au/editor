update loader_name set record_type = 'heading' where loader_batch_id = (select id from loader_batch where name = 'APC List 103 draft 05 Mar') and rank = 'family' ;
