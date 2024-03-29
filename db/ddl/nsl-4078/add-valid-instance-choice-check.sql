alter table loader_name_match add constraint valid_instance_choice check (
(instance_choice_confirmed and use_batch_default_reference and not copy_append_from_existing_use_batch_def_ref and not use_existing_instance) or 
(instance_choice_confirmed and not use_batch_default_reference and copy_append_from_existing_use_batch_def_ref and not use_existing_instance) or 
(instance_choice_confirmed and not use_batch_default_reference and not copy_append_from_existing_use_batch_def_ref and use_existing_instance) or
(not instance_choice_confirmed and not use_batch_default_reference and not copy_append_from_existing_use_batch_def_ref and not use_existing_instance));
