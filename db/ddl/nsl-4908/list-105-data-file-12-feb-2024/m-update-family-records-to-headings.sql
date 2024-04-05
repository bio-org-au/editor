update loader_name
   set record_type = 'heading'
 where loader_batch_id = (select id
                            from loader_batch
                           where name = 'APC List 105')
   and rank = 'family'
   and record_type = 'accepted';
