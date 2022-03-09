create index lower_simple_name_unaccent_ndx on loader_name using btree (lower(f_unaccent(simple_name)));
