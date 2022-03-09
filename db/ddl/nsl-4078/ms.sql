SELECT id,simple_name FROM "loader_name" WHERE (1=1) AND (not exists (
        select null
          from name
        where (loader_name.simple_name = name.simple_name
               or
               loader_name.simple_name = name.full_name)
          and exists (
            select null
              from name_type nt
            where name.name_type_id = nt.id
              and nt.scientific))) 
 AND (loader_batch_id = (select id from loader_batch where lower(name) = 'apc list 103 draft 16 feb')  )
 and exists (select null from name where name.simple_name like loader_name.simple_name || ' MS')
ORDER BY seq;

