
drop table if exists loader_batch_raw_list_2019_with_taxon_full;
\i create-table-loader-batch-raw-list-2019-with-taxon-full.sql
\i load-raw-data-list-2019-with-taxon-full.sql

\i insert-batch.sql
--\i add-simple-and-full-name-cols.sql
\i copy-raw-to-loader-name.sql
\i bulk-update-loader-name-parent-id.sql
 
