
drop table if exists loader_batch_raw_list_2019_with_taxon_full;
\i create-table-loader-batch-raw-list-2019-with-taxon-full.sql
\i load-raw-data-list-2019-with-taxon-full.sql

\i insert-batch.sql
\i add-simple-and-full-name-cols.sql
\i copy-raw-to-loader-name.sql
\i bulk-update-loader-name-parent-id.sql


\i create-table-name-review-comment-type.sql
\i seed-name-review-comment-type.sql
\i add-name-review-comment-type-id-col.sql
\i add-name-review-comment-resolved-boolean-col.sql
 
\i rename-remark-col-to-remark-to-reviewers.sql
