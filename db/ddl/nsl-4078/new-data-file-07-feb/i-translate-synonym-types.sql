begin;

update loader_name
   set synonym_type = 'nomenclatural synonym', updated_by = 'greg synonym-type',
       updated_at = now()
 where synonym_type    = 'homotypic'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc list 103 draft 07 feb'
       ) ;

update loader_name
   set synonym_type = 'taxonomic synonym', updated_by = 'greg synonym-type',
       updated_at = now()
 where synonym_type    = 'heterotypic'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name)     = 'apc list 103 draft 07 feb'
       )
;

commit;
