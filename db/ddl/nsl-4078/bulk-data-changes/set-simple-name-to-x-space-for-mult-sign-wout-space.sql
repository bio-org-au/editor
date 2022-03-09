
begin;


update loader_name
   set simple_name = replace(simple_name_as_loaded,'×','x '), 
       updated_by = 'greg',
       updated_at = now()
 where simple_name_as_loaded ~ ' ×[A-z]'
   and simple_name !~ ' x '
   and loader_batch_id = (
    select id
      from loader_batch
 where name            = 'APC List 103'
       );
