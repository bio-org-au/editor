SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: loader; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA loader;
CREATE SEQUENCE loader.nsl_global_seq
    INCREMENT BY 1
    CACHE 1;

CREATE SCHEMA audit;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--



--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--



--
-- Name: accepted_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accepted_status(nameid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select coalesce(excluded_status(nameId), inc_status(nameId), 'unplaced');
$$;


--
-- Name: apni_detail_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_detail_jsonb(nameid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'ref_citation_html', refs.citation_html,
           'ref_citation', refs.citation,
           'instance_id', refs.instance_id,
           'instance_uri', refs.instance_uri,
           'instance_type', refs.instance_type,
           'page', refs.page,
           'type_notes', coalesce(type_notes_jsonb(refs.instance_id), '{}' :: jsonb),
           'synonyms', coalesce(apni_ordered_synonymy_jsonb(refs.instance_id), apni_synonym_jsonb(refs.instance_id), '[]' :: jsonb),
           'non_type_notes', coalesce(non_type_notes_jsonb(refs.instance_id), '{}' :: jsonb),
           'profile', coalesce(latest_accepted_profile_jsonb(refs.instance_id), '{}' :: jsonb),
           'resources', coalesce(instance_resources_jsonb(refs.instance_id), '{}' :: jsonb),
           'tree', coalesce(instance_on_accepted_tree_jsonb(refs.instance_id), '{}' :: jsonb)
         )
       )
from apni_ordered_references(nameid) refs
$$;


