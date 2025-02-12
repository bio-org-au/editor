
drop table if exists loader.name_review_vote;


create table loader.name_review_vote (
  loader_name_id bigint not null,
  batch_review_id bigint not null,
  org_id bigint not null,
  vote boolean not null default true,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null default now(),
  created_by character varying(50)    not null default user,
  updated_at timestamp with time zone not null default now(),
  updated_by character varying(50)    not null default user,
  primary key                                               (org_id, batch_review_id, loader_name_id),
  constraint name_review_vote_org_fk            foreign key (org_id, batch_review_id) REFERENCES org_batch_review_voter(org_id, batch_review_id),
  constraint name_review_vote_loader_name_fk    foreign key (loader_name_id)          REFERENCES loader_name(id)
)
;


