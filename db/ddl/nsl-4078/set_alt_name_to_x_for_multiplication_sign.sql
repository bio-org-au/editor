update loader_name
   set alt_name_for_matching = replace(simple_name,'×','x')
 where simple_name like '%×%'
   and loader_batch_id = (
    select id
      from loader_batch
 where name            = 'APC List 103'
       );
