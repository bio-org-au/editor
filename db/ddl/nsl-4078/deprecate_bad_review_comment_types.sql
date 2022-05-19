update name_review_comment_type 
set deprecated = true
where name not in ('other', 'general');
