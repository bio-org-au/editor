update loader_name set excluded = true where loader_batch_id = (select id from loader_batch where name = 'Second Batch') and unplaced = '1';
