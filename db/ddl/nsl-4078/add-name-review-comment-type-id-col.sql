
alter table name_review_comment add column name_review_comment_type_id bigint;

alter table name_review_comment add constraint name_review_comment_type_fk foreign key (name_review_comment_type_id) REFERENCES name_review_comment_type(id);

update name_review_comment
set name_review_comment_type_id = (select id from name_review_comment_type where name = 'other')
where name_review_comment_type_id is null;

alter table name_review_comment alter column name_review_comment_type_id set not null;
