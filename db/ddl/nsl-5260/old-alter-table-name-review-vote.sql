
alter table name_review_vote drop constraint name_review_vote_org_fk;
alter table name_review_vote drop constraint name_review_vote_batch_fk;

alter table name_review_vote add constraint name_review_vote_org_fk  foreign key (org_id) REFERENCES org_batch_review_voter(org_id);
alter table name_review_vote add constraint name_review_vote_batch_review_fk  foreign key (batch_review_id) REFERENCES org_batch_review_voter(batch_review_id);



alter table name_review_vote add constraint name_review_vote_pk primary key (org_id, batch_review_id, loader_name_id);

alter table name_review_vote add constraint name_review_vote_org_fk  foreign key (org_id, batch_review_id) REFERENCES org_batch_review_voter(org_id, batch_review_id);

alter table name_review_vote drop column batch_reviewer_id;

