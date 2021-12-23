select ln.id, ln.raw_id, ln.scientific_name, ln.parent_id,
       ln.parent_raw_id, parent.scientific_name parent_name, parent.id
  from loader_name ln
  left outer join loader_name parent
    on ln.loader_batch_id = parent.loader_batch_id
   and ln.parent_raw_id = parent.raw_id
 where ln.loader_batch_id = (
    select id
      from loader_batch
 where name                = 'List 100'
       )
 order by ln.id limit 20;
