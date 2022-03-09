
begin;


update loader_name
   set simple_name = replace(simple_name_as_loaded,'–','-'), 
       updated_by = 'greg',
       updated_at = now()
 where simple_name_as_loaded ~ '–'
   and simple_name !~ '-'
   and loader_batch_id = (
    select id
      from loader_batch
 where name            = 'APC List 103'
       );
