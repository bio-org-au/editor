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
  note,
  footnote,
  distribution,
  comment_,
  remark,
  original_text,
  seq)
select (select id from loader_batch where name = 'Second Batch'),
  id,
  parent_id,
  coalesce(record_type,'no-raw-record-type'),
  family,
  hr_comment,
  rank,
  nsl_rank,
  coalesce(taxon,'no-raw-taxon'),
  ex_base_author,
  base_author,
  ex_author,
  author,
  author_rank,
  name_status,
  name_comment,
  partly,
  auct_non,
  (doubtful = 1),
  synonym_type,
  doubtful,
  case hybrid
  when null then false
  else true
  end,
  isonym,
  publ_count,
  article_author,
  article_title,
  article_title_full,
  in_flag,
  author_2,
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
  comment,
  remark,
  original_text,
  id*10
  from orchids_from_rex_csv rex
  order by rex.id
;
