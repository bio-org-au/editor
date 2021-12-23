
update loader_name
   set remark_to_reviewers=higher_rank_comment
 where higher_rank_comment is not null
   and remark_to_reviewers is null;
