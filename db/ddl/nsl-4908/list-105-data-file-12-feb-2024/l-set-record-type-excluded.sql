update loader_name
   set record_type = 'excluded'
 where record_type = 'accepted'
   and unplaced = 'true'
   and loader_batch_id in (
    select id
      from loader_batch
 where name = 'APC List 105'
       );

