
update loader_name
   set synonym_type = 
         case
           when doubtful = 't' and (publ_partly = 'p.p.' or partly  = 'p.p.') then
            'doubtful pro parte misapplied'
           when doubtful = 't' then
            'doubtful misapplied'
           when publ_partly = 'p.p.' or partly = 'p.p.' then
            'pro parte misapplied'
           else 'misapplied'
          end
 where loader_batch_id = (select id
                            from loader_batch
                           where name = 'APC List 105')
   and record_type = 'misapplied';


