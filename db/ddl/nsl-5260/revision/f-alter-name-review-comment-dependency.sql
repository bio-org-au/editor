alter table name_review_comment drop constraint name_review_comme_reviewer_fk;


alter table name_review_comment add constraint name_review_comment_reviewer_fk FOREIGN KEY (batch_reviewer_id) REFERENCES batch_reviewer(id);
