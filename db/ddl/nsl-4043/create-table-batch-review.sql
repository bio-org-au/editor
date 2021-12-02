create table batch_review (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  loader_batch_id bigint not null,
  name varchar(200) not null,
  in_progress boolean not null default false,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  constraint batch_review_loader_batch_fk foreign key (loader_batch_id) REFERENCES loader_batch(id),
  unique (loader_batch_id, name)
)
;
