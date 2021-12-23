create table name_review_comment_type (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  name character varying(50)    not null default 'unknown',
  for_reviewer boolean not null default true,
  for_compiler boolean not null default true,
  deprecated boolean not null default false,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  unique (name)
)
;

