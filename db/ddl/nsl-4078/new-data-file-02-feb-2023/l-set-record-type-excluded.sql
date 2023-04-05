update loader_name
   set record_type = 'excluded'
 where record_type = 'accepted'
   and excluded
   and loader_batch_id in (
    select id
      from loader_batch
 where name = 'APC List 103 draft 02 feb 2023'
       );

