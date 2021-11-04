create table name_review_comment (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  review_period_id bigint not null,
  batch_reviewer_id bigint not null,
  loader_name_id bigint not null,
  comment text not null,
  in_progress boolean not null default false,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  constraint name_review_comment_period_fk foreign key (review_period_id) REFERENCES batch_review_period(id),
  constraint name_review_comme_reviewer_fk foreign key (batch_reviewer_id) REFERENCES batch_reviewer(id),
  constraint name_review_loader_name_fk    foreign key (loader_name_id) REFERENCES loader_name(id)
)
;

