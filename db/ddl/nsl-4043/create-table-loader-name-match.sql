create table loader_name_match (
  id bigint not null default  nextval('nsl_global_seq'::regclass) primary key,
  loader_name_id bigint not null,
  name_id bigint not null,
  instance_id bigint not null,
  standalone_instance_created boolean not null default false,
  standalone_instance_found boolean not null default false,
  standalone_instance_id bigint not null,
  relationship_instance_type_id bigint not null,
  relationship_instance_created boolean not null default false,
  relationship_instance_found boolean not null default false,
  relationship_instance_id bigint not null,
  drafted boolean not null default false,
  manually_drafted boolean not null default false,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  constraint loader_name_match_inst_uniq unique (loader_name_id, name_id, instance_id),
  constraint loader_name_match_instance_fk foreign key (instance_id) REFERENCES instance(id),
  constraint loader_name_match_name_fk foreign key (name_id) REFERENCES name(id),
  constraint loader_name_match_loadr_nam_fk foreign key (loader_name_id) REFERENCES loader_name(id),
  constraint loader_name_match_rel_inst_fk foreign key (relationship_instance_id) REFERENCES instance(id),
  constraint loader_nme_mtch_r_inst_type_fk foreign key (relationship_instance_id) REFERENCES instance_type(id),
  constraint loader_name_match_sta_inst_fk foreign key (standalone_instance_id) REFERENCES instance(id)
)
;

