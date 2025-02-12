create table loader.org_batch_review_voter (
  org_id bigint not null,
  batch_review_id bigint not null,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  primary key (org_id, batch_review_id),
  constraint name_review_vote_batch_fk foreign key (batch_review_id) REFERENCES batch_review(id),
  constraint name_review_vote_org_fk    foreign key (org_id) REFERENCES org(id)
)
;


