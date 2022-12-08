update loader_name
   set record_type = 'excluded'
 where record_type = 'accepted'
   and excluded
   and loader_batch_id in (
    select id
      from loader_batch
 where name = 'APC List 103 draft 05 Mar'
       );

--update mar set record_type = 'synonym' where record_type= 'excluded' and exists (select null from archive.loader_batch_raw_names_05_mar_2022 raw where mar.raw_id = raw.id and raw.record_type = 'synonym');
