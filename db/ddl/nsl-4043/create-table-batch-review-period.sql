create table batch_review_period (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  batch_review_id bigint not null,
  name varchar(200) not null,
  start_date date not null,
  end_date date,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  unique (batch_review_id, start_date),
  constraint batch_review_period_batch_review_fk foreign key (batch_review_id) references batch_review(id)
)
;

