

update loader_name
   set distribution = regexp_replace(distribution,' \|',',','g'),
       updated_by = 'nsl-4771',
       updated_at = Now()
 where distribution like '%|%' 
   and loader_batch_id = (select id
                            from loader_batch
                           where name = 'APC List 105')
;

