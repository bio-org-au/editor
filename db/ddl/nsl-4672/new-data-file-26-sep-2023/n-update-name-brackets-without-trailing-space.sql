

update loader_name
   set simple_name = regexp_replace(simple_name, '\)([^ ])', ') \1'),
       updated_at = now(),
       updated_by = 'fix simple name brackets'
 where simple_name ~ '\)[^ ]'
   and simple_name !~ '\)\]'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc 2022 updates'
       );


update loader_name
   set full_name = regexp_replace(full_name, '\)([^ ])', ') \1'),
       updated_at = now(),
       updated_by = 'fix full name brackets'
 where full_name ~ '\)[^ ]'
   and full_name !~ '\)\]'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc 2022 updates'
       );
