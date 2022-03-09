alter table name_review_comment add context varchar(30) not null default 'unknown' check (context ~ 'loader-name|distribution|concept-note|unknown');
