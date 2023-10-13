update loader_name
   set record_type = 'heading'
 where loader_batch_id = (select id
                            from loader_batch
                           where name = 'APC 2022 Updates')
   and rank = 'family'
   and record_type = 'accepted';
