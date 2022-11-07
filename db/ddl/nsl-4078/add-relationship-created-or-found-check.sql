alter table loader_name_match add constraint relationship_created_or_found check 
((relationship_instance_id is null and relationship_instance_created = false and relationship_instance_found = false) or
 (relationship_instance_id is not null and relationship_instance_created = true and relationship_instance_found = false) or
 (relationship_instance_id is not null and relationship_instance_created = false and relationship_instance_found = true) 
);