--
-- Name: apni_detail_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_detail_text(nameid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg(' ' ||
                  refs.citation ||
                  ': ' ||
                  refs.page || E'
' ||
                  coalesce(type_notes_text(refs.instance_id), '') ||
                  coalesce(apni_ordered_synonymy_text(refs.instance_id), apni_synonym_text(refs.instance_id), '') ||
                  coalesce(non_type_notes_text(refs.instance_id), '') ||
                  coalesce(latest_accepted_profile_text(refs.instance_id), ''),
                  E'
')
from apni_ordered_references(nameid) refs
$$;


--
-- Name: apni_ordered_nom_synonymy(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_nom_synonymy(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, iso_publication_date text, page text, sort_name text, misapplied boolean, ref_id bigint)
    LANGUAGE sql
    AS $$
select i.id,
       i.uri,
       it.has_label                     as instance_type,
       it.id                            as instance_type_id,
       n.id                             as name_id,
       n.uri,
       n.full_name,
       n.full_name_html,
       ns.name                          as name_status,
       r.citation,
       r.citation_html,
       ref_year(iso_date) as year,
       coalesce(iso_date, '-'),
       cites.page,
       n.sort_name,
       false,
       r.id
from instance i
         join instance_type it on i.instance_type_id = it.id and it.nomenclatural
         join name n on i.name_id = n.id
         join name_status ns on n.name_status_id = ns.id
         left outer join instance cites on i.cites_id = cites.id
         left outer join reference r on cites.reference_id = r.id
         left outer join ref_parent_date(r.id) iso_date on true
where i.cited_by_id = instanceid
order by (it.sort_order < 20) desc,
         it.nomenclatural desc,
         iso_date,
         n.sort_name,
         it.pro_parte,
         it.doubtful,
         cites.page,
         cites.id;
$$;


--
-- Name: apni_ordered_other_synonymy(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_other_synonymy(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, iso_publication_date text, page text, sort_name text, group_name text, group_head boolean, group_iso_pub_date text, misapplied boolean, ref_id bigint, og_id bigint, og_head boolean, og_name text, og_year text)
    LANGUAGE sql
    AS $$
select i.id                                                            as instance_id,
       i.uri                                                           as instance_uri,
       it.has_label                                                    as instance_type,
       it.id                                                           as instance_type_id,
       n.id                                                            as name_id,
       n.uri                                                           as name_uri,
       n.full_name,
       n.full_name_html,
       ns.name                                                         as name_status,
       r.citation,
       r.citation_html,
       ref_year(iso_date)                                as year,
       coalesce(iso_date,'-'),
       cites.page,
       n.sort_name,
       ng.group_name                                                   as group_name,
       ng.group_id = n.id                                              as group_head,
       coalesce(ng.group_iso_pub_date, r.iso_publication_date) :: text as group_iso_pub_date,
       it.misapplied,
       r.id                                                            as ref_id,
       og_id                                                           as og_id,
       og_id = n.id                                                    as og_head,
       coalesce(ogn.sort_name, n.sort_name)                            as og_name,
       coalesce(ogr.iso_publication_date, r.iso_publication_date)      as og_iso_pub_date
from instance i
         join instance_type it on i.instance_type_id = it.id and not it.nomenclatural and it.relationship
         join name n on i.name_id = n.id
         join name_type nt on n.name_type_id = nt.id
         join orth_or_alt_of(case when nt.autonym then n.parent_id else n.id end) og_id on true
         left outer join name ogn on ogn.id = og_id and not og_id = n.id
         left outer join instance ogi
         join reference ogr on ogr.id = ogi.reference_id
              on ogi.name_id = og_id and ogi.id = i.cited_by_id and not og_id = n.id
         left outer join first_ref(basionym(og_id)) ng on true
         join name_status ns on n.name_status_id = ns.id
         left outer join instance cites on i.cites_id = cites.id
         left outer join reference r on cites.reference_id = r.id
         left outer join ref_parent_date(r.id) iso_date on true
where i.cited_by_id = instanceid
order by (it.sort_order < 20) desc,
         it.taxonomic desc,
         group_iso_pub_date,
         group_name,
         group_head desc,
         og_iso_pub_date,
         og_name,
         og_head desc,
         iso_date,
         n.sort_name,
         it.pro_parte,
         it.misapplied desc,
         it.doubtful,
         cites.page,
         cites.id;
$$;


--
-- Name: apni_ordered_references(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_references(nameid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, citation text, citation_html text, year integer, iso_publication_date text, pages text, page text)
    LANGUAGE sql
    AS $$
select i.id,
       i.uri,
       it.name,
       r.citation,
       r.citation_html,
       ref_year(iso_date),
       iso_date,
       r.pages,
       coalesce(i.page, citedby.page, '-')
from instance i
         join reference r on i.reference_id = r.id
         join instance_type it on i.instance_type_id = it.id
         left outer join instance citedby on i.cited_by_id = citedby.id
         left outer join ref_parent_date(r.id) iso_date on true
where i.name_id = nameid
group by r.id, iso_date, i.id, it.id, citedby.id
order by iso_date, it.protologue, it.primary_instance, r.citation, r.pages, i.page, r.id;
$$;


--
-- Name: apni_ordered_synonymy(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_synonymy(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, iso_publication_date text, page text, sort_name text, misapplied boolean, ref_id bigint)
    LANGUAGE sql
    AS $$

select instance_id,
       instance_uri,
       instance_type,
       instance_type_id,
       name_id,
       name_uri,
       full_name,
       full_name_html,
       name_status,
       citation,
       citation_html,
       iso_publication_date,
       page,
       sort_name,
       misapplied,
       ref_id
from apni_ordered_nom_synonymy(instanceid)
union all
select instance_id,
       instance_uri,
       instance_type,
       instance_type_id,
       name_id,
       name_uri,
       full_name,
       full_name_html,
       name_status,
       citation,
       citation_html,
       iso_publication_date,
       page,
       sort_name,
       misapplied,
       ref_id
from apni_ordered_other_synonymy(instanceid)
$$;


--
-- Name: apni_ordered_synonymy_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_synonymy_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'instance_id', syn.instance_id,
           'instance_uri', syn.instance_uri,
           'instance_type', syn.instance_type,
           'name_uri', syn.name_uri,
           'full_name_html', syn.full_name_html,
           'name_status', syn.name_status,
           'misapplied', syn.misapplied,
           'citation_html', syn.citation_html
             )
           )
from apni_ordered_synonymy(instanceid) syn;
$$;


--
-- Name: apni_ordered_synonymy_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_ordered_synonymy_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' ||
                  syn.instance_type ||
                  ': ' ||
                  syn.full_name ||
                  (case
                     when syn.name_status = 'legitimate' then ''
                     when syn.name_status = '[n/a]' then ''
                     else ' ' || syn.name_status end) ||
                  (case
                     when syn.misapplied then syn.citation
                     else '' end), E'
') || E'
'
from apni_ordered_synonymy(instanceid) syn;
$$;


--
-- Name: apni_synonym(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_synonym(instanceid bigint) RETURNS TABLE(instance_id bigint, instance_uri text, instance_type text, instance_type_id bigint, name_id bigint, name_uri text, full_name text, full_name_html text, name_status text, citation text, citation_html text, year integer, iso_publication_date text, page text, misapplied boolean, sort_name text)
    LANGUAGE sql
    AS $$
select i.id,
       i.uri,
       it.of_label as instance_type,
       it.id       as instance_type_id,
       n.id        as name_id,
       n.uri,
       n.full_name,
       n.full_name_html,
       ns.name,
       r.citation,
       r.citation_html,
       ref_year(iso_date),
       iso_date,
       i.page,
       it.misapplied,
       n.sort_name
from instance i
         join instance_type it on i.instance_type_id = it.id
         join instance cites on i.cited_by_id = cites.id
         join name n on cites.name_id = n.id
         join name_status ns on n.name_status_id = ns.id
         join reference r on i.reference_id = r.id
         left outer join ref_parent_date(r.id) iso_date on true
where i.id = instanceid
  and it.relationship;
$$;


--
-- Name: apni_synonym_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_synonym_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'instance_id', syn.instance_id,
           'instance_uri', syn.instance_uri,
           'instance_type', syn.instance_type,
           'name_uri', syn.name_uri,
           'full_name_html', syn.full_name_html,
           'name_status', syn.name_status,
           'misapplied', syn.misapplied,
           'citation_html', syn.citation_html
             )
           )
from apni_synonym(instanceid) syn;
$$;


--
-- Name: apni_synonym_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apni_synonym_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' ||
                  syn.instance_type ||
                  ': ' ||
                  syn.full_name ||
                  (case
                     when syn.name_status = 'legitimate' then ''
                     when syn.name_status = '[n/a]' then ''
                     else ' ' || syn.name_status end) ||
                  (case
                     when syn.misapplied
                             then 'by ' || syn.citation
                     else '' end), E'
') || E'
'
from apni_synonym(instanceid) syn;
$$;


--
-- Name: author_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.author_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'author deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'author updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'author created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: basionym(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.basionym(nameid bigint) RETURNS bigint
    LANGUAGE sql
    AS $$
select coalesce(
         (select coalesce(bas_name.id, primary_inst.name_id)
          from instance primary_inst
                 left join instance bas_inst
                 join name bas_name on bas_inst.name_id = bas_name.id
                 join instance_type bas_it on bas_inst.instance_type_id = bas_it.id and bas_it.name in ('basionym','replaced synonym')
                 join instance cit_inst on bas_inst.cites_id = cit_inst.id on bas_inst.cited_by_id = primary_inst.id
                 join instance_type primary_it on primary_inst.instance_type_id = primary_it.id and primary_it.primary_instance
          where primary_inst.name_id = nameid
          limit 1), nameid);
$$;


--
-- Name: bs(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bs(bool boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
   -- variable declaration
begin
  return case bool
  when true then 'TRUE'
  when false then 'F'
  else bool::text
  end;
end;
$$;


--
-- Name: daily_top_nodes(text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.daily_top_nodes(tree_label text, since timestamp without time zone) RETURNS TABLE(latest_node_id bigint, year double precision, month double precision, day double precision)
    LANGUAGE sql
    AS $$

WITH RECURSIVE treewalk AS (
  SELECT class_root.*
  FROM tree_node class_node
    JOIN tree_arrangement a ON class_node.id = a.node_id AND a.label = tree_label
    JOIN tree_link sublink ON class_node.id = sublink.supernode_id
    JOIN tree_node class_root ON sublink.subnode_id = class_root.id
  UNION ALL
  SELECT node.*
  FROM treewalk
    JOIN tree_node node ON treewalk.prev_node_id = node.id
)
SELECT
  max(tw.id) AS latest_node_id,
  year,
  month,
  day
FROM treewalk tw
  JOIN tree_event event ON tw.checked_in_at_id = event.id
  ,
      extract(YEAR FROM event.time_stamp) AS year,
      extract(MONTH FROM event.time_stamp) AS month,
      extract(DAY FROM event.time_stamp) AS day
WHERE event.time_stamp > since
GROUP BY year, month, day
ORDER BY latest_node_id ASC
$$;


--
-- Name: diff_list(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.diff_list(v1 bigint, v2 bigint) RETURNS TABLE(operation text, previous_tve text, current_tve text, simple_name text, synonyms_html text, name_path text)
    LANGUAGE sql
    AS $$
select 'modified' op, ptve_element_link, after.element_link, after_te.simple_name, after_te.synonyms_html, after.name_path
from find_modified(v1, v2)
         join tree_version_element after on tve_element_link = after.element_link
         join tree_element after_te on after.tree_element_id = after_te.id
union
select 'added' op, ''::text, after.element_link, after_te.simple_name, after_te.synonyms_html, after.name_path
from find_added(v1, v2)
         join tree_version_element after on tve_element_link = after.element_link
         join tree_element after_te on after.tree_element_id = after_te.id
union
select  'removed' op, ptve_element_link, ''::text, before_te.simple_name, before_te.synonyms_html, before.name_path
from find_removed(v1, v2)
         join tree_version_element before on ptve_element_link = before.element_link
         join tree_element before_te on before.tree_element_id = before_te.id
order by name_path
$$;


--
-- Name: dist_entry_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dist_entry_status(entry_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
with status as (
    SELECT string_agg(ds.name, ' and ') status
    from (
             select ds.name
             FROM dist_entry de
                      join dist_region dr on de.region_id = dr.id
                      join dist_entry_dist_status deds on de.id = deds.dist_entry_status_id
                      join dist_status ds on deds.dist_status_id = ds.id
             where de.id = entry_id
             order by ds.sort_order) ds
)
select case
           when status.status = 'native' then
               ''
           else
                       '(' || status.status || ')'
           end
from status;
$$;


--
-- Name: distribution(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.distribution(element_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg(e.display, ', ') from
    (select entry.display display
     from dist_entry entry
              join dist_region dr on entry.region_id = dr.id
              join tree_element_distribution_entries tede
                   on tede.dist_entry_id = entry.id and tede.tree_element_id = element_id
     order by dr.sort_order) e
$$;


--
-- Name: excluded_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.excluded_status(nameid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select case when te.excluded = true then 'excluded' else 'accepted' end
from tree_element te
         JOIN tree_version_element tve ON te.id = tve.tree_element_id
         JOIN tree ON tve.tree_version_id = tree.current_tree_version_id AND tree.accepted_tree = TRUE
where te.name_id = nameId
$$;


--
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO 'public', 'pg_temp'
    AS $_$
SELECT unaccent('unaccent', $1)
$_$;


--
-- Name: find_added(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_added(v1 bigint, v2 bigint) RETURNS TABLE(tve_element_link text, tve_te_id bigint)
    LANGUAGE sql
    AS $$
select not_in_first.element_link, not_in_first.tree_element_id
from not_in(v2, v1) not_in_first
where not_in_first.tree_element_id not in (select ptve_te_id from find_modified(v1, v2))
$$;


--
-- Name: find_all_changes(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_all_changes(v1 bigint, v2 bigint) RETURNS TABLE(te_id bigint, simple_name character varying, previous_element_id bigint, synonyms jsonb, synonyms_html text, operation character varying, tree_version_id bigint)
    LANGUAGE sql
    AS $$

select id, simple_name, previous_element_id, synonyms, synonyms_html, 'added' op, v1 from tree_element
where previous_element_id is null
  and id in
      (
          SELECT tree_element_id
          FROM tree_version_element
          WHERE tree_version_id = v1
              EXCEPT
          SELECT tree_element_id
          FROM tree_version_element
          WHERE tree_version_id = v2
      )
union
select id, simple_name, previous_element_id, synonyms, synonyms_html, 'removed' op, v1 from tree_element
where previous_element_id is null
  and id in
      (
          SELECT tree_element_id
          FROM tree_version_element
          WHERE tree_version_id = v2
              EXCEPT
          SELECT tree_element_id
          FROM tree_version_element
          WHERE tree_version_id = v1
      )
union
select id, simple_name, previous_element_id, synonyms, synonyms_html, 'changed' op, v1 from tree_element
where previous_element_id is not null
  and id in
      (
          SELECT tree_element_id
          FROM tree_version_element
          WHERE tree_version_id = v1
              EXCEPT
          SELECT tree_element_id
          FROM tree_version_element
          WHERE tree_version_id = v2
      )
$$;


--
-- Name: find_family_name_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_family_name_id(target_element_link text) RETURNS bigint
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (name_id, rank, parent_id) AS (
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  FROM tree_version_element tve
    JOIN tree_element te ON tve.tree_element_id = te.id
  WHERE element_link = target_element_link
  UNION ALL
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  FROM walk, tree_version_element tve
    JOIN tree_element te ON tve.tree_element_id = te.id
  WHERE element_link = walk.parent_id
)
SELECT name_id
FROM walk
WHERE rank = 'Familia';
$$;


--
-- Name: find_modified(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_modified(v1 bigint, v2 bigint) RETURNS TABLE(tve_element_link text, tve_te_id bigint, ptve_element_link text, ptve_te_id bigint)
    LANGUAGE sql
    AS $$
select tve.element_link, tve.tree_element_id, ptve.element_link, ptve.tree_element_id
from Tree_Version_Element tve
         join tree_element te on tve.tree_element_id = te.id
        , Tree_Version_Element ptve
              join tree_element pte on ptve.tree_element_id = pte.id,
     not_in(v1,v2) not_in_first
where tve.tree_version_id = v1
  and ptve.tree_version_id = v2
  and pte.name_id = te.name_id
  and te.id in (not_in_first.tree_element_id)
order by tve.name_path
$$;


--
-- Name: find_rank(bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_rank(name_id bigint, rank_sort_order integer) RETURNS TABLE(name_element text, rank text, sort_order integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (parent_id, name_element, rank, sort_order) AS (
    SELECT parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM name n
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE n.id = name_id
      AND r.sort_order >= rank_sort_order
    UNION ALL
    SELECT n.parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM walk w,
         name n
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE n.id = w.parent_id
      AND r.sort_order >= rank_sort_order
)
SELECT w.name_element,
       w.rank,
       w.sort_order
FROM walk w
WHERE w.sort_order >= rank_sort_order
order by w.sort_order asc
limit 1
$$;


--
-- Name: find_removed(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_removed(v1 bigint, v2 bigint) RETURNS TABLE(ptve_element_link text, ptve_te_id bigint)
    LANGUAGE sql
    AS $$
select not_in_first.element_link, not_in_first.tree_element_id
from not_in(v1,v2) not_in_first
where
        not_in_first.tree_element_id not in (select tve_te_id from find_modified(v1, v2))
$$;


--
-- Name: find_tree_rank(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_tree_rank(tve_id text, rank_sort_order integer) RETURNS TABLE(name_element text, rank text, sort_order integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (parent_id, name_element, rank, sort_order) AS (
    SELECT tve.parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM tree_version_element tve
             JOIN tree_element te ON tve.tree_element_id = te.id
             JOIN name n ON te.name_id = n.id
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE tve.element_link = tve_id
      AND r.sort_order >= rank_sort_order
    UNION ALL
    SELECT tve.parent_id,
           n.name_element,
           r.name,
           r.sort_order
    FROM walk w,
         tree_version_element tve
             JOIN tree_element te ON tve.tree_element_id = te.id
             JOIN name n ON te.name_id = n.id
             JOIN name_rank r ON n.name_rank_id = r.id
    WHERE tve.element_link = w.parent_id
      AND r.sort_order >= rank_sort_order
)
SELECT w.name_element,
       w.rank,
       w.sort_order
FROM walk w
WHERE w.sort_order = rank_sort_order
limit 1
$$;


--
-- Name: first_ref(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.first_ref(nameid bigint) RETURNS TABLE(group_id bigint, group_name text, group_iso_pub_date text)
    LANGUAGE sql
    AS $$
select n.id group_id, n.sort_name group_name, min(r.iso_publication_date)
from name n
         join instance i
         join reference r on i.reference_id = r.id
              on n.id = i.name_id
where n.id = nameid
group by n.id, sort_name
$$;


--
-- Name: fn_errata_author_change(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_errata_author_change(v_author_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE row record;
BEGIN
    -- Update the tree_element synonymy_html
    UPDATE tree_element
    SET
        synonyms_html = coalesce(
                synonyms_as_html(instance_id),
                '<synonyms></synonyms>'),
        synonyms = coalesce(
                synonyms_as_jsonb(
                        instance_id,
                        (SELECT host_name FROM tree WHERE accepted_tree = TRUE)), '[]' :: jsonb),
        updated_at = NOW(),
        updated_by = 'F_ErrAuthor'
    WHERE instance_id IN (
        select distinct instance_id
        from tree_element
             -- removed author to accomodate base, ex and ex-base author types
        where synonyms->>'list' like '% data-id=''' || v_author_id || ''' title=%'
    );
    RAISE NOTICE 'Updated te synonyms_html and synonyms jsonb for direct references';
END;
$$;


--
-- Name: fn_errata_name_change_get_instance_ids(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_errata_name_change_get_instance_ids(v_name_id bigint) RETURNS TABLE(in_id bigint)
    LANGUAGE plpgsql STABLE STRICT
    AS $$
DECLARE
    row record;
BEGIN
    for row in (select id from name
                where id = v_name_id)
        LOOP
            RETURN QUERY select instance_id
                         from tree_element
                         where synonyms_html ilike '%<name data-id=''' || row.id || '''>%';
            RAISE NOTICE '% processing', row.id;
        end loop;
end
$$;


--
-- Name: fn_errata_name_change_update_te(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_errata_name_change_update_te(v_name_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    row record;
BEGIN
    for row in (select distinct in_id
                from fn_errata_name_change_get_instance_ids(v_name_id))
        LOOP
            RAISE NOTICE 'Updating Instance ID: %', row.in_id;
            UPDATE tree_element
            SET synonyms = coalesce(
                    synonyms_as_jsonb(
                            row.in_id,
                            (SELECT host_name FROM tree WHERE accepted_tree = TRUE)), '[]' :: jsonb),
                synonyms_html = coalesce(
                        synonyms_as_html(row.in_id), '<synonyms></synonyms>'),
                updated_at = NOW(),
                updated_by = 'F_ErrName'
            WHERE instance_id = row.in_id;
        end loop;
end
$$;


--
-- Name: fn_errata_ref_change(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_errata_ref_change(v_ref_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    -- Update the tree_element synonyms_html where reference is directly quoted
    UPDATE tree_element
    SET
        synonyms_html = coalesce(
                synonyms_as_html(instance_id),
                '<synonyms></synonyms>'),
        synonyms = coalesce(
                synonyms_as_jsonb(
                        instance_id,
                        (SELECT host_name FROM tree WHERE accepted_tree = TRUE)), '[]' :: jsonb),
        updated_at = NOW(),
        updated_by = 'F_ErrReference'
    WHERE id IN ( SELECT id
                  FROM tree_element
                  WHERE synonyms ->> 'list' LIKE '%reference/apni/' || v_ref_id || '%');
    RAISE NOTICE 'Updating instance for ref: %', v_ref_id;
END;
$$;


--
-- Name: fn_update_ics(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_update_ics() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    -- Update instance cached_synonymy_html attribute
    update instance
    set
        cached_synonymy_html = coalesce(synonyms_as_html(id), '<synonyms></synonyms>'),
        updated_by = 'SynonymyUpdateJob',
        updated_at = now()
    where
            id in (select distinct instance_id from tree_element)
      and
            cached_synonymy_html <> coalesce(synonyms_as_html(id), '<synonyms></synonyms>');
END
$$;


--
-- Name: format_isodate(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.format_isodate(isodate text) RETURNS text
    LANGUAGE sql
    AS $$
with m(k, v) as (values ('', ''),
                        ('01', 'January'),
                        ('02', 'February'),
                        ('03', 'March'),
                        ('04', 'April'),
                        ('05', 'May'),
                        ('06', 'June'),
                        ('07', 'July'),
                        ('08', 'August'),
                        ('09', 'September'),
                        ('10', 'October'),
                        ('11', 'November'),
                        ('12', 'December'))
select trim(coalesce(day.d, '')  ||
            ' ' || coalesce(m.v, '') ||
            ' ' || year)
from m,
     (select nullif(split_part(isodate, '-', 3),'')::numeric::text d) day,
     split_part(isodate, '-', 2) month,
     split_part(isodate, '-', 1) year
where m.k = month
   or (month = '' and m.k = '00')
$$;


--
-- Name: get_hstore_tree(text); Type: FUNCTION; Schema: public; Owner: -
--



--
-- Name: get_tree_path(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_tree_path(v_te_id bigint, v_tv_id bigint) RETURNS text
    LANGUAGE plpgsql
    AS $$
    declare
        v_final_path text;
    begin
        WITH RECURSIVE walk (tree_element_id, parent_id, tree_path) AS (
            SELECT
                tree_element_id        AS tree_element_id,
                parent_id              AS parent_id,
                '/' || tree_element_id AS tree_path,
                te.simple_name         AS name,
                tve.tree_version_id    AS tree_version_id
            FROM tree_version_element tve
                     JOIN tree_element te on te.id = tve.tree_element_id
            WHERE tve.tree_element_id = v_te_id and tve.tree_version_id = v_tv_id
            UNION ALL
            SELECT
                e.tree_element_id                          AS tree_element_id,
                e.parent_id                                AS parent_id,
                '/' || e.tree_element_id || walk.tree_path AS tree_path,
                walk.name AS name,
                walk.tree_version_id    AS tree_version_id
            FROM walk, tree_version_element e
            WHERE CAST(regexp_replace(walk.parent_id, '(/.*?){3}', '') as BIGINT) = e.tree_element_id and e.tree_version_id = v_tv_id
        )
        select tree_path into v_final_path
        from walk
        where length(tree_path) = (select max(length(tree_path)) from walk);
        return v_final_path;
    end;
$$;


--
-- Name: is_iso8601(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_iso8601(isostring character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE match boolean;
begin
    match := isoString ~ '^[1,2][0-9]{3}$' or
             isoString ~ '^[1,2][0-9]{3}-(01|02|03|04|05|06|07|08|09|10|11|12)$';
    if match then
        return true;
    end if;
    perform isoString::TIMESTAMP;
    return true;
exception when others then
    return false;
end;
$_$;


--
-- Name: name_walk(bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_walk(nameid bigint, rank text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
declare
    name_id bigint;
	f integer;
	s integer;
    nm record;
begin

	select sort_order into f from name_rank where rdf_id in ('family','familia');
	if rank = 'family' THEN
	 select sort_order into s from name_rank where rdf_id in ('family','familia');
	else
		select sort_order into s from name_rank where rdf_id = rank;
	end if;


    SELECT  parent_id, sort_order, simple_name, name_element, name.id, family_id
       into nm
    from public.name
	         join public.name_rank on name.name_rank_id = name_rank.id
    WHERE name.id = nameid;

	name_id := nm.parent_id;
    while  nm.sort_order > s  and nm.parent_id is not null and nm.sort_order > f loop

            SELECT parent_id, sort_order, simple_name,name_element, name.id, family_id
                    into nm
                  from public.name
	                join public.name_rank on name.name_rank_id = name_rank.id
            WHERE name.id = name_id;

            name_id := nm.parent_id;

    end loop;

	if s = nm.sort_order then
	     return jsonb_build_object ('id', nm.id, 'name', nm.simple_name, 'element', nm.name_element, 'family_id', nm.family_id);
    else
		return null;
    end if;

end;
    
$$;


--
-- Name: nc_authorship(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nc_authorship(name_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
SELECT CASE
	       WHEN code.value = 'ICN' THEN
		       CASE
			       WHEN nmt.autonym or nmt.formula or nmt.cultivar THEN NULL::text
			       ELSE
				       COALESCE(
						       '(' || COALESCE(xb.abbrev || ' ex ', '') || b.abbrev || ') ',
						       ''
				       ) || COALESCE(
						       COALESCE(xa.abbrev || ' ex ', '') || a.abbrev,
						       ''
				            )
			       END
	       WHEN code.value = 'ICZN' THEN
		       CASE
			       WHEN nm.changed_combination THEN
				       COALESCE(
						       '(' || a.abbrev || COALESCE(', ' || nm.published_year, '') || ')',
						       ''
				       )
			       ELSE
				       COALESCE(
						       a.abbrev || COALESCE(', ' || nm.published_year, ''),
						       ''
				       )
			       END
	       END AS value
FROM public.name nm
	     JOIN public.name_type nmt ON nm.name_type_id = nmt.id
	     LEFT JOIN public.shard_config code ON code.name::text = 'nomenclatural code'::text
	     LEFT JOIN public.author b ON nm.base_author_id = b.id
	     LEFT JOIN public.author xb ON nm.ex_base_author_id = xb.id
	     LEFT JOIN public.author a ON nm.author_id = a.id
	     LEFT JOIN public.author xa ON nm.ex_author_id = xa.id
WHERE nm.id = name_id;
$$;


--
-- Name: nsl_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nsl_global_seq
    INCREMENT BY 1
    CACHE 1;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.author (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev text,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    date_range character varying(50),
    duplicate_of_id bigint,
    full_name character varying(255),
    ipni_id character varying(50),
    name character varying(1000),
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    uri text,
    extra_information character varying(255),
    CONSTRAINT abbrev_length_check CHECK ((char_length(abbrev) <= 150))
);


--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    draft boolean DEFAULT false NOT NULL,
    instance_type_id bigint NOT NULL,
    name_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    nomenclatural_status character varying(50),
    page character varying(255),
    page_qualifier character varying(255),
    parent_id bigint,
    reference_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(1000) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_name_string character varying(255),
    uri text,
    cached_synonymy_html text,
    uncited boolean DEFAULT false NOT NULL,
    CONSTRAINT citescheck CHECK (((cites_id IS NULL) OR (cited_by_id IS NOT NULL)))
);


--
-- Name: instance_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_note (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint NOT NULL,
    instance_note_key_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    value character varying(4000) NOT NULL
);


--
-- Name: instance_note_key; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_note_key (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: instance_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    citing boolean DEFAULT false NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    doubtful boolean DEFAULT false NOT NULL,
    misapplied boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    nomenclatural boolean DEFAULT false NOT NULL,
    primary_instance boolean DEFAULT false NOT NULL,
    pro_parte boolean DEFAULT false NOT NULL,
    protologue boolean DEFAULT false NOT NULL,
    relationship boolean DEFAULT false NOT NULL,
    secondary_instance boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    standalone boolean DEFAULT false NOT NULL,
    synonym boolean DEFAULT false NOT NULL,
    taxonomic boolean DEFAULT false NOT NULL,
    unsourced boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    has_label character varying(255) DEFAULT 'not set'::character varying NOT NULL,
    of_label character varying(255) DEFAULT 'not set'::character varying NOT NULL,
    bidirectional boolean DEFAULT false NOT NULL,
    alignment boolean DEFAULT false NOT NULL
);


--
-- Name: name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint NOT NULL,
    name_status_id bigint NOT NULL,
    name_type_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    orth_var boolean DEFAULT false NOT NULL,
    parent_id bigint,
    sanctioning_author_id bigint,
    second_parent_id bigint,
    simple_name character varying(250),
    simple_name_html character varying(2048),
    source_dup_of_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    status_summary character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text DEFAULT ''::text NOT NULL,
    uri text,
    changed_combination boolean DEFAULT false NOT NULL,
    published_year integer,
    apni_json jsonb,
    basionym_id bigint,
    primary_instance_id bigint,
    CONSTRAINT published_year_limits CHECK (((published_year > 0) AND (published_year < 2500)))
);


--
-- Name: name_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_group (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50),
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: name_rank; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_rank (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev character varying(20) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    has_parent boolean DEFAULT false NOT NULL,
    italicize boolean DEFAULT false NOT NULL,
    major boolean DEFAULT false NOT NULL,
    name character varying(50) NOT NULL,
    name_group_id bigint NOT NULL,
    parent_rank_id bigint,
    sort_order integer DEFAULT 0 NOT NULL,
    visible_in_name boolean DEFAULT true NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_verbatim_rank boolean DEFAULT false NOT NULL,
    display_name text NOT NULL
);


--
-- Name: name_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_status (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    display boolean DEFAULT true NOT NULL,
    name character varying(50),
    name_group_id bigint NOT NULL,
    name_status_id bigint,
    nom_illeg boolean DEFAULT false NOT NULL,
    nom_inval boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    deprecated boolean DEFAULT false NOT NULL
);


--
-- Name: name_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    autonym boolean DEFAULT false NOT NULL,
    connector character varying(1),
    cultivar boolean DEFAULT false NOT NULL,
    formula boolean DEFAULT false NOT NULL,
    hybrid boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    name_category_id bigint NOT NULL,
    name_group_id bigint NOT NULL,
    scientific boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50),
    deprecated boolean DEFAULT false NOT NULL,
    vernacular boolean DEFAULT false NOT NULL
);


--
-- Name: reference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reference (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev_title character varying(2000),
    author_id bigint NOT NULL,
    bhl_url character varying(4000),
    citation character varying(4000),
    citation_html character varying(4000),
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    display_title character varying(2000) NOT NULL,
    doi character varying(255),
    duplicate_of_id bigint,
    edition character varying(100),
    isbn character varying(17),
    issn character varying(16),
    language_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    pages character varying(1000),
    parent_id bigint,
    publication_date character varying(50),
    published boolean DEFAULT false NOT NULL,
    published_location character varying(1000),
    publisher character varying(1000),
    ref_author_role_id bigint NOT NULL,
    ref_type_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    title character varying(2000) NOT NULL,
    tl2 character varying(30),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(1000) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_author character varying(1000),
    verbatim_citation character varying(2000),
    verbatim_reference character varying(1000),
    volume character varying(100),
    year integer,
    uri text,
    iso_publication_date character varying(10),
    url text,
    version_label text,
    CONSTRAINT check_iso_date CHECK (public.is_iso8601(iso_publication_date)),
    CONSTRAINT parent_not_self CHECK ((parent_id <> id))
);


--
-- Name: COLUMN reference.url; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference.version_label; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: shard_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shard_config (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(5000) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    use_notes character varying(255)
);


--
-- Name: tree; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    accepted_tree boolean DEFAULT false NOT NULL,
    config jsonb,
    current_tree_version_id bigint,
    default_draft_tree_version_id bigint,
    description_html text DEFAULT 'Edit me'::text NOT NULL,
    group_name text NOT NULL,
    host_name text NOT NULL,
    link_to_home_page text,
    name text NOT NULL,
    reference_id bigint,
    rdf_id text NOT NULL,
    full_name text,
    is_schema boolean DEFAULT false,
    is_read_only boolean DEFAULT false NOT NULL,
    CONSTRAINT draft_not_current CHECK ((current_tree_version_id <> default_draft_tree_version_id))
);


--
-- Name: tree_element; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_element (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    display_html text NOT NULL,
    excluded boolean DEFAULT false NOT NULL,
    instance_id bigint NOT NULL,
    instance_link text NOT NULL,
    name_element character varying(255) NOT NULL,
    name_id bigint NOT NULL,
    name_link text NOT NULL,
    previous_element_id bigint,
    profile jsonb,
    rank character varying(50) NOT NULL,
    simple_name text NOT NULL,
    source_element_link text,
    source_shard text NOT NULL,
    synonyms jsonb,
    synonyms_html text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    first_tree_version_id bigint
);


--
-- Name: tree_version_element; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version_element (
    element_link text NOT NULL,
    depth integer NOT NULL,
    name_path text NOT NULL,
    parent_id text,
    taxon_id bigint NOT NULL,
    taxon_link text NOT NULL,
    tree_element_id bigint NOT NULL,
    tree_path text NOT NULL,
    tree_version_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    merge_conflict boolean DEFAULT false NOT NULL
);


--
-- Name: name_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--


--
-- Name: MATERIALIZED VIEW name_mv; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: nsl_name_rank; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--


--
-- Name: primary_instance_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.primary_instance_v AS
 WITH pt AS (
         SELECT instance_type.id,
            instance_type.lock_version,
            instance_type.citing,
            instance_type.deprecated,
            instance_type.doubtful,
            instance_type.misapplied,
            instance_type.name,
            instance_type.nomenclatural,
            instance_type.primary_instance,
            instance_type.pro_parte,
            instance_type.protologue,
            instance_type.relationship,
            instance_type.secondary_instance,
            instance_type.sort_order,
            instance_type.standalone,
            instance_type.synonym,
            instance_type.taxonomic,
            instance_type.unsourced,
            instance_type.description_html,
            instance_type.rdf_id,
            instance_type.has_label,
            instance_type.of_label,
            instance_type.bidirectional,
            instance_type.alignment
           FROM public.instance_type
          WHERE (instance_type.standalone AND instance_type.primary_instance)
        ), bt AS (
         SELECT instance_type.id,
            instance_type.lock_version,
            instance_type.citing,
            instance_type.deprecated,
            instance_type.doubtful,
            instance_type.misapplied,
            instance_type.name,
            instance_type.nomenclatural,
            instance_type.primary_instance,
            instance_type.pro_parte,
            instance_type.protologue,
            instance_type.relationship,
            instance_type.secondary_instance,
            instance_type.sort_order,
            instance_type.standalone,
            instance_type.synonym,
            instance_type.taxonomic,
            instance_type.unsourced,
            instance_type.description_html,
            instance_type.rdf_id,
            instance_type.has_label,
            instance_type.of_label,
            instance_type.bidirectional,
            instance_type.alignment
           FROM public.instance_type
          WHERE (instance_type.nomenclatural AND ((instance_type.rdf_id)::text ~ '(basionym|replace|primary)'::text))
        ), ot AS (
         SELECT instance_type.id,
            instance_type.lock_version,
            instance_type.citing,
            instance_type.deprecated,
            instance_type.doubtful,
            instance_type.misapplied,
            instance_type.name,
            instance_type.nomenclatural,
            instance_type.primary_instance,
            instance_type.pro_parte,
            instance_type.protologue,
            instance_type.relationship,
            instance_type.secondary_instance,
            instance_type.sort_order,
            instance_type.standalone,
            instance_type.synonym,
            instance_type.taxonomic,
            instance_type.unsourced,
            instance_type.description_html,
            instance_type.rdf_id,
            instance_type.has_label,
            instance_type.of_label,
            instance_type.bidirectional,
            instance_type.alignment
           FROM public.instance_type
          WHERE (instance_type.nomenclatural AND ((instance_type.rdf_id)::text ~ '(orthographic|alternative|isonym)'::text))
        ), pi AS (
         SELECT DISTINCT ON (i.name_id) i.name_id,
            n_1.full_name,
            n_1.simple_name,
            n_1.verbatim_rank,
            nk.rdf_id AS rank_rdf_id,
            nk.visible_in_name,
            nk.has_parent,
            nt.rdf_id AS name_type_rdf_id,
            COALESCE(((n_1.base_author_id)::integer)::boolean, n_1.changed_combination) AS is_changed_combination,
            COALESCE(oo.id, bu.id,
                CASE
                    WHEN (NOT n_1.changed_combination) THEN i.id
                    ELSE NULL::bigint
                END) AS primary_id,
            COALESCE(oo.name_id, bu.name_id, i.name_id) AS primary_name_id,
            i.id AS combination_id,
            bu.name_id AS basionym_id,
            COALESCE((n_1.published_year)::text, (br.iso_publication_date)::text, (ir.iso_publication_date)::text) AS primary_date,
            COALESCE(ir.iso_publication_date, ((n_1.published_year)::text)::character varying) AS combination_date,
                CASE
                    WHEN ((code.value)::text = 'ICN'::text) THEN COALESCE(ot.rdf_id, it.rdf_id)
                    ELSE ut.rdf_id
                END AS publication_usage_type,
                CASE
                    WHEN ((code.value)::text = 'ICN'::text) THEN COALESCE(ir.iso_publication_date, br.iso_publication_date, ((n_1.published_year)::text)::character varying)
                    ELSE COALESCE(br.iso_publication_date, ir.iso_publication_date, ((n_1.published_year)::text)::character varying)
                END AS publication_date,
                CASE
                    WHEN ((code.value)::text = 'ICN'::text) THEN COALESCE(ir.citation, br.citation)
                    ELSE COALESCE(br.citation, ir.citation)
                END AS publication_citation,
            dataset.value AS dataset_name
           FROM (((((((((((public.name n_1
             JOIN public.name_type nt ON ((n_1.name_type_id = nt.id)))
             JOIN public.name_rank nk ON ((n_1.name_rank_id = nk.id)))
             JOIN public.name_status ns_1 ON ((n_1.name_status_id = ns_1.id)))
             LEFT JOIN public.name np ON ((np.id = n_1.parent_id)))
             LEFT JOIN public.instance i ON ((i.name_id = n_1.id)))
             JOIN public.instance_type it ON (((i.instance_type_id = it.id) AND it.standalone)))
             LEFT JOIN public.reference ir ON (((i.reference_id = ir.id) AND (NOT (EXISTS ( SELECT 1
                   FROM public.tree
                  WHERE (tree.reference_id = ir.id)))))))
             LEFT JOIN ((public.instance er
             JOIN bt ON ((er.instance_type_id = bt.id)))
             JOIN ((public.instance bu
             JOIN public.instance_type ut ON ((bu.instance_type_id = ut.id)))
             LEFT JOIN public.reference br ON ((bu.reference_id = br.id))) ON ((bu.id = er.cites_id))) ON ((i.id = er.cited_by_id)))
             LEFT JOIN ((((public.instance ou
             JOIN ot ON ((ot.id = ou.instance_type_id)))
             JOIN public.instance oi ON ((oi.id = ou.cited_by_id)))
             LEFT JOIN public.instance oo ON ((oo.name_id = oi.name_id)))
             JOIN pt ON ((oo.instance_type_id = pt.id))) ON ((ou.cites_id = i.id)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))
          ORDER BY i.name_id, ((((it.standalone)::integer)::text || ((it.primary_instance)::integer)::text) || ((it.protologue)::integer)::text) DESC, bt.sort_order, (COALESCE(br.year, ir.year))::text
        )
 SELECT pi.name_id,
    ns.rdf_id AS name_status_rdf_id,
    ai.name_id AS autonym_of_id,
    pi.is_changed_combination,
    pi.basionym_id,
    pi.primary_name_id,
    COALESCE(ai.primary_id, pi.primary_id) AS primary_id,
    COALESCE(ai.combination_id, pi.combination_id) AS combination_id,
    COALESCE(ai.primary_date, pi.primary_date) AS primary_date,
    pi.combination_date,
    pi.publication_usage_type,
    pi.publication_date,
    pi.publication_citation,
    pi.dataset_name
   FROM ((((public.name n
     JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
     JOIN pi ON ((n.id = pi.name_id)))
     LEFT JOIN LATERAL ( WITH RECURSIVE parent_part AS (
                 SELECT v.id,
                    v.parent_id,
                    r.major,
                    v.full_name
                   FROM (public.name v
                     JOIN public.name_rank r ON ((v.name_rank_id = r.id)))
                  WHERE (v.id = n.parent_id)
                UNION ALL
                 SELECT p.id,
                    p.parent_id,
                    k.major,
                    p.full_name
                   FROM ((public.name p
                     JOIN parent_part c ON ((p.id = c.parent_id)))
                     JOIN public.name_rank k ON ((p.name_rank_id = k.id)))
                  WHERE (NOT c.major)
                )
         SELECT parent_part.id,
            parent_part.parent_id,
            parent_part.full_name
           FROM parent_part
          WHERE parent_part.major
         LIMIT 1) pp ON (pi.has_parent))
     LEFT JOIN pi ai ON (((pp.id = ai.name_id) AND ((pi.publication_usage_type)::text ~ 'autonym'::text))))
  WHERE ((n.name_path !~ '^C[MLAF]/'::text) OR (n.name_path IS NULL));


--
-- Name: taxon_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--



--
-- Name: MATERIALIZED VIEW taxon_mv; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxon_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.name_type; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.accepted_name_usage_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.accepted_name_usage; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.nomenclatural_status; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxonomic_status; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.pro_parte; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.scientific_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.nom_illeg; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.nom_inval; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.scientific_name_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.canonical_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.scientific_name_authorship; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.parent_name_usage_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxon_rank; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxon_rank_sort_order; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.kingdom; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.class; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.subclass; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.family; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxon_concept_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.name_according_to; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.name_according_to_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxon_remarks; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.taxon_distribution; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.higher_classification; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.first_hybrid_parent_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.first_hybrid_parent_name_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.second_hybrid_parent_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.second_hybrid_parent_name_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.nomenclatural_code; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.created; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.modified; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.dataset_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.dataset_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.license; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN taxon_mv.cc_attribution_iri; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: tnu_index_v; Type: VIEW; Schema: public; Owner: -
--



--
-- Name: gettnu(text); Type: FUNCTION; Schema: public; Owner: -
--



--
-- Name: inc_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inc_status(nameid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select 'included' :: text
where exists(select 1
             from tree_element te2
             where synonyms @> (select '{"list":[{"name_id":' || nameId || ', "mis":false}]}') :: JSONB)
$$;


--
-- Name: instance_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'instance deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'instance updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'instance created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: instance_on_accepted_tree(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_on_accepted_tree(instanceid bigint) RETURNS TABLE(current boolean, excluded boolean, element_link text, tree_name text)
    LANGUAGE sql
    AS $$
select t.current_tree_version_id = tv.id, te.excluded, tve.element_link, t.name
from tree_element te
       join tree_version_element tve on te.id = tve.tree_element_id
       join tree_version tv on tve.tree_version_id = tv.id
       join tree t on tv.tree_id = t.id and t.accepted_tree
where te.instance_id = instanceId
  and tv.published
order by tve.tree_version_id desc
limit 1;
$$;


--
-- Name: instance_on_accepted_tree_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_on_accepted_tree_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
             'current', tve.current,
             'excluded', tve.excluded,
             'element_link', tve.element_link,
             'tree_name', tve.tree_name
             )
           )
from instance_on_accepted_tree(instanceid) tve
$$;


--
-- Name: instance_resources(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_resources(instanceid bigint) RETURNS TABLE(name text, description text, url text, css_icon text, media_icon text)
    LANGUAGE sql
    AS $$
select rd.name, rd.description, s.url || '/' || r.path, rd.css_icon, 'media/' || m.id
from instance_resources ir
       join resource r on ir.resource_id = r.id
       join site s on r.site_id = s.id
       join resource_type rd on r.resource_type_id = rd.id
      left outer join media m on m.id = rd.media_icon_id
    where ir.instance_id = instanceid
$$;


--
-- Name: instance_resources_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_resources_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'type', ir.name,
           'description', ir.description,
           'url', ir.url,
           'css_icon', ir.css_icon,
           'media_icon', ir.media_icon
         )
       )
from instance_resources(instanceid) ir
$$;


--
-- Name: latest_accepted_profile(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.latest_accepted_profile(instanceid bigint) RETURNS TABLE(comment_key text, comment_value text, dist_key text, dist_value text)
    LANGUAGE sql
    AS $$
select config ->> 'comment_key'                                 as comment_key,
       (profile -> (config ->> 'comment_key')) ->> 'value'      as comment_value,
       config ->> 'distribution_key'                            as dist_key,
       (profile -> (config ->> 'distribution_key')) ->> 'value' as dist_value
from tree_version_element tve
       join tree_element te on tve.tree_element_id = te.id
       join tree_version tv on tve.tree_version_id = tv.id and tv.published
       join tree t on tv.tree_id = t.id and t.accepted_tree
where te.instance_id = instanceid
order by tv.id desc
limit 1
$$;


--
-- Name: latest_accepted_profile_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.latest_accepted_profile_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_build_object(
         'comment_key', comment_key,
         'comment_value', comment_value,
         'dist_key', dist_key,
         'dist_value', dist_value
           )
from latest_accepted_profile(instanceid)
$$;


--
-- Name: latest_accepted_profile_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.latest_accepted_profile_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select '  ' ||
       case
         when comment_value is not null
                 then comment_key || ': ' || comment_value
         else ''
           end ||
       case
         when dist_value is not null
                 then dist_key || ': ' || dist_value
         else ''
           end ||
       E'
'
from latest_accepted_profile(instanceid)
$$;


--
-- Name: list_dependent_views(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_dependent_views(ref_view_name text) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
DECLARE dep_view TEXT;
BEGIN

	FOR dep_view IN
		SELECT dep_view_name from (SELECT distinct dependent_obj.relkind::text,
		                                           dependent_ns.nspname || '.' || dependent_obj.relname dep_view_name
		                           FROM pg_depend
			                                INNER JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
			                                INNER JOIN pg_class AS dependent_obj ON pg_rewrite.ev_class = dependent_obj.oid
			                                INNER JOIN pg_class AS ref_obj ON pg_depend.refobjid = ref_obj.oid
			                                INNER JOIN pg_namespace AS dependent_ns
			                                           ON dependent_obj.relnamespace = dependent_ns.oid
			                                INNER JOIN pg_namespace AS ref_ns ON ref_obj.relnamespace = ref_ns.oid
		                           WHERE (ref_ns.nspname || '.' || ref_obj.relname = ref_view_name OR
		                                  ref_ns.nspname || '.' || ref_obj.relname = ref_view_name || '_data')
			                         AND (ref_obj.relkind::text = 'v' OR ref_obj.relkind::text = 'm')
			                         AND dependent_obj.relname != ref_obj.relname
		                           ORDER BY 1) dpv
		LOOP
			RETURN NEXT dep_view;
			RETURN QUERY EXECUTE 'SELECT * FROM list_dependent_views(''' || dep_view || ''')';
		END LOOP;
END;
$$;


--
-- Name: name_constructor(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_constructor(name_id bigint) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN nc_jsonb(name_id) ->> 'full_name';

END;
$$;


--
-- Name: name_name_path(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_name_path(target_name_id bigint) RETURNS TABLE(name_path text, family_id bigint)
    LANGUAGE sql
    AS $$
with pathElements (id, path_element, rank_name) as (
  WITH RECURSIVE walk (id, parent_id, path_element, pos, rank_name) AS (
    SELECT
      n.id,
      n.parent_id,
      n.name_element,
      1,
      rank.name
    FROM name n
      join name_rank rank on n.name_rank_id = rank.id
    WHERE n.id = target_name_id
    UNION ALL
    SELECT
      n.id,
      n.parent_id,
      n.name_element,
      walk.pos + 1,
      rank.name
    FROM walk, name n
      join name_rank rank on n.name_rank_id = rank.id
    WHERE n.id = walk.parent_id
  )
  SELECT
    id,
    path_element,
    rank_name
  FROM walk
  order by walk.pos desc)
select
  string_agg(path_element, '/'),
  (select id
   from pathElements p2
   where p2.rank_name = 'Familia'
   limit 1)
from pathElements;
$$;


--
-- Name: name_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'name deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'name updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'name created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: nc_core(public.name, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nc_core(nm public.name, state jsonb DEFAULT '{"depth": 0, "in_hybrid": false, "in_phrase": false, "in_autonym": false, "in_formula": false, "in_cultivar": false}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$
DECLARE
	current_id BIGINT;
	rank_abbrev TEXT;
	name_rank TEXT;
	rank_id BIGINT;
	rank_rdfid TEXT;
	has_parent BOOLEAN;
	genus_rank_id BIGINT;
	target_rank BIGINT;
	parent_rank BIGINT;
	element TEXT := '';
	name_string TEXT := '';
	name_type TEXT;
	is_format BOOLEAN;
	capitalize BOOLEAN;
	is_hybrid BOOLEAN;
	is_autonym BOOLEAN;
	is_formula BOOLEAN;
	is_cultivar BOOLEAN;
	ws_connector TEXT;
	authors    TEXT;
	authorship TEXT ;
	name_status TEXT;
	status_text TEXT;
	code TEXT;
	simple_name TEXT;
	name_path TEXT;
	x_state JSONB;
	full_name TEXT := '';
	html_full TEXT := '';
	html_simple TEXT;
	rdfa_name TEXT := '';
	title TEXT := '';
	element_id BIGINT;
	second_parent BIGINT;
	name_rdfid TEXT;
	nmx public.name%ROWTYPE ;
	author TEXT;

BEGIN


	    nmx := nm;
		-- capture this name's metadate
		SELECT
			t.rdf_id,
			t.autonym,
			nullif(k.rdf_id,'n-a'),
			s.rdf_id,
			s.name,
			g.rdf_id,
			path.value,
			gk.id,
			t.connector
		INTO
			name_type, is_autonym, name_rank, name_status, status_text, code, name_path, genus_rank_id,
			ws_connector

		FROM
			   public.name_rank k
			    JOIN public.name_type t
			       JOIN public.name_group g ON t.name_group_id = g.id
			     ON nmx.name_type_id = t.id
			     LEFT JOIN public.name_status s on nmx.name_status_id = s.id and s.display -- (s.nom_inval or s.rdf_id = 'manuscript')
			     LEFT JOIN public.shard_config path on path.name = 'services path name element'
			     LEFT JOIN public.name_rank gk on gk.rdf_id = 'genus'
		   where nmx.name_rank_id = k.id
		;

	    element_id := nmx.id;
	    element := nmx.name_element;
	    current_id := nmx.id;
	    second_parent := nmx.second_parent_id;
		name_rdfid := name_type;

		state := jsonb_set( state, '{in_autonym}', to_jsonb(is_autonym), true);

		IF name_type ~ 'cultivar-hybrid' THEN
			state := jsonb_set( state, '{in_hybrid}', to_jsonb(true), true);
		END IF;

	LOOP


		IF nmx.family_id = nmx.id and (state->>'depth')::int > 0 THEN
			EXIT;
		END IF;

		-- Fetch the necessary information for the current name element

		SELECT nmx.id,
		       rtrim(nmx.name_element),
		       rtrim(nmx.simple_name),
		       nmx.parent_id,
		       k.id,
		       k.parent_rank_id,
		       CASE
			       WHEN k.visible_in_name THEN
				       COALESCE(CASE WHEN k.use_verbatim_rank THEN
				                   nmx.verbatim_rank END,
				                CASE WHEN k.abbrev ~ '^\[.*\]$' THEN
				                    '[unranked]'
		                        ELSE k.abbrev
	                            END
				       ) END,
		       k.italicize,
		       -- CASE WHEN k.sort_order <= f.sort_order THEN true ELSE false END AS capitalize,
		       k.has_parent,
		       k.rdf_id,
		       nmx.second_parent_id,
		       t.rdf_id,
		       t.hybrid,
		       -- t.autonym,
		       t.formula,
		       t.cultivar,
		       t.connector,
		       CASE
			       WHEN code.value = 'ICN' THEN
				       CASE
					       WHEN t.autonym or t.formula or t.cultivar THEN NULL::text
					       ELSE
						       COALESCE(
								       '(' || COALESCE(xb.abbrev || ' ex ', '') || b.abbrev || ') ',
								       ''
						       ) || COALESCE(
								       COALESCE(xa.abbrev || ' ex ', '') || a.abbrev,
								       ''
						            )
					       END
			       WHEN code.value = 'ICZN' THEN
				       CASE
					       WHEN nmx.changed_combination THEN
						       COALESCE(
								       '(' || a.abbrev || COALESCE(', ' || nmx.published_year, '') || ')',
								       ''
						       )
					       ELSE
						       COALESCE(
								       a.abbrev || COALESCE(', ' || nmx.published_year, ''),
								       ''
						       )
					       END
			       END AS authorship
		INTO element_id, element, simple_name, current_id, rank_id, parent_rank, rank_abbrev,
			is_format, -- capitalize,
		    has_parent, rank_rdfid, second_parent, name_rdfid,
			is_hybrid, -- is_autonym,
			is_formula, is_cultivar, ws_connector, authors
		FROM public.name_rank k -- ON n.name_rank_id = k.id
			     JOIN public.name_type t ON nmx.name_type_id = t.id
			     LEFT JOIN public.shard_config code ON code.name::text = 'nomenclatural code'::text
				 LEFT JOIN public.author a ON nmx.author_id = a.id
				 LEFT JOIN public.author xa ON nmx.ex_author_id = xa.id
				 LEFT JOIN public.author b ON nmx.base_author_id = b.id
				 LEFT JOIN public.author xb ON nmx.ex_base_author_id = xb.id
		         LEFT JOIN public.name_rank f  on f.rdf_id = 'family'
		    
		WHERE  nmx.name_rank_id = k.id;

		IF code ~ 'zoological' and has_parent and current_id is null THEN
			element := simple_name;
		END IF;

		if (state ->> 'in_cultivar')::BOOLEAN and (state ->> 'in_hybrid')::BOOLEAN THEN
			parent_rank := genus_rank_id;
		end if;

		-- Handle common or vernacular names
		IF name_rdfid ~ '(common|vernacular)' THEN
			name_string := element;
			EXIT;
		END IF;

        -- Handle name formulae
		IF is_formula THEN

			IF (state ->> 'in_cultivar')::BOOLEAN THEN
				-- name := nc_jsonb(current_id, jsonb_set( x_state, '{in_formula}', to_jsonb(true))::JSONB)->>'name';
				name_string := public.nc_jsonb(current_id,
				                         jsonb_set(jsonb_set(state, '{depth}', to_jsonb((state ->> 'depth')::int+1), true),
				                         '{in_formula}', 'true'::jsonb, true)) ->> 'name';
			ELSE
				x_state := state;
				 x_state := jsonb_set(x_state, '{in_formula}', to_jsonb(true), true);
				   x_state := jsonb_set(x_state, '{depth}', to_jsonb((state ->> 'depth')::int + 1));
				name_string := CONCAT_WS(
						' ',
						public.nc_jsonb(current_id, x_state) ->> 'name',
						ws_connector,
						COALESCE(public.nc_jsonb(second_parent, x_state) ->> 'name', '?')
				        );
				IF (state ->> 'in_formula')::BOOLEAN THEN
					name_string := CONCAT('(', name_string, ')');
					state := jsonb_set(state, '{in_formula}', to_jsonb(false), true);
				END IF;
			END IF;
			EXIT;
		END IF;

		-- Handle cultivar names
		IF is_cultivar THEN

			IF is_hybrid THEN
				parent_rank := genus_rank_id;
				state := jsonb_set(state, '{in_hybrid}', 'true'::JSONB, true);
			END IF;

			name_string := public.nc_jsonb(current_id,
			                         jsonb_set(jsonb_set(state, '{depth}', to_jsonb((state ->> 'depth')::int + 1)),
			                                   '{in_cultivar}', 'true'::JSONB, true)) ->> 'name';

			IF NOT (state ->> 'in_cultivar')::BOOLEAN THEN
				name_string := CONCAT_WS(' ', name_string, '''' || element || '''');
			END IF;

			EXIT;
		END IF;


		IF rank_rdfid = 'subgenus' and code = 'zoological' and current_id is not null THEN
			element := '(' || element || ')';
		END IF;

		-- IF ( rdfa or html ) and is_format and name_rdfid !~ 'phrase' THEN
		IF is_format and name_rdfid !~ 'phrase' THEN
			element := CONCAT('<i>', element, '</i>');
		END IF;

		-- IF capitalize and code = 'zoological' THEN
		--	element := upper(element);
		--end if;

		IF name_rdfid ~ 'phrase' THEN
			--  to include named_parts ... rank_rdfid is only an example.
			--  The rank table needs a column 'name_of_name' for the name of a name at rank.
			--  element := CONCAT( '<em property="', rank_rdfid, '">', element, '</em>');
			--  without this, use <i> [note <i> cannot have properties]
			state := jsonb_set( state, '{in_phrase}', to_jsonb(true), true);
		 	 name_string := CONCAT_WS(' ', rtrim((public.nc_jsonb(current_id,
                                                 jsonb_set(state, '{depth}', to_jsonb((state ->> 'depth')::int + 1))) ->> 'name')),
                                               nullif(rank_abbrev,'[unranked]'), element,
                                                 (CASE WHEN (state->>'depth')::INT = 0 THEN authors END ));
		 	-- name_string := CONCAT_WS(' ', nullif(rank_abbrev,'[unranked]'), element, authors);
		 	 EXIT;
			-- rank_abbrev :=  nullif(rank_abbrev,'[unranked]');
			-- target_rank := rank_id;
		 END IF;

        -- Handle named hybrid
		IF name_rdfid ~ 'named-hybrid' and rank_rdfid !~ 'notho' THEN
			element := 'x ' || element;
		END IF;

		IF (state ->> 'in_cultivar')::BOOLEAN  or
		   ((state ->> 'depth')::INT > 0 and not (state ->> '{in_formula}')::boolean)
		THEN
			author := null;
		ELSE
			author := '<auth>'||authors||'</auth>';
		END IF;

        -- Construct the scientific name
		-- raise notice 'depth % name_type %, element_id %, current_id %, parent_rank %, rank_id %, target_rank %, state %,  element %, name %', (state ->> 'depth')::int, name_type, element_id , current_id , parent_rank, rank_id, target_rank, state, element, name_string;

		IF name_string = '' THEN


			IF rank_rdfid ~ 'unranked' and not (state ->> 'in_cultivar')::BOOLEAN THEN
				
				name_string := CONCAT_WS(' ', public.nc_jsonb(current_id, jsonb_set(state, '{depth}',
				                                                              to_jsonb((state ->> 'depth')::int + 1))) ->>
				                       'name', rank_abbrev, element, author);

				EXIT;
			END IF;

			CASE WHEN (state ->> 'in_hybrid')::BOOLEAN and parent_rank != rank_id THEN
				     NULL;
			     WHEN (((state ->> 'in_autonym')::BOOLEAN or (state ->> 'in_cultivar')::BOOLEAN ) and code ~ 'botanical') or
			            (((state->>'depth')::INT > 0 ) and not (state ->> 'in_formula')::BOOLEAN) THEN
				     name_string := CONCAT_WS(' ', rank_abbrev, element);
			     ELSE
				name_string := CONCAT_WS(' ', rank_abbrev, element, author );
			END CASE;
			target_rank := parent_rank;
			authorship := authors;
		ELSE

			IF rank_id is not distinct from target_rank  THEN

				IF (state ->> 'in_autonym')::BOOLEAN  and code ~ 'botanical' and not  (state ->> 'in_phrase')::BOOLEAN
				THEN
					name_string := CONCAT_WS(' ', element, author , name_string);
				ELSE
					name_string := CONCAT_WS(' ', element, name_string);
				END IF;
				state := jsonb_set(state, '{in_autonym}', to_jsonb(false), true);

			END IF;
			target_rank := parent_rank;
		END IF;

	 -- raise notice 'depth % name_type %, element_id %, current_id %, has_parent % parent_rank %, rank_id %, target_rank %, state %,  element %, name %', (state ->> 'depth')::int, name_type, element_id , current_id , has_parent, parent_rank, rank_id, target_rank, state, element, name_string;

		IF not has_parent THEN
			EXIT;
		END IF;
		-- If we've reached the root (uninomial), exit the loop- just to be sure  o
		IF current_id IS NULL or (state->>'depth')::int > 4 THEN
			EXIT;
		END IF;

        -- get the parent
		select * into nmx from public.name where id = current_id;

	END LOOP;

	name_string := ltrim(regexp_replace(name_string, '</i> <i>', ' ', 'g'));

	if (state ->> 'in_formula')::BOOLEAN then
		name_string := rtrim(name_string);
	end if;

	html_simple := rtrim(regexp_replace(name_string,'(<auth>[^<]*</auth>) *', '', 'g'));
	simple_name := regexp_replace(html_simple,'</*i>', '', 'g');
	html_full := rtrim(regexp_replace(name_string,'</*auth>', '', 'g'));
	full_name := regexp_replace(html_full, '</*i>', '', 'g');

	rdfa_name :=
			CONCAT(
					'<a href="https://id.biodiversity.org.au/name/'||name_path||'/', nmx.id,
					'" prefix="nsl: https://id.biodiversity.org.au/voc/"',
					' version="nc-0" typeof="nsl:TaxonName"' , '>',
					'<span property="nsl:fullName" content="',
					full_name, '">',
					html_full,
					', ' || status_text, '</span>'
					'<meta property="nsl:nameCode" content="nsl:' || code || '"/>',
					'<meta property="nsl:nameType" content="nsl:' || name_type || '"/>',
					'<meta property="nsl:nameRank" content="nsl:' || name_rank || '"/>',
					'<meta property="nsl:nameStatus" content="nsl:' || name_status || '"/>',
					'</a>'
			);

	title := CONCAT_WS (' ', html_full, status_text);

		-- raise notice '2 name_type %, element_id %, current_id %, parent_rank %, rank_id %, target_rank %, state % ,  element %, name %, status_text %', name_type, element_id , current_id , parent_rank, rank_id, target_rank, state, element, name_string, status_text;

		if (state ->> 'depth')::int = 0 then

			-- nmx.names_cache :=
		 	RETURN	jsonb_build_object ('rdfa', rdfa_name, 'title', title, 'html_full', html_full, 'full_name', full_name, 'html_simple', html_simple, 'simple_name', simple_name, 'authorship', authorship);
		else
			-- loop with state
			RETURN jsonb_build_object('name', name_string, 'state', state);

		end if;

   -- RETURN nmx;
END;
$_$;


--
-- Name: nc_jsonb(bigint, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nc_jsonb(name_id bigint, state jsonb DEFAULT '{"depth": 0, "in_hybrid": false, "in_phrase": false, "in_autonym": false, "in_formula": false, "in_cultivar": false}'::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
	nmx public.name%ROWTYPE;
BEGIN

	IF name_id is null THEN return null; END IF;

	SELECT * into nmx from public.name where id = name_id;

	-- nmx := nc_core ( nmx, state);

	RETURN public.nc_core(nmx, state);

END;
$$;


--
-- Name: nc_table(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nc_table(name_id bigint) RETURNS TABLE(full_name text, title text, rdfa text, html_full text, simple_name text, html_simple text, authorship text)
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF name_id is null THEN return; END IF;

	RETURN QUERY
		SELECT nc.full_name,
		       nc.title,
		       nc.rdfa,
		       nc.html_full,
		       nc.simple_name,
		       nc.html_simple,
		       nc.authorship
		from jsonb_to_record(public.nc_jsonb(name_id))
			     as nc (
			            full_name text,
			            title text,
			            rdfa text,
			            html_full text,
			            simple_name text,
			            html_simple text,
			            authorship text
				);

END;
$$;


--
-- Name: non_type_notes(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.non_type_notes(instanceid bigint) RETURNS TABLE(note_key text, note text)
    LANGUAGE sql
    AS $$
select k.name, nt.value
from instance_note nt
       join instance_note_key k on nt.instance_note_key_id = k.id
where nt.instance_id = instanceid
  and k.name not ilike '%type'
$$;


--
-- Name: non_type_notes_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.non_type_notes_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'note_key', nt.note_key,
           'note_value', nt.note
             )
           )
from non_type_notes(instanceid) as nt
$$;


--
-- Name: non_type_notes_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.non_type_notes_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' || nt.note_key || ': ' || nt.note || E'
', E'
')
from non_type_notes(instanceid) as nt
$$;


--
-- Name: not_in(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.not_in(v1 bigint, v2 bigint) RETURNS TABLE(element_link text, tree_element_id bigint)
    LANGUAGE sql
    AS $$
Select t1.element_link, t1.tree_element_id
from (SELECT * FROM tree_version_element WHERE tree_version_id = v1) t1
where t1.tree_element_id not in (SELECT t2.tree_element_id FROM tree_version_element t2 WHERE tree_version_id = v2)
$$;


--
-- Name: orth_or_alt_of(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.orth_or_alt_of(nameid bigint) RETURNS bigint
    LANGUAGE sql
    AS $$
select coalesce((select alt_of_inst.name_id
                 from name n
                        join name_status ns on n.name_status_id = ns.id
                        join instance alt_inst on n.id = alt_inst.name_id
                        join instance_type alt_it on alt_inst.instance_type_id = alt_it.id and
                                                     alt_it.name in ('orthographic variant', 'alternative name')
                        join instance alt_of_inst on alt_of_inst.id = alt_inst.cited_by_id
                 where n.id = nameid
                   and ns.name ~ '(orth. var.|nom. alt.)' limit 1), nameid) id
$$;


--
-- Name: pbool(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pbool(bool boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
begin
return case bool
       when true
        then 'true'
      else
        ''
      end;
end; $$;


--
-- Name: profile_as_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.profile_as_jsonb(source_instance_id bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
SELECT jsonb_object_agg(key.name, jsonb_build_object(
    'value', note.value,
    'created_at', note.created_at,
    'created_by', note.created_by,
    'updated_at', note.updated_at,
    'updated_by', note.updated_by,
    'source_link', 'https://id.biodiversity.org.au' || '/instanceNote/apni/' || note.id
))
FROM instance i
  JOIN instance_note note ON i.id = note.instance_id
  JOIN instance_note_key key ON note.instance_note_key_id = key.id
WHERE i.id = source_instance_id;
$$;


--
-- Name: profile_instance_constraint(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.profile_instance_constraint() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	tei_id BIGINT;
BEGIN

	IF NEW.tree_element_id IS NOT NULL THEN

	 SELECT instance_id INTO tei_id
	 FROM tree_element te
	 WHERE te.id = NEW.tree_element_id;

	 IF coalesce(NEW.instance_id, tei_id) != tei_id  THEN
		RAISE EXCEPTION 'Profile Tree_element.instance_id mismatch';
	 END IF;

	END IF;

	RETURN NEW;
END;
$$;


--
-- Name: profile_object_type_constraint(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.profile_object_type_constraint() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF TG_OP = 'UPDATE' and NEW.product_item_config_id != OLD.product_item_config_id   THEN
	 RAISE EXCEPTION 'Profile Item Type mismatch on update';
	ELSE
      -- Determine the correct object_type from the associated product_item_config
      SELECT pot.rdf_id
      INTO NEW.profile_object_rdf_id
      FROM product_item_config pic
      JOIN profile_item_type pit ON pic.profile_item_type_id = pit.id
      JOIN profile_object_type pot ON pit.profile_object_type_id = pot.id
      WHERE pic.id = NEW.product_item_config_id;

    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: ref_parent_date(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ref_parent_date(ref_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
select case
           when rt.use_parent_details = true
               then coalesce(r.iso_publication_date, pr.iso_publication_date)
           else r.iso_publication_date
           end
from reference r
         join ref_type rt on r.ref_type_id = rt.id
         left outer join reference pr on r.parent_id = pr.id
where r.id = ref_id;
$$;


--
-- Name: ref_year(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ref_year(iso_publication_date text) RETURNS integer
    LANGUAGE sql
    AS $$
select cast(substring(iso_publication_date from 1 for 4) AS integer)
$$;


--
-- Name: reference_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reference_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'reference deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'reference updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'reference created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: searchbyname(text, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.searchbyname(v_search_string text, v_tv_id bigint) RETURNS TABLE(element_link text, name text, tve_id bigint, parent_id text, tree_path text)
    LANGUAGE plpgsql
    AS $$
    declare
        result text;
    begin
        return query
        select tve.element_link, te.simple_name, tve.tree_element_id, tve.parent_id, tve.tree_path
        from tree_version_element tve
        join tree_element te on tve.tree_element_id = te.id
        where simple_name ilike v_search_string and tve.tree_version_id = v_tv_id;
    end;
$$;


--
-- Name: synonym_as_html(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonym_as_html(instanceid bigint) RETURNS TABLE(html text)
    LANGUAGE sql
    AS $$
SELECT CASE
           WHEN it.nomenclatural
               THEN '<nom>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                    '</name-status> <year>(' || format_isodate(iso_publication_date) || ')</year> <type>' || instance_type ||
                    '</type></nom>'
           WHEN it.taxonomic
               THEN '<tax>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                    '</name-status> <year>(' || format_isodate(iso_publication_date) || ')</year> <type>' || instance_type ||
                    '</type></tax>'
           WHEN it.misapplied
               THEN '<mis>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                    '</name-status><type>' || instance_type || '</type> by <citation>' ||
                    citation_html || '</citation></mis>'
           WHEN it.synonym
               THEN '<syn>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                    '</name-status> <year>(' || format_isodate(iso_publication_date) || ')</year> <type>' || it.name || '</type></syn>'
           ELSE '<oth>' || full_name_html || '<name-status class="' || name_status || '">, ' || name_status ||
                '</name-status> <type>' || it.name || '</type></oth>'
           END
FROM apni_ordered_synonymy(instanceid)
         join instance_type it on instance_type_id = it.id
$$;


--
-- Name: synonyms_as_html(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonyms_as_html(instance_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
SELECT '<synonyms>' || string_agg(html, '') || '</synonyms>'
FROM synonym_as_html(instance_id) AS html;
$$;


--
-- Name: synonyms_as_jsonb(bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonyms_as_jsonb(instance_id bigint, host text) RETURNS jsonb
    LANGUAGE sql
    AS $$
SELECT jsonb_build_object('list',
                          coalesce(
                              jsonb_agg(jsonb_build_object(
                                  'host', host,
                                  'instance_id', syn_inst.id,
                                  'instance_link', syn_inst.uri,
                                  'concept_link', coalesce(cites_inst.uri, syn_inst.uri),
                                  'simple_name', synonym.simple_name,
                                  'type', it.name,
                                  'name_id', synonym.id :: BIGINT,
                                  'name_link', synonym.uri,
                                  'full_name_html', synonym.full_name_html,
                                  'nom', it.nomenclatural,
                                  'tax', it.taxonomic,
                                  'mis', it.misapplied,
                                  'cites', coalesce(cites_ref.citation, syn_ref.citation),
                                  'cites_html', coalesce(cites_ref.citation_html, syn_ref.citation_html),
                                  'cites_link', '/reference/'|| lower(conf.value) || '/' || (coalesce(cites_ref.id, syn_ref.id)),
                                  'year', cites_ref.year
                                )), '[]' :: JSONB)
         )
FROM Instance i,
     Instance syn_inst
       JOIN instance_type it ON syn_inst.instance_type_id = it.id
       JOIN reference syn_ref on syn_inst.reference_id = syn_ref.id
       LEFT JOIN instance cites_inst ON syn_inst.cites_id = cites_inst.id
       LEFT JOIN reference cites_ref ON cites_inst.reference_id = cites_ref.id
    ,
     name synonym,
     shard_config conf
WHERE i.id = instance_id
  AND syn_inst.cited_by_id = i.id
  AND synonym.id = syn_inst.name_id
  AND conf.name = 'name space';
$$;


--
-- Name: tree_element_data_from_start_node(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tree_element_data_from_start_node(root_node bigint) RETURNS TABLE(tree_id bigint, node_id bigint, excluded boolean, declared_bt boolean, instance_id bigint, name_id bigint, simple_name text, name_path text, instance_path text, parent_instance_path text, parent_excluded boolean, depth integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE treewalk (tree_id, node_id, excluded, declared_bt, instance_id, name_id, simple_name, name_path, instance_path,
    parent_instance_path, parent_excluded, depth) AS (
  SELECT
    tree.id                   AS tree_id,
    node.id                   AS node_id,
    (node.type_uri_id_part <>
     'ApcConcept') :: BOOLEAN AS excluded,
    (node.type_uri_id_part =
     'DeclaredBt') :: BOOLEAN AS declared_bt,
    node.instance_id          AS instance_id,
    node.name_id              AS name_id,
    n.simple_name :: TEXT     AS simple_name,
    coalesce(n.name_element,
             '?')             AS name_path,
    CASE
    WHEN (node.type_uri_id_part = 'ApcConcept')
      THEN
        node.instance_id :: TEXT
    WHEN (node.type_uri_id_part = 'DeclaredBt')
      THEN
        'b' || node.instance_id :: TEXT
    ELSE
      'x' || node.instance_id :: TEXT
    END                       AS instance_path,
    ''                        AS parent_instance_path,
    FALSE                     AS parent_excluded,
    1                         AS depth
  FROM tree_link link
    JOIN tree_node node ON link.subnode_id = node.id
    JOIN tree_arrangement tree ON node.tree_arrangement_id = tree.id
    JOIN name n ON node.name_id = n.id
    JOIN name_rank rank ON n.name_rank_id = rank.id
    JOIN instance inst ON node.instance_id = inst.id
    JOIN reference ref ON inst.reference_id = ref.id
  WHERE link.supernode_id = root_node
        AND node.internal_type = 'T'
  UNION ALL
  SELECT
    treewalk.tree_id                           AS tree_id,
    node.id                                    AS node_id,
    (node.type_uri_id_part <>
     'ApcConcept') :: BOOLEAN                  AS excluded,
    (node.type_uri_id_part =
     'DeclaredBt') :: BOOLEAN                  AS declared_bt,
    node.instance_id                           AS instance_id,
    node.name_id                               AS name_id,
    n.simple_name :: TEXT                      AS simple_name,
    treewalk.name_path || '/' || COALESCE(n.name_element,
                                          '?') AS name_path,
    CASE
    WHEN (node.type_uri_id_part = 'ApcConcept')
      THEN
        treewalk.instance_path || '/' || node.instance_id :: TEXT
    WHEN (node.type_uri_id_part = 'DeclaredBt')
      THEN
        treewalk.instance_path || '/b' || node.instance_id :: TEXT
    ELSE
      treewalk.instance_path || '/x' || node.instance_id :: TEXT
    END                                        AS instance_path,
    treewalk.instance_path                     AS parent_instance_path,
    treewalk.excluded                          AS parent_excluded,
    treewalk.depth + 1                         AS depth
  FROM treewalk
    JOIN tree_link link ON link.supernode_id = treewalk.node_id
    JOIN tree_node node ON link.subnode_id = node.id
    JOIN name n ON node.name_id = n.id
    JOIN name_rank rank ON n.name_rank_id = rank.id
    JOIN instance inst ON node.instance_id = inst.id
    JOIN reference REF ON inst.reference_id = REF.id
  WHERE node.internal_type = 'T'
        AND node.tree_arrangement_id = treewalk.tree_id
)
SELECT
  tree_id,
  node_id,
  excluded,
  declared_bt,
  instance_id,
  name_id,
  simple_name,
  name_path,
  instance_path,
  parent_instance_path,
  parent_excluded,
  depth
FROM treewalk
$$;


--
-- Name: type_notes(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notes(instanceid bigint) RETURNS TABLE(note_key text, note text)
    LANGUAGE sql
    AS $$
select k.name, nt.value
from instance_note nt
       join instance_note_key k on nt.instance_note_key_id = k.id
where nt.instance_id = instanceid
  and k.name ilike '%type'
$$;


--
-- Name: type_notes_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notes_jsonb(instanceid bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select jsonb_agg(
         jsonb_build_object(
           'note_key', nt.note_key,
           'note_value', nt.note
             )
           )
from type_notes(instanceid) as nt
$$;


--
-- Name: type_notes_text(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notes_text(instanceid bigint) RETURNS text
    LANGUAGE sql
    AS $$
select string_agg('  ' || nt.note_key || ': ' || nt.note || E'
', E'
')
from type_notes(instanceid) as nt
$$;


--
-- Name: update_synonyms_and_cache(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_synonyms_and_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR NEW.instance_type_id <> OLD.instance_type_id THEN
        UPDATE instance
        SET cached_synonymy_html = coalesce(synonyms_as_html(instance.id), '<synonyms></synonyms>')
        WHERE instance.id=NEW.id;
        UPDATE instance
        SET cached_synonymy_html = coalesce(synonyms_as_html(instance.id), '<synonyms></synonyms>')
        WHERE instance.id IN (SELECT cited_by_id FROM instance WHERE instance.id=NEW.id);
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    tree_id bigint,
    reference_id bigint,
    name text NOT NULL,
    description_html text,
    is_current boolean DEFAULT false NOT NULL,
    is_available boolean DEFAULT false NOT NULL,
    is_name_index boolean DEFAULT false NOT NULL,
    has_default_reference boolean DEFAULT false NOT NULL,
    source_id bigint,
    source_system character varying(50),
    source_id_string character varying(100),
    namespace_id bigint,
    internal_notes text,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone,
    context_id integer DEFAULT 0 NOT NULL,
    context_sort_order integer DEFAULT 0 NOT NULL,
    manages_taxonomic_concept boolean DEFAULT false NOT NULL,
    manages_taxonomy boolean DEFAULT false NOT NULL,
    manages_profile boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE product; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.tree_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.reference_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.description_html; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.is_current; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.is_available; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.is_name_index; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.source_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.source_system; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.source_id_string; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.namespace_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.internal_notes; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: product_item_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_item_config (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    product_id bigint NOT NULL,
    profile_item_type_id bigint NOT NULL,
    display_html text,
    sort_order numeric(5,2),
    tool_tip text,
    is_deprecated boolean DEFAULT false NOT NULL,
    is_hidden boolean DEFAULT false NOT NULL,
    internal_notes text,
    external_context text,
    external_mapping text,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE product_item_config; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.product_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.profile_item_type_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.display_html; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.sort_order; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.tool_tip; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.is_deprecated; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.is_hidden; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.internal_notes; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.external_context; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.external_mapping; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN product_item_config.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: profile_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_item (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    instance_id bigint NOT NULL,
    tree_element_id bigint,
    product_item_config_id bigint NOT NULL,
    profile_object_rdf_id text NOT NULL,
    source_profile_item_id bigint,
    is_draft boolean DEFAULT true NOT NULL,
    published_date timestamp with time zone,
    end_date timestamp with time zone,
    statement_type text DEFAULT 'fact'::text NOT NULL,
    profile_text_id bigint,
    is_object_type_reference boolean DEFAULT false NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    namespace_id bigint,
    lock_version integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone,
    CONSTRAINT profile_item_check CHECK (((((instance_id IS NOT NULL))::integer + ((tree_element_id IS NOT NULL))::integer) >= 1)),
    CONSTRAINT profile_item_statement_type_check CHECK ((statement_type = ANY (ARRAY['fact'::text, 'link'::text, 'assertion'::text]))),
    CONSTRAINT validate_object_type CHECK (
CASE
    WHEN (profile_object_rdf_id = 'text'::text) THEN (profile_text_id IS NOT NULL)
    WHEN (profile_object_rdf_id = 'reference'::text) THEN is_object_type_reference
    ELSE NULL::boolean
END),
    CONSTRAINT validate_single_object_type CHECK (((((profile_text_id IS NOT NULL))::integer + (is_object_type_reference)::integer) = 1))
);


--
-- Name: TABLE profile_item; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.instance_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.product_item_config_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.profile_object_rdf_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.source_profile_item_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.is_draft; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.published_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.end_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.statement_type; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.profile_text_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.is_object_type_reference; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.source_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.source_id_string; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.source_system; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.namespace_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: profile_item_annotation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_item_annotation (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    profile_item_id bigint NOT NULL,
    value text NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system text,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_item_annotation; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.profile_item_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.value; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.source_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.source_id_string; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.source_system; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_annotation.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: profile_item_annotation_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.profile_item_annotation_v AS
 SELECT pia.id AS annotation_id,
    pia.profile_item_id,
    pia.value AS annotation_text,
    pia.created_at AS created,
    t.rdf_id AS tree_rdf_id
   FROM (public.profile_item_annotation pia
     JOIN (public.profile_item itm
     JOIN (public.product_item_config pic
     JOIN (public.product prd
     LEFT JOIN public.tree t ON ((t.id = prd.tree_id))) ON ((prd.id = pic.product_id))) ON (((itm.product_item_config_id = pic.id) AND (NOT pic.is_hidden)))) ON ((pia.profile_item_id = itm.id)));


--
-- Name: profile_item_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_item_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    profile_object_type_id bigint NOT NULL,
    name text NOT NULL,
    rdf_id text NOT NULL,
    description_html text,
    sort_order numeric(5,2) NOT NULL,
    is_deprecated boolean DEFAULT false,
    internal_notes text,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_item_type; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.profile_object_type_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.rdf_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.description_html; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.sort_order; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.is_deprecated; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.internal_notes; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_type.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: profile_object_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_object_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name text NOT NULL,
    rdf_id text NOT NULL,
    is_deprecated boolean DEFAULT false,
    internal_notes text,
    lock_version bigint DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_object_type; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.rdf_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.is_deprecated; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.internal_notes; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_object_type.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: profile_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_text (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    value text NOT NULL,
    value_md text,
    source_id bigint,
    source_system character varying(50),
    source_id_string character varying(100),
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_text; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.value; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.value_md; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.source_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.source_system; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.source_id_string; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_text.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: tree_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    draft_name text NOT NULL,
    log_entry text,
    previous_version_id bigint,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    published_by character varying(100),
    tree_id bigint NOT NULL
);


--
-- Name: profile_text_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.profile_text_v AS
 SELECT itm.instance_id AS taxon_name_usage_id,
    itm.tree_element_id,
    itm.id AS profile_item_id,
    pit.id AS profile_item_type_id,
    itm.profile_object_rdf_id,
    itm.profile_text_id,
    t.id AS tree_id,
    itm.created_at,
    itm.updated_at,
    pic.display_html AS heading,
    txt.value_md AS profile_text_md,
    txt.value AS profile_text,
    itm.source_id AS source_profile_item_id,
    tnu.id AS source_tnu_id,
    ref.id AS source_reference_id,
    COALESCE(ref.citation, (
        CASE
            WHEN (pit.rdf_id = 'assertion'::text) THEN concat_ws(' '::text, COALESCE(t.name, prd.name), to_char(tv.published_at, '(YYYY-MM-DD)'::text))
            ELSE NULL::text
        END)::character varying) AS attribution,
    pit.rdf_id AS item_type,
        CASE
            WHEN (pit.rdf_id = 'assertion'::text) THEN concat_ws(' '::text, COALESCE(t.name, prd.name), to_char(tv.published_at, '(YYYY-MM-DD)'::text))
            ELSE NULL::text
        END AS asserted_by,
    pot.rdf_id AS object_type,
    pit.rdf_id AS text_type,
    pic.sort_order AS text_order,
    t.rdf_id AS tree_rdf_id,
    true AS is_true
   FROM ((((public.profile_item itm
     JOIN public.profile_text txt ON ((itm.profile_text_id = txt.id)))
     JOIN ((public.product_item_config pic
     JOIN (public.profile_item_type pit
     JOIN public.profile_object_type pot ON ((pit.profile_object_type_id = pot.id))) ON ((pic.profile_item_type_id = pit.id)))
     JOIN (public.product prd
     LEFT JOIN public.tree t ON ((t.id = prd.tree_id))) ON ((prd.id = pic.product_id))) ON (((itm.product_item_config_id = pic.id) AND (NOT pic.is_hidden))))
     LEFT JOIN (public.tree_element te
     JOIN public.tree_version tv ON ((tv.id = te.first_tree_version_id))) ON ((te.id = itm.tree_element_id)))
     LEFT JOIN (public.profile_item src
     JOIN (public.instance tnu
     JOIN public.reference ref ON ((ref.id = tnu.reference_id))) ON ((tnu.id = src.instance_id))) ON ((src.id = itm.source_profile_item_id)));


--
-- Name: namespace; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: trees_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--



--
-- Name: taxon_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: apii_image; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apii_image (
    basisofrecord text,
    scientificname text,
    catalognumber text,
    creator text,
    createdate text,
    title text,
    description text,
    caption text,
    occurrenceremarks text,
    subjectpart text,
    identifier text,
    metadatadate date,
    providerliteral text,
    rights text,
    rightsowner text,
    credit text,
    accessuri text,
    phformat text,
    variantliteral text,
    variant text,
    updatedate date,
    photono integer,
    photoclass text,
    photoid integer,
    copyright_status text
);


--
-- Name: author_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.author_v AS
 SELECT auth_v.author_id,
    auth_v.identifier,
    auth_v.standard_form,
    auth_v.see_also,
    auth_v.author_name,
    auth_v.author_full_name,
    auth_v.dataset_name
   FROM ( SELECT a.id AS author_id,
            (((((host.value)::text || 'author/'::text) || (p.rdf_id)::text) || '/'::text) || a.id) AS identifier,
            a.abbrev AS standard_form,
            a.ipni_id AS see_also,
            a.name AS author_name,
            a.full_name AS author_full_name,
            dataset.value AS dataset_name
           FROM (((public.author a
             JOIN public.namespace p ON ((a.namespace_id = p.id)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))
          WHERE (a.duplicate_of_id IS NULL)) auth_v;


--
-- Name: nsl_tree_mv; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: cited_usage_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: name_status_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_status_v AS
 SELECT name_status.id AS name_status_id,
    name_status.deprecated,
    name_status.name AS name_status_label,
    name_status.display AS display_as,
    name_status.name_group_id,
    name_status.nom_illeg AS is_nom_illeg,
    name_status.nom_inval AS is_nom_inval,
    name_status.description_html,
    name_status.rdf_id AS name_status_rdf_id
   FROM public.name_status;


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    iso6391code character varying(2),
    iso6393code character varying(3) NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: ref_author_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_author_role (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: ref_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    parent_id bigint,
    parent_optional boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_parent_details boolean DEFAULT false NOT NULL
);


--
-- Name: reference_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reference_v AS
 SELECT ref_v.reference_id,
    ref_v.reference_type,
    ref_v.is_published,
    ref_v.identifier,
    ref_v.title,
    ref_v.author_id,
    ref_v.author_name,
    ref_v.author_role,
    ref_v.citation,
    ref_v.volume,
    ref_v.year,
    ref_v.edition,
    ref_v.pages,
    ref_v.publication_date,
    ref_v.iso_publication_date,
    ref_v.publisher,
    ref_v.published_location,
    ref_v.uri,
    ref_v.short_title,
    ref_v.display_title,
    ref_v.reference_notes,
    ref_v.doi,
    ref_v.isbn,
    ref_v.issn,
    ref_v.parent_id,
    ref_v.ref_author_role_id,
    ref_v.ref_type_id,
    ref_v.language,
    ref_v.tl2,
    ref_v.verbatim_author,
    ref_v.dataset_name,
    ref_v.is_true
   FROM ( SELECT r.id AS reference_id,
            rt.rdf_id AS reference_type,
            r.published AS is_published,
            (((((host.value)::text || 'reference/'::text) || (ns.rdf_id)::text) || '/'::text) || r.id) AS identifier,
            r.title,
            r.author_id,
            a.name AS author_name,
            rar.rdf_id AS author_role,
            r.citation,
            r.volume,
            r.year,
            r.edition,
            r.pages,
            r.publication_date,
            r.iso_publication_date,
            r.publisher,
            r.published_location,
            r.uri,
            r.abbrev_title AS short_title,
            r.display_title,
            r.notes AS reference_notes,
            r.doi,
            r.isbn,
            r.issn,
            r.parent_id,
            r.ref_author_role_id,
            r.ref_type_id,
            l.iso6391code AS language,
            r.tl2,
            r.verbatim_author,
            dataset.value AS dataset_name,
            true AS is_true
           FROM (((((((public.reference r
             JOIN public.author a ON ((r.author_id = a.id)))
             JOIN public.ref_type rt ON ((r.ref_type_id = rt.id)))
             JOIN public.ref_author_role rar ON ((r.ref_author_role_id = rar.id)))
             JOIN public.namespace ns ON ((r.namespace_id = ns.id)))
             JOIN public.language l ON ((r.language_id = l.id)))
             JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
          WHERE (r.duplicate_of_id IS NULL)) ref_v;


--
-- Name: primary_instance_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.primary_instance_mv AS
 SELECT primary_instance_v.name_id,
    primary_instance_v.name_status_rdf_id,
    primary_instance_v.autonym_of_id,
    primary_instance_v.is_changed_combination,
    primary_instance_v.basionym_id,
    primary_instance_v.primary_name_id,
    primary_instance_v.primary_id,
    primary_instance_v.combination_id,
    primary_instance_v.primary_date,
    primary_instance_v.combination_date,
    primary_instance_v.publication_usage_type,
    primary_instance_v.publication_date,
    primary_instance_v.publication_citation,
    primary_instance_v.dataset_name
   FROM public.primary_instance_v
  WITH NO DATA;


--
-- Name: taxon_name_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: taxon_name_usage_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: taxonomic_status_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: tree_closure_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: tree_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tree_v AS
 SELECT t.id AS tree_id,
    t.name AS tree_name,
    t.reference_id AS tree_reference_id,
    ((mapper_host.value)::text || t.id) AS identifier,
    t.description_html AS tree_description_html,
    t.link_to_home_page AS tree_home_page,
    t.current_tree_version_id,
    t.default_draft_tree_version_id,
    dataset.value AS dataset_name,
    code.value AS code
   FROM (((public.tree t
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
     LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)));


--
-- Name: usage_type_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.usage_type_v AS
 SELECT t.id AS usage_type_id,
    t.rdf_id AS usage_type_rdf_id,
    (((mapper_host.value)::text || '/voc'::text) || (t.rdf_id)::text) AS identifier,
    t.name AS usage_type_label,
    t.description_html,
    t.rdf_id,
    t.has_label AS usage_type_has_label,
    t.of_label AS usage_type_of_label,
    t.sort_order,
    t.doubtful AS is_doubtful,
    t.misapplied AS is_misapplied,
    t.nomenclatural AS is_homotypic,
    t.primary_instance AS is_primary_instance,
    t.pro_parte AS is_pro_parte,
    t.protologue AS is_protologue,
    t.relationship AS is_relationship,
    t.secondary_instance AS is_secondary,
    t.standalone AS is_treatment,
    t.synonym AS is_synonym,
    t.taxonomic AS is_heterotypic,
    t.unsourced AS is_unsourced,
    t.bidirectional AS is_bidirectional,
        CASE
            WHEN ((t.rdf_id)::text ~ '(common|vernacular)'::text) THEN true
            ELSE false
        END AS is_vernacular,
        CASE
            WHEN ((t.rdf_id)::text = 'isonym'::text) THEN true
            ELSE false
        END AS is_isonym,
        CASE
            WHEN ((t.rdf_id)::text ~ '(excluded|intercepted|vagrant)'::text) THEN true
            ELSE false
        END AS is_excluded,
        CASE
            WHEN ((t.rdf_id)::text ~ '(taxonomy|synonymy)'::text) THEN true
            ELSE false
        END AS is_vide,
        CASE
            WHEN ((t.rdf_id)::text ~ '(miscellaneous)'::text) THEN true
            ELSE false
        END AS is_miscellaneous,
    (((((((((((
        CASE
            WHEN ((t.rdf_id)::text ~ '(excluded|intercepted|vagrant)'::text) THEN '1'::text
            ELSE '0'::text
        END ||
        CASE
            WHEN ((t.rdf_id)::text ~ '(common|vernacular)'::text) THEN '1'::text
            ELSE '0'::text
        END) ||
        CASE
            WHEN ((t.rdf_id)::text ~ '(taxonomy|synonymy)'::text) THEN '1'::text
            ELSE '0'::text
        END) ||
        CASE
            WHEN ((t.rdf_id)::text ~ '(miscellaneous)'::text) THEN '1'::text
            ELSE '0'::text
        END) || ((t.protologue)::integer)::text) || ((t.misapplied)::integer)::text) || ((t.taxonomic)::integer)::text) || ((t.nomenclatural)::integer)::text) || ((t.protologue)::integer)::text) || ((t.primary_instance)::integer)::text) || lpad((t.sort_order)::text, 4, '0'::text)) || ((t.standalone)::integer)::text) AS usage_type_order
   FROM (public.instance_type t
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)));


--
-- Name: batch_review; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.batch_review (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    loader_batch_id bigint NOT NULL,
    name character varying(200) NOT NULL,
    allow_voting boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: batch_review_period; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.batch_review_period (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    batch_review_id bigint NOT NULL,
    name character varying(200) NOT NULL,
    start_date date NOT NULL,
    end_date date,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: batch_review_role; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.batch_review_role (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(30) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: batch_reviewer; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.batch_reviewer (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    user_id bigint NOT NULL,
    org_id bigint,
    batch_review_role_id bigint NOT NULL,
    batch_review_id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: bulk_processing_log; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.bulk_processing_log (
    id integer NOT NULL,
    log_entry text DEFAULT 'Wat?'::text NOT NULL,
    logged_at timestamp with time zone DEFAULT now() NOT NULL,
    logged_by character varying(255) NOT NULL
);


--
-- Name: bulk_processing_log_id_seq; Type: SEQUENCE; Schema: loader; Owner: -
--

CREATE SEQUENCE loader.bulk_processing_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bulk_processing_log_id_seq; Type: SEQUENCE OWNED BY; Schema: loader; Owner: -
--

ALTER SEQUENCE loader.bulk_processing_log_id_seq OWNED BY loader.bulk_processing_log.id;


--
-- Name: loader_batch; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.loader_batch (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    default_reference_id bigint,
    use_sort_key_for_ordering boolean DEFAULT true NOT NULL
);


--
-- Name: loader_batch_job_lock; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.loader_batch_job_lock (
    id boolean DEFAULT true NOT NULL,
    job_name text,
    CONSTRAINT job_lock_unique CHECK (id)
);


--
-- Name: loader_name; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.loader_name (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    loader_batch_id bigint NOT NULL,
    raw_id integer,
    parent_raw_id integer,
    parent_id bigint,
    record_type text NOT NULL,
    hybrid text,
    family text NOT NULL,
    higher_rank_comment text,
    subfamily text,
    tribe text,
    subtribe text,
    rank text NOT NULL,
    rank_nsl text,
    scientific_name text DEFAULT 'not-supplied-on-load'::text NOT NULL,
    ex_base_author text,
    base_author text,
    ex_author text,
    author text,
    author_rank text,
    name_status text,
    name_comment text,
    partly text,
    auct_non text,
    unplaced text,
    synonym_type text,
    doubtful boolean DEFAULT false NOT NULL,
    hybrid_flag text,
    isonym text,
    publ_count bigint,
    article_author text,
    article_title text,
    article_title_full text,
    in_flag text,
    second_author text,
    title text,
    title_full text,
    edition text,
    volume text,
    page text,
    year text,
    date_ text,
    publ_partly text,
    publ_note text,
    notes text,
    footnote text,
    distribution text,
    comment text,
    remark_to_reviewers text,
    original_text text,
    seq bigint DEFAULT 0 NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(255) DEFAULT 'batch'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(255) DEFAULT 'batch'::character varying NOT NULL,
    no_further_processing boolean DEFAULT false NOT NULL,
    excluded boolean DEFAULT false NOT NULL,
    simple_name text DEFAULT 'not-supplied-on-load'::text NOT NULL,
    full_name text DEFAULT 'not-supplied-on-load'::text NOT NULL,
    simple_name_as_loaded text NOT NULL,
    created_manually boolean DEFAULT false NOT NULL,
    sort_key text,
    loaded_from_instance_id bigint,
    formatted_text_above text,
    formatted_text_below text
);


--
-- Name: loader_name_match; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.loader_name_match (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    loader_name_id bigint NOT NULL,
    name_id bigint NOT NULL,
    instance_id bigint NOT NULL,
    standalone_instance_created boolean DEFAULT false NOT NULL,
    standalone_instance_found boolean DEFAULT false NOT NULL,
    standalone_instance_id bigint,
    relationship_instance_type_id bigint,
    relationship_instance_created boolean DEFAULT false NOT NULL,
    relationship_instance_found boolean DEFAULT false NOT NULL,
    relationship_instance_id bigint,
    drafted boolean DEFAULT false NOT NULL,
    manually_drafted boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    use_batch_default_reference boolean DEFAULT false NOT NULL,
    copy_append_from_existing_use_batch_def_ref boolean DEFAULT false NOT NULL,
    instance_choice_confirmed boolean DEFAULT false NOT NULL,
    use_existing_instance boolean DEFAULT false NOT NULL,
    source_for_copy_instance_id bigint,
    intended_tree_parent_name_id bigint,
    CONSTRAINT relationship_created_or_found CHECK ((((relationship_instance_id IS NULL) AND (relationship_instance_created = false) AND (relationship_instance_found = false)) OR ((relationship_instance_id IS NOT NULL) AND (relationship_instance_created = true) AND (relationship_instance_found = false)) OR ((relationship_instance_id IS NOT NULL) AND (relationship_instance_created = false) AND (relationship_instance_found = true)))),
    CONSTRAINT standalone_created_or_found CHECK ((((standalone_instance_id IS NULL) AND (standalone_instance_created = false) AND (standalone_instance_found = false)) OR ((standalone_instance_id IS NOT NULL) AND (standalone_instance_created = true) AND (standalone_instance_found = false)) OR ((standalone_instance_id IS NOT NULL) AND (standalone_instance_created = false) AND (standalone_instance_found = true)))),
    CONSTRAINT valid_instance_choice CHECK (((instance_choice_confirmed AND use_batch_default_reference AND (NOT copy_append_from_existing_use_batch_def_ref) AND (NOT use_existing_instance)) OR (instance_choice_confirmed AND (NOT use_batch_default_reference) AND copy_append_from_existing_use_batch_def_ref AND (NOT use_existing_instance)) OR (instance_choice_confirmed AND (NOT use_batch_default_reference) AND (NOT copy_append_from_existing_use_batch_def_ref) AND use_existing_instance) OR ((NOT instance_choice_confirmed) AND (NOT use_batch_default_reference) AND (NOT copy_append_from_existing_use_batch_def_ref) AND (NOT use_existing_instance)))),
    CONSTRAINT valid_use_existing_instance CHECK (((use_existing_instance AND standalone_instance_found AND (standalone_instance_id IS NOT NULL)) OR (use_existing_instance AND relationship_instance_found AND (relationship_instance_id IS NOT NULL)) OR ((NOT use_existing_instance) AND (NOT standalone_instance_found) AND (standalone_instance_id IS NULL)) OR ((NOT use_existing_instance) AND (NOT relationship_instance_found) AND (relationship_instance_id IS NULL))))
);


--
-- Name: name_review_comment; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.name_review_comment (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    batch_review_period_id bigint NOT NULL,
    batch_reviewer_id bigint NOT NULL,
    loader_name_id bigint NOT NULL,
    name_review_comment_type_id bigint NOT NULL,
    comment text NOT NULL,
    in_progress boolean DEFAULT false NOT NULL,
    resolved boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    context character varying(30) DEFAULT 'unknown'::character varying NOT NULL
);


--
-- Name: name_review_comment_type; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.name_review_comment_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(50) DEFAULT 'unknown'::character varying NOT NULL,
    for_reviewer boolean DEFAULT true NOT NULL,
    for_compiler boolean DEFAULT true NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: name_review_vote; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.name_review_vote (
    loader_name_id bigint NOT NULL,
    batch_review_id bigint NOT NULL,
    org_id bigint NOT NULL,
    vote boolean DEFAULT true NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: org; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(100) NOT NULL,
    abbrev character varying(30) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    can_vote boolean DEFAULT false NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    user_name character varying(30) NOT NULL,
    given_name character varying(60),
    family_name character varying(60) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    internal_note text,
    default_product_context_id bigint,
    CONSTRAINT users_user_name_lowercase_ck CHECK (((user_name)::text = lower((user_name)::text)))
);


--
-- Name: batch_stack_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.batch_stack_v AS
 SELECT subq.display_as,
    subq.id,
    subq.name,
    subq.batch_name,
    subq.batch_id,
    subq.description,
    subq.created_at,
    subq.start,
    subq.order_by
   FROM ( SELECT 'Loader Batch in stack'::text AS display_as,
            loader_batch.id,
            loader_batch.name,
            loader_batch.name AS batch_name,
            loader_batch.id AS batch_id,
            loader_batch.description,
            loader_batch.created_at,
            loader_batch.created_at AS start,
            (((loader_batch.name)::text || ' A batch '::text) || (loader_batch.name)::text) AS order_by
           FROM loader.loader_batch
        UNION
         SELECT 'Batch Review in stack'::text AS display_as,
            br.id,
            br.name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            br.created_at,
            br.created_at,
            (((lb.name)::text || (('A batch '::text || (lb.name)::text) || ' B review '::text)) || (br.name)::text) AS order_by
           FROM (loader.batch_review br
             JOIN loader.loader_batch lb ON ((br.loader_batch_id = lb.id)))
        UNION
         SELECT 'Review Period in stack'::text AS display_as,
            brp.id,
            ((((((brp.name)::text || ' ('::text) || to_char((brp.start_date)::timestamp with time zone, 'DD-Mon-YYYY'::text)) ||
                CASE (brp.end_date IS NULL)
                    WHEN true THEN ' - '::text
                    ELSE ' end: '::text
                END) || COALESCE(to_char((brp.end_date)::timestamp with time zone, 'DD-Mon-YYYY'::text), ''::text)) || ')'::text) AS name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            brp.created_at,
            brp.start_date,
            (((lb.name)::text || (((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' C period '::text)) || brp.start_date) AS order_by
           FROM ((loader.batch_review_period brp
             JOIN loader.batch_review br ON ((brp.batch_review_id = br.id)))
             JOIN loader.loader_batch lb ON ((br.loader_batch_id = lb.id)))
        UNION
         SELECT 'Batch Reviewer in stack'::text AS display_as,
            brer.id,
            (((((((users.given_name)::text || ' '::text) || (users.family_name)::text) || ' for '::text) || COALESCE((org.abbrev)::text, 'no org'::text)) || ' as '::text) || (brrole.name)::text) AS name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            brer.created_at,
            brer.created_at,
            ((((lb.name)::text || (((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' D reviewer '::text)) || (users.given_name)::text) || (users.family_name)::text) AS order_by
           FROM (((((loader.batch_reviewer brer
             JOIN loader.batch_review br ON ((br.id = brer.batch_review_id)))
             JOIN public.users ON ((brer.user_id = users.id)))
             JOIN loader.loader_batch lb ON ((br.loader_batch_id = lb.id)))
             LEFT JOIN public.org ON ((brer.org_id = org.id)))
             JOIN loader.batch_review_role brrole ON ((brer.batch_review_role_id = brrole.id)))) subq
  ORDER BY subq.order_by;


--
-- Name: bdr_prefix_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_prefix_v AS
 SELECT d.value AS tree_description,
    l.value AS tree_label,
    t.value AS tree_context,
    n.value AS name_context
   FROM ((((public.shard_config c
     JOIN jsonb_each_text('{"AFD": "afd", "APNI": "apc", "Algae": "aal", "Fungi": "afl", "Lichen": "alc", "AusMoss": "cab"}'::jsonb) t(key, value) ON ((t.key = (c.value)::text)))
     JOIN jsonb_each_text('{"AFD": "afdni", "APNI": "apni", "Algae": "aani", "Fungi": "afni", "Lichen": "alni", "AusMoss": "abni"}'::jsonb) n(key, value) ON ((n.key = (c.value)::text)))
     LEFT JOIN (public.shard_config x
     LEFT JOIN public.shard_config d ON (((d.name)::text = ((x.value)::text || ' description'::text)))) ON (((x.name)::text = 'classification tree key'::text)))
     LEFT JOIN public.shard_config l ON (((l.name)::text = 'tree label text'::text)))
  WHERE ((c.name)::text = 'name space'::text);


--
-- Name: bdr_alt_labels_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: bdr_concept_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: bdr_context_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_context_v AS
 SELECT 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'::text AS rdf,
    'http://prefix.cc/'::text AS prefix,
    'http://www.w3.org/2011/http#'::text AS http,
    'http://purl.org/dc/elements/1.1/'::text AS dc,
    'http://purl.org/dc/terms/'::text AS dct,
    'http://vocab.getty.edu/ontology#'::text AS gvp,
    'http://www.w3.org/2004/02/skos/core#'::text AS skos,
    'http://www.w3.org/2008/05/skos-xl#'::text AS skosxl,
    'http://www.w3.org/2001/XMLSchema#'::text AS xsd,
    'http://rs.tdwg.org/ontology/voc/TaxonName#'::text AS tn,
    'http://www.w3.org/2000/01/rdf-schema#'::text AS rdfs,
    'http://rs.tdwg.org/dwc/terms/'::text AS dwc,
    'http://www.w3.org/ns/prov#'::text AS prov,
    'https://schema.org/'::text AS sdo,
    'https://purl.org/pav/'::text AS pav,
    'http://purl.org/dc/terms/'::text AS dcterms,
    'http://www.w3.org/2002/07/owl#'::text AS owl,
    'https://linked.data.gov.au/def/nslvoc/'::text AS boa,
    'https://id.biodiversity.org.au/tree/'::text AS aunsl,
    'https://id.biodiversity.org.au/tree/apc/'::text AS apc,
    'https://id.biodiversity.org.au/tree/afd/'::text AS afd,
    'https://id.biodiversity.org.au/tree/cab/'::text AS cab,
    'https://id.biodiversity.org.au/tree/aal/'::text AS aal,
    'https://id.biodiversity.org.au/tree/afl/'::text AS afl,
    'https://id.biodiversity.org.au/tree/all/'::text AS "all",
    'https://id.biodiversity.org.au/name/apni/'::text AS apni,
    'https://id.biodiversity.org.au/name/afd/'::text AS afdni,
    'https://id.biodiversity.org.au/name/lichen/'::text AS alni,
    'https://id.biodiversity.org.au/name/ausmoss/'::text AS abni,
    'https://id.biodiversity.org.au/name/algae/'::text AS aani,
    'https://id.biodiversity.org.au/name/fungi/'::text AS afni,
    tv.id AS tree_version_id
   FROM (public.tree t
     JOIN public.tree_version tv ON ((tv.id = t.current_tree_version_id)))
  WHERE t.accepted_tree;


--
-- Name: bdr_graph_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_graph_v AS
 SELECT tv.id AS tree_version_id
   FROM (public.tree t
     JOIN public.tree_version tv ON ((tv.id = t.current_tree_version_id)))
  WHERE t.accepted_tree;


--
-- Name: bdr_labels_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_labels_v AS
 SELECT x.value AS _id,
    jsonb_build_object('@id', x.key) AS "rdfs__subPropertyOf",
    tv.id AS tree_version_id
   FROM ((public.tree t
     JOIN public.tree_version tv ON ((tv.id = t.current_tree_version_id)))
     JOIN json_each('{"skosxl:altLabel":"boa:hasVernacularLabel",
      "skosxl:altLabel":"boa:hasHeterotypicLabel",
      "skosxl:altLabel":"boa:hasHomotypicLabel",
      "skosxl:hiddenLabel":"boa:hasMisappliedLabel",
      "skosxl:hiddenLabel":"boa:hasOrthographicLabel",
      "skosxl:hiddenLabel":"boa:hasExcludedLabel",
      "skosxl:altLabel":"boa:hasSynonymicLabel",
      "skosxl:prefLabel":"boa:acceptedLabel",
      "skosxl:prefLabel":"boa:unplacedLabel",
      "skos:altLabel":"boa:canonicalLabel"
    }'::json) x(key, value) ON (true))
  WHERE t.accepted_tree;


--
-- Name: bdr_schema_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_schema_v AS
 SELECT ((c.tree_context || ':'::text) || t.current_tree_version_id) AS _id,
    'skos:ConceptScheme'::text AS _type,
    jsonb_build_object('@type', 'xsd:date', '@value', tv.created_at) AS dct__created,
    json_build_object('@id', 'https://linked.data.gov.au/org/nsl') AS dct__creator,
    jsonb_build_object('@type', 'xsd:date', '@value', tv.published_at) AS dct__modified,
    json_build_object('@id', 'https://linked.data.gov.au/org/nsl') AS dct__publisher,
    jsonb_build_object('@language', 'en', '@value', c.tree_description) AS skos__definition,
    jsonb_build_object('@id', ((c.name_context || ':'::text) || te.name_id)) AS "skos__hasTopConcept",
    jsonb_build_object('@language', 'en', '@value', c.tree_label) AS "skos__prefLabel",
    jsonb_build_object('@id', ('aunsl:'::text || c.tree_context)) AS "dcterms__isVersionOf",
    jsonb_build_object('@id', ((c.tree_context || ':'::text) || t.current_tree_version_id)) AS "owl__versionIRI",
        CASE
            WHEN (tv.previous_version_id IS NOT NULL) THEN jsonb_build_object('@id', ((c.tree_context || ':'::text) || tv.previous_version_id))
            ELSE NULL::jsonb
        END AS "pav__previousVersion",
    te.id AS top_concept_id,
    tv.id AS tree_version_id
   FROM ((public.tree t
     JOIN (public.tree_version tv
     JOIN (public.tree_version_element tve
     JOIN public.tree_element te ON ((te.id = tve.tree_element_id))) ON (((tve.tree_version_id = tv.id) AND (tve.parent_id IS NULL)))) ON ((t.current_tree_version_id = tv.id)))
     LEFT JOIN public.bdr_prefix_v c ON (true))
  WHERE t.accepted_tree;


--
-- Name: bdr_sdo_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_sdo_v AS
 SELECT 'https://linked.data.gov.au/org/nsl'::text AS _id,
    'sdo:Organization'::text AS _type,
    'Australian National Species List'::text AS sdo__name,
    jsonb_build_object('@id', 'https://linked.data.gov.au/org/abrs') AS "sdo__parentOrganization",
    jsonb_build_object('@type', 'xsd:anyURI', '@value', 'https://biodiversity.org.au/nsl') AS sdo__url,
    tv.id AS tree_version_id
   FROM (public.tree t
     JOIN public.tree_version tv ON ((tv.id = t.current_tree_version_id)))
  WHERE t.accepted_tree;


--
-- Name: bdr_top_concept_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: bdr_tree_schema_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_tree_schema_v AS
 SELECT ('aunsl:'::text || c.tree_context) AS _id,
    'skos:ConceptScheme'::text AS _type,
    jsonb_build_object('@language', 'en', '@value', c.tree_label) AS "skos__prefLabel",
    jsonb_build_object('@language', 'en', '@value', c.tree_description) AS skos__definition,
    json_build_object('@id', ((c.tree_context || ':'::text) || t.current_tree_version_id)) AS "pav__hasCurrentVersion",
    ( SELECT x.v
           FROM ( SELECT jsonb_agg(jsonb_build_object('_id', ((c.tree_context || ':'::text) || p.id))) AS v
                   FROM ( SELECT tv_1.id
                           FROM public.tree_version tv_1
                          WHERE ((tv_1.tree_id = t.id) AND tv_1.published)
                          ORDER BY tv_1.published_at DESC
                         LIMIT 5) p) x) AS "pav__hasVersion",
    tv.id AS tree_version_id
   FROM ((public.tree t
     JOIN public.tree_version tv ON ((t.current_tree_version_id = tv.id)))
     LEFT JOIN public.bdr_prefix_v c ON (true))
  WHERE t.accepted_tree;


--
-- Name: bdr_unplaced_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: column_view_dependencies_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.column_view_dependencies_v AS
 SELECT tbl.relname AS table_name,
    att.attname AS column_name,
    obj.relname AS dependent_object,
    nsp.nspname AS object_schema,
    obj.relkind AS object_kind
   FROM ((((((pg_depend d
     LEFT JOIN pg_rewrite rw ON ((d.objid = rw.oid)))
     LEFT JOIN pg_proc f ON ((d.objid = f.oid)))
     LEFT JOIN pg_class obj ON ((COALESCE(rw.ev_class, f.oid) = obj.oid)))
     LEFT JOIN pg_namespace nsp ON ((COALESCE(obj.relnamespace, f.pronamespace) = nsp.oid)))
     JOIN pg_attribute att ON (((d.refobjid = att.attrelid) AND (d.refobjsubid = att.attnum))))
     JOIN pg_class tbl ON ((att.attrelid = tbl.oid)))
  WHERE ((tbl.relkind = 'r'::"char") AND ((obj.relkind = ANY (ARRAY['v'::"char", 'm'::"char"])) OR (f.oid IS NOT NULL)))
  ORDER BY tbl.relname, att.attname, obj.relname;


--
-- Name: view_depends_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_depends_v AS
 WITH views AS (
         SELECT v.relkind,
            v.relname AS view,
            d.refobjid AS ref_object,
            v.oid AS view_oid,
            ns.nspname AS namespace
           FROM (((pg_depend d
             JOIN pg_rewrite r ON ((r.oid = d.objid)))
             JOIN pg_class v ON ((v.oid = r.ev_class)))
             JOIN pg_namespace ns ON ((ns.oid = v.relnamespace)))
          WHERE ((v.relkind = ANY (ARRAY['v'::"char", 'm'::"char"])) AND (ns.nspname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name, 'gp_toolkit'::name])) AND (d.deptype = 'n'::"char") AND (NOT (v.oid = d.refobjid)))
        )
 SELECT DISTINCT class.relkind AS ref_view_kind,
    (views.ref_object)::regclass AS ref_view,
    views.relkind AS dep_view_kind,
    views.view AS dep_view_name,
    views.namespace AS dep_view_schema,
    ref_nspace.nspname AS ref_view_schema
   FROM (((views
     JOIN pg_depend dep ON ((dep.refobjid = views.view_oid)))
     JOIN pg_class class ON ((views.ref_object = class.oid)))
     JOIN pg_namespace ref_nspace ON ((class.relnamespace = ref_nspace.oid)))
  WHERE ((class.relkind = ANY (ARRAY['v'::"char", 'm'::"char"])) AND (dep.deptype = 'n'::"char"))
  ORDER BY (views.ref_object)::regclass, views.relkind;


--
-- Name: column_dependent_objects_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.column_dependent_objects_v AS
 SELECT b.table_name,
    b.column_name,
    b.object_kind AS direct_dependency_kind,
    b.dependent_object AS direct_dependency_object,
    b.object_schema AS direct_dependency_schema,
    d.dep_view_name AS downstream_view,
    d.dep_view_schema
   FROM (public.column_view_dependencies_v b
     LEFT JOIN public.view_depends_v d ON ((((d.ref_view)::text = b.dependent_object) AND (d.ref_view_schema = b.object_schema))));


--
-- Name: comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: common_name_export; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.common_name_export AS
 SELECT ((mapper_host.value)::text || cn.uri) AS common_name_id,
    cn.full_name AS common_name,
    ((mapper_host.value)::text || i.uri) AS instance_id,
    r.citation,
    ((mapper_host.value)::text || n.uri) AS scientific_name_id,
    n.full_name AS scientific_name,
    dataset.value AS "datasetName",
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
    ((mapper_host.value)::text || n.uri) AS "ccAttributionIRI"
   FROM (((((public.instance i
     JOIN public.instance_type it ON ((i.instance_type_id = it.id)))
     JOIN public.name cn ON ((i.name_id = cn.id)))
     JOIN public.reference r ON ((i.reference_id = r.id)))
     JOIN public.instance cbi ON ((i.cited_by_id = cbi.id)))
     JOIN public.name n ON ((cbi.name_id = n.id))),
    public.shard_config mapper_host,
    public.shard_config dataset
  WHERE (((it.name)::text = 'common name'::text) AND ((mapper_host.name)::text = 'mapper host'::text) AND ((dataset.name)::text = 'name label'::text));


--
-- Name: tree_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tree_vw AS
 SELECT t.id AS tree_id,
    t.accepted_tree,
    t.config,
    t.current_tree_version_id,
    t.default_draft_tree_version_id,
    t.description_html,
    t.group_name,
    t.host_name,
    t.link_to_home_page,
    t.name,
    t.reference_id,
    tv.id AS tree_version_id,
    tv.draft_name,
    tv.log_entry,
    tv.previous_version_id,
    tv.published,
    tv.published_at,
    tv.published_by,
    tve.element_link,
    tve.depth,
    tve.name_path,
    tve.parent_id,
    tve.taxon_id,
    tve.taxon_link,
    tve.tree_element_id AS tree_element_id_fk,
    tve.tree_path,
    tve.tree_version_id AS tree_version_id_fk,
    tve.merge_conflict,
    te.id AS tree_element_id,
    te.display_html,
    te.excluded,
    te.instance_id,
    te.instance_link,
    te.name_element,
    te.name_id,
    te.name_link,
    te.previous_element_id,
    te.profile,
    te.rank,
    te.simple_name,
    te.source_element_link,
    te.source_shard,
    te.synonyms,
    te.synonyms_html
   FROM (((public.tree t
     JOIN public.tree_version tv ON ((t.id = tv.tree_id)))
     JOIN public.tree_version_element tve ON ((tv.id = tve.tree_version_id)))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)));


--
-- Name: current_accepted_tree_version_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.current_accepted_tree_version_vw AS
 SELECT tree_vw.tree_id,
    tree_vw.accepted_tree,
    tree_vw.config,
    tree_vw.current_tree_version_id,
    tree_vw.default_draft_tree_version_id,
    tree_vw.description_html,
    tree_vw.group_name,
    tree_vw.host_name,
    tree_vw.link_to_home_page,
    tree_vw.name,
    tree_vw.reference_id,
    tree_vw.tree_version_id,
    tree_vw.draft_name,
    tree_vw.log_entry,
    tree_vw.previous_version_id,
    tree_vw.published,
    tree_vw.published_at,
    tree_vw.published_by,
    tree_vw.element_link,
    tree_vw.depth,
    tree_vw.name_path,
    tree_vw.parent_id,
    tree_vw.taxon_id,
    tree_vw.taxon_link,
    tree_vw.tree_element_id_fk,
    tree_vw.tree_path,
    tree_vw.tree_version_id_fk,
    tree_vw.merge_conflict,
    tree_vw.tree_element_id,
    tree_vw.display_html,
    tree_vw.excluded,
    tree_vw.instance_id,
    tree_vw.instance_link,
    tree_vw.name_element,
    tree_vw.name_id,
    tree_vw.name_link,
    tree_vw.previous_element_id,
    tree_vw.profile,
    tree_vw.rank,
    tree_vw.simple_name,
    tree_vw.source_element_link,
    tree_vw.source_shard,
    tree_vw.synonyms,
    tree_vw.synonyms_html
   FROM public.tree_vw
  WHERE ((tree_vw.tree_version_id = tree_vw.current_tree_version_id) AND tree_vw.accepted_tree);


--
-- Name: current_scheme_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: current_tree_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.current_tree_vw AS
 SELECT tree_vw.tree_id,
    tree_vw.accepted_tree,
    tree_vw.config,
    tree_vw.current_tree_version_id,
    tree_vw.default_draft_tree_version_id,
    tree_vw.description_html,
    tree_vw.group_name,
    tree_vw.host_name,
    tree_vw.link_to_home_page,
    tree_vw.name,
    tree_vw.reference_id,
    tree_vw.tree_version_id,
    tree_vw.draft_name,
    tree_vw.log_entry,
    tree_vw.previous_version_id,
    tree_vw.published,
    tree_vw.published_at,
    tree_vw.published_by,
    tree_vw.element_link,
    tree_vw.depth,
    tree_vw.name_path,
    tree_vw.parent_id,
    tree_vw.taxon_id,
    tree_vw.taxon_link,
    tree_vw.tree_element_id_fk,
    tree_vw.tree_path,
    tree_vw.tree_version_id_fk,
    tree_vw.merge_conflict,
    tree_vw.tree_element_id,
    tree_vw.display_html,
    tree_vw.excluded,
    tree_vw.instance_id,
    tree_vw.instance_link,
    tree_vw.name_element,
    tree_vw.name_id,
    tree_vw.name_link,
    tree_vw.previous_element_id,
    tree_vw.profile,
    tree_vw.rank,
    tree_vw.simple_name,
    tree_vw.source_element_link,
    tree_vw.source_shard,
    tree_vw.synonyms,
    tree_vw.synonyms_html
   FROM public.tree_vw
  WHERE ((tree_vw.current_tree_version_id = tree_vw.tree_version_id) AND tree_vw.accepted_tree);


--
-- Name: current_tve; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.current_tve (
    element_link text,
    depth integer,
    name_path text,
    parent_id text,
    taxon_id bigint,
    taxon_link text,
    tree_element_id bigint,
    tree_path text,
    tree_version_id bigint,
    updated_at timestamp with time zone,
    updated_by character varying(255),
    merge_conflict boolean
);


--
-- Name: db_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: default_draft_tree_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.default_draft_tree_vw AS
 SELECT tree_vw.tree_id,
    tree_vw.accepted_tree,
    tree_vw.config,
    tree_vw.current_tree_version_id,
    tree_vw.default_draft_tree_version_id,
    tree_vw.description_html,
    tree_vw.group_name,
    tree_vw.host_name,
    tree_vw.link_to_home_page,
    tree_vw.name,
    tree_vw.reference_id,
    tree_vw.tree_version_id,
    tree_vw.draft_name,
    tree_vw.log_entry,
    tree_vw.previous_version_id,
    tree_vw.published,
    tree_vw.published_at,
    tree_vw.published_by,
    tree_vw.element_link,
    tree_vw.depth,
    tree_vw.name_path,
    tree_vw.parent_id,
    tree_vw.taxon_id,
    tree_vw.taxon_link,
    tree_vw.tree_element_id_fk,
    tree_vw.tree_path,
    tree_vw.tree_version_id_fk,
    tree_vw.merge_conflict,
    tree_vw.tree_element_id,
    tree_vw.display_html,
    tree_vw.excluded,
    tree_vw.instance_id,
    tree_vw.instance_link,
    tree_vw.name_element,
    tree_vw.name_id,
    tree_vw.name_link,
    tree_vw.previous_element_id,
    tree_vw.profile,
    tree_vw.rank,
    tree_vw.simple_name,
    tree_vw.source_element_link,
    tree_vw.source_shard,
    tree_vw.synonyms,
    tree_vw.synonyms_html
   FROM public.tree_vw
  WHERE ((NOT tree_vw.published) AND (tree_vw.tree_version_id = tree_vw.default_draft_tree_version_id));


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    attempts numeric(19,2),
    created_at timestamp with time zone NOT NULL,
    failed_at timestamp with time zone,
    handler text,
    last_error text,
    locked_at timestamp with time zone,
    locked_by character varying(4000),
    priority numeric(19,2),
    queue character varying(4000),
    run_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: dist_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_entry (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    display character varying(255) NOT NULL,
    region_id bigint NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: dist_entry_dist_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_entry_dist_status (
    dist_entry_status_id bigint,
    dist_status_id bigint
);


--
-- Name: dist_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_status (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    description_html text,
    def_link character varying(255),
    name character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: dist_entry_dist_status_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dist_entry_dist_status_vw AS
 SELECT de.display,
    ds.name
   FROM ((public.dist_entry de
     JOIN public.dist_entry_dist_status deds ON ((de.id = deds.dist_entry_status_id)))
     JOIN public.dist_status ds ON ((deds.dist_status_id = ds.id)));


--
-- Name: dist_granular_booleans_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: dist_region; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_region (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    description_html text,
    def_link character varying(255),
    name character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: dist_status_dist_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dist_status_dist_status (
    dist_status_combining_status_id bigint,
    dist_status_id bigint
);


--
-- Name: dwc_name_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: VIEW dwc_name_v; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: dwc_taxon_v; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: VIEW dwc_taxon_v; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: event_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_record (
    id bigint NOT NULL,
    version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    data jsonb,
    dealt_with boolean DEFAULT false NOT NULL,
    type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: glossary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.glossary (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    term_name text,
    description text
);


--
-- Name: id_mapper; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.id_mapper (
    id bigint NOT NULL,
    from_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    system character varying(20) NOT NULL,
    to_id bigint
);


--
-- Name: instance_note_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.instance_note_vw AS
 SELECT key.name AS note_type,
    note.value AS note
   FROM (public.instance_note_key key
     LEFT JOIN public.instance_note note ON ((key.id = note.instance_note_key_id)))
  ORDER BY key.name;


--
-- Name: instance_resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_resource (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    resource_host_id bigint NOT NULL,
    instance_id bigint NOT NULL,
    value text,
    note text,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    api_name character varying(50),
    api_at timestamp with time zone,
    CONSTRAINT instance_resource_note_check CHECK ((char_length(note) <= 2400)),
    CONSTRAINT nr_length_check CHECK ((char_length(value) <= 250))
);


--
-- Name: TABLE instance_resource; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.resource_host_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.value; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.note; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN instance_resource.api_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: instance_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_resources (
    instance_id bigint NOT NULL,
    resource_id bigint NOT NULL
);


--
-- Name: resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    path character varying(2400) NOT NULL,
    site_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    resource_type_id bigint NOT NULL
);


--
-- Name: site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    description character varying(1000) NOT NULL,
    name character varying(100) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    url character varying(500) NOT NULL
);


--
-- Name: instance_resource_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.instance_resource_vw AS
 SELECT site.name AS site_name,
    site.description AS site_description,
    site.url AS site_url,
    resource.path AS resource_path,
    ((site.url)::text || (resource.path)::text) AS url,
    instance_resources.instance_id
   FROM (((public.site
     JOIN public.resource ON ((site.id = resource.site_id)))
     JOIN public.instance_resources ON ((resource.id = instance_resources.resource_id)))
     JOIN public.instance ON ((instance_resources.instance_id = instance.id)));


--
-- Name: last_export_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.last_export_mv AS
 SELECT now() AS export_time
  WITH NO DATA;


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    version bigint NOT NULL,
    data bytea NOT NULL,
    description text NOT NULL,
    file_name text NOT NULL,
    mime_type text NOT NULL
);


--
-- Name: name_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_category (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50),
    max_parents_allowed integer DEFAULT 0 NOT NULL,
    min_parents_required integer DEFAULT 0 NOT NULL,
    parent_1_help_text text,
    parent_2_help_text text,
    requires_family boolean DEFAULT false NOT NULL,
    requires_higher_ranked_parent boolean DEFAULT false NOT NULL,
    requires_name_element boolean DEFAULT false NOT NULL,
    takes_author_only boolean DEFAULT false NOT NULL,
    takes_authors boolean DEFAULT false NOT NULL,
    takes_cultivar_scoped_parent boolean DEFAULT false NOT NULL,
    takes_hybrid_scoped_parent boolean DEFAULT false NOT NULL,
    takes_name_element boolean DEFAULT false NOT NULL,
    takes_verbatim_rank boolean DEFAULT false NOT NULL,
    takes_rank boolean DEFAULT false NOT NULL
);


--
-- Name: name_detail_commons_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_detail_commons_vw AS
 SELECT instance.cited_by_id,
    ((((ity.name)::text || ':'::text) || (name.full_name_html)::text) || (
        CASE
            WHEN (ns.nom_illeg OR ns.nom_inval) THEN ns.name
            ELSE ''::character varying
        END)::text) AS entry,
    instance.id,
    instance.cites_id,
    ity.name AS instance_type_name,
    ity.sort_order AS instance_type_sort_order,
    name.full_name,
    name.full_name_html,
    ns.name,
    instance.name_id,
    instance.id AS instance_id,
    instance.cited_by_id AS name_detail_id
   FROM (((public.instance
     JOIN public.name ON ((instance.name_id = name.id)))
     JOIN public.instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN public.name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text = ANY (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_detail_synonyms_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_detail_synonyms_vw AS
 SELECT instance.cited_by_id,
    ((((ity.name)::text || ':'::text) || (name.full_name_html)::text) || (
        CASE
            WHEN (ns.nom_illeg OR ns.nom_inval) THEN ns.name
            ELSE ''::character varying
        END)::text) AS entry,
    instance.id,
    instance.cites_id,
    ity.name AS instance_type_name,
    ity.sort_order AS instance_type_sort_order,
    name.full_name,
    name.full_name_html,
    ns.name,
    instance.name_id,
    instance.id AS instance_id,
    instance.cited_by_id AS name_detail_id,
    instance.reference_id
   FROM (((public.instance
     JOIN public.name ON ((instance.name_id = name.id)))
     JOIN public.instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN public.name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text <> ALL (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_details_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_details_vw AS
 SELECT n.id,
    n.full_name,
    n.simple_name,
    s.name AS status_name,
    r.name AS rank_name,
    r.visible_in_name AS rank_visible_in_name,
    r.sort_order AS rank_sort_order,
    t.name AS type_name,
    t.scientific AS type_scientific,
    t.cultivar AS type_cultivar,
    i.id AS instance_id,
    ref.year AS reference_year,
    ref.id AS reference_id,
    ref.citation_html AS reference_citation_html,
    ity.name AS instance_type_name,
    ity.id AS instance_type_id,
    ity.primary_instance,
    ity.standalone AS instance_standalone,
    sty.standalone AS synonym_standalone,
    sty.name AS synonym_type_name,
    i.page,
    i.page_qualifier,
    i.cited_by_id,
    i.cites_id,
    i.bhl_url,
        CASE ity.primary_instance
            WHEN true THEN 'A'::text
            ELSE 'B'::text
        END AS primary_instance_first,
    sname.full_name AS synonym_full_name,
    author.name AS author_name,
    n.id AS name_id,
    n.sort_name,
    ((((ref.citation_html)::text || ': '::text) || (COALESCE(i.page, ''::character varying))::text) ||
        CASE ity.primary_instance
            WHEN true THEN ((' ['::text || (ity.name)::text) || ']'::text)
            ELSE ''::text
        END) AS entry
   FROM ((((((((((public.name n
     JOIN public.name_status s ON ((n.name_status_id = s.id)))
     JOIN public.name_rank r ON ((n.name_rank_id = r.id)))
     JOIN public.name_type t ON ((n.name_type_id = t.id)))
     JOIN public.instance i ON ((n.id = i.name_id)))
     JOIN public.instance_type ity ON ((i.instance_type_id = ity.id)))
     JOIN public.reference ref ON ((i.reference_id = ref.id)))
     LEFT JOIN public.author ON ((ref.author_id = author.id)))
     LEFT JOIN public.instance syn ON ((syn.cited_by_id = i.id)))
     LEFT JOIN public.instance_type sty ON ((syn.instance_type_id = sty.id)))
     LEFT JOIN public.name sname ON ((syn.name_id = sname.id)))
  WHERE (n.duplicate_of_id IS NULL);


--
-- Name: name_group_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_group_v AS
 SELECT name_group.id AS name_group_id,
    name_group.name AS name_group_label,
    name_group.description_html,
    name_group.rdf_id AS name_group_rdf_id
   FROM public.name_group;


--
-- Name: name_resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_resource (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    resource_host_id bigint NOT NULL,
    name_id bigint NOT NULL,
    value text,
    note text,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    api_name character varying(50),
    api_at timestamp with time zone,
    CONSTRAINT name_resource_note_check CHECK ((char_length(note) <= 2400)),
    CONSTRAINT nr_length_check CHECK ((char_length(value) <= 250))
);


--
-- Name: TABLE name_resource; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.resource_host_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.value; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.note; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN name_resource.api_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: name_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_resources (
    resource_id bigint NOT NULL,
    name_id bigint NOT NULL
);


--
-- Name: name_tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_tag (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: name_tag_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_tag_name (
    name_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: name_type_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_type_v AS
 SELECT nt.id AS name_type_id,
    nt.name AS name_type_label,
    nt.cultivar AS is_cultivar,
    nt.formula AS is_formula,
    nt.hybrid AS is_hybrid,
    nt.scientific AS is_scientific,
    g.rdf_id AS name_group_rdf_id
   FROM (public.name_type nt
     JOIN public.name_group g ON ((nt.name_group_id = g.id)));


--
-- Name: name_view; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: VIEW name_view; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id bigint NOT NULL,
    version bigint NOT NULL,
    message character varying(255) NOT NULL,
    object_id bigint
);


--
-- Name: nsl_5579_2024_updates; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nsl_5579_2024_updates AS
 SELECT loader_name.parent_id,
    loader_name.id AS ln_id,
    loader_name.simple_name,
    loader_name.record_type,
    SUBSTRING(nir.citation FROM 1 FOR 80) AS expected_citation,
    nit.name AS expected_type,
    ni.id AS expected_instance,
    SUBSTRING(ar.citation FROM 1 FOR 80) AS actual_citation,
    ai.id AS actual_instance
   FROM (((((((((loader.loader_name
     JOIN loader.loader_name_match lnm ON ((loader_name.id = lnm.loader_name_id)))
     JOIN loader.loader_batch lb ON ((loader_name.loader_batch_id = lb.id)))
     JOIN public.name ON ((lnm.name_id = name.id)))
     JOIN public.instance ni ON ((name.id = ni.name_id)))
     JOIN public.instance_type nit ON ((ni.instance_type_id = nit.id)))
     JOIN public.reference nir ON ((ni.reference_id = nir.id)))
     LEFT JOIN loader.loader_name parent ON ((loader_name.parent_id = parent.id)))
     JOIN public.instance ai ON ((lnm.instance_id = ai.id)))
     JOIN public.reference ar ON ((ai.reference_id = ar.id)))
  WHERE (((lb.name)::text = 'APC 2024 Updates'::text) AND (loader_name.record_type <> 'misapplied'::text) AND nit.primary_instance AND (ai.id <> ni.id))
  ORDER BY loader_name.sort_key;


--
-- Name: nsl_simple_name_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nsl_simple_name_export (
    id text,
    apc_comment character varying(4000),
    apc_distribution character varying(4000),
    apc_excluded boolean,
    apc_familia character varying(255),
    apc_instance_id text,
    apc_name character varying(512),
    apc_proparte boolean,
    apc_relationship_type character varying(255),
    apni boolean,
    author character varying(255),
    authority character varying(255),
    autonym boolean,
    basionym character varying(512),
    base_name_author character varying(255),
    classifications character varying(255),
    created_at timestamp without time zone,
    created_by character varying(255),
    cultivar boolean,
    cultivar_name character varying(255),
    ex_author character varying(255),
    ex_base_name_author character varying(255),
    familia character varying(255),
    family_nsl_id text,
    formula boolean,
    full_name_html character varying(2048),
    genus character varying(255),
    genus_nsl_id text,
    homonym boolean,
    hybrid boolean,
    infraspecies character varying(255),
    name character varying(255),
    classis character varying(255),
    name_element character varying(255),
    subclassis character varying(255),
    name_type_name character varying(255),
    nom_illeg boolean,
    nom_inval boolean,
    nom_stat character varying(255),
    parent_nsl_id text,
    proto_citation character varying(512),
    proto_instance_id text,
    proto_year smallint,
    rank character varying(255),
    rank_abbrev character varying(255),
    rank_sort_order integer,
    replaced_synonym character varying(512),
    sanctioning_author character varying(255),
    scientific boolean,
    second_parent_nsl_id text,
    simple_name_html character varying(2048),
    species character varying(255),
    species_nsl_id text,
    taxon_name character varying(512),
    updated_at timestamp without time zone,
    updated_by character varying(255)
);


--
-- Name: nsl_taxon_cv; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: nsl_tree_closure_cv; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: product_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_role (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    product_id bigint NOT NULL,
    role_id bigint NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    description text
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(50) NOT NULL,
    description text DEFAULT 'Please describe this product role type'::text NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: product_role_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.product_role_v AS
 SELECT pr.id,
    product.name AS product,
    roles.name AS role,
    product.id AS product_id,
    roles.id AS role_id
   FROM ((public.product_role pr
     JOIN public.product ON ((pr.product_id = product.id)))
     JOIN public.roles ON ((pr.role_id = roles.id)))
  ORDER BY pr.id, product.name, roles.name;


--
-- Name: profile_item_reference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profile_item_reference (
    profile_item_id bigint NOT NULL,
    reference_id bigint NOT NULL,
    pages text,
    annotation text,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_item_reference; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.profile_item_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.reference_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.pages; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.annotation; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN profile_item_reference.api_date; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: reference_resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reference_resource (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    resource_host_id bigint NOT NULL,
    reference_id bigint NOT NULL,
    value text,
    note text,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    api_name character varying(50),
    api_at timestamp with time zone,
    CONSTRAINT nr_length_check CHECK ((char_length(value) <= 250)),
    CONSTRAINT reference_resource_note_check CHECK ((char_length(note) <= 2400))
);


--
-- Name: TABLE reference_resource; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.resource_host_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.value; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.note; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.api_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN reference_resource.api_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: resource_host; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_host (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(50),
    description text,
    resolving_url text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    for_reference boolean DEFAULT false NOT NULL,
    for_name boolean DEFAULT false NOT NULL,
    for_instance boolean DEFAULT false NOT NULL,
    rdf_id character varying(50) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL,
    CONSTRAINT lr_length_check CHECK ((char_length(resolving_url) <= 250)),
    CONSTRAINT resource_host_description_check CHECK ((char_length(description) <= 250))
);


--
-- Name: TABLE resource_host; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.description; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.resolving_url; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.sort_order; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.for_reference; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.for_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.for_instance; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.rdf_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.deprecated; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.lock_version; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.created_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.created_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.updated_at; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN resource_host.updated_by; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: resource_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    css_icon text,
    deprecated boolean DEFAULT false NOT NULL,
    description text NOT NULL,
    display boolean DEFAULT true NOT NULL,
    media_icon_id bigint,
    name text NOT NULL,
    rdf_id character varying(50)
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: taxon_mv_compare; Type: TABLE; Schema: public; Owner: -
--


--
-- Name: taxon_view; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: VIEW taxon_view; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: tree_element_distribution_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_element_distribution_entries (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    dist_entry_id bigint NOT NULL,
    tree_element_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: tree_join_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tree_join_v AS
 SELECT t.id AS tree_id,
    t.accepted_tree,
    t.config,
    t.current_tree_version_id,
    t.default_draft_tree_version_id,
    t.description_html,
    t.group_name,
    t.host_name,
    t.link_to_home_page,
    t.name,
    t.name AS tree_name,
    t.reference_id,
    tv.id AS tree_version_id,
    tv.draft_name,
    tv.log_entry,
    tv.previous_version_id,
    tv.published,
    tv.published_at,
    tv.published_by,
    tve.element_link,
    tve.depth,
    tve.name_path,
    tve.parent_id,
    tve.taxon_id,
    tve.taxon_link,
    tve.tree_element_id AS tree_element_id_fk,
    tve.tree_path,
    tve.tree_version_id AS tree_version_id_fk,
    tve.merge_conflict,
    te.id AS tree_element_id,
    te.display_html,
    te.excluded,
    te.instance_id,
    te.instance_link,
    te.name_element,
    te.name_id,
    te.name_link,
    te.previous_element_id,
    te.profile,
    te.rank,
    te.simple_name,
    te.source_element_link,
    te.source_shard,
    te.synonyms,
    te.synonyms_html,
    (t.current_tree_version_id = tv.id) AS is_current_version
   FROM (((public.tree t
     JOIN public.tree_version tv ON ((t.id = tv.tree_id)))
     JOIN public.tree_version_element tve ON ((tv.id = tve.tree_version_id)))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)));


--
-- Name: tree_version_element_tmp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version_element_tmp (
    element_link text,
    depth integer,
    name_path text,
    parent_id text,
    taxon_id bigint,
    taxon_link text,
    tree_element_id bigint,
    tree_path text,
    tree_version_id bigint,
    updated_at timestamp with time zone,
    updated_by character varying(255),
    merge_conflict boolean
);


--
-- Name: user_product_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_product_role (
    user_id bigint NOT NULL,
    product_role_id bigint NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: user_product_role_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.user_product_role_v AS
 SELECT users.user_name,
    product.name AS product,
    roles.name AS role,
    ref.citation AS reference,
    tree.name AS tree,
    (product.is_name_index)::text AS is_name_index,
    users.id AS user_id,
    pr.id AS product_role_id,
    product.id AS product_id,
    roles.id AS role_id,
    tree.id AS tree_id
   FROM ((((((public.user_product_role upr
     JOIN public.users ON ((upr.user_id = users.id)))
     JOIN public.product_role pr ON ((upr.product_role_id = pr.id)))
     JOIN public.product ON ((pr.product_id = product.id)))
     JOIN public.roles ON ((pr.role_id = roles.id)))
     LEFT JOIN public.reference ref ON ((product.reference_id = ref.id)))
     LEFT JOIN public.tree ON ((product.tree_id = tree.id)))
  ORDER BY users.user_name, product.name, roles.name;


--
-- Name: wfo_export; Type: VIEW; Schema: public; Owner: -
--


--
-- Name: VIEW wfo_export; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN wfo_export.wfo_link; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN wfo_export.name_id; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN wfo_export.full_name_html; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: COLUMN wfo_export.full_name; Type: COMMENT; Schema: public; Owner: -
--



--
-- Name: bulk_processing_log id; Type: DEFAULT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.bulk_processing_log ALTER COLUMN id SET DEFAULT nextval('loader.bulk_processing_log_id_seq'::regclass);


--
-- Name: batch_review batch_review_loader_batch_id_name_key; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review
    ADD CONSTRAINT batch_review_loader_batch_id_name_key UNIQUE (loader_batch_id, name);


--
-- Name: batch_review_period batch_review_period_batch_review_id_start_date_key; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_period
    ADD CONSTRAINT batch_review_period_batch_review_id_start_date_key UNIQUE (batch_review_id, start_date);


--
-- Name: batch_review_period batch_review_period_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_period
    ADD CONSTRAINT batch_review_period_pkey PRIMARY KEY (id);


--
-- Name: batch_review batch_review_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review
    ADD CONSTRAINT batch_review_pkey PRIMARY KEY (id);


--
-- Name: batch_review_role batch_review_role_name_key; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_role
    ADD CONSTRAINT batch_review_role_name_key UNIQUE (name);


--
-- Name: batch_review_role batch_review_role_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_role
    ADD CONSTRAINT batch_review_role_pkey PRIMARY KEY (id);


--
-- Name: batch_reviewer batch_reviewer_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_pkey PRIMARY KEY (id);


--
-- Name: batch_reviewer batch_reviewer_user_id_org_id_batch_review_role_id_batch_re_key; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_user_id_org_id_batch_review_role_id_batch_re_key UNIQUE (user_id, org_id, batch_review_role_id, batch_review_id);


--
-- Name: loader_batch_job_lock loader_batch_job_lock_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_batch_job_lock
    ADD CONSTRAINT loader_batch_job_lock_pkey PRIMARY KEY (id);


--
-- Name: loader_batch loader_batch_name_uk; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_batch
    ADD CONSTRAINT loader_batch_name_uk UNIQUE (name);


--
-- Name: loader_batch loader_batch_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_batch
    ADD CONSTRAINT loader_batch_pkey PRIMARY KEY (id);


--
-- Name: loader_name_match loader_name_match_inst_uniq; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_inst_uniq UNIQUE (loader_name_id, name_id, instance_id);


--
-- Name: loader_name_match loader_name_match_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_pkey PRIMARY KEY (id);


--
-- Name: loader_name loader_name_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name
    ADD CONSTRAINT loader_name_pkey PRIMARY KEY (id);


--
-- Name: name_review_comment name_review_comment_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_comment_pkey PRIMARY KEY (id);


--
-- Name: name_review_comment_type name_review_comment_type_name_key; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment_type
    ADD CONSTRAINT name_review_comment_type_name_key UNIQUE (name);


--
-- Name: name_review_comment_type name_review_comment_type_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment_type
    ADD CONSTRAINT name_review_comment_type_pkey PRIMARY KEY (id);


--
-- Name: name_review_vote name_review_vote_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_vote
    ADD CONSTRAINT name_review_vote_pkey PRIMARY KEY (org_id, batch_review_id, loader_name_id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: db_version db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: dist_entry dist_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry
    ADD CONSTRAINT dist_entry_pkey PRIMARY KEY (id);


--
-- Name: dist_region dist_region_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_region
    ADD CONSTRAINT dist_region_pkey PRIMARY KEY (id);


--
-- Name: dist_status dist_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_status
    ADD CONSTRAINT dist_status_pkey PRIMARY KEY (id);


--
-- Name: event_record event_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_record
    ADD CONSTRAINT event_record_pkey PRIMARY KEY (id);


--
-- Name: glossary glossary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glossary
    ADD CONSTRAINT glossary_pkey PRIMARY KEY (id);


--
-- Name: id_mapper id_mapper_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT id_mapper_pkey PRIMARY KEY (id);


--
-- Name: instance_note_key instance_note_key_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note_key
    ADD CONSTRAINT instance_note_key_pkey PRIMARY KEY (id);


--
-- Name: instance_note instance_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT instance_note_pkey PRIMARY KEY (id);


--
-- Name: instance instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT instance_pkey PRIMARY KEY (id);


--
-- Name: instance_resource instance_resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resource
    ADD CONSTRAINT instance_resource_pkey PRIMARY KEY (id);


--
-- Name: instance_resources instance_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT instance_resources_pkey PRIMARY KEY (instance_id, resource_id);


--
-- Name: instance_type instance_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_type
    ADD CONSTRAINT instance_type_pkey PRIMARY KEY (id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: resource_host lr_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_host
    ADD CONSTRAINT lr_unique_name UNIQUE (name);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: name_category name_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_category
    ADD CONSTRAINT name_category_pkey PRIMARY KEY (id);


--
-- Name: name_group name_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_group
    ADD CONSTRAINT name_group_pkey PRIMARY KEY (id);


--
-- Name: name name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT name_pkey PRIMARY KEY (id);


--
-- Name: name_rank name_rank_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT name_rank_pkey PRIMARY KEY (id);


--
-- Name: name_resource name_resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_resource
    ADD CONSTRAINT name_resource_pkey PRIMARY KEY (id);


--
-- Name: name_resources name_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_resources
    ADD CONSTRAINT name_resources_pkey PRIMARY KEY (name_id, resource_id);


--
-- Name: name_status name_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT name_status_pkey PRIMARY KEY (id);


--
-- Name: name_tag_name name_tag_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT name_tag_name_pkey PRIMARY KEY (name_id, tag_id);


--
-- Name: name_tag name_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag
    ADD CONSTRAINT name_tag_pkey PRIMARY KEY (id);


--
-- Name: name_type name_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT name_type_pkey PRIMARY KEY (id);


--
-- Name: namespace namespace_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (id);


--
-- Name: instance no_duplicate_synonyms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT no_duplicate_synonyms UNIQUE (name_id, reference_id, instance_type_id, page, cites_id, cited_by_id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: name_rank nr_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT nr_unique_name UNIQUE (name_group_id, name);


--
-- Name: name_status ns_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT ns_unique_name UNIQUE (name_group_id, name);


--
-- Name: name_type nt_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT nt_unique_name UNIQUE (name_group_id, name);


--
-- Name: org org_abbrev_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT org_abbrev_key UNIQUE (abbrev);


--
-- Name: org org_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT org_name_key UNIQUE (name);


--
-- Name: org org_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org
    ADD CONSTRAINT org_pkey PRIMARY KEY (id);


--
-- Name: product_role pr_unique_product_role; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT pr_unique_product_role UNIQUE (product_id, role_id);


--
-- Name: product_item_config product_item_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_item_config
    ADD CONSTRAINT product_item_config_pkey PRIMARY KEY (id);


--
-- Name: product_item_config product_item_config_product_id_profile_item_type_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_item_config
    ADD CONSTRAINT product_item_config_product_id_profile_item_type_id_key UNIQUE (product_id, profile_item_type_id);


--
-- Name: product_item_config product_item_config_product_id_sort_order_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_item_config
    ADD CONSTRAINT product_item_config_product_id_sort_order_key UNIQUE (product_id, sort_order);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- Name: product_role product_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT product_role_pkey PRIMARY KEY (id);


--
-- Name: profile_item_annotation profile_item_annotation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_annotation
    ADD CONSTRAINT profile_item_annotation_pkey PRIMARY KEY (id);


--
-- Name: profile_item profile_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_pkey PRIMARY KEY (id);


--
-- Name: profile_item_reference profile_item_reference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_reference
    ADD CONSTRAINT profile_item_reference_pkey PRIMARY KEY (profile_item_id, reference_id);


--
-- Name: profile_item_type profile_item_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_type
    ADD CONSTRAINT profile_item_type_pkey PRIMARY KEY (id);


--
-- Name: profile_item_type profile_item_type_rdf_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_type
    ADD CONSTRAINT profile_item_type_rdf_id_key UNIQUE (rdf_id);


--
-- Name: profile_object_type profile_object_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_object_type
    ADD CONSTRAINT profile_object_type_pkey PRIMARY KEY (id);


--
-- Name: profile_object_type profile_object_type_rdf_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_object_type
    ADD CONSTRAINT profile_object_type_rdf_id_key UNIQUE (rdf_id);


--
-- Name: profile_text profile_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_text
    ADD CONSTRAINT profile_text_pkey PRIMARY KEY (id);


--
-- Name: ref_author_role ref_author_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_author_role
    ADD CONSTRAINT ref_author_role_pkey PRIMARY KEY (id);


--
-- Name: ref_type ref_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (id);


--
-- Name: reference reference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (id);


--
-- Name: reference_resource reference_resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference_resource
    ADD CONSTRAINT reference_resource_pkey PRIMARY KEY (id);


--
-- Name: resource_host resource_host_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_host
    ADD CONSTRAINT resource_host_pkey PRIMARY KEY (id);


--
-- Name: resource resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_pkey PRIMARY KEY (id);


--
-- Name: resource_type resource_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_type
    ADD CONSTRAINT resource_type_pkey PRIMARY KEY (id);


--
-- Name: roles role_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT role_unique_name UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shard_config shard_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_config
    ADD CONSTRAINT shard_config_pkey PRIMARY KEY (id);


--
-- Name: site site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: tree_element_distribution_entries tede_te_de_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT tede_te_de_unique UNIQUE (tree_element_id, dist_entry_id);


--
-- Name: tree_element_distribution_entries tree_element_distribution_entries_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT tree_element_distribution_entries_pkey1 PRIMARY KEY (id);


--
-- Name: tree_element tree_element_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT tree_element_pkey PRIMARY KEY (id);


--
-- Name: tree tree_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT tree_pkey PRIMARY KEY (id);


--
-- Name: tree_version_element tree_version_element_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT tree_version_element_pkey PRIMARY KEY (element_link);


--
-- Name: tree_version tree_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT tree_version_pkey PRIMARY KEY (id);


--
-- Name: ref_type uk_4fp66uflo7rgx59167ajs0ujv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT uk_4fp66uflo7rgx59167ajs0ujv UNIQUE (name);


--
-- Name: name_group uk_5185nbyw5hkxqyyqgylfn2o6d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_group
    ADD CONSTRAINT uk_5185nbyw5hkxqyyqgylfn2o6d UNIQUE (name);


--
-- Name: name uk_66rbixlxv32riosi9ob62m8h5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT uk_66rbixlxv32riosi9ob62m8h5 UNIQUE (uri);


--
-- Name: author uk_9kovg6nyb11658j2tv2yv4bsi; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT uk_9kovg6nyb11658j2tv2yv4bsi UNIQUE (abbrev);


--
-- Name: instance_note_key uk_a0justk7c77bb64o6u1riyrlh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note_key
    ADD CONSTRAINT uk_a0justk7c77bb64o6u1riyrlh UNIQUE (name);


--
-- Name: instance uk_bl9pesvdo9b3mp2qdna1koqc7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT uk_bl9pesvdo9b3mp2qdna1koqc7 UNIQUE (uri);


--
-- Name: namespace uk_eq2y9mghytirkcofquanv5frf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT uk_eq2y9mghytirkcofquanv5frf UNIQUE (name);


--
-- Name: language uk_g8hr207ijpxlwu10pewyo65gv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_g8hr207ijpxlwu10pewyo65gv UNIQUE (name);


--
-- Name: language uk_hghw87nl0ho38f166atlpw2hy; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_hghw87nl0ho38f166atlpw2hy UNIQUE (iso6391code);


--
-- Name: instance_type uk_j5337m9qdlirvd49v4h11t1lk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_type
    ADD CONSTRAINT uk_j5337m9qdlirvd49v4h11t1lk UNIQUE (name);


--
-- Name: reference uk_kqwpm0crhcq4n9t9uiyfxo2df; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT uk_kqwpm0crhcq4n9t9uiyfxo2df UNIQUE (doi);


--
-- Name: ref_author_role uk_l95kedbafybjpp3h53x8o9fke; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_author_role
    ADD CONSTRAINT uk_l95kedbafybjpp3h53x8o9fke UNIQUE (name);


--
-- Name: reference uk_nivlrafbqdoj0yie46ixithd3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT uk_nivlrafbqdoj0yie46ixithd3 UNIQUE (uri);


--
-- Name: name_tag uk_o4su6hi7vh0yqs4c1dw0fsf1e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag
    ADD CONSTRAINT uk_o4su6hi7vh0yqs4c1dw0fsf1e UNIQUE (name);


--
-- Name: author uk_rd7q78koyhufe1edfb2rgfrum; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT uk_rd7q78koyhufe1edfb2rgfrum UNIQUE (uri);


--
-- Name: language uk_rpsahneqboogcki6p1bpygsua; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_rpsahneqboogcki6p1bpygsua UNIQUE (iso6393code);


--
-- Name: name_category uk_rxqxoenedjdjyd4x7c98s59io; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_category
    ADD CONSTRAINT uk_rxqxoenedjdjyd4x7c98s59io UNIQUE (name);


--
-- Name: id_mapper unique_from_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT unique_from_id UNIQUE (to_id, from_id);


--
-- Name: user_product_role user_product_role_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_product_role
    ADD CONSTRAINT user_product_role_pkey1 PRIMARY KEY (user_id, product_role_id);


--
-- Name: users users_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_name_key UNIQUE (user_name);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: loader_name_lower_simple_batch_id; Type: INDEX; Schema: loader; Owner: -
--

CREATE INDEX loader_name_lower_simple_batch_id ON loader.loader_name USING btree (lower(simple_name), loader_batch_id);


--
-- Name: name_unique_case_insensitive; Type: INDEX; Schema: loader; Owner: -
--

CREATE UNIQUE INDEX name_unique_case_insensitive ON loader.loader_batch USING btree (lower((name)::text));


--
-- Name: accepted_name_anuid_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: accepted_name_id_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: accepted_name_instance_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: accepted_name_name_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: accepted_name_name_id_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: accepted_name_txid_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: accepted_name_version_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: apii_image_scientificname_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX apii_image_scientificname_idx ON public.apii_image USING btree (scientificname);


--
-- Name: auth_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_index ON public.author USING btree (namespace_id, source_id, source_system);


--
-- Name: auth_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_string_index ON public.author USING btree (source_id_string);


--
-- Name: auth_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_system_index ON public.author USING btree (source_system);


--
-- Name: author_abbrev_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_abbrev_index ON public.author USING btree (abbrev);


--
-- Name: author_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_name_index ON public.author USING btree (name);


--
-- Name: basionym_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX basionym_id_index ON public.primary_instance_mv USING btree (basionym_id);


--
-- Name: comment_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_author_index ON public.comment USING btree (author_id);


--
-- Name: comment_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_instance_index ON public.comment USING btree (instance_id);


--
-- Name: comment_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_name_index ON public.comment USING btree (name_id);


--
-- Name: comment_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_reference_index ON public.comment USING btree (reference_id);


--
-- Name: event_record_created_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_created_index ON public.event_record USING btree (created_at);


--
-- Name: event_record_dealt_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_dealt_index ON public.event_record USING btree (dealt_with);


--
-- Name: event_record_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_index ON public.event_record USING btree (created_at, dealt_with, type);


--
-- Name: event_record_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_type_index ON public.event_record USING btree (type);


--
-- Name: id_mapper_from_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX id_mapper_from_index ON public.id_mapper USING btree (from_id, namespace_id, system);


--
-- Name: instance_citedby_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_citedby_index ON public.instance USING btree (cited_by_id);


--
-- Name: instance_cites_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_cites_index ON public.instance USING btree (cites_id);


--
-- Name: instance_instancetype_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_instancetype_index ON public.instance USING btree (instance_type_id);


--
-- Name: instance_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_name_index ON public.instance USING btree (name_id);


--
-- Name: instance_note_key_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_note_key_rdfid ON public.instance_note_key USING btree (rdf_id);


--
-- Name: instance_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_parent_index ON public.instance USING btree (parent_id);


--
-- Name: instance_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_reference_index ON public.instance USING btree (reference_id);


--
-- Name: instance_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_index ON public.instance USING btree (namespace_id, source_id, source_system);


--
-- Name: instance_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_string_index ON public.instance USING btree (source_id_string);


--
-- Name: instance_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_system_index ON public.instance USING btree (source_system);


--
-- Name: instance_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_type_rdfid ON public.instance_type USING btree (rdf_id);


--
-- Name: iso_pub_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX iso_pub_index ON public.reference USING btree (iso_publication_date);


--
-- Name: lower_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lower_full_name ON public.name USING btree (lower((full_name)::text));


--
-- Name: name_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_author_index ON public.name USING btree (author_id);


--
-- Name: name_baseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_baseauthor_index ON public.name USING btree (base_author_id);


--
-- Name: name_category_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_category_rdfid ON public.name_category USING btree (rdf_id);


--
-- Name: name_duplicate_of_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_duplicate_of_id_index ON public.name USING btree (duplicate_of_id);


--
-- Name: name_exauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exauthor_index ON public.name USING btree (ex_author_id);


--
-- Name: name_exbaseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exbaseauthor_index ON public.name USING btree (ex_base_author_id);


--
-- Name: name_full_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_full_name_index ON public.name USING btree (full_name);


--
-- Name: name_full_name_trgm_index; Type: INDEX; Schema: public; Owner: -
--

SET search_path TO nsl, public;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION if not exists unaccent;
CREATE OR REPLACE FUNCTION public.f_unaccent(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
SELECT unaccent('unaccent', $1)
$function$
;

CREATE INDEX name_full_name_trgm_index ON public.name USING gin (full_name public.gin_trgm_ops);


--
-- Name: name_group_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_group_rdfid ON public.name_group USING btree (rdf_id);


--
-- Name: name_lower_f_unaccent_full_name_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_f_unaccent_full_name_like ON public.name USING btree (lower(public.f_unaccent((full_name)::text)) varchar_pattern_ops);


--
-- Name: name_lower_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_full_name_gin_trgm ON public.name USING gin (lower((full_name)::text) public.gin_trgm_ops);


--
-- Name: name_lower_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_simple_name_gin_trgm ON public.name USING gin (lower((simple_name)::text) public.gin_trgm_ops);


--
-- Name: name_lower_unacent_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_full_name_gin_trgm ON public.name USING gin (lower(public.f_unaccent((full_name)::text)) public.gin_trgm_ops);


--
-- Name: name_lower_unacent_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_simple_name_gin_trgm ON public.name USING gin (lower(public.f_unaccent((simple_name)::text)) public.gin_trgm_ops);


--
-- Name: name_mv_canonical_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: name_mv_family_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: name_mv_id_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: name_mv_name_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: name_mv_name_id_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: name_name_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_name_element_index ON public.name USING btree (name_element);


--
-- Name: name_name_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_name_path_index ON public.name USING gin (name_path public.gin_trgm_ops);


--
-- Name: name_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_parent_id_ndx ON public.name USING btree (parent_id);


--
-- Name: name_rank_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_index ON public.name USING btree (name_rank_id);


--
-- Name: name_rank_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_rdfid ON public.name_rank USING btree (rdf_id);


--
-- Name: name_sanctioningauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_sanctioningauthor_index ON public.name USING btree (sanctioning_author_id);


--
-- Name: name_second_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_second_parent_id_ndx ON public.name USING btree (second_parent_id);


--
-- Name: name_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_simple_name_index ON public.name USING btree (simple_name);


--
-- Name: name_sort_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_sort_name_idx ON public.name USING btree (sort_name);


--
-- Name: name_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_index ON public.name USING btree (namespace_id, source_id, source_system);


--
-- Name: name_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_string_index ON public.name USING btree (source_id_string);


--
-- Name: name_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_index ON public.name USING btree (name_status_id);


--
-- Name: name_status_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_rdfid ON public.name_status USING btree (rdf_id);


--
-- Name: name_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_system_index ON public.name USING btree (source_system);


--
-- Name: name_tag_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_name_index ON public.name_tag_name USING btree (name_id);


--
-- Name: name_tag_tag_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_tag_index ON public.name_tag_name USING btree (tag_id);


--
-- Name: name_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_index ON public.name USING btree (name_type_id);


--
-- Name: name_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_rdfid ON public.name_type USING btree (rdf_id);


--
-- Name: namespace_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX namespace_rdfid ON public.namespace USING btree (rdf_id);


--
-- Name: note_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_instance_index ON public.instance_note USING btree (instance_id);


--
-- Name: note_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_key_index ON public.instance_note USING btree (instance_note_key_id);


--
-- Name: note_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_index ON public.instance_note USING btree (namespace_id, source_id, source_system);


--
-- Name: note_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_string_index ON public.instance_note USING btree (source_id_string);


--
-- Name: note_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_system_index ON public.instance_note USING btree (source_system);


--
-- Name: nsl_tree_accepted_name_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: nsl_tree_excluded_name_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: nsl_tree_name_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: one_draft_per_tree; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_draft_per_tree ON public.tree_version USING btree (tree_id, published) WHERE (published IS FALSE);


--
-- Name: pi_instance_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pi_instance_i ON public.profile_item USING btree (instance_id);


--
-- Name: pi_text__id_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pi_text__id_i ON public.profile_item USING btree (profile_text_id);


--
-- Name: pi_tree_element_id_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pi_tree_element_id_i ON public.profile_item USING btree (tree_element_id);


--
-- Name: pit_path_u; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pit_path_u ON public.profile_item_type USING btree (name);


--
-- Name: primary_combination_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX primary_combination_id_index ON public.primary_instance_mv USING btree (combination_id);


--
-- Name: primary_instance_citation_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX primary_instance_citation_gin_trgm ON public.primary_instance_mv USING gin (publication_citation public.gin_trgm_ops);


--
-- Name: primary_instance_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX primary_instance_id_index ON public.primary_instance_mv USING btree (primary_id);


--
-- Name: primary_instance_name_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX primary_instance_name_id_index ON public.primary_instance_mv USING btree (name_id) INCLUDE (primary_id, combination_id, basionym_id, publication_citation, publication_date, publication_usage_type);


--
-- Name: product_item_config_product_item_u; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX product_item_config_product_item_u ON public.product_item_config USING btree (product_id, profile_item_type_id);


--
-- Name: product_unique_tree_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX product_unique_tree_owner ON public.product USING btree (tree_id);


--
-- Name: profile_item_annotation_item_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_item_annotation_item_i ON public.profile_item_annotation USING btree (profile_item_id);


--
-- Name: profile_text_value_md_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profile_text_value_md_i ON public.profile_text USING gin (value public.gin_trgm_ops);


--
-- Name: ref_author_role_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_author_role_rdfid ON public.ref_author_role USING btree (rdf_id);


--
-- Name: ref_citation_text_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_citation_text_index ON public.reference USING gin (to_tsvector('english'::regconfig, public.f_unaccent(COALESCE((citation)::text, ''::text))));


--
-- Name: ref_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_index ON public.reference USING btree (namespace_id, source_id, source_system);


--
-- Name: ref_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_string_index ON public.reference USING btree (source_id_string);


--
-- Name: ref_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_system_index ON public.reference USING btree (source_system);


--
-- Name: ref_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_type_rdfid ON public.ref_type USING btree (rdf_id);


--
-- Name: reference_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_author_index ON public.reference USING btree (author_id);


--
-- Name: reference_authorrole_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_authorrole_index ON public.reference USING btree (ref_author_role_id);


--
-- Name: reference_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_parent_index ON public.reference USING btree (parent_id);


--
-- Name: reference_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_type_index ON public.reference USING btree (ref_type_id);


--
-- Name: taxon_compare_id_i; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: tree_element_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_instance_index ON public.tree_element USING btree (instance_id);


--
-- Name: tree_element_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_name_index ON public.tree_element USING btree (name_id);


--
-- Name: tree_element_previous_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_previous_index ON public.tree_element USING btree (previous_element_id);


--
-- Name: tree_name_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_name_path_index ON public.tree_version_element USING btree (name_path);


--
-- Name: tree_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_path_index ON public.tree_version_element USING btree (tree_path);


--
-- Name: tree_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_simple_name_index ON public.tree_element USING btree (simple_name);


--
-- Name: tree_synonyms_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_synonyms_index ON public.tree_element USING gin (synonyms);


--
-- Name: tree_version_element_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_element_index ON public.tree_version_element USING btree (tree_element_id);


--
-- Name: tree_version_element_link_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_link_index ON public.tree_version_element USING btree (element_link);


--
-- Name: tree_version_element_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_parent_index ON public.tree_version_element USING btree (parent_id);


--
-- Name: tree_version_element_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_taxon_id_index ON public.tree_version_element USING btree (taxon_id);


--
-- Name: tree_version_element_taxon_link_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_taxon_link_index ON public.tree_version_element USING btree (taxon_link);


--
-- Name: tree_version_element_version_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_version_index ON public.tree_version_element USING btree (tree_version_id);


--
-- Name: trees_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_name_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_name_path_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_parent_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_parent_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_path_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_path_instance_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_path_ltree_path_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_path_name_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_path_sort_name_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: trees_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--



--
-- Name: author audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: comment audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: instance audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: instance_note audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: name audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: reference audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: tree_element audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: author audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: comment audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: instance audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: instance_note audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: name audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: reference audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: tree_element audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--



--
-- Name: author author_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER author_update AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE FUNCTION public.author_notification();


--
-- Name: profile_item compare_instance_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compare_instance_id BEFORE INSERT OR UPDATE ON public.profile_item FOR EACH ROW EXECUTE FUNCTION public.profile_instance_constraint();


--
-- Name: instance instance_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_insert_delete AFTER INSERT OR DELETE ON public.instance FOR EACH ROW EXECUTE FUNCTION public.instance_notification();


--
-- Name: instance instance_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_update AFTER UPDATE OF cited_by_id ON public.instance FOR EACH ROW EXECUTE FUNCTION public.instance_notification();


--
-- Name: name name_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER name_update AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE FUNCTION public.name_notification();


--
-- Name: reference reference_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reference_update AFTER INSERT OR DELETE OR UPDATE ON public.reference FOR EACH ROW EXECUTE FUNCTION public.reference_notification();


--
-- Name: profile_item set_profile_object_type; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_profile_object_type BEFORE INSERT OR UPDATE ON public.profile_item FOR EACH ROW EXECUTE FUNCTION public.profile_object_type_constraint();


--
-- Name: instance update_instance_synonyms_and_cache; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_instance_synonyms_and_cache AFTER INSERT OR UPDATE ON public.instance FOR EACH ROW EXECUTE FUNCTION public.update_synonyms_and_cache();


--
-- Name: batch_review batch_review_loader_batch_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review
    ADD CONSTRAINT batch_review_loader_batch_fk FOREIGN KEY (loader_batch_id) REFERENCES loader.loader_batch(id);


--
-- Name: batch_review_period batch_review_period_batch_review_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_period
    ADD CONSTRAINT batch_review_period_batch_review_fk FOREIGN KEY (batch_review_id) REFERENCES loader.batch_review(id);


--
-- Name: batch_reviewer batch_reviewer_batch_review_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_batch_review_fk FOREIGN KEY (batch_review_id) REFERENCES loader.batch_review(id);


--
-- Name: batch_reviewer batch_reviewer_review_role_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_review_role_fk FOREIGN KEY (batch_review_role_id) REFERENCES loader.batch_review_role(id);


--
-- Name: batch_reviewer batch_reviewer_user_org_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_user_org_fk FOREIGN KEY (org_id) REFERENCES public.org(id);


--
-- Name: batch_reviewer batch_reviewer_users_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: loader_name loader_name_loader_batch_id_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name
    ADD CONSTRAINT loader_name_loader_batch_id_fk FOREIGN KEY (loader_batch_id) REFERENCES loader.loader_batch(id);


--
-- Name: loader_name_match loader_name_match_instance_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_instance_fk FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: loader_name_match loader_name_match_loadr_nam_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_loadr_nam_fk FOREIGN KEY (loader_name_id) REFERENCES loader.loader_name(id);


--
-- Name: loader_name_match loader_name_match_name_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_name_fk FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: loader_name_match loader_name_match_rel_inst_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_rel_inst_fk FOREIGN KEY (relationship_instance_id) REFERENCES public.instance(id);


--
-- Name: loader_name_match loader_name_match_sta_inst_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_name_match_sta_inst_fk FOREIGN KEY (standalone_instance_id) REFERENCES public.instance(id);


--
-- Name: loader_name loader_name_parent_id_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name
    ADD CONSTRAINT loader_name_parent_id_fk FOREIGN KEY (parent_id) REFERENCES loader.loader_name(id);


--
-- Name: loader_name_match loader_nme_mtch_r_inst_type_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_name_match
    ADD CONSTRAINT loader_nme_mtch_r_inst_type_fk FOREIGN KEY (relationship_instance_type_id) REFERENCES public.instance_type(id);


--
-- Name: name_review_comment name_review_comment_period_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_comment_period_fk FOREIGN KEY (batch_review_period_id) REFERENCES loader.batch_review_period(id);


--
-- Name: name_review_comment name_review_comment_reviewer_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_comment_reviewer_fk FOREIGN KEY (batch_reviewer_id) REFERENCES loader.batch_reviewer(id);


--
-- Name: name_review_comment name_review_comment_type_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_comment_type_fk FOREIGN KEY (name_review_comment_type_id) REFERENCES loader.name_review_comment_type(id);


--
-- Name: name_review_comment name_review_loader_name_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_loader_name_fk FOREIGN KEY (loader_name_id) REFERENCES loader.loader_name(id);


--
-- Name: name_review_vote name_review_vote_batch_review_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_vote
    ADD CONSTRAINT name_review_vote_batch_review_fk FOREIGN KEY (batch_review_id) REFERENCES loader.batch_review(id);


--
-- Name: name_review_vote name_review_vote_loader_name_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_vote
    ADD CONSTRAINT name_review_vote_loader_name_fk FOREIGN KEY (loader_name_id) REFERENCES loader.loader_name(id);


--
-- Name: name_review_vote name_review_vote_org_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_vote
    ADD CONSTRAINT name_review_vote_org_fk FOREIGN KEY (org_id) REFERENCES public.org(id);


--
-- Name: loader_batch ref_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.loader_batch
    ADD CONSTRAINT ref_fk FOREIGN KEY (default_reference_id) REFERENCES public.reference(id);


--
-- Name: name_type fk_10d0jlulq2woht49j5ccpeehu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT fk_10d0jlulq2woht49j5ccpeehu FOREIGN KEY (name_category_id) REFERENCES public.name_category(id);


--
-- Name: name fk_156ncmx4599jcsmhh5k267cjv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_156ncmx4599jcsmhh5k267cjv FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: reference fk_1qx84m8tuk7vw2diyxfbj5r2n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_1qx84m8tuk7vw2diyxfbj5r2n FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: name_tag_name fk_22wdc2pxaskytkgpdgpyok07n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT fk_22wdc2pxaskytkgpdgpyok07n FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: name_tag_name fk_2uiijd73snf6lh5s6a82yjfin; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT fk_2uiijd73snf6lh5s6a82yjfin FOREIGN KEY (tag_id) REFERENCES public.name_tag(id);


--
-- Name: instance fk_30enb6qoexhuk479t75apeuu5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_30enb6qoexhuk479t75apeuu5 FOREIGN KEY (cites_id) REFERENCES public.instance(id);


--
-- Name: reference fk_3min66ljijxavb0fjergx5dpm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_3min66ljijxavb0fjergx5dpm FOREIGN KEY (duplicate_of_id) REFERENCES public.reference(id);


--
-- Name: name fk_3pqdqa03w5c6h4yyrrvfuagos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_3pqdqa03w5c6h4yyrrvfuagos FOREIGN KEY (duplicate_of_id) REFERENCES public.name(id);


--
-- Name: comment fk_3tfkdcmf6rg6hcyiu8t05er7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_3tfkdcmf6rg6hcyiu8t05er7x FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: tree fk_48skgw51tamg6ud4qa8oh0ycm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT fk_48skgw51tamg6ud4qa8oh0ycm FOREIGN KEY (default_draft_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: instance_resources fk_49ic33s4xgbdoa4p5j107rtpf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT fk_49ic33s4xgbdoa4p5j107rtpf FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: tree_version fk_4q3huja5dv8t9xyvt5rg83a35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT fk_4q3huja5dv8t9xyvt5rg83a35 FOREIGN KEY (tree_id) REFERENCES public.tree(id);


--
-- Name: ref_type fk_51alfoe7eobwh60yfx45y22ay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT fk_51alfoe7eobwh60yfx45y22ay FOREIGN KEY (parent_id) REFERENCES public.ref_type(id);


--
-- Name: name fk_5fpm5u0ukiml9nvmq14bd7u51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_5fpm5u0ukiml9nvmq14bd7u51 FOREIGN KEY (name_status_id) REFERENCES public.name_status(id);


--
-- Name: name fk_5gp2lfblqq94c4ud3340iml0l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_5gp2lfblqq94c4ud3340iml0l FOREIGN KEY (second_parent_id) REFERENCES public.name(id);


--
-- Name: name_type fk_5r3o78sgdbxsf525hmm3t44gv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT fk_5r3o78sgdbxsf525hmm3t44gv FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: tree_element fk_5sv181ivf7oybb6hud16ptmo5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT fk_5sv181ivf7oybb6hud16ptmo5 FOREIGN KEY (previous_element_id) REFERENCES public.tree_element(id);


--
-- Name: author fk_6a4p11f1bt171w09oo06m0wag; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT fk_6a4p11f1bt171w09oo06m0wag FOREIGN KEY (duplicate_of_id) REFERENCES public.author(id);


--
-- Name: resource_type fk_6nxjoae1hvplngbvpo0k57jjt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource_type
    ADD CONSTRAINT fk_6nxjoae1hvplngbvpo0k57jjt FOREIGN KEY (media_icon_id) REFERENCES public.media(id);


--
-- Name: comment fk_6oqj6vquqc33cyawn853hfu5g; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_6oqj6vquqc33cyawn853hfu5g FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: tree_version_element fk_80khvm60q13xwqgpy43twlnoe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_80khvm60q13xwqgpy43twlnoe FOREIGN KEY (tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: instance_resources fk_8mal9hru5u3ypaosfoju8ulpd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT fk_8mal9hru5u3ypaosfoju8ulpd FOREIGN KEY (resource_id) REFERENCES public.resource(id);


--
-- Name: tree_version_element fk_8nnhwv8ldi9ppol6tg4uwn4qv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_8nnhwv8ldi9ppol6tg4uwn4qv FOREIGN KEY (parent_id) REFERENCES public.tree_version_element(element_link);


--
-- Name: comment fk_9aq5p2jgf17y6b38x5ayd90oc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_9aq5p2jgf17y6b38x5ayd90oc FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: reference fk_a98ei1lxn89madjihel3cvi90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_a98ei1lxn89madjihel3cvi90 FOREIGN KEY (ref_author_role_id) REFERENCES public.ref_author_role(id);


--
-- Name: name fk_ai81l07vh2yhmthr3582igo47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_ai81l07vh2yhmthr3582igo47 FOREIGN KEY (sanctioning_author_id) REFERENCES public.author(id);


--
-- Name: name fk_airfjupm6ohehj1lj82yqkwdx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_airfjupm6ohehj1lj82yqkwdx FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: reference fk_am2j11kvuwl19gqewuu18gjjm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_am2j11kvuwl19gqewuu18gjjm FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: name fk_bcef76k0ijrcquyoc0yxehxfp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_bcef76k0ijrcquyoc0yxehxfp FOREIGN KEY (name_type_id) REFERENCES public.name_type(id);


--
-- Name: instance_note fk_bw41122jb5rcu8wfnog812s97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_bw41122jb5rcu8wfnog812s97 FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: name fk_coqxx3ewgiecsh3t78yc70b35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_coqxx3ewgiecsh3t78yc70b35 FOREIGN KEY (base_author_id) REFERENCES public.author(id);


--
-- Name: dist_entry_dist_status fk_cpmfv1d7wlx26gjiyxrebjvxn; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry_dist_status
    ADD CONSTRAINT fk_cpmfv1d7wlx26gjiyxrebjvxn FOREIGN KEY (dist_entry_status_id) REFERENCES public.dist_entry(id);


--
-- Name: reference fk_cr9avt4miqikx4kk53aflnnkd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_cr9avt4miqikx4kk53aflnnkd FOREIGN KEY (parent_id) REFERENCES public.reference(id);


--
-- Name: name fk_dd33etb69v5w5iah1eeisy7yt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_dd33etb69v5w5iah1eeisy7yt FOREIGN KEY (parent_id) REFERENCES public.name(id);


--
-- Name: reference fk_dm9y4p9xpsc8m7vljbohubl7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_dm9y4p9xpsc8m7vljbohubl7x FOREIGN KEY (ref_type_id) REFERENCES public.ref_type(id);


--
-- Name: instance_note fk_f6s94njexmutjxjv8t5dy1ugt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_f6s94njexmutjxjv8t5dy1ugt FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: dist_entry fk_ffleu7615efcrsst8l64wvomw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry
    ADD CONSTRAINT fk_ffleu7615efcrsst8l64wvomw FOREIGN KEY (region_id) REFERENCES public.dist_region(id);


--
-- Name: tree_element_distribution_entries fk_fmic32f9o0fplk3xdix1yu6ha; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT fk_fmic32f9o0fplk3xdix1yu6ha FOREIGN KEY (tree_element_id) REFERENCES public.tree_element(id);


--
-- Name: dist_status_dist_status fk_g38me2w6f5ismhdjbj8je7nv0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_status_dist_status
    ADD CONSTRAINT fk_g38me2w6f5ismhdjbj8je7nv0 FOREIGN KEY (dist_status_id) REFERENCES public.dist_status(id);


--
-- Name: name_status fk_g4o6xditli5a0xrm6eqc6h9gw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT fk_g4o6xditli5a0xrm6eqc6h9gw FOREIGN KEY (name_status_id) REFERENCES public.name_status(id);


--
-- Name: instance fk_gdunt8xo68ct1vfec9c6x5889; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_gdunt8xo68ct1vfec9c6x5889 FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: name_resources fk_goyj9wmbb1y4a6y4q5ww3nhby; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_resources
    ADD CONSTRAINT fk_goyj9wmbb1y4a6y4q5ww3nhby FOREIGN KEY (resource_id) REFERENCES public.resource(id);


--
-- Name: instance fk_gtkjmbvk6uk34fbfpy910e7t6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_gtkjmbvk6uk34fbfpy910e7t6 FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: tree_element_distribution_entries fk_h7k45ugqa75w0860tysr4fgrt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element_distribution_entries
    ADD CONSTRAINT fk_h7k45ugqa75w0860tysr4fgrt FOREIGN KEY (dist_entry_id) REFERENCES public.dist_entry(id);


--
-- Name: comment fk_h9t5eaaqhnqwrc92rhryyvdcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_h9t5eaaqhnqwrc92rhryyvdcf FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: instance fk_hb0xb97midopfgrm2k5fpe3p1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_hb0xb97midopfgrm2k5fpe3p1 FOREIGN KEY (parent_id) REFERENCES public.instance(id);


--
-- Name: instance_note fk_he1t3ug0o7ollnk2jbqaouooa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_he1t3ug0o7ollnk2jbqaouooa FOREIGN KEY (instance_note_key_id) REFERENCES public.instance_note_key(id);


--
-- Name: resource fk_i2tgkebwedao7dlbjcrnvvtrv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT fk_i2tgkebwedao7dlbjcrnvvtrv FOREIGN KEY (resource_type_id) REFERENCES public.resource_type(id);


--
-- Name: dist_entry_dist_status fk_jnh4hl7ev54cknuwm5juvb22i; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_entry_dist_status
    ADD CONSTRAINT fk_jnh4hl7ev54cknuwm5juvb22i FOREIGN KEY (dist_status_id) REFERENCES public.dist_status(id);


--
-- Name: resource fk_l76e0lo0edcngyyqwkmkgywj9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT fk_l76e0lo0edcngyyqwkmkgywj9 FOREIGN KEY (site_id) REFERENCES public.site(id);


--
-- Name: instance fk_lumlr5avj305pmc4hkjwaqk45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_lumlr5avj305pmc4hkjwaqk45 FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: name_resources fk_nhx4nd4uceqs7n5abwfeqfun5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_resources
    ADD CONSTRAINT fk_nhx4nd4uceqs7n5abwfeqfun5 FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: instance fk_o80rrtl8xwy4l3kqrt9qv0mnt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_o80rrtl8xwy4l3kqrt9qv0mnt FOREIGN KEY (instance_type_id) REFERENCES public.instance_type(id);


--
-- Name: author fk_p0ysrub11cm08xnhrbrfrvudh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT fk_p0ysrub11cm08xnhrbrfrvudh FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: name_rank fk_p3lpayfbl9s3hshhoycfj82b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT fk_p3lpayfbl9s3hshhoycfj82b9 FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: reference fk_p8lhsoo01164dsvvwxob0w3sp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_p8lhsoo01164dsvvwxob0w3sp FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: instance fk_pr2f6peqhnx9rjiwkr5jgc5be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_pr2f6peqhnx9rjiwkr5jgc5be FOREIGN KEY (cited_by_id) REFERENCES public.instance(id);


--
-- Name: dist_status_dist_status fk_q0p6tn5peagvsl7xmqcy39yuh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dist_status_dist_status
    ADD CONSTRAINT fk_q0p6tn5peagvsl7xmqcy39yuh FOREIGN KEY (dist_status_combining_status_id) REFERENCES public.dist_status(id);


--
-- Name: id_mapper fk_qiy281xsleyhjgr0eu1sboagm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT fk_qiy281xsleyhjgr0eu1sboagm FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: name_rank fk_r67um91pujyfrx7h1cifs3cmb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT fk_r67um91pujyfrx7h1cifs3cmb FOREIGN KEY (parent_rank_id) REFERENCES public.name_rank(id);


--
-- Name: name fk_rp659tjcxokf26j8551k6an2y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_rp659tjcxokf26j8551k6an2y FOREIGN KEY (ex_base_author_id) REFERENCES public.author(id);


--
-- Name: name fk_sgvxmyj7r9g4wy9c4hd1yn4nu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_sgvxmyj7r9g4wy9c4hd1yn4nu FOREIGN KEY (ex_author_id) REFERENCES public.author(id);


--
-- Name: name fk_sk2iikq8wla58jeypkw6h74hc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_sk2iikq8wla58jeypkw6h74hc FOREIGN KEY (name_rank_id) REFERENCES public.name_rank(id);


--
-- Name: tree fk_svg2ee45qvpomoer2otdc5oyc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT fk_svg2ee45qvpomoer2otdc5oyc FOREIGN KEY (current_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: name_status fk_swotu3c2gy1hp8f6ekvuo7s26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT fk_swotu3c2gy1hp8f6ekvuo7s26 FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: tree_version fk_tiniptsqbb5fgygt1idm1isfy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT fk_tiniptsqbb5fgygt1idm1isfy FOREIGN KEY (previous_version_id) REFERENCES public.tree_version(id);


--
-- Name: tree_version_element fk_ufme7yt6bqyf3uxvuvouowhh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_ufme7yt6bqyf3uxvuvouowhh FOREIGN KEY (tree_element_id) REFERENCES public.tree_element(id);


--
-- Name: name fk_whce6pgnqjtxgt67xy2lfo34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_whce6pgnqjtxgt67xy2lfo34 FOREIGN KEY (family_id) REFERENCES public.name(id);


--
-- Name: instance_resource instance_resource_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resource
    ADD CONSTRAINT instance_resource_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: instance_resource instance_resource_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resource
    ADD CONSTRAINT instance_resource_resource_id_fkey FOREIGN KEY (resource_host_id) REFERENCES public.resource_host(id);


--
-- Name: name name_basionym_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT name_basionym_id_fkey FOREIGN KEY (basionym_id) REFERENCES public.name(id);


--
-- Name: name name_primary_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT name_primary_instance_id_fkey FOREIGN KEY (primary_instance_id) REFERENCES public.instance(id);


--
-- Name: name_resource name_resource_name_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_resource
    ADD CONSTRAINT name_resource_name_id_fkey FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: name_resource name_resource_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_resource
    ADD CONSTRAINT name_resource_resource_id_fkey FOREIGN KEY (resource_host_id) REFERENCES public.resource_host(id);


--
-- Name: product_role pr_product_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT pr_product_fk FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: product_role pr_role_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT pr_role_fk FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: product_item_config product_item_config_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_item_config
    ADD CONSTRAINT product_item_config_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: product_item_config product_item_config_profile_item_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_item_config
    ADD CONSTRAINT product_item_config_profile_item_type_id_fkey FOREIGN KEY (profile_item_type_id) REFERENCES public.profile_item_type(id);


--
-- Name: product product_reference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: product product_tree_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_tree_id_fkey FOREIGN KEY (tree_id) REFERENCES public.tree(id);


--
-- Name: profile_item_annotation profile_item_annotation_profile_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_annotation
    ADD CONSTRAINT profile_item_annotation_profile_item_id_fkey FOREIGN KEY (profile_item_id) REFERENCES public.profile_item(id);


--
-- Name: profile_item profile_item_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: profile_item profile_item_product_item_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_product_item_config_id_fkey FOREIGN KEY (product_item_config_id) REFERENCES public.product_item_config(id);


--
-- Name: profile_item profile_item_profile_object_rdf_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_profile_object_rdf_id_fkey FOREIGN KEY (profile_object_rdf_id) REFERENCES public.profile_object_type(rdf_id);


--
-- Name: profile_item profile_item_profile_text_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_profile_text_id_fkey FOREIGN KEY (profile_text_id) REFERENCES public.profile_text(id);


--
-- Name: profile_item_reference profile_item_reference_profile_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_reference
    ADD CONSTRAINT profile_item_reference_profile_item_id_fkey FOREIGN KEY (profile_item_id) REFERENCES public.profile_item(id);


--
-- Name: profile_item_reference profile_item_reference_reference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_reference
    ADD CONSTRAINT profile_item_reference_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: profile_item profile_item_source_profile_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_source_profile_item_id_fkey FOREIGN KEY (source_profile_item_id) REFERENCES public.profile_item(id);


--
-- Name: profile_item profile_item_tree_element_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item
    ADD CONSTRAINT profile_item_tree_element_id_fkey FOREIGN KEY (tree_element_id) REFERENCES public.tree_element(id);


--
-- Name: profile_item_type profile_item_type_profile_object_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profile_item_type
    ADD CONSTRAINT profile_item_type_profile_object_type_id_fkey FOREIGN KEY (profile_object_type_id) REFERENCES public.profile_object_type(id);


--
-- Name: reference_resource reference_resource_reference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference_resource
    ADD CONSTRAINT reference_resource_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: reference_resource reference_resource_resource_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference_resource
    ADD CONSTRAINT reference_resource_resource_id_fkey FOREIGN KEY (resource_host_id) REFERENCES public.resource_host(id);


--
-- Name: tree_element tree_element_first_tree_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT tree_element_first_tree_version_id_fkey FOREIGN KEY (first_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: user_product_role upr_product_role_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_product_role
    ADD CONSTRAINT upr_product_role_fk FOREIGN KEY (product_role_id) REFERENCES public.product_role(id);


--
-- Name: user_product_role upr_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_product_role
    ADD CONSTRAINT upr_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO public, loader;



