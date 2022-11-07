alter table loader_name_match add constraint standalone_created_or_found check 
((standalone_instance_id is null and standalone_instance_created = false and standalone_instance_found = false) or
 (standalone_instance_id is not null and standalone_instance_created = true and standalone_instance_found = false) or
 (standalone_instance_id is not null and standalone_instance_created = false and standalone_instance_found = true) 
);
