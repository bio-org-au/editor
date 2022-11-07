alter table loader_name_match add constraint valid_use_existing_instance check (
(use_existing_instance and standalone_instance_found and standalone_instance_id is not null) or
(use_existing_instance and relationship_instance_found and relationship_instance_id is not null) or
(not use_existing_instance and not standalone_instance_found and standalone_instance_id is null) or
(not use_existing_instance and not relationship_instance_found and relationship_instance_id is null)
);
