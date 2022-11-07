
-- https://stackoverflow.com/questions/25307244/how-to-allow-only-one-row-for-a-table/25393923#25393923
-- Answer by Erwin Brandstetter


CREATE TABLE loader.loader_batch_job_lock (
   id bool PRIMARY KEY DEFAULT TRUE
 , job_name text
 , CONSTRAINT job_lock_unique CHECK (id)
);

grant select, insert, update, delete on loader_batch_job_lock to webapni;
