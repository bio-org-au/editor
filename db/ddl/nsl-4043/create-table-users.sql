create table users (
  id bigint not null default  nextval('nsl_global_seq'::regclass) primary key,
  userid varchar(30) not null,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user
)
;
