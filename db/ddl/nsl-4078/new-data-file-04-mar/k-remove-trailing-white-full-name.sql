update loader_name
   set full_name = regexp_replace(full_name, ' *$','')
 where full_name ~ ' $'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc list 103 draft 04 mar'
       );
