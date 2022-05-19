update loader_name
   set simple_name = replace(simple_name,'×','x'), 
       updated_by = 'greg',
       updated_at = now()
 where simple_name like '%×%'
   and loader_batch_id = (
    select id
      from loader_batch
 where name            = 'APC List 103'
       );
