begin;

update loader_name
   set simple_name = simple_name_as_loaded,
       updated_by = 'greg: bulk job reset',
       updated_at = now()
 where simple_name_as_loaded like '%×%'
   and updated_by = 'greg: bulk job at load'
   and loader_batch_id = (
    select id
      from loader_batch
 where name            = 'APC List 103 draft 07 Feb'
       );

select count(*)
  from loader_name
 where loader_batch_id = 51633760
   and simple_name ~ ' ×[A-z]'
;

update loader_name
   set simple_name = regexp_replace(simple_name, ' ×([A-z])', ' x \1'),
       updated_by = 'greg: bulk job at load',
       updated_at = now()
 where loader_batch_id =  (
    select id
      from loader_batch
 where name            = 'APC List 103 draft 07 Feb'
       )
   and simple_name ~ ' ×[A-z]';

select count(*)
  from loader_name
 where loader_batch_id = 51633760
   and simple_name ~ ' ×[A-z]'
;

select id, simple_name
  from loader_name
 where loader_batch_id = 51633760
   and simple_name ~ ' ×[A-z]'
order by 1,2
;

select count(*)
  from loader_name
 where loader_batch_id = 51633760
   and simple_name ~ '×'
;

update loader_name
   set simple_name = replace(simple_name,'×','x'), 
       updated_by = 'greg: bulk job at load',
       updated_at = now()
 where simple_name ~ '×'
   and loader_batch_id = (
    select id
      from loader_batch
 where name            = 'APC List 103 draft 07 Feb'
       );

select count(*)
  from loader_name
 where loader_batch_id = 51633760
   and simple_name ~ '×'
;


select id, simple_name
  from loader_name
 where loader_batch_id = 51633760
   and simple_name ~ '×'
order by 1,2
;

commit;
