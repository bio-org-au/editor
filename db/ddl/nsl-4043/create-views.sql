\i create-view-batch-review-period-vw.sql


create view br as select * from batch_review;
create view brr as select * from batch_review_role;
create view brp as select * from batch_review_period;
create view brer as select * from batch_reviewer;
create view brc as select * from batch_review_comment;
create view nrc as select * from name_review_comment;

