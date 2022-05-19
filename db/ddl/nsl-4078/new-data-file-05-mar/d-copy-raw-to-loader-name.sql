insert into loader_name
 (loader_batch_id,
  raw_id,
  parent_raw_id,
  record_type,
  family,
  higher_rank_comment,
  rank,
  rank_nsl,
  scientific_name,
  simple_name,
  simple_name_as_loaded,
  full_name,
  ex_base_author,
  base_author,
  ex_author,
  author,
  author_rank,
  name_status,
  name_comment,
  partly,
  auct_non,
  excluded,
  synonym_type,
  doubtful,
  hybrid_flag,
  isonym,
  publ_count,
  article_author,
  article_title,
  article_title_full,
  in_flag,
  second_author,
  title,
  title_full,
  edition,
  volume,
  page,
  year,
  date_,
  publ_partly,
  publ_note,
  notes,
  footnote,
  distribution,
  comment,
  remark_to_reviewers, 
  original_text,
  seq)
select (select id from loader_batch where name = 'APC List 103 draft 05 Mar'),
  id,
  parent_id,
  coalesce(record_type,'no-raw-record-type'),
  family,
  hr_comment,
  rank,
  rank_nsl,
  'deprecated-column',
  coalesce(taxon,'no-raw-taxon value supplied'),
  coalesce(taxon,'no-raw-taxon value supplied'),
  coalesce(taxon_full,coalesce(taxon, 'no taxon or taxon_full value supplied')),
  ex_base_author,
  base_author,
  ex_author,
  author,
  author_rank,
  name_status,
  name_comment,
  partly,
  auct_non,
  (case unplaced when '1' then true else false end),
  synonym_type,
  (case doubtful when '1' then true else false end),
  hybrid_flag,
  isonym,
  publ_count,
  article_author,
  article_title,
  article_title_full,
  in_flag,
  second_author,
  title,
  title_full,
  edition,
  volume,
  page,
  year,
  date_,
  publ_partly,
  publ_note,
  note,
  footnote,
  distribution,
  comment_,
  remark,
  original_text,
  (id*10)
  from loader_batch_raw_names_05_mar_2022 raw
  order by raw.id
;
