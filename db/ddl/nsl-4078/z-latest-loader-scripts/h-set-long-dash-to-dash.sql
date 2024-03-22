

begin;

select count(*)
  from loader_name
 where simple_name ~ '–'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name) = lower('APC List 103 draft 20 Mar 2023')
       );

update loader_name
   set simple_name = replace(simple_name_as_loaded,'–','-'), 
       updated_by = 'greg: bulk job at load',
       updated_at = now()
 where simple_name_as_loaded ~ '–'
   and simple_name !~ '-'
   and loader_batch_id = (
    select id
      from loader_batch
 where lower(name) = lower('APC List 103 draft 20 Mar 2023')
       );

commit;
