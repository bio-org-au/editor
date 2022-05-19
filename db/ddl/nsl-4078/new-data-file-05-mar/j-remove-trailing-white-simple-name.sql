update loader_name
   set simple_name = regexp_replace(simple_name, ' *$','')
 where simple_name ~ ' $'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc list 103 draft 05 mar'
       );
