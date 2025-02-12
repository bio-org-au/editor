
create table batch_reviewer (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  user_id bigint not null,
  org_id bigint not null,
  batch_review_role_id bigint not null,
  batch_review_id bigint not null,
  active boolean not null default true,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  constraint batch_reviewer_users_fk foreign key (user_id) REFERENCES users(id),
  constraint batch_reviewer_user_org_fk foreign key (org_id) REFERENCES org(id),
  constraint batch_reviewer_review_role_fk foreign key (batch_review_role_id) REFERENCES batch_review_role(id),
  constraint batch_reviewer_batch_review_fk foreign key (batch_review_id) REFERENCES batch_review(id),
  unique (user_id, org_id, batch_review_role_id, batch_review_id)
)
;



