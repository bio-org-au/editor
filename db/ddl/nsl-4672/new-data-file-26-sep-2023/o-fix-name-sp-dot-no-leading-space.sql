
update loader_name
   set simple_name = regexp_replace(simple_name, '([^ ])sp\.', '\1 sp.'),
       full_name = regexp_replace(full_name, '([^ ])sp\.', '\1 sp.'),
       updated_at = now(),
       updated_by = 'fix sp. job'
 where (simple_name ~ '[^ ]sp\.'
        and
        simple_name !~ 'subsp\.')
    or (full_name ~ '[^ ]sp\.'
        and 
        full_name !~ 'subsp\.')
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc 2022 updates'
       );



