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

CREATE SCHEMA if not exists loader;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA if not exists public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION if not exists btree_gist WITH SCHEMA public;
CREATE EXTENSION if not exists unaccent WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;

--
-- Name: accepted_status(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.xaccepted_status(nameid bigint) RETURNS text
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

CREATE FUNCTION public.get_hstore_tree(tve_id text) RETURNS public.hstore
    LANGUAGE plpgsql
    AS $$
			DECLARE
				current_id     text   := tve_id;
				result_hstore  hstore := '';
				current_record RECORD;
			BEGIN
				LOOP
					-- Fetch the record of the current node
					-- Exit the loop if there is no parent

					SELECT tve.parent_id,
					       n.name_element,
					       r.rdf_id
					into current_record
					FROM tree_version_element tve
						     JOIN tree_element te ON tve.tree_element_id = te.id
						     JOIN name n ON te.name_id = n.id
						     JOIN name_rank r ON n.name_rank_id = r.id
					WHERE tve.element_link = current_id;

					EXIT WHEN current_record IS NULL;
					-- Exit if the node does not exist

					-- Add the current node's rank and name_element to the hstore
					result_hstore := result_hstore || hstore(current_record.rdf_id::text, current_record.name_element);

					-- Move up to the parent
					current_id := current_record.parent_id;

					-- Exit the loop if there is no parent
					EXIT WHEN current_id IS NULL;
				END LOOP;

				RETURN result_hstore;
			END
			$$;


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
-- Name: nsl_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nsl_global_seq
    START WITH 1
    INCREMENT BY 1
    CACHE 1;

CREATE SEQUENCE loader.nsl_global_seq
    START WITH 1
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
    uri text
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
    CONSTRAINT check_iso_date CHECK (public.is_iso8601(iso_publication_date)),
    CONSTRAINT parent_not_self CHECK ((parent_id <> id))
);


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
    is_read_only boolean DEFAULT false,
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

CREATE MATERIALIZED VIEW public.name_mv AS
 WITH shard AS MATERIALIZED (
         SELECT jsonb_object_agg(shard_config.name, shard_config.value) AS cfg
           FROM public.shard_config
        )
 SELECT nv.name_id,
    nv.basionym_id,
    nv.scientific_name,
    nv.scientific_name_html,
    nv.canonical_name,
    nv.canonical_name_html,
    nv.name_element,
    nv.scientific_name_id,
    nv.name_type,
    nv.nomenclatural_status,
    nv.scientific_name_authorship,
    nv.changed_combination,
    nv.autonym,
    nv.hybrid,
    nv.cultivar,
    nv.formula,
    nv.scientific,
    nv.nom_inval,
    nv.nom_illeg,
    nv.name_published_in,
    nv.name_published_in_id,
    nv.name_published_in_year,
    nv.name_instance_type,
    nv.name_according_to_id,
    nv.name_according_to,
    nv.original_name_usage,
    nv.original_name_usage_id,
    nv.original_name_usage_year,
    nv.type_citation,
    nv.kingdom,
    nv.family,
    nv.uninomial,
    nv.infrageneric_epithet,
    nv.generic_name,
    nv.specific_epithet,
    nv.infraspecific_epithet,
    nv.cultivar_epithet,
    nv.rank_rdf_id,
    nv.taxon_rank,
    nv.taxon_rank_sort_order,
    nv.taxon_rank_abbreviation,
    nv.first_hybrid_parent_name,
    nv.first_hybrid_parent_name_id,
    nv.second_hybrid_parent_name,
    nv.second_hybrid_parent_name_id,
    nv.created,
    nv.modified,
    nv.nomenclatural_code,
    nv.dataset_name,
    nv.taxonomic_status,
    nv.nsl_accepted,
    nv.status_according_to,
    nv.license,
    nv.cc_attribution_iri
   FROM ( SELECT DISTINCT ON (n.id) n.id AS name_id,
            basionym_inst.name_id AS basionym_id,
            n.full_name AS scientific_name,
            n.full_name_html AS scientific_name_html,
            n.simple_name AS canonical_name,
            n.simple_name_html AS canonical_name_html,
            n.name_element,
            ((shard.cfg ->> 'mapper host'::text) || n.uri) AS scientific_name_id,
            nt.rdf_id AS name_type,
                CASE
                    WHEN ((ns.rdf_id)::text !~ 'default'::text) THEN ns.name
                    ELSE NULL::character varying
                END AS nomenclatural_status,
                CASE ng.rdf_id
                    WHEN 'zoological'::text THEN
                    CASE
                        WHEN n.changed_combination THEN ((('('::text || (a.abbrev)::text) || COALESCE((', '::text || n.published_year), ''::text)) || ')'::text)
                        ELSE ((a.abbrev)::text || COALESCE((', '::text || n.published_year), ''::text))
                    END
                    WHEN 'botanical'::text THEN
                    CASE
                        WHEN nt.autonym THEN NULL::text
                        ELSE (COALESCE(((('('::text || COALESCE(((xb.abbrev)::text || ' ex '::text), ''::text)) || (b.abbrev)::text) || ') '::text), ''::text) || COALESCE((COALESCE(((xa.abbrev)::text || ' ex '::text), ''::text) || (a.abbrev)::text), ''::text))
                    END
                    ELSE NULL::text
                END AS scientific_name_authorship,
            COALESCE(((n.base_author_id)::integer)::boolean, n.changed_combination) AS changed_combination,
            nt.autonym,
            nt.hybrid,
            nt.cultivar,
            nt.formula,
            nt.scientific,
            ns.nom_inval,
            ns.nom_illeg,
                CASE
                    WHEN ((COALESCE(primary_ref.abbrev_title, 'null'::character varying))::text <> 'AFD'::text) THEN ((((primary_ref.citation)::text || ' ['::text) || (primary_inst.page)::text) || ']'::text)
                    ELSE NULL::text
                END AS name_published_in,
                CASE
                    WHEN ((COALESCE(primary_ref.abbrev_title, 'null'::character varying))::text <> 'AFD'::text) THEN (((((shard.cfg ->> 'mapper host'::text) || 'reference/'::text) || (shard.cfg ->> 'services path name element'::text)) || '/'::text) || primary_ref.id)
                    ELSE NULL::text
                END AS name_published_in_id,
                CASE
                    WHEN ((COALESCE(primary_ref.abbrev_title, 'null'::character varying))::text <> 'AFD'::text) THEN (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer
                    ELSE NULL::integer
                END AS name_published_in_year,
            primary_it.name AS name_instance_type,
            ((shard.cfg ->> 'mapper host'::text) || primary_inst.uri) AS name_according_to_id,
            ((primary_auth.name)::text ||
                CASE
                    WHEN (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying) IS NOT NULL) THEN ((' ('::text || (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying))::text) || ')'::text)
                    ELSE NULL::text
                END) AS name_according_to,
            basionym.full_name AS original_name_usage,
                CASE
                    WHEN (basionym_inst.id IS NOT NULL) THEN ((shard.cfg ->> 'mapper host'::text) || basionym_inst.uri)
                    ELSE NULL::text
                END AS original_name_usage_id,
            COALESCE(substr((basionym_ref.iso_publication_date)::text, 1, 4), (basionym_ref.year)::text) AS original_name_usage_year,
                CASE
                    WHEN ((nt.autonym = true) AND (parent_name.id IS NOT NULL)) THEN (parent_name.full_name)::text
                    ELSE ( SELECT string_agg(regexp_replace((((key1.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text) AS string_agg
                       FROM (public.instance_note note
                         JOIN public.instance_note_key key1 ON (((key1.id = note.instance_note_key_id) AND ((key1.rdf_id)::text ~* 'type$'::text))))
                      WHERE (note.instance_id = ANY (ARRAY[primary_inst.id, basionym_inst.cites_id])))
                END AS type_citation,
            COALESCE(( SELECT find_tree_rank.name_element
                   FROM public.find_tree_rank(COALESCE(tve.element_link, tve2.element_link), kingdom.sort_order) find_tree_rank(name_element, rank, sort_order)),
                CASE
                    WHEN ((shard.cfg ->> 'nomenclatural code'::text) = 'ICN'::text) THEN 'Plantae'::text
                    WHEN ((shard.cfg ->> 'nomenclatural code'::text) = 'ICZN'::text) THEN 'Animalia'::text
                    ELSE NULL::text
                END) AS kingdom,
                CASE
                    WHEN (rank.sort_order > family.sort_order) THEN COALESCE(( SELECT find_tree_rank.name_element
                       FROM public.find_tree_rank(COALESCE(tve.element_link, tve2.element_link), family.sort_order) find_tree_rank(name_element, rank, sort_order)), ( SELECT find_tree_rank.name_element
                       FROM public.find_tree_rank(COALESCE(( SELECT tvg.element_link
                               FROM (public.tree_version_element tvg
                                 JOIN public.tree_element e ON (((tvg.tree_element_id = e.id) AND (e.name_id = ((( SELECT public.name_walk(n.id, 'genus'::text) AS name_walk) ->> 'id'::text))::bigint))))
                             LIMIT 1), ( SELECT tvs.element_link
                               FROM ((public.tree_version_element tvs
                                 JOIN public.tree_element es ON ((tvs.tree_element_id = es.id)))
                                 JOIN public.instance gi ON (((es.instance_id = gi.cited_by_id) AND (gi.name_id = ((( SELECT public.name_walk(n.id, 'genus'::text) AS name_walk) ->> 'id'::text))::bigint))))
                             LIMIT 1)), family.sort_order) find_tree_rank(name_element, rank, sort_order)), (( SELECT f.name_element
                       FROM (public.name f
                         JOIN public.name g ON (((g.family_id = f.id) AND (g.id = ((( SELECT public.name_walk(n.id, 'genus'::text) AS name_walk) ->> 'id'::text))::bigint))))))::text, (family_name.name_element)::text)
                    ELSE NULL::text
                END AS family,
                CASE
                    WHEN (((COALESCE(n.simple_name, ' '::character varying))::text !~ '\s'::text) AND ((n.simple_name)::text = (n.name_element)::text) AND (rank.sort_order <= genus.sort_order)) THEN n.simple_name
                    ELSE NULL::character varying
                END AS uninomial,
                CASE
                    WHEN (((pk.rdf_id)::text = 'genus'::text) AND ((rank.rdf_id)::text <> 'species'::text)) THEN n.name_element
                    ELSE NULL::character varying
                END AS infrageneric_epithet,
                CASE
                    WHEN (rank.sort_order >= genus.sort_order) THEN COALESCE((public.name_walk(n.id, 'genus'::text) ->> 'element'::text), ((array_remove(string_to_array(regexp_replace(rtrim(substr((n.simple_name)::text, 1, (length((n.simple_name)::text) - length((n.name_element)::text)))), '(^cf\. |^aff[,.] )'::text, ''::text, 'i'::text), ' '::text), 'x'::text) || (n.name_element)::text))[1])
                    ELSE NULL::text
                END AS generic_name,
                CASE
                    WHEN (rank.sort_order > species.sort_order) THEN COALESCE((public.name_walk(n.id, 'species'::text) ->> 'element'::text), ((array_remove(string_to_array(regexp_replace(rtrim(substr((n.simple_name)::text, 1, (length((n.simple_name)::text) - length((n.name_element)::text)))), '(^cf\. |^aff[,.] )'::text, ''::text, 'i'::text), ' '::text), 'x'::text) || (n.name_element)::text))[2])
                    WHEN (rank.sort_order = species.sort_order) THEN (n.name_element)::text
                    ELSE NULL::text
                END AS specific_epithet,
                CASE
                    WHEN (rank.sort_order > species.sort_order) THEN n.name_element
                    ELSE NULL::character varying
                END AS infraspecific_epithet,
                CASE
                    WHEN (nt.cultivar = true) THEN n.name_element
                    ELSE NULL::character varying
                END AS cultivar_epithet,
            rank.rdf_id AS rank_rdf_id,
            rank.name AS taxon_rank,
            rank.sort_order AS taxon_rank_sort_order,
            rank.abbrev AS taxon_rank_abbreviation,
            first_hybrid_parent.full_name AS first_hybrid_parent_name,
            ((shard.cfg ->> 'mapper host'::text) || first_hybrid_parent.uri) AS first_hybrid_parent_name_id,
            second_hybrid_parent.full_name AS second_hybrid_parent_name,
            ((shard.cfg ->> 'mapper host'::text) || second_hybrid_parent.uri) AS second_hybrid_parent_name_id,
            n.created_at AS created,
            n.updated_at AS modified,
            (shard.cfg ->> 'nomenclatural code'::text) AS nomenclatural_code,
            (shard.cfg ->> 'name label'::text) AS dataset_name,
                CASE
                    WHEN t.accepted_tree THEN
                    CASE
                        WHEN te.excluded THEN 'excluded'::text
                        ELSE 'accepted'::text
                    END
                    WHEN t2.accepted_tree THEN
                    CASE
                        WHEN te2.excluded THEN 'excluded'::text
                        ELSE 'included'::text
                    END
                    ELSE 'unplaced'::text
                END AS taxonomic_status,
                CASE
                    WHEN t.accepted_tree THEN
                    CASE
                        WHEN te.excluded THEN false
                        ELSE true
                    END
                    ELSE NULL::boolean
                END AS nsl_accepted,
            accepted_tree.name AS status_according_to,
            'https://creativecommons.org/licenses/by/3.0/'::text AS license,
            ((shard.cfg ->> 'mapper host'::text) || n.uri) AS cc_attribution_iri
           FROM ((((((((((((((((((((((public.name n
             JOIN public.name_type nt ON ((n.name_type_id = nt.id)))
             JOIN public.name_group ng ON ((ng.id = nt.name_group_id)))
             JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
             LEFT JOIN public.name parent_name ON ((n.parent_id = parent_name.id)))
             LEFT JOIN public.name family_name ON ((n.family_id = family_name.id)))
             LEFT JOIN public.author b ON ((n.base_author_id = b.id)))
             LEFT JOIN public.author xb ON ((n.ex_base_author_id = xb.id)))
             LEFT JOIN public.author a ON ((n.author_id = a.id)))
             LEFT JOIN public.author xa ON ((n.ex_author_id = xa.id)))
             LEFT JOIN public.name first_hybrid_parent ON (((n.parent_id = first_hybrid_parent.id) AND nt.hybrid)))
             LEFT JOIN public.name second_hybrid_parent ON (((n.second_parent_id = second_hybrid_parent.id) AND nt.hybrid)))
             LEFT JOIN (((public.instance primary_inst
             JOIN public.instance_type primary_it ON (((primary_it.id = primary_inst.instance_type_id) AND primary_it.primary_instance)))
             JOIN public.reference primary_ref ON ((primary_inst.reference_id = primary_ref.id)))
             JOIN public.author primary_auth ON ((primary_ref.author_id = primary_auth.id))) ON ((primary_inst.name_id = n.id)))
             LEFT JOIN ((((public.instance basionym_rel
             JOIN public.instance_type bt ON (((bt.id = basionym_rel.instance_type_id) AND ((bt.rdf_id)::text ~ '(basionym|primary-synonym)'::text))))
             JOIN public.instance basionym_inst ON ((basionym_rel.cites_id = basionym_inst.id)))
             JOIN public.name basionym ON ((basionym.id = basionym_inst.name_id)))
             JOIN public.reference basionym_ref ON ((basionym_inst.reference_id = basionym_ref.id))) ON ((basionym_rel.cited_by_id = primary_inst.id)))
             LEFT JOIN shard ON (true))
             JOIN public.name_rank kingdom ON (((kingdom.rdf_id)::text ~ '(regnum|kingdom)'::text)))
             JOIN public.name_rank family ON (((family.rdf_id)::text ~ '(^family|^familia)'::text)))
             JOIN public.name_rank genus ON (((genus.rdf_id)::text = 'genus'::text)))
             JOIN public.name_rank species ON (((species.rdf_id)::text = 'species'::text)))
             JOIN (public.name_rank rank
             LEFT JOIN public.name_rank pk ON ((rank.parent_rank_id = pk.id))) ON ((n.name_rank_id = rank.id)))
             JOIN public.tree accepted_tree ON (accepted_tree.accepted_tree))
             LEFT JOIN ((public.tree_element te
             JOIN public.tree_version_element tve ON ((te.id = tve.tree_element_id)))
             JOIN public.tree t ON (((tve.tree_version_id = t.current_tree_version_id) AND t.accepted_tree))) ON ((te.name_id = n.id)))
             LEFT JOIN (((public.instance s
             JOIN public.tree_element te2 ON ((te2.instance_id = s.cited_by_id)))
             JOIN public.tree_version_element tve2 ON ((te2.id = tve2.tree_element_id)))
             JOIN public.tree t2 ON (((tve2.tree_version_id = t2.current_tree_version_id) AND t2.accepted_tree))) ON ((s.name_id = n.id)))
          WHERE ((EXISTS ( SELECT 1
                   FROM public.instance
                  WHERE (instance.name_id = n.id))) AND ((nt.rdf_id)::text !~ '(common|vernacular)'::text) AND ((n.name_element)::text !~* 'unplaced'::text) AND ((n.name_path !~ '^C[MLAF]/'::text) OR (n.name_path IS NULL)))
          ORDER BY n.id,
                CASE
                    WHEN ((COALESCE(primary_ref.abbrev_title, 'null'::character varying))::text <> 'AFD'::text) THEN (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer
                    ELSE NULL::integer
                END, COALESCE(substr((basionym_ref.iso_publication_date)::text, 1, 4), (basionym_ref.year)::text)) nv
  ORDER BY nv.family, nv.generic_name, nv.specific_epithet, nv.infraspecific_epithet, nv.cultivar_epithet
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW name_mv; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.name_mv IS 'A snake_case listing of a shard''s scientific_names with status according to the current default tree version,using Darwin_Core semantics';


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
          WHERE (instance_type.nomenclatural AND ((instance_type.rdf_id)::text ~ '(basionym|replaced)'::text))
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
          WHERE (instance_type.nomenclatural AND ((instance_type.rdf_id)::text ~ '(orthographic|alternative)'::text))
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
            COALESCE(br.iso_publication_date, ir.iso_publication_date, ((n_1.published_year)::text)::character varying) AS primary_date,
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
           FROM ((((((((((public.name n_1
             JOIN public.name_type nt ON ((n_1.name_type_id = nt.id)))
             JOIN public.name_rank nk ON ((n_1.name_rank_id = nk.id)))
             LEFT JOIN public.name np ON ((np.id = n_1.parent_id)))
             LEFT JOIN public.instance i ON ((i.name_id = n_1.id)))
             JOIN public.instance_type it ON (((i.instance_type_id = it.id) AND it.standalone)))
             JOIN public.reference ir ON ((i.reference_id = ir.id)))
             LEFT JOIN ((public.instance er
             JOIN bt ON ((er.instance_type_id = bt.id)))
             JOIN ((public.instance bu
             JOIN public.instance_type ut ON ((bu.instance_type_id = ut.id)))
             JOIN public.reference br ON ((bu.reference_id = br.id))) ON ((bu.id = er.cites_id))) ON ((i.id = er.cited_by_id)))
             LEFT JOIN ((((public.instance ou
             JOIN ot ON ((ot.id = ou.instance_type_id)))
             JOIN public.instance oi ON ((oi.id = ou.cited_by_id)))
             LEFT JOIN public.instance oo ON ((oo.name_id = oi.name_id)))
             JOIN pt ON ((oo.instance_type_id = pt.id))) ON ((ou.cites_id = i.id)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))
          ORDER BY i.name_id, it.standalone DESC, it.primary_instance DESC, n_1.verbatim_rank, it.sort_order, it.secondary_instance DESC
        )
 SELECT pi.name_id,
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
   FROM (((public.name n
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

CREATE MATERIALIZED VIEW public.taxon_mv AS
 WITH it AS (
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
            instance_type.alignment,
            (((((((((((
                CASE
                    WHEN ((instance_type.rdf_id)::text ~ '(excluded|intercepted|vagrant)'::text) THEN '1'::text
                    ELSE '0'::text
                END ||
                CASE
                    WHEN ((instance_type.rdf_id)::text ~ '(common|vernacular)'::text) THEN '1'::text
                    ELSE '0'::text
                END) ||
                CASE
                    WHEN ((instance_type.rdf_id)::text ~ '(taxonomy|synonymy)'::text) THEN '1'::text
                    ELSE '0'::text
                END) ||
                CASE
                    WHEN ((instance_type.rdf_id)::text ~ 'miscellaneous'::text) THEN '1'::text
                    ELSE '0'::text
                END) || ((instance_type.misapplied)::integer)::text) ||
                CASE
                    WHEN ((instance_type.rdf_id)::text ~ '(generic-combination|heterotypic-combination)'::text) THEN '1'::text
                    ELSE '0'::text
                END) || ((instance_type.taxonomic)::integer)::text) || ((instance_type.nomenclatural)::integer)::text) ||
                CASE
                    WHEN ((instance_type.rdf_id)::text ~ 'isonym'::text) THEN '0'::text
                    ELSE '1'::text
                END) || ((instance_type.standalone)::integer)::text) || ((instance_type.primary_instance)::integer)::text) || ((instance_type.protologue)::integer)::text) AS itorder
           FROM public.instance_type
          WHERE ((instance_type.rdf_id)::text !~* '(isonym|common|vernacular|trade|synonymy|taxonomy|designation|secondary-source|miscellaneous|misidentification)'::text)
        )
 SELECT
        CASE
            WHEN (e.instance_id = i.id) THEN (rtrim((mapper_host.value)::text, '/'::text) || tve.taxon_link)
            ELSE ((mapper_host.value)::text || i.uri)
        END AS taxon_id,
    nt.name AS name_type,
    (rtrim((mapper_host.value)::text, '/'::text) || tve.taxon_link) AS accepted_name_usage_id,
    COALESCE(x.full_name, n.full_name) AS accepted_name_usage,
        CASE
            WHEN ((ns.rdf_id)::text !~ 'default'::text) THEN ns.name
            ELSE NULL::character varying
        END AS nomenclatural_status,
        CASE
            WHEN (i.cited_by_id IS NOT NULL) THEN (it.name)::text
            WHEN e.excluded THEN 'excluded'::text
            ELSE 'accepted'::text
        END AS taxonomic_status,
    it.pro_parte,
    n.full_name AS scientific_name,
    ns.nom_illeg,
    ns.nom_inval,
    ((mapper_host.value)::text || n.uri) AS scientific_name_id,
    n.simple_name AS canonical_name,
        CASE
            WHEN ((ng.rdf_id)::text = 'zoological'::text) THEN (( SELECT author.abbrev
               FROM public.author
              WHERE (author.id = n.author_id)))::text
            WHEN nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((n.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS scientific_name_authorship,
        CASE
            WHEN (i.cited_by_id IS NOT NULL) THEN NULL::text
            ELSE NULLIF((rtrim((mapper_host.value)::text, '/'::text) || pve.taxon_link), rtrim((mapper_host.value)::text, '/'::text))
        END AS parent_name_usage_id,
    k.name AS taxon_rank,
    k.sort_order AS taxon_rank_sort_order,
    'x' as kingdom,
    'x' as class,
    'x' as subclass,
    'x' as family,
    concat(mapper_host.value, 'instance/', p.value, '/', e.instance_id) AS taxon_concept_id,
    r.citation AS name_according_to,
    concat(mapper_host.value, 'reference/', p.value, '/', r.id) AS name_according_to_id,
        CASE
            WHEN (i.cited_by_id IS NOT NULL) THEN NULL::text
            ELSE ((e.profile -> (t.config ->> 'comment_key'::text)) ->> 'value'::text)
        END AS taxon_remarks,
        CASE
            WHEN (i.cited_by_id IS NOT NULL) THEN NULL::text
            ELSE ((e.profile -> (t.config ->> 'distribution_key'::text)) ->> 'value'::text)
        END AS taxon_distribution,
    regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text) AS higher_classification,
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS first_hybrid_parent_name,
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ((mapper_host.value)::text || firsthybridparent.uri)
            ELSE NULL::text
        END AS first_hybrid_parent_name_id,
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS second_hybrid_parent_name,
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ((mapper_host.value)::text || secondhybridparent.uri)
            ELSE NULL::text
        END AS second_hybrid_parent_name_id,
    (( SELECT COALESCE(( SELECT shard_config.value
                   FROM public.shard_config
                  WHERE ((shard_config.name)::text = 'nomenclatural code'::text)), 'ICN'::character varying) AS "coalesce"))::text AS nomenclatural_code,
    i.created_at AS created,
    i.updated_at AS modified,
    t.name AS dataset_name,
    (((mapper_host.value)::text || 'tree/'::text) || t.current_tree_version_id) AS dataset_id,
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
        CASE
            WHEN (e.instance_id = i.id) THEN (rtrim((mapper_host.value)::text, '/'::text) || tve.taxon_link)
            ELSE ((mapper_host.value)::text || i.uri)
        END AS cc_attribution_iri,
    t.current_tree_version_id AS tree_version_id,
    e.id AS tree_element_id,
    i.id AS instance_id,
    i.name_id,
    it.nomenclatural AS homotypic,
    it.taxonomic AS heterotypic,
    it.misapplied,
    it.relationship,
    it.synonym,
    e.excluded AS excluded_name,
        CASE
            WHEN e.excluded THEN false
            ELSE (COALESCE((NULLIF(e.instance_id, i.cited_by_id))::integer, 0))::boolean
        END AS accepted,
    tve.taxon_id AS accepted_id,
    k.rdf_id AS rank_rdf_id,
    name_space.value AS name_space,
    d.value AS tree_description,
    l.value AS tree_label,
    'x' as "order",
    'x' as generic_name,
    tve.name_path,
    tve.taxon_id AS node_id,
    pve.taxon_id AS parent_node_id,
    it.rdf_id AS usage_type,
    pi.publication_date,
    rk.rk AS rank_hash,
    ((((it.itorder ||
        CASE
            WHEN it.nomenclatural THEN '0000'::text
            ELSE COALESCE(substr((pi.primary_date)::text, 1, 4), '9999'::text)
        END) ||
        CASE
            WHEN (pi.autonym_of_id = COALESCE(x.id, n.id)) THEN '0'::text
            ELSE '1'::text
        END) || COALESCE(lpad((pi.primary_id)::text, 8, '0'::text), lpad((i.id)::text, 8, '0'::text))) || (COALESCE(pi.publication_date, '9999'::character varying))::text) AS usage_order
   FROM ((((((((((((public.instance i
     JOIN (public.tree_element e
     JOIN ((public.tree_version_element tve
     JOIN public.tree t ON (((t.current_tree_version_id = tve.tree_version_id) AND t.accepted_tree)))
     LEFT JOIN public.tree_version_element pve ON ((pve.element_link = tve.parent_id))) ON ((e.id = tve.tree_element_id))) ON (((i.id = e.instance_id) OR ((i.cited_by_id = e.instance_id) AND (e.name_id <> i.name_id)))))
     LEFT JOIN (public.instance a
     JOIN public.name x ON ((x.id = a.name_id))) ON ((a.id = i.cited_by_id)))
     JOIN it ON ((it.id = i.instance_type_id)))
     JOIN public.reference r ON ((r.id = i.reference_id)))
     JOIN (((((public.name n
     JOIN (public.name_type nt
     JOIN public.name_group ng ON ((nt.name_group_id = ng.id))) ON ((n.name_type_id = nt.id)))
     JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
     JOIN public.name_rank k ON ((n.name_rank_id = k.id)))
     LEFT JOIN public.name firsthybridparent ON (((n.parent_id = firsthybridparent.id) AND nt.hybrid)))
     LEFT JOIN public.name secondhybridparent ON (((n.second_parent_id = secondhybridparent.id) AND nt.hybrid))) ON ((i.name_id = n.id)))
     LEFT JOIN public.shard_config name_space ON (((name_space.name)::text = 'name space'::text)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     LEFT JOIN public.shard_config d ON (((d.name)::text = 'tree description'::text)))
     LEFT JOIN public.shard_config l ON (((l.name)::text = 'tree label text'::text)))
     LEFT JOIN public.shard_config p ON (((p.name)::text = 'services path name element'::text)))
     CROSS JOIN LATERAL public.get_hstore_tree(tve.element_link) rk(rk))
     LEFT JOIN public.primary_instance_v pi ON ((pi.name_id = i.name_id)))
  ORDER BY COALESCE(x.full_name, n.full_name), ((((it.itorder ||
        CASE
            WHEN it.nomenclatural THEN '0000'::text
            ELSE COALESCE(substr((pi.primary_date)::text, 1, 4), '9999'::text)
        END) ||
        CASE
            WHEN (pi.autonym_of_id = COALESCE(x.id, n.id)) THEN '0'::text
            ELSE '1'::text
        END) || COALESCE(lpad((pi.primary_id)::text, 8, '0'::text), lpad((i.id)::text, 8, '0'::text))) || (COALESCE(pi.publication_date, '9999'::character varying))::text)
  WITH NO DATA;

    --(rk.rk OPERATOR(public.->) 'kingdom'::text) AS kingdom,
    --(rk.rk OPERATOR(public.->) 'class'::text) AS class,
    --(rk.rk OPERATOR(public.->) 'subclass'::text) AS subclass,
    --(rk.rk OPERATOR(public.->) 'family'::text) AS family,
    --(rk.rk OPERATOR(public.->) 'order'::text) AS "order",
    --(rk.rk OPERATOR(public.->) 'genus'::text) AS generic_name,
  --ORDER BY (rk.rk OPERATOR(public.->) 'family'::text), COALESCE(x.full_name, n.full_name), ((((it.itorder ||

--
-- Name: MATERIALIZED VIEW taxon_mv; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.taxon_mv IS 'A snake_case listing of the accepted classification for a shard as Darwin_Core taxon records (almost): All taxa and their synonyms.';


--
-- Name: COLUMN taxon_mv.taxon_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxon_id IS 'The record identifier (URI): The node ID from the accepted classification for the taxon concept; the Taxon_Name_Usage (relationship instance) for a synonym. For higher taxa it uniquely identifiers the subtended branch.';


--
-- Name: COLUMN taxon_mv.name_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.name_type IS 'A categorisation of the name, e.g. scientific, hybrid, cultivar';


--
-- Name: COLUMN taxon_mv.accepted_name_usage_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.accepted_name_usage_id IS 'For a synonym, the taxon_id in this listing of the accepted concept. Self, for a taxon_record';


--
-- Name: COLUMN taxon_mv.accepted_name_usage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.accepted_name_usage IS 'For a synonym, the accepted taxon name in this classification.';


--
-- Name: COLUMN taxon_mv.nomenclatural_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.nomenclatural_status IS 'The nomencultural status of this name. http://rs.gbif.org/vocabulary/gbif/nomenclatural_status.xml';


--
-- Name: COLUMN taxon_mv.taxonomic_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxonomic_status IS 'Is this record accepted, excluded or a synonym of an accepted name.';


--
-- Name: COLUMN taxon_mv.pro_parte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.pro_parte IS 'A flag on a synonym for a partial taxonomic relationship with the accepted taxon';


--
-- Name: COLUMN taxon_mv.scientific_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.scientific_name IS 'The full scientific name including authority.';


--
-- Name: COLUMN taxon_mv.nom_illeg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.nom_illeg IS 'The scientific_name is illegitimate (ICN)';


--
-- Name: COLUMN taxon_mv.nom_inval; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.nom_inval IS 'The scientific_name is invalid';


--
-- Name: COLUMN taxon_mv.scientific_name_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.scientific_name_id IS 'The identifier (URI) for the scientific name in this shard.';


--
-- Name: COLUMN taxon_mv.canonical_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.canonical_name IS 'The name without authorship.';


--
-- Name: COLUMN taxon_mv.scientific_name_authorship; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.scientific_name_authorship IS 'Authorship of the name.';


--
-- Name: COLUMN taxon_mv.parent_name_usage_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.parent_name_usage_id IS 'The identifier ( a URI) in this listing for the parent taxon in the classification.';


--
-- Name: COLUMN taxon_mv.taxon_rank; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxon_rank IS 'The taxonomic rank of the scientific_name.';


--
-- Name: COLUMN taxon_mv.taxon_rank_sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxon_rank_sort_order IS 'A sort order that can be applied to the rank.';


--
-- Name: COLUMN taxon_mv.kingdom; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.kingdom IS 'The canonical name of the kingdom in this branch of the classification.';


--
-- Name: COLUMN taxon_mv.class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.class IS 'The canonical name of the class in this branch of the classification.';


--
-- Name: COLUMN taxon_mv.subclass; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.subclass IS 'The canonical name of the subclass in this branch of the classification.';


--
-- Name: COLUMN taxon_mv.family; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.family IS 'The canonical name of the family in this branch of the classification.';


--
-- Name: COLUMN taxon_mv.taxon_concept_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxon_concept_id IS 'The URI for the congruent published concept cited by this record.';


--
-- Name: COLUMN taxon_mv.name_according_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.name_according_to IS 'The reference citation for the congruent concept.';


--
-- Name: COLUMN taxon_mv.name_according_to_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.name_according_to_id IS 'The identifier (URI) for the reference citation for the congriuent concept.';


--
-- Name: COLUMN taxon_mv.taxon_remarks; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxon_remarks IS 'Comments made specifically about this taxon in this classification.';


--
-- Name: COLUMN taxon_mv.taxon_distribution; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.taxon_distribution IS 'The State or Territory distribution of the taxon.';


--
-- Name: COLUMN taxon_mv.higher_classification; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.higher_classification IS 'The taxon hierarchy, down to (and including) this taxon, as a list of names separated by a |.';


--
-- Name: COLUMN taxon_mv.first_hybrid_parent_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.first_hybrid_parent_name IS 'The scientific_name for the first hybrid parent. For hybrids.';


--
-- Name: COLUMN taxon_mv.first_hybrid_parent_name_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.first_hybrid_parent_name_id IS 'The identifier (URI) the scientific_name for the first hybrid parent.';


--
-- Name: COLUMN taxon_mv.second_hybrid_parent_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.second_hybrid_parent_name IS 'The scientific_name for the second hybrid parent. For hybrids.';


--
-- Name: COLUMN taxon_mv.second_hybrid_parent_name_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.second_hybrid_parent_name_id IS 'The identifier (URI) the scientific_name for the second hybrid parent.';


--
-- Name: COLUMN taxon_mv.nomenclatural_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.nomenclatural_code IS 'The nomenclatural code governing this classification.';


--
-- Name: COLUMN taxon_mv.created; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.created IS 'Date the record for this concept was created. Format ISO:86 01';


--
-- Name: COLUMN taxon_mv.modified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.modified IS 'Date the record for this concept was modified. Format ISO:86 01';


--
-- Name: COLUMN taxon_mv.dataset_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.dataset_name IS 'the Name for this branch of the classification  (tree). e.g. APC, Aus_moss';


--
-- Name: COLUMN taxon_mv.dataset_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.dataset_id IS 'the IRI for this branch of the classification  (tree)';


--
-- Name: COLUMN taxon_mv.license; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.license IS 'The license by which this data is being made available.';


--
-- Name: COLUMN taxon_mv.cc_attribution_iri; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.cc_attribution_iri IS 'The attribution to be used when citing this concept.';


--
-- Name: tnu_index_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tnu_index_v AS
 SELECT nv.family,
    ((((nv.scientific_name)::text || ' sensu. '::text) || (auth.name)::text) || COALESCE(((' ('::text || (ref.iso_publication_date)::text) || ')'::text), ''::text)) AS tnu_label,
    tn.scientific_name AS accepted_name_usage,
    ((mapper_host.value)::text || tnu.uri) AS dct_identifier,
    it.rdf_id AS taxonomic_status,
    ((mapper_host.value)::text || txc.uri) AS accepted_name_usage_id,
    nv.name_according_to_id AS primary_usage_id,
    nv.original_name_usage_id,
    ref.citation AS name_according_to,
    ref.iso_publication_date AS tnu_publication_date,
    (((((mapper_host.value)::text || 'reference/'::text) || (path.value)::text) || '/'::text) || ref.id) AS name_according_to_id,
    nv.scientific_name_id,
    nv.scientific_name,
    nv.canonical_name,
    nv.scientific_name_authorship,
    nv.rank_rdf_id AS taxon_rank,
    nv.name_published_in_year,
    nv.nomenclatural_status,
    nv.changed_combination AS is_changed_combination,
    it.primary_instance AS is_primary_usage,
    it.relationship AS is_relationship,
    it.nomenclatural AS is_homotypic_usage,
    it.taxonomic AS is_heterotypic_usage,
    nv.dataset_name,
    tnu.id AS instance_id,
    nv.name_id,
    ref.id AS reference_id,
    tnu.cited_by_id,
    tnu.cites_id,
    nv.license,
    tv.higher_classification
   FROM (((((((((public.instance tnu
     JOIN public.instance_type it ON ((it.id = tnu.instance_type_id)))
     JOIN public.name_mv nv ON ((tnu.name_id = nv.name_id)))
     JOIN (public.reference ref
     JOIN public.author auth ON ((ref.author_id = auth.id))) ON ((tnu.reference_id = ref.id)))
     LEFT JOIN (public.instance txc
     JOIN public.name_mv tn ON ((tn.name_id = txc.name_id))) ON ((txc.id = tnu.cited_by_id)))
     LEFT JOIN ( SELECT DISTINCT ON (taxon_mv.canonical_name) taxon_mv.canonical_name,
            taxon_mv.scientific_name,
            taxon_mv.higher_classification
           FROM public.taxon_mv) tv ON (((COALESCE(tn.scientific_name, nv.scientific_name))::text = (tv.scientific_name)::text)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
     LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))
     LEFT JOIN public.shard_config path ON (((path.name)::text = 'services path name element'::text)))
  ORDER BY tv.higher_classification, COALESCE(tn.scientific_name, nv.scientific_name), ref.iso_publication_date, COALESCE(txc.uri, tnu.uri), it.relationship, nv.name_published_in_year;


--
-- Name: gettnu(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gettnu(tnu_name text) RETURNS SETOF public.tnu_index_v
    LANGUAGE sql
    AS $$
	/* Returns tnu_index_v rows for names matching (and related by) POSIX expression 'tnu_name'.  */
select *
from (with a as (select * from tnu_index_v where scientific_name ~ tnu_name or accepted_name_usage ~ tnu_name),
           b as (select *
                 from tnu_index_v u
                 where exists(
		                 select 1 from a where u.dct_identifier = a.accepted_name_usage_id
	                 )
	               and scientific_name !~ tnu_name),
           c as (select *
                 from tnu_index_v v
                 where exists(
		                 select 1 from b where name_id = v.name_id
	                 )
	               and (accepted_name_usage !~ tnu_name or is_primary_usage)),
           d as (select *
                 from tnu_index_v w
                 where exists(
		                       select 1 from c where w.dct_identifier = c.accepted_name_usage_id
	                       ))
      select * from a
      union
      select * from b
      union
      select * from c
      union
      select * from d ) tnu
order by higher_classification,
         coalesce(accepted_name_usage, scientific_name),
         tnu_publication_date, coalesce(accepted_name_usage_id, dct_identifier), is_relationship,
         name_published_in_year;

$$;


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
-- Name: name_constructor(bigint, boolean, boolean, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_constructor(name_id bigint, rdfa boolean DEFAULT false, simple boolean DEFAULT false, state jsonb DEFAULT '{"in_hybrid": false, "in_autonym": false, "in_formula": false, "in_cultivar": false}'::jsonb) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
	current_id bigint := name_id;
	element_id bigint;
	rank_abbrev TEXT;
	name_rank TEXT;
	rank_id bigint;
	rank_rdfid TEXT;
	has_parent boolean;
	genus_rank_id bigint;
	target_rank bigint;
	parent_rank bigint;
	element TEXT := '';
	scientific_name TEXT := '';
	name_rdfid TEXT;
	name_type TEXT;
	is_format boolean;
	is_hybrid boolean;
	second_parent bigint;
	is_autonym boolean;
	is_formula boolean;
	ws_connector TEXT;
	authorship TEXT ;
	name_status TEXT;
	status_text TEXT;
	code TEXT;
	simple_name TEXT;
	name_path TEXT;
	x_state jsonb;
BEGIN

	IF name_id is null THEN return null; END IF;

	-- capture this names metadate
	SELECT
		t.rdf_id, t.autonym, t.formula, nullif(k.rdf_id,'n-a'), s.rdf_id, s.name, g.rdf_id, path.value, gk.id
	INTO
		name_type, is_autonym, is_formula, name_rank, name_status, status_text, code, name_path, genus_rank_id
	FROM name n
		     JOIN name_rank k ON n.name_rank_id = k.id
		     JOIN name_type t ON n.name_type_id = t.id
		     JOIN name_group g ON t.name_group_id = g.id
		     LEFT JOIN name_status s on n.name_status_id = s.id and (s.nom_inval or s.rdf_id = 'manuscript')
		     LEFT JOIN shard_config path on path.name = 'services path name element'
		     LEFT JOIN name_rank gk on gk.rdf_id = 'genus'
	WHERE n.id = name_id;

	state := jsonb_set( state, '{in_autonym}', to_jsonb(is_autonym), true);

	IF name_type ~ 'cultivar-hybrid' THEN
		state := jsonb_set( state, '{in_hybrid}', to_jsonb(true), true);
	END IF;

	LOOP
		-- Fetch the necessary information for the current name element
		SELECT n.id,
		       rtrim(n.name_element), rtrim(n.simple_name),
		       n.parent_id,
		       k.id,
		       k.parent_rank_id,
		       CASE
			       WHEN k.visible_in_name THEN
			           COALESCE(CASE WHEN k.use_verbatim_rank THEN n.verbatim_rank END, k.abbrev)
			       END,
		       k.italicize, k.has_parent,
		       k.rdf_id,
		       n.second_parent_id,
		       t.rdf_id,
		       t.hybrid,
		       t.autonym,
		       t.formula,
		       t.connector
		INTO element_id, element, simple_name, current_id, rank_id, parent_rank, rank_abbrev,
			is_format, has_parent, rank_rdfid, second_parent, name_rdfid,
			is_hybrid, is_autonym, is_formula, ws_connector
		FROM name n
			     JOIN name_rank k ON n.name_rank_id = k.id
			     JOIN name_type t ON n.name_type_id = t.id
		         --LEFT JOIN name p ON p.id = n.parent_id
		           -- JOIN name_rank pk on pk.id = p.name_rank_id
		WHERE n.id = current_id;

        IF code ~ 'zoological' and has_parent and current_id is null THEN
            element := simple_name;
        END IF;

		if (state ->> 'in_cultivar')::boolean and (state ->> 'in_hybrid')::boolean THEN
			parent_rank := genus_rank_id;
		end if;

		-- Handle common or vernacular names
		IF name_rdfid ~ '(common|vernacular)' THEN
			scientific_name := element;
			EXIT;
		END IF;


		-- Handle cultivar names
		IF name_rdfid ~ 'cultivar' THEN
		IF (state ->> 'in_cultivar')::boolean THEN
				scientific_name :=   CONCAT_WS(' ', name_constructor(current_id, rdfa, true, state));
			ELSE
		    x_state := state;
			x_state := jsonb_set( state, '{in_cultivar}', to_jsonb(true), true);
			scientific_name := CONCAT_WS(' ', name_constructor(current_id, rdfa, true, x_state), '''' || element || '''');
		END IF;
		EXIT;
		END IF;

		-- Handle formula names
		IF is_formula THEN
			IF (state ->> 'in_cultivar')::boolean THEN
			 	scientific_name := CONCAT_WS( ' ', name_constructor(current_id, rdfa, false, state));
			ELSE
			  x_state := state;
			  x_state := jsonb_set( x_state, '{in_formula}', to_jsonb(true), true);
			  scientific_name := CONCAT_WS(
					' ',
					name_constructor(current_id, rdfa, false,x_state),
					ws_connector,
					COALESCE(name_constructor(second_parent, rdfa, false , x_state ), '?')
			                   );
			  IF (state ->> 'in_formula')::boolean THEN
				scientific_name := CONCAT('(', scientific_name, ')');
				state := jsonb_set( state, '{in_formula}', to_jsonb(false), true);
			  END IF;
			END IF;
			-- current_id := null;
			EXIT;
		END IF;


		IF rdfa and is_format and name_rdfid !~ 'phrase' THEN
			 --  to include named_parts ... rank_rdfid is only an example.
			 --  The rank table needs a column 'name_of_name' for the name of a name at rank.
			 --  element := CONCAT( '<em property="', rank_rdfid, '">', element, '</em>');
			  element := CONCAT( '<em>', element, '</em>');
		END IF;

		-- Handle named hybrid
		IF name_rdfid ~ 'named-hybrid' and rank_rdfid !~ 'notho' THEN
			element := 'x ' || element;
		END IF;


		IF (state ->> 'in_cultivar')::boolean THEN
			authorship := null;
		ELSE
		    authorship := nc_authorship(element_id);
		END IF;

		IF rank_abbrev ~ '^\[.*\]$' THEN
			rank_abbrev := null;
		END IF;

		-- Handle unranked names



		-- Construct the scientific name

		IF scientific_name = ''   THEN

		--	IF  (state ->> 'in_cultivar')::boolean THEN
		--		scientific_name := 'XXX';
		--	END IF;

			IF rank_rdfid ~ 'unranked'  and not (state ->> 'in_cultivar')::boolean THEN
				scientific_name := CONCAT_WS(' ', name_constructor(current_id, rdfa, true, state), rank_abbrev, element, authorship);
				EXIT;
			END IF;

			IF (state ->> 'in_hybrid')::boolean and parent_rank != rank_id THEN
				NULL;
			 	-- scientific_name := CONCAT_WS(' ', scientific_name);
			ELSEIF simple  or ((state ->> 'in_autonym')::boolean and code ~ 'botanical')  THEN
				scientific_name := CONCAT_WS(' ', rank_abbrev, element);
			ELSE
				scientific_name := CONCAT_WS(' ', rank_abbrev, element, authorship);
			END IF;
			target_rank := parent_rank;
		ELSE

			IF rank_id = target_rank THEN
			  -- IF parent_rank is not null and (in_cultivar or in_formula) THEN
			  -- IF in_cultivar /*and parent_rank is not null*/ THEN
			  --   NULL;
			  -- ELSE

				-- IF (state ->> 'in_hybrid')::boolean THEN
				--	 scientific_name := CONCAT_WS(' ', 'X', scientific_name);
				--	 EXIT;
				--ELSE
			  IF (state ->> 'in_autonym')::boolean THEN
					scientific_name := CONCAT_WS(' ', element, authorship, scientific_name);
					state := jsonb_set( state, '{in_autonym}', to_jsonb(false), true);
				ELSE
				    scientific_name := CONCAT_WS(' ', element, scientific_name);
				END IF;
				--  target_rank := parent_rank;
			  -- END IF;
			  target_rank := parent_rank;
			 END IF;
		END IF;

		-- If we've reached the root (uninomial), exit the loop
		IF current_id IS NULL THEN
			EXIT;
		END IF;
	END LOOP;

    scientific_name := regexp_replace(scientific_name, '</em> <em>', ' ', 'g');
	-- RETURN rtrim(scientific_name);

	if not simple and (rdfa and not (state ->> 'in_formula')::boolean) then
		scientific_name :=
			CONCAT(
					'<a href="https://id.biodiversity.org.au/name/'||name_path||'/', name_id,
					'" prefix="nsl: https://id.biodiversity.org.au/voc/"',
					' typeof="nsl:TaxonName"' , '>',
					'<span property="nsl:nameCode" content="nsl:'||code||'"></span>',
					'<span property="nsl:nameType" content="nsl:'||name_type||'"></span>',
				    '<span property="nsl:nameRank" content="nsl:'||name_rank||'"></span>',
					'<span property="nsl:nameStatus" content="nsl:'||name_status||'"></span>',
					'<span property="nsl:fullName" content="',
					 -- regexp_replace(scientific_name, '</*em[^>]*>', '', 'g'), '">',
					 regexp_replace(scientific_name, '</*em>', '', 'g'), '">',
					 scientific_name,
				     ', '||status_text,
					 '</span></a>'
			);
	-- else
		-- scientific_name := CONCAT_WS(', ', scientific_name, name_status);
	end if;


	RETURN rtrim(scientific_name);
END;
$_$;


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
-- Name: nc_authorship(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nc_authorship(name_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
SELECT CASE
	       WHEN code.value = 'ICN' THEN
		       CASE
			       WHEN nt.autonym THEN NULL::text
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
			       WHEN n.changed_combination THEN
				       COALESCE(
						       '(' || a.abbrev || COALESCE(', ' || n.published_year, '') || ')',
						       ''
				       )
			       ELSE
				       COALESCE(
						       a.abbrev || COALESCE(', ' || n.published_year, ''),
						       ''
				       )
			       END
	       END AS value
FROM public.name n
	     JOIN public.name_type nt ON n.name_type_id = nt.id
	     LEFT JOIN public.shard_config code ON code.name::text = 'nomenclatural code'::text
	     LEFT JOIN public.author b ON n.base_author_id = b.id
	     LEFT JOIN public.author xb ON n.ex_base_author_id = xb.id
	     LEFT JOIN public.author a ON n.author_id = a.id
	     LEFT JOIN public.author xa ON n.ex_author_id = xa.id
WHERE n.id = name_id;
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
-- Name: trees_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.trees_mv AS
 SELECT tve.taxon_id,
    pve.taxon_id AS parent_taxon_id,
    (rtrim((mapper_host.value)::text, '/'::text) || tve.taxon_link) AS identifier,
    t.id AS tree_id,
    t.name AS tree_name,
        CASE
            WHEN te.excluded THEN false
            ELSE true
        END AS is_accepted,
    te.excluded AS is_excluded,
    tve.tree_element_id,
    pve.tree_element_id AS parent_element_id,
    t.current_tree_version_id AS tree_version_id,
    public.text2ltree(regexp_replace(ltrim(tve.tree_path, '/'::text), '/'::text, '.'::text, 'g'::text)) AS ltree_path,
    public.nlevel(public.text2ltree(regexp_replace(ltrim(tve.tree_path, '/'::text), '/'::text, '.'::text, 'g'::text))) AS depth,
    tve.name_path,
    te.instance_id,
    n.id AS name_id,
    k.rdf_id AS name_rank_id,
    pn.id AS parent_name_id,
    pk.rdf_id AS parent_rank_id,
    gn.id AS parent_parent_name_id,
    gk.rdf_id AS parent_parent_rank_id,
    n.sort_name,
    t.rdf_id AS tree_rdf_id,
    t.accepted_tree
   FROM (((((public.tree_version_element tve
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     JOIN (public.tree_element te
     JOIN (public.instance i
     JOIN (public.name n
     JOIN public.name_rank k ON ((k.id = n.name_rank_id))) ON ((i.name_id = n.id))) ON ((te.instance_id = i.id))) ON ((te.id = tve.tree_element_id)))
     LEFT JOIN ((public.tree_version_element pve
     JOIN (public.tree_element pe
     JOIN (public.instance pi
     JOIN (public.name pn
     JOIN public.name_rank pk ON ((pk.id = pn.name_rank_id))) ON ((pn.id = pi.name_id))) ON ((pi.id = pe.instance_id))) ON ((pe.id = pve.tree_element_id)))
     LEFT JOIN (public.tree_version_element gve
     JOIN (public.tree_element ge
     JOIN ((public.instance gi
     JOIN public.namespace ns ON (((gi.namespace_id = ns.id) AND ((ns.rdf_id)::text = 'afd'::text))))
     JOIN (public.name gn
     JOIN public.name_rank gk ON ((gn.name_rank_id = gk.id))) ON ((gn.id = gi.name_id))) ON ((gi.id = ge.instance_id))) ON ((ge.id = gve.tree_element_id))) ON ((pve.parent_id = gve.element_link))) ON ((pve.element_link = tve.parent_id)))
     JOIN (public.tree t
     LEFT JOIN (public.reference r
     JOIN public.author a ON ((a.id = r.author_id))) ON ((t.reference_id = r.id))) ON (((tve.tree_version_id = t.current_tree_version_id) AND t.is_schema)))
  ORDER BY t.name, tve.name_path
  WITH NO DATA;


--
-- Name: taxon_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.taxon_v AS
 SELECT ntv.taxon_id,
    ntv.identifier,
    ntv.instance_id AS taxon_concept_id,
    te.excluded AS is_excluded,
        CASE
            WHEN te.excluded THEN 'excluded'::text
            ELSE 'accepted'::text
        END AS taxonomic_status,
    ntv.parent_taxon_id,
    ntv.tree_element_id,
    t.id AS tree_id,
    t.name AS tree_name,
    ntv.tree_version_id,
    COALESCE((COALESCE((((((gn.simple_name)::text || ' '::text) || (pn.name_element)::text) || ' '::text) || (n.name_element)::text), COALESCE((((pn.simple_name)::text || ' '::text) || (n.name_element)::text), (COALESCE(n.simple_name, ''::character varying))::text)) || COALESCE((' '::text ||
        CASE
            WHEN n.changed_combination THEN ((('('::text || (na.abbrev)::text) || COALESCE((', '::text || n.published_year), ''::text)) || ')'::text)
            ELSE ((na.abbrev)::text || COALESCE((', '::text || n.published_year), ''::text))
        END), ''::text)), (n.full_name)::text) AS title,
    (((n.full_name)::text || COALESCE((' sec. '::text || (a.name)::text), (' sec. '::text || t.name))) || COALESCE(((' ('::text || to_char(tv.published_at, 'YYYY-MM-DD'::text)) || ')'::text), ''::text)) AS name_usage_label,
    ntv.name_id,
    ntv.parent_name_id,
    t.reference_id,
    r.citation AS publication_citation,
    (to_char(tv.published_at, 'YYYY'::text))::integer AS publication_year,
    tv.published_at AS publication_date,
    n.full_name,
    te.updated_at,
    ntv.depth,
    ntv.name_path,
    ntv.ltree_path,
    t.name AS dataset_name,
    ntv.tree_rdf_id,
    t.accepted_tree,
    true AS is_true
   FROM (((((((((public.trees_mv ntv
     JOIN public.instance i ON ((i.id = ntv.instance_id)))
     JOIN (public.name n
     LEFT JOIN public.author na ON ((n.author_id = na.id))) ON ((ntv.name_id = n.id)))
     JOIN public.tree_element te ON ((te.id = ntv.tree_element_id)))
     JOIN (public.tree t
     LEFT JOIN (public.reference r
     JOIN public.author a ON ((a.id = r.author_id))) ON ((t.reference_id = r.id))) ON ((ntv.tree_id = t.id)))
     JOIN public.tree_version tv ON ((tv.id = ntv.tree_version_id)))
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     LEFT JOIN public.name pn ON (((ntv.parent_name_id = pn.id) AND ((dataset.value)::text = 'AFD'::text) AND ((ntv.parent_rank_id)::text ~ '(species|subgenus|species-aggregate)'::text))))
     LEFT JOIN public.name gn ON (((ntv.parent_parent_name_id = gn.id) AND ((dataset.value)::text = 'AFD'::text) AND ((ntv.parent_parent_rank_id)::text ~ '(subgenus|species-aggregate)'::text))));


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

CREATE VIEW public.nsl_tree_mv AS
 SELECT trees_mv.taxon_id,
    trees_mv.parent_taxon_id,
    trees_mv.identifier,
    trees_mv.tree_id,
    trees_mv.tree_name,
    trees_mv.is_accepted,
    trees_mv.is_excluded,
    trees_mv.tree_element_id,
    trees_mv.parent_element_id,
    trees_mv.tree_version_id,
    trees_mv.ltree_path,
    trees_mv.depth,
    trees_mv.name_path,
    trees_mv.instance_id,
    trees_mv.name_id,
    trees_mv.name_rank_id,
    trees_mv.parent_name_id,
    trees_mv.parent_rank_id,
    trees_mv.parent_parent_name_id,
    trees_mv.parent_parent_rank_id,
    trees_mv.sort_name,
    trees_mv.tree_rdf_id,
    trees_mv.accepted_tree
   FROM public.trees_mv
  WHERE trees_mv.accepted_tree;


--
-- Name: cited_usage_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.cited_usage_v AS
 SELECT ru.instance_id,
    ru.identifier,
    ru.name_id,
    ru.reference_id,
    ru.author_id,
    ru.usage_type_rdf_id,
    ru.usage_type_id,
    ru.full_name,
    ru.publication_author,
    ru.cited_identifier,
    ru.publication_year,
    ru.iso_publication_date,
    ru.publication_citation,
    ru.page_citation,
    ru.bhl_url,
    ru.verbatim_name_string,
    ru.relationship_notes,
    ru.cited_usage_notes,
    ru.cited_by_id,
    ru.cites_id,
    ru.is_current_relationship,
    ru.is_relationship,
    ru.is_synonym,
    ru.is_homotypic,
    ru.is_heterotypic,
    ru.is_misapplication,
    ru.is_pro_parte,
    ru.is_vernacular,
    ru.is_isonym,
    ru.is_secondary_source,
    ru.is_generic_combination,
    ru.is_uncited,
    ru.usage_order,
    ru.dataset_name,
    ru.host,
    ru.is_true
   FROM ( SELECT i.id AS instance_id,
            ((host.value)::text || i.uri) AS identifier,
            i.name_id,
            ci.reference_id,
            r.author_id,
            it.rdf_id AS usage_type_rdf_id,
            it.id AS usage_type_id,
            n.full_name,
            a.name AS publication_author,
            ((host.value)::text || ci.uri) AS cited_identifier,
            r.year AS publication_year,
            r.iso_publication_date,
            r.citation AS publication_citation,
            ci.page AS page_citation,
            ci.bhl_url,
            ci.verbatim_name_string,
            ( SELECT string_agg(regexp_replace((((key.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text ORDER BY key.sort_order) AS string_agg
                   FROM (public.instance_note note
                     JOIN public.instance_note_key key ON ((key.id = note.instance_note_key_id)))
                  WHERE (note.instance_id = i.id)) AS relationship_notes,
            ( SELECT string_agg(regexp_replace((((key.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text ORDER BY key.sort_order) AS string_agg
                   FROM (public.instance_note note
                     JOIN public.instance_note_key key ON ((key.id = note.instance_note_key_id)))
                  WHERE (note.instance_id = ci.id)) AS cited_usage_notes,
            i.cited_by_id,
            i.cites_id,
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM public.nsl_tree_mv ntv
                      WHERE (ntv.instance_id = i.cited_by_id))) THEN true
                    ELSE false
                END AS is_current_relationship,
            it.relationship AS is_relationship,
            it.synonym AS is_synonym,
            it.nomenclatural AS is_homotypic,
            it.taxonomic AS is_heterotypic,
            it.misapplied AS is_misapplication,
            it.pro_parte AS is_pro_parte,
                CASE
                    WHEN ((it.rdf_id)::text ~ '(common|vernacular)'::text) THEN true
                    ELSE false
                END AS is_vernacular,
                CASE
                    WHEN ((it.rdf_id)::text = 'isonym'::text) THEN true
                    ELSE false
                END AS is_isonym,
                CASE
                    WHEN ((it.rdf_id)::text = 'secondary-source'::text) THEN true
                    ELSE false
                END AS is_secondary_source,
                CASE
                    WHEN ((it.rdf_id)::text = 'generic-combination'::text) THEN true
                    ELSE false
                END AS is_generic_combination,
                CASE
                    WHEN i.uncited THEN true
                    ELSE false
                END AS is_uncited,
            (((((((((((
                CASE
                    WHEN ((it.rdf_id)::text ~ '(excluded|intercepted|vagrant)'::text) THEN '1'::text
                    ELSE '0'::text
                END ||
                CASE
                    WHEN ((it.rdf_id)::text ~ '(common|vernacular)'::text) THEN '1'::text
                    ELSE '0'::text
                END) ||
                CASE
                    WHEN ((it.rdf_id)::text ~ '(taxonomy|synonymy)'::text) THEN '1'::text
                    ELSE '0'::text
                END) ||
                CASE
                    WHEN ((it.rdf_id)::text ~ '(miscellaneous)'::text) THEN '1'::text
                    ELSE '0'::text
                END) || ((it.misapplied)::integer)::text) || ((it.taxonomic)::integer)::text) || ((it.nomenclatural)::integer)::text) || ((it.standalone)::integer)::text) || ((it.primary_instance)::integer)::text) || ((it.protologue)::integer)::text) || lpad((it.sort_order)::text, 4, '0'::text)) || (COALESCE(r.iso_publication_date, ''::character varying))::text) AS usage_order,
            dataset.value AS dataset_name,
            host.value AS host,
            true AS is_true
           FROM ((((((public.instance i
             JOIN public.namespace ns ON ((i.namespace_id = ns.id)))
             JOIN public.name n ON ((i.name_id = n.id)))
             JOIN public.instance_type it ON ((i.instance_type_id = it.id)))
             LEFT JOIN ((public.instance ci
             JOIN public.instance_type ct ON ((ci.instance_type_id = ct.id)))
             JOIN (public.reference r
             JOIN public.author a ON ((r.author_id = a.id))) ON ((ci.reference_id = r.id))) ON ((ci.id = i.cites_id)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))) ru;


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

CREATE VIEW public.taxon_name_v AS
 SELECT tnv.name_id,
    tnv.identifier,
    tnv.name_type,
    tnv.rank,
    tnv.full_name,
    tnv.title,
    tnv.nomenclatural_status,
    tnv.simple_name,
    tnv.authorship,
    tnv.publication_citation,
    tnv.publication_year,
    tnv.author_id,
    tnv.basionym_id,
    tnv.basionym_author_id,
    tnv.primary_usage_id,
    tnv.combination_usage_id,
    tnv.publication_usage_type,
    tnv.rank_rdf_id,
    tnv.rank_abbreviation,
    tnv.verbatim_rank,
    tnv.is_accepted,
    tnv.nsl_status,
    tnv.is_changed_combination,
    tnv.is_autonym,
    tnv.is_cultivar,
    tnv.is_name_formula,
    tnv.is_scientific,
    tnv.is_nom_inval,
    tnv.is_nom_illeg,
    tnv.type_citation,
    tnv.kingdom,
    tnv.family,
    tnv.uninomial,
    tnv.infrageneric_epithet,
    tnv.generic_name,
    tnv.specific_epithet,
    tnv.infraspecific_epithet,
    tnv.cultivar_epithet,
    tnv.is_hybrid,
    tnv.first_hybrid_parent_name,
    tnv.first_hybrid_parent_name_id,
    tnv.second_hybrid_parent_name,
    tnv.second_hybrid_parent_name_id,
    tnv.created,
    tnv.modified,
    tnv.nomenclatural_code,
    tnv.dataset_name,
    tnv.license,
    tnv.cc_attribution_iri,
    tnv.source_id,
    tnv.source_id_string,
    tnv.sort_name,
    tnv.taxon_rank_sort_order,
    tnv.is_true,
    tnv.name_status_id
   FROM ( SELECT n.id AS name_id,
            ((mapper_host.value)::text || n.uri) AS identifier,
            nt.rdf_id AS name_type,
            rank.name AS rank,
            n.full_name,
            ((n.full_name)::text ||
                CASE
                    WHEN (ns.nom_inval AND ((code.value)::text = 'ICN'::text)) THEN (' ,'::text || (ns.name)::text)
                    ELSE ''::text
                END) AS title,
                CASE
                    WHEN ((ns.rdf_id)::text !~ '(default|n-a|deleted)'::text) THEN ns.name
                    ELSE NULL::character varying
                END AS nomenclatural_status,
            n.simple_name,
                CASE ng.rdf_id
                    WHEN 'botanical'::text THEN
                    CASE
                        WHEN nt.autonym THEN NULL::text
                        ELSE (COALESCE(((('('::text || COALESCE(((xb.abbrev)::text || ' ex '::text), ''::text)) || (b.abbrev)::text) || ') '::text), ''::text) || COALESCE((COALESCE(((xa.abbrev)::text || ' ex '::text), ''::text) || (a.abbrev)::text), ''::text))
                    END
                    ELSE
                    CASE
                        WHEN n.changed_combination THEN COALESCE(((('('::text || (a.abbrev)::text) || COALESCE((', '::text || n.published_year), ''::text)) || ')'::text), ''::text)
                        ELSE COALESCE(((a.abbrev)::text || COALESCE((', '::text || n.published_year), ''::text)), ''::text)
                    END
                END AS authorship,
            p.publication_citation,
            "left"((p.publication_date)::text, 4) AS publication_year,
            n.author_id,
            p.basionym_id,
            n.base_author_id AS basionym_author_id,
            p.primary_id AS primary_usage_id,
            p.combination_id AS combination_usage_id,
            p.publication_usage_type,
            rank.rdf_id AS rank_rdf_id,
            rank.abbrev AS rank_abbreviation,
            n.verbatim_rank,
            nv.nsl_accepted AS is_accepted,
            nv.taxonomic_status AS nsl_status,
            COALESCE(((n.base_author_id)::integer)::boolean, n.changed_combination) AS is_changed_combination,
            nt.autonym AS is_autonym,
            nt.cultivar AS is_cultivar,
            nt.formula AS is_name_formula,
            nt.scientific AS is_scientific,
            ns.nom_inval AS is_nom_inval,
            ns.nom_illeg AS is_nom_illeg,
                CASE
                    WHEN (nt.autonym = true) THEN (parent_name.full_name)::text
                    ELSE ( SELECT string_agg(regexp_replace((((key1.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text) AS string_agg
                       FROM (public.instance_note note
                         JOIN public.instance_note_key key1 ON (((key1.id = note.instance_note_key_id) AND ((key1.rdf_id)::text ~* 'type$'::text))))
                      WHERE (note.instance_id = p.primary_id))
                END AS type_citation,
            nv.kingdom,
            nv.family,
            nv.uninomial,
            nv.infrageneric_epithet,
            nv.generic_name,
            nv.specific_epithet,
            nv.infraspecific_epithet,
            nv.cultivar_epithet,
            nt.hybrid AS is_hybrid,
            first_hybrid_parent.full_name AS first_hybrid_parent_name,
            ((mapper_host.value)::text || first_hybrid_parent.uri) AS first_hybrid_parent_name_id,
            second_hybrid_parent.full_name AS second_hybrid_parent_name,
            ((mapper_host.value)::text || second_hybrid_parent.uri) AS second_hybrid_parent_name_id,
            n.created_at AS created,
            n.updated_at AS modified,
            (COALESCE(code.value, 'ICN'::character varying))::text AS nomenclatural_code,
            dataset.value AS dataset_name,
            'https://creativecommons.org/licenses/by/3.0/'::text AS license,
            ((mapper_host.value)::text || n.uri) AS cc_attribution_iri,
            n.source_id,
            n.source_id_string,
            n.sort_name,
            rank.sort_order AS taxon_rank_sort_order,
            true AS is_true,
            ns.id AS name_status_id
           FROM (((((((((((((((((((((public.name n
             JOIN (public.name_type nt
             JOIN public.name_group ng ON ((ng.id = nt.name_group_id))) ON ((n.name_type_id = nt.id)))
             LEFT JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
             LEFT JOIN public.name parent_name ON ((n.parent_id = parent_name.id)))
             LEFT JOIN public.name family_name ON ((n.family_id = family_name.id)))
             LEFT JOIN public.name_mv nv ON ((n.id = nv.name_id)))
             LEFT JOIN public.author b ON ((n.base_author_id = b.id)))
             LEFT JOIN public.author xb ON ((n.ex_base_author_id = xb.id)))
             LEFT JOIN public.author a ON ((n.author_id = a.id)))
             LEFT JOIN public.author xa ON ((n.ex_author_id = xa.id)))
             LEFT JOIN public.name first_hybrid_parent ON (((n.parent_id = first_hybrid_parent.id) AND nt.hybrid)))
             LEFT JOIN public.name second_hybrid_parent ON (((n.second_parent_id = second_hybrid_parent.id) AND nt.hybrid)))
             LEFT JOIN public.primary_instance_mv p ON ((p.name_id = n.id)))
             LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))
             LEFT JOIN public.shard_config path ON (((path.name)::text = 'services path name element'::text)))
             JOIN public.name_rank kingdom ON (((kingdom.rdf_id)::text ~ '(regnum|kingdom)'::text)))
             JOIN public.name_rank family ON (((family.rdf_id)::text ~ '(^family|^familia)'::text)))
             JOIN public.name_rank genus ON (((genus.rdf_id)::text = 'genus'::text)))
             JOIN public.name_rank species ON (((species.rdf_id)::text = 'species'::text)))
             JOIN (public.name_rank rank
             LEFT JOIN public.name_rank pk ON ((rank.parent_rank_id = pk.id))) ON ((n.name_rank_id = rank.id)))
          WHERE ((EXISTS ( SELECT 1
                   FROM public.instance
                  WHERE (instance.name_id = n.id))) AND (COALESCE(n.name_path, 'X'::text) !~ '^C[MLAF]/'::text))) tnv;


--
-- Name: taxon_name_usage_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.taxon_name_usage_v AS
 SELECT nu.instance_id,
    nu.identifier,
    nu.title,
    nu.name_id,
    nu.instance_type_id,
    nu.reference_id,
    nu.author_id,
    nu.bhl_url,
    nu.usage_type_id,
    nu.usage_type_rdf_id,
    nu.full_name,
    nu.publication_author,
    nu.publication_year,
    nu.iso_publication_date,
    nu.primary_year,
    nu.publication_citation,
    nu.page_citation,
    nu.verbatim_name_string,
    nu.usage_notes,
    nu.cited_by_id,
    nu.cites_id,
    nu.concept_id,
    nu.is_current_usage,
    nu.is_current_relationship,
    nu.is_primary_instance,
    nu.is_combination_instance,
    nu.primary_instance_id,
    nu.is_standalone,
    nu.is_relationship,
    nu.is_synonym,
    nu.is_homotypic,
    nu.is_heterotypic,
    nu.is_misapplication,
    nu.is_pro_parte,
    nu.is_vernacular,
    nu.is_isonym,
    nu.is_secondary_source,
    nu.is_generic_combination,
    nu.is_uncited,
    nu.simple_name,
    nu.usage_order,
    nu.dataset_name,
    nu.host,
    nu.is_true
   FROM ( SELECT ui.id AS instance_id,
            ((host.value)::text || ui.uri) AS identifier,
                CASE
                    WHEN it.misapplied THEN concat_ws(' '::text, un.simple_name, 'auct. non.', (('('::text || (ba.abbrev)::text) || ')'::text), na.abbrev, 'sensu', ((ca.name)::text || ','::text), "left"((cr.iso_publication_date)::text, 4), 'sec.', ((ua.name)::text || ','::text), "left"((ur.iso_publication_date)::text, 4))
                    ELSE concat_ws(' '::text, un.full_name,
                    CASE
                        WHEN it.alignment THEN concat_ws((('sensu '::text || (ca.name)::text) || ','::text), "left"((cr.iso_publication_date)::text, 4))
                        WHEN nt.scientific THEN
                        CASE
                            WHEN (ns.nom_inval AND ((code.value)::text = 'ICN'::text)) THEN (','::text || (ns.name)::text)
                            ELSE NULL::text
                        END
                        ELSE NULL::text
                    END, 'sec.', ((ua.name)::text || ','::text), "left"((ur.iso_publication_date)::text, 4))
                END AS title,
            ui.name_id,
            ui.instance_type_id,
            ui.reference_id,
            ur.author_id,
            ui.bhl_url,
            it.id AS usage_type_id,
            it.rdf_id AS usage_type_rdf_id,
            un.full_name,
            ua.name AS publication_author,
            (substr((ur.iso_publication_date)::text, 1, 4))::integer AS publication_year,
            ur.iso_publication_date,
            substr((pi.publication_date)::text, 1, 4) AS primary_year,
            ur.citation AS publication_citation,
            ui.page AS page_citation,
            ui.verbatim_name_string,
            ( SELECT string_agg(regexp_replace((((key.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text ORDER BY key.sort_order) AS string_agg
                   FROM (public.instance_note note
                     JOIN public.instance_note_key key ON ((key.id = note.instance_note_key_id)))
                  WHERE (note.instance_id = ui.id)) AS usage_notes,
            ui.cited_by_id,
            ui.cites_id,
            COALESCE(ui.cited_by_id, ui.id) AS concept_id,
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM public.nsl_tree_mv ntv
                      WHERE (ntv.instance_id = ui.id))) THEN true
                    ELSE false
                END AS is_current_usage,
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM public.nsl_tree_mv ntv
                      WHERE (ntv.instance_id = ui.cited_by_id))) THEN true
                    ELSE false
                END AS is_current_relationship,
                CASE
                    WHEN (ui.id = pi.primary_id) THEN true
                    ELSE false
                END AS is_primary_instance,
                CASE
                    WHEN (ui.id = pi.combination_id) THEN true
                    ELSE false
                END AS is_combination_instance,
                CASE
                    WHEN (ui.id <> pi.primary_id) THEN pi.primary_id
                    ELSE NULL::bigint
                END AS primary_instance_id,
            it.standalone AS is_standalone,
            it.relationship AS is_relationship,
            it.synonym AS is_synonym,
            it.nomenclatural AS is_homotypic,
            it.taxonomic AS is_heterotypic,
            it.misapplied AS is_misapplication,
            it.pro_parte AS is_pro_parte,
                CASE
                    WHEN ((it.rdf_id)::text ~ '(common|vernacular)'::text) THEN true
                    ELSE false
                END AS is_vernacular,
                CASE
                    WHEN ((it.rdf_id)::text = 'isonym'::text) THEN true
                    ELSE false
                END AS is_isonym,
                CASE
                    WHEN ((it.rdf_id)::text = 'secondary-source'::text) THEN true
                    ELSE false
                END AS is_secondary_source,
                CASE
                    WHEN ((it.rdf_id)::text = 'generic-combination'::text) THEN true
                    ELSE false
                END AS is_generic_combination,
                CASE
                    WHEN ui.uncited THEN true
                    ELSE false
                END AS is_uncited,
            un.simple_name,
            (((((((((((((((
                CASE
                    WHEN ((it.rdf_id)::text ~ '(excluded|intercepted|vagrant)'::text) THEN '1'::text
                    ELSE '0'::text
                END ||
                CASE
                    WHEN ((it.rdf_id)::text ~ '(common|vernacular)'::text) THEN '1'::text
                    ELSE '0'::text
                END) ||
                CASE
                    WHEN ((it.rdf_id)::text ~ '(taxonomy|synonymy)'::text) THEN '1'::text
                    ELSE '0'::text
                END) ||
                CASE
                    WHEN ((it.rdf_id)::text ~ 'miscellaneous'::text) THEN '1'::text
                    ELSE '0'::text
                END) || ((it.misapplied)::integer)::text) ||
                CASE
                    WHEN ((it.rdf_id)::text ~ '(generic-combination|heterotypic-combination)'::text) THEN '1'::text
                    ELSE '0'::text
                END) || ((it.taxonomic)::integer)::text) || ((it.nomenclatural)::integer)::text) ||
                CASE
                    WHEN ((it.rdf_id)::text ~ 'isonym'::text) THEN '0'::text
                    ELSE '1'::text
                END) || ((it.standalone)::integer)::text) || ((it.primary_instance)::integer)::text) || ((it.protologue)::integer)::text) ||
                CASE
                    WHEN it.nomenclatural THEN '0000'::text
                    ELSE COALESCE(substr((pi.primary_date)::text, 1, 4), '9999'::text)
                END) ||
                CASE
                    WHEN (pi.autonym_of_id = COALESCE(nx.id, un.id)) THEN '0'::text
                    ELSE '1'::text
                END) || COALESCE(lpad((pi.primary_id)::text, 8, '0'::text), lpad((ui.id)::text, 8, '0'::text))) || (COALESCE(pi.publication_date, '9999'::character varying))::text) AS usage_order,
            dataset.value AS dataset_name,
            host.value AS host,
            true AS is_true
           FROM (((((((((public.instance ui
             LEFT JOIN public.primary_instance_mv pi ON ((pi.name_id = ui.name_id)))
             JOIN ((((public.name un
             LEFT JOIN public.author na ON ((na.id = un.author_id)))
             LEFT JOIN public.author ba ON ((ba.id = un.base_author_id)))
             JOIN public.name_type nt ON ((un.name_type_id = nt.id)))
             JOIN public.name_status ns ON ((un.name_status_id = ns.id))) ON ((ui.name_id = un.id)))
             JOIN (public.reference ur
             JOIN public.author ua ON ((ur.author_id = ua.id))) ON ((ui.reference_id = ur.id)))
             JOIN public.instance_type it ON ((ui.instance_type_id = it.id)))
             LEFT JOIN (public.instance ra
             JOIN public.name nx ON ((nx.id = ra.name_id))) ON ((ui.cited_by_id = ra.id)))
             LEFT JOIN (public.instance ci
             JOIN (public.reference cr
             JOIN public.author ca ON ((cr.author_id = ca.id))) ON ((ci.reference_id = cr.id))) ON ((ui.cites_id = ci.id)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))
             LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))) nu;


--
-- Name: taxonomic_status_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.taxonomic_status_v AS
 SELECT tmv.tree_name,
    tmv.taxon_id,
    tmv.instance_id AS accepted_name_usage_id,
    tmv.instance_id AS name_usage_id,
    tmv.name_id AS accepted_name_id,
    tmv.name_id,
        CASE
            WHEN tmv.is_accepted THEN 'accepted'::text
            WHEN tmv.is_excluded THEN 'excluded'::text
            ELSE NULL::text
        END AS tree_status,
    NULL::character varying AS usage_type
   FROM public.trees_mv tmv
UNION ALL
 SELECT tmv.tree_name,
    tmv.taxon_id,
    tmv.instance_id AS accepted_name_usage_id,
    inst.id AS name_usage_id,
    tmv.name_id AS accepted_name_id,
    n.id AS name_id,
        CASE
            WHEN (it.synonym AND tmv.is_accepted) THEN 'included'::text
            WHEN tmv.is_excluded THEN 'excluded'::text
            ELSE NULL::text
        END AS tree_status,
    it.rdf_id AS usage_type
   FROM (((public.trees_mv tmv
     JOIN public.instance inst ON ((tmv.instance_id = inst.cited_by_id)))
     JOIN public.instance_type it ON ((inst.instance_type_id = it.id)))
     JOIN public.name n ON ((inst.name_id = n.id)));


--
-- Name: tree_closure_v; Type: VIEW; Schema: public; Owner: -
--
/*
CREATE VIEW public.tree_closure_v AS
 SELECT a.taxon_id AS ancestor_id,
    c.taxon_id AS node_id,
    (c.depth - a.depth) AS depth,
    c.tree_name AS dataset_name,
    t.accepted_tree
   FROM ((public.trees_mv c
     JOIN public.trees_mv a ON ((a.ltree_path OPERATOR(public.@>) c.ltree_path)))
     JOIN public.tree t ON ((c.tree_id = t.id)));
*/

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
    org_id bigint NOT NULL,
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
    context character varying(30) DEFAULT 'unknown'::character varying NOT NULL,
    CONSTRAINT name_review_comment_context_check CHECK (((context)::text ~ 'accepted|excluded|distribution|concept-note|synonym|misapplied|unknown|main'::text))
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
    not_a_real_org boolean DEFAULT false NOT NULL,
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
    updated_by character varying(50) DEFAULT USER NOT NULL
);

alter table public.users 
add constraint users_user_name_lowercase_ck 
check (user_name = lower(user_name));

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
            (((((((users.given_name)::text || ' '::text) || (users.family_name)::text) || ' for '::text) || (org.abbrev)::text) || ' as '::text) || (brrole.name)::text) AS name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            brer.created_at,
            brer.created_at,
            (((lb.name)::text || (((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' D reviewer '::text)) || (users.user_name)::text) AS order_by
           FROM (((((loader.batch_reviewer brer
             JOIN loader.batch_review br ON ((br.id = brer.batch_review_id)))
             JOIN public.users ON ((brer.user_id = users.id)))
             JOIN loader.loader_batch lb ON ((br.loader_batch_id = lb.id)))
             JOIN public.org ON ((brer.org_id = org.id)))
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

CREATE VIEW public.bdr_alt_labels_v AS
 SELECT DISTINCT ON (tx.name_id) ((c.name_context || ':'::text) || tx.name_id) AS _id,
    jsonb_build_array('skos:Concept', 'skosxl:Label') AS _type,
    tx.scientific_name AS "skos__prefLabel",
    tx.scientific_name_id AS dct__identifier,
    tx.scientific_name AS "dwc__scientificName",
    tx.scientific_name_authorship AS "dwc__scientificNameAuthorship",
    tx.nomenclatural_status AS "dwc__nomenclaturalStatus",
    tx.canonical_name AS "boa__canonicalLabel",
    tx.taxon_rank AS "dwc__taxonRank",
    tx.taxonomic_status AS "dwc__taxonomicStatus",
    jsonb_build_object('@language', 'en', '@value', 'A related name object (synonym, misapplication, etc.) cited in this revision of the NSL taxonomy.') AS skos__definition,
    tx.tree_version_id,
    tx.name_id,
    tx.accepted_name_usage_id
   FROM (public.taxon_mv tx
     LEFT JOIN public.bdr_prefix_v c ON (true))
  WHERE (tx.relationship AND tx.synonym);


--
-- Name: bdr_concept_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_concept_v AS
 SELECT ((c.name_context || ':'::text) || tx.name_id) AS _id,
    jsonb_build_array('skos:Concept', 'tn:TaxonName') AS _type,
    tx.scientific_name_id AS dct__identifier,
    tx.taxon_id AS "dwc__taxonID",
    tx.scientific_name AS "dwc__scientificName",
    tx.scientific_name_authorship AS "dwc__scientificNameAuthorship",
    tx.nomenclatural_status AS "dwc__nomenclaturalStatus",
    tx.scientific_name AS "skos__prefLabel",
    tx.canonical_name AS "boa__canonicalLabel",
    tx.taxon_rank AS "dwc__taxonRank",
    jsonb_build_object('@id', ((c.name_context || ':'::text) || px.name_id)) AS skos__broader,
    jsonb_build_object('@id', ((c.tree_context || ':'::text) || tx.tree_version_id)) AS "skos__inScheme",
    tx.taxonomic_status AS "dwc__taxonomicStatus",
    jsonb_build_object('@language', 'en', '@value', 'A taxon name object accepted in this revision of the NSL taxonomy.') AS skos__definition,
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND sx.homotypic AND (sx.taxonomic_status !~* '(misspelling|orthographic)'::text))
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasHomotypicLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND sx.heterotypic)
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasHeterotypicLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND sx.homotypic AND (sx.taxonomic_status ~* '(misspelling|orthographic)'::text))
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasOrthographicLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.misapplied)
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasMisappliedLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND (NOT sx.heterotypic) AND (NOT sx.homotypic) AND (NOT sx.misapplied))
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasSynonymicLabel",
    tx.tree_version_id,
    tx.name_id,
    tx.taxon_id,
    tx.higher_classification
   FROM ((public.taxon_mv tx
     JOIN public.taxon_mv px ON ((px.taxon_id = tx.parent_name_usage_id)))
     LEFT JOIN public.bdr_prefix_v c ON (true))
  WHERE (tx.accepted AND (tx.parent_name_usage_id IS NOT NULL))
  ORDER BY tx.higher_classification;


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

CREATE VIEW public.bdr_top_concept_v AS
 SELECT ((c.name_context || ':'::text) || tx.name_id) AS _id,
    jsonb_build_array('skos:Concept', 'tn:TaxonName') AS _type,
    tx.scientific_name_id AS dct__identifier,
    tx.taxon_id AS "dwc__taxonID",
    tx.scientific_name AS "dwc__scientificName",
    tx.scientific_name_authorship AS "dwc__scientificNameAuthorship",
    tx.nomenclatural_status AS "dwc__nomenclaturalStatus",
    tx.taxon_rank AS "dwc__taxonRank",
    tx.taxonomic_status AS "dwc__taxonomicStatus",
    jsonb_build_object('@language', 'en', '@value', 'The top taxon name object accepted in this revision of the NSL taxonomy') AS skos__definition,
    jsonb_build_object('@id', ((c.tree_context || ':'::text) || tx.tree_version_id)) AS "skos__inScheme",
    tx.scientific_name AS "skos__prefLabel",
    tx.canonical_name AS "boa__canonicalLabel",
    jsonb_build_object('@id', ((c.tree_context || ':'::text) || tx.tree_version_id)) AS "skos__topConceptOf",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND sx.homotypic AND (sx.taxonomic_status !~* '(misspelling|orthographic)'::text))
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasHomotypicLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND sx.heterotypic)
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasHeterotypicLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND sx.homotypic AND (sx.taxonomic_status ~* '(misspelling|orthographic)'::text))
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasOrthographicLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.misapplied)
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasMisappliedLabel",
    ( SELECT cited.boa__cites
           FROM ( SELECT jsonb_agg(json_build_object('@id', ((c.name_context || ':'::text) || sx.name_id))) AS boa__cites,
                    sx.accepted_name_usage_id
                   FROM public.taxon_mv sx
                  WHERE (sx.relationship AND sx.synonym AND (NOT sx.heterotypic) AND (NOT sx.homotypic) AND (NOT sx.misapplied))
                  GROUP BY sx.accepted_name_usage_id) cited
          WHERE (cited.accepted_name_usage_id = tx.taxon_id)) AS "boa__hasSynonymicLabel",
    tx.tree_version_id,
    tx.name_id,
    tx.taxon_id,
    tx.higher_classification
   FROM (public.taxon_mv tx
     LEFT JOIN public.bdr_prefix_v c ON (true))
  WHERE ((tx.parent_name_usage_id IS NULL) AND tx.accepted);


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

CREATE VIEW public.bdr_unplaced_v AS
 SELECT ((c.name_context || ':'::text) || mx.name_id) AS _id,
    jsonb_build_array('skos:Concept', 'tn:TaxonName') AS _type,
    mx.taxonomic_status AS "dwc__taxonomicStatus",
    mx.scientific_name AS "skos__prefLabel",
    mx.scientific_name_id AS dct__identifier,
    mx.scientific_name AS "dwc__scientificName",
    mx.scientific_name_authorship AS "dwc__scientificNameAuthorship",
    mx.nomenclatural_status AS "dwc__nomenclaturalStatus",
    mx.canonical_name AS "boa__canonicalLabel",
    mx.taxon_rank AS "dwc__taxonRank",
    jsonb_build_object('@id', ((c.tree_context || ':'::text) || t.current_tree_version_id)) AS "skos__inScheme",
    jsonb_build_object('@language', 'en', '@value', 'A published name object unplaced within the NSL taxonomy. Not in this SKOS scheme.') AS skos__definition,
    mx.name_id,
    t.current_tree_version_id AS tree_version_id
   FROM ((public.name_mv mx
     LEFT JOIN public.tree t ON (t.accepted_tree))
     LEFT JOIN public.bdr_prefix_v c ON (true))
  WHERE (NOT (EXISTS ( SELECT 1
           FROM public.taxon_mv tx
          WHERE (tx.name_id = mx.name_id))));


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

CREATE VIEW public.current_scheme_v AS
 SELECT 'bdr_prefix_v'::text AS view_name
   FROM public.bdr_prefix_v
UNION
 SELECT 'bdr_context_v'::text AS view_name
   FROM public.bdr_context_v
UNION
 SELECT 'bdr_sdo_v'::text AS view_name
   FROM public.bdr_sdo_v
UNION
 SELECT 'bdr_graph_v'::text AS view_name
   FROM public.bdr_graph_v
UNION
 SELECT 'bdr_tree_schema_v'::text AS view_name
   FROM public.bdr_tree_schema_v
UNION
 SELECT 'bdr_schema_v'::text AS view_name
   FROM public.bdr_schema_v
UNION
 SELECT 'bdr_top_concept_v'::text AS view_name
   FROM public.bdr_top_concept_v
UNION
 SELECT 'bdr_concept_v'::text AS view_name
   FROM public.bdr_concept_v
UNION
 SELECT 'bdr_alt_labels_v'::text AS view_name
   FROM public.bdr_alt_labels_v
UNION
 SELECT 'bdr_unplaced_v'::text AS view_name
   FROM public.bdr_unplaced_v;


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

CREATE VIEW public.dist_granular_booleans_v AS
 SELECT taxon_mv.taxon_id,
    taxon_mv.name_type,
    taxon_mv.accepted_name_usage_id,
    taxon_mv.accepted_name_usage,
    taxon_mv.nomenclatural_status,
    taxon_mv.taxonomic_status,
    taxon_mv.pro_parte,
    taxon_mv.scientific_name,
    taxon_mv.nom_illeg,
    taxon_mv.nom_inval,
    taxon_mv.scientific_name_id,
    taxon_mv.canonical_name,
    taxon_mv.scientific_name_authorship,
    taxon_mv.parent_name_usage_id,
    taxon_mv.taxon_rank,
    taxon_mv.taxon_rank_sort_order,
    taxon_mv.kingdom,
    taxon_mv.class,
    taxon_mv.subclass,
    taxon_mv.family,
    taxon_mv.taxon_concept_id,
    taxon_mv.name_according_to,
    taxon_mv.name_according_to_id,
    taxon_mv.taxon_remarks,
    taxon_mv.taxon_distribution,
    taxon_mv.higher_classification,
    taxon_mv.first_hybrid_parent_name,
    taxon_mv.first_hybrid_parent_name_id,
    taxon_mv.second_hybrid_parent_name,
    taxon_mv.second_hybrid_parent_name_id,
    taxon_mv.nomenclatural_code,
    taxon_mv.created,
    taxon_mv.modified,
    taxon_mv.dataset_name,
    taxon_mv.dataset_id,
    taxon_mv.license,
    taxon_mv.cc_attribution_iri,
    taxon_mv.tree_version_id,
    taxon_mv.tree_element_id,
    taxon_mv.instance_id,
    taxon_mv.name_id,
    taxon_mv.homotypic,
    taxon_mv.heterotypic,
    taxon_mv.misapplied,
    taxon_mv.relationship,
    taxon_mv.synonym,
    taxon_mv.excluded_name,
    taxon_mv.accepted,
    taxon_mv.accepted_id,
    taxon_mv.rank_rdf_id,
    taxon_mv.name_space,
    taxon_mv.tree_description,
    taxon_mv.tree_label,
    taxon_mv."order",
    taxon_mv.generic_name,
    taxon_mv.name_path,
    taxon_mv.node_id,
    taxon_mv.parent_node_id,
    taxon_mv.usage_type,
    taxon_mv.publication_date,
    taxon_mv.rank_hash,
    taxon_mv.usage_order,
    ((taxon_mv.taxon_distribution ~ 'ACT,'::text) OR (taxon_mv.taxon_distribution ~ 'ACT$'::text)) AS act_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'NSW,'::text) OR (taxon_mv.taxon_distribution ~ 'NSW$'::text)) AS nsw_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'NT,'::text) OR (taxon_mv.taxon_distribution ~ 'NT$'::text)) AS nt_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'Qld,'::text) OR (taxon_mv.taxon_distribution ~ 'Qld$'::text)) AS qld_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'SA,'::text) OR (taxon_mv.taxon_distribution ~ 'SA$'::text)) AS sa_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'Tas,'::text) OR (taxon_mv.taxon_distribution ~ 'Tas$'::text)) AS tas_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'Vic,'::text) OR (taxon_mv.taxon_distribution ~ 'Vic$'::text)) AS vic_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'WA,'::text) OR (taxon_mv.taxon_distribution ~ 'WA$'::text)) AS wa_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'AR,'::text) OR (taxon_mv.taxon_distribution ~ 'AR$'::text)) AS ar_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'LHI,'::text) OR (taxon_mv.taxon_distribution ~ 'LHI$'::text)) AS lhi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'ChI,'::text) OR (taxon_mv.taxon_distribution ~ 'ChI$'::text)) AS chi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'CaI,'::text) OR (taxon_mv.taxon_distribution ~ 'CaI$'::text)) AS cai_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'CSI,'::text) OR (taxon_mv.taxon_distribution ~ 'CSI$'::text)) AS csi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'CoI,'::text) OR (taxon_mv.taxon_distribution ~ 'CoI$'::text)) AS coi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'HI,'::text) OR (taxon_mv.taxon_distribution ~ 'HI$'::text)) AS hi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'MDI,'::text) OR (taxon_mv.taxon_distribution ~ 'MDI$'::text)) AS mdi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'MI,'::text) OR (taxon_mv.taxon_distribution ~ 'MI$'::text)) AS mi_unqualified_native,
    ((taxon_mv.taxon_distribution ~ 'NI,'::text) OR (taxon_mv.taxon_distribution ~ 'NI$'::text)) AS ni_unqualified_native,
    (taxon_mv.taxon_distribution ~ 'ACT \(naturalised\)'::text) AS act_naturalised,
    (taxon_mv.taxon_distribution ~ 'NSW \(naturalised\)'::text) AS nsw_naturalised,
    (taxon_mv.taxon_distribution ~ 'NT \(naturalised\)'::text) AS nt_naturalised,
    (taxon_mv.taxon_distribution ~ 'Qld \(naturalised\)'::text) AS qld_naturalised,
    (taxon_mv.taxon_distribution ~ 'SA \(naturalised\)'::text) AS sa_naturalised,
    (taxon_mv.taxon_distribution ~ 'Tas \(naturalised\)'::text) AS tas_naturalised,
    (taxon_mv.taxon_distribution ~ 'Vic \(naturalised\)'::text) AS vic_naturalised,
    (taxon_mv.taxon_distribution ~ 'WA \(naturalised\)'::text) AS wa_naturalised,
    (taxon_mv.taxon_distribution ~ 'ACT \(doubtfully naturalised\)'::text) AS act_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'NSW \(doubtfully naturalised\)'::text) AS nsw_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'NT \(doubtfully naturalised\)'::text) AS nt_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'Qld \(doubtfully naturalised\)'::text) AS qld_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'SA \(doubtfully naturalised\)'::text) AS sa_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'Tas \(doubtfully naturalised\)'::text) AS tas_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'Vic \(doubtfully naturalised\)'::text) AS vic_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'WA \(doubtfully naturalised\)'::text) AS wa_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'ACT \(formerly naturalised\)'::text) AS act_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'NSW \(formerly naturalised\)'::text) AS nsw_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'NT \(formerly naturalised\)'::text) AS nt_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'Qld \(formerly naturalised\)'::text) AS qld_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'SA \(formerly naturalised\)'::text) AS sa_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'Tas \(formerly naturalised\)'::text) AS tas_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'Vic \(formerly naturalised\)'::text) AS vic_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'WA \(formerly naturalised\)'::text) AS wa_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'ACT \(native and naturalised\)'::text) AS act_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'NSW \(native and naturalised\)'::text) AS nsw_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'NT \(native and naturalised\)'::text) AS nt_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'Qld \(native and naturalised\)'::text) AS qld_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'SA \(native and naturalised\)'::text) AS sa_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'Tas \(native and naturalised\)'::text) AS tas_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'Vic \(native and naturalised\)'::text) AS vic_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'WA \(native and naturalised\)'::text) AS wa_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'ACT \(native and doubtfully naturalised\)'::text) AS act_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'NSW \(native and doubtfully naturalised\)'::text) AS nsw_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'NT \(native and doubtfully naturalised\)'::text) AS nt_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'Qld \(native and doubtfully naturalised\)'::text) AS qld_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'SA \(native and doubtfully naturalised\)'::text) AS sa_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'Tas \(native and doubtfully naturalised\)'::text) AS tas_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'Vic \(native and doubtfully naturalised\)'::text) AS vic_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'WA \(native and doubtfully naturalised\)'::text) AS wa_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'ACT \(native and formerly naturalised\)'::text) AS act_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'NSW \(native and formerly naturalised\)'::text) AS nsw_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'NT \(native and formerly naturalised\)'::text) AS nt_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'Qld \(native and formerly naturalised\)'::text) AS qld_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'SA \(native and formerly naturalised\)'::text) AS sa_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'Tas \(native and formerly naturalised\)'::text) AS tas_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'Vic \(native and formerly naturalised\)'::text) AS vic_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'WA \(native and formerly naturalised\)'::text) AS wa_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'ACT \(native and naturalised and uncertain origin\)'::text) AS act_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NSW \(native and naturalised and uncertain origin\)'::text) AS nsw_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NT \(native and naturalised and uncertain origin\)'::text) AS nt_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Qld \(native and naturalised and uncertain origin\)'::text) AS qld_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'SA \(native and naturalised and uncertain origin\)'::text) AS sa_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Tas \(native and naturalised and uncertain origin\)'::text) AS tas_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Vic \(native and naturalised and uncertain origin\)'::text) AS vic_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'WA \(native and naturalised and uncertain origin\)'::text) AS wa_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ACT \(native and doubtfully naturalised and uncertain origin\)'::text) AS act_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NSW \(native and doubtfully naturalised and uncertain origin\)'::text) AS nsw_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NT \(native and doubtfully naturalised and uncertain origin\)'::text) AS nt_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Qld \(native and doubtfully naturalised and uncertain origin\)'::text) AS qld_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'SA \(native and doubtfully naturalised and uncertain origin\)'::text) AS sa_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Tas \(native and doubtfully naturalised and uncertain origin\)'::text) AS tas_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Vic \(native and doubtfully naturalised and uncertain origin\)'::text) AS vic_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'WA \(native and doubtfully naturalised and uncertain origin\)'::text) AS wa_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ACT \(native and uncertain origin\)'::text) AS act_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NSW \(native and uncertain origin\)'::text) AS nsw_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NT \(native and uncertain origin\)'::text) AS nt_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Qld \(native and uncertain origin\)'::text) AS qld_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'SA \(native and uncertain origin\)'::text) AS sa_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Tas \(native and uncertain origin\)'::text) AS tas_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Vic \(native and uncertain origin\)'::text) AS vic_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'WA \(native and uncertain origin\)'::text) AS wa_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ACT \(naturalised and uncertain origin\)'::text) AS act_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NSW \(naturalised and uncertain origin\)'::text) AS nsw_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NT \(naturalised and uncertain origin\)'::text) AS nt_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Qld \(naturalised and uncertain origin\)'::text) AS qld_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'SA \(naturalised and uncertain origin\)'::text) AS sa_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Tas \(naturalised and uncertain origin\)'::text) AS tas_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Vic \(naturalised and uncertain origin\)'::text) AS vic_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'WA \(naturalised and uncertain origin\)'::text) AS wa_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ACT \(presumed extinct\)'::text) AS act_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'NSW \(presumed extinct\)'::text) AS nsw_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'NT \(presumed extinct\)'::text) AS nt_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'Qld \(presumed extinct\)'::text) AS qld_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'SA \(presumed extinct\)'::text) AS sa_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'Tas \(presumed extinct\)'::text) AS tas_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'Vic \(presumed extinct\)'::text) AS vic_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'WA \(presumed extinct\)'::text) AS wa_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'ACT \(uncertain origin\)'::text) AS act_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NSW \(uncertain origin\)'::text) AS nsw_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NT \(uncertain origin\)'::text) AS nt_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Qld \(uncertain origin\)'::text) AS qld_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'SA \(uncertain origin\)'::text) AS sa_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Tas \(uncertain origin\)'::text) AS tas_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'Vic \(uncertain origin\)'::text) AS vic_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'WA \(uncertain origin\)'::text) AS wa_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'AR \(naturalised\)'::text) AS ar_naturalised,
    (taxon_mv.taxon_distribution ~ 'ChI \(naturalised\)'::text) AS chi_naturalised,
    (taxon_mv.taxon_distribution ~ 'CaI \(naturalised\)'::text) AS cai_naturalised,
    (taxon_mv.taxon_distribution ~ 'CoI \(naturalised\)'::text) AS coi_naturalised,
    (taxon_mv.taxon_distribution ~ 'CSI \(naturalised\)'::text) AS csi_naturalised,
    (taxon_mv.taxon_distribution ~ 'HI \(naturalised\)'::text) AS hi_naturalised,
    (taxon_mv.taxon_distribution ~ 'LHI \(naturalised\)'::text) AS lhi_naturalised,
    (taxon_mv.taxon_distribution ~ 'MDI \(naturalised\)'::text) AS mdi_naturalised,
    (taxon_mv.taxon_distribution ~ 'MI \(naturalised\)'::text) AS mi_naturalised,
    (taxon_mv.taxon_distribution ~ 'NI \(naturalised\)'::text) AS ni_naturalised,
    (taxon_mv.taxon_distribution ~ 'AR \(doubtfully naturalised\)'::text) AS ar_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'ChI \(doubtfully naturalised\)'::text) AS chi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'CaI \(doubtfully naturalised\)'::text) AS cai_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'CoI \(doubtfully naturalised\)'::text) AS coi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'CSI \(doubtfully naturalised\)'::text) AS csi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'HI \(doubtfully naturalised\)'::text) AS hi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'LHI \(doubtfully naturalised\)'::text) AS lhi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'MDI \(doubtfully naturalised\)'::text) AS mdi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'MI \(doubtfully naturalised\)'::text) AS mi_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'NI \(doubtfully naturalised\)'::text) AS ni_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'AR \(formerly naturalised\)'::text) AS ar_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'ChI \(formerly naturalised\)'::text) AS chi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'CaI \(formerly naturalised\)'::text) AS cai_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'CoI \(formerly naturalised\)'::text) AS coi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'CSI \(formerly naturalised\)'::text) AS csi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'HI \(formerly naturalised\)'::text) AS hi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'LHI \(formerly naturalised\)'::text) AS lhi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'MDI \(formerly naturalised\)'::text) AS mdi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'MI \(formerly naturalised\)'::text) AS mi_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'NI \(formerly naturalised\)'::text) AS ni_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'AR \(native and naturalised\)'::text) AS ar_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'ChI \(native and naturalised\)'::text) AS chi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'CaI \(native and naturalised\)'::text) AS cai_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'CoI \(native and naturalised\)'::text) AS coi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'CSI \(native and naturalised\)'::text) AS csi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'HI \(native and naturalised\)'::text) AS hi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'LHI \(native and naturalised\)'::text) AS lhi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'MDI \(native and naturalised\)'::text) AS mdi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'MI \(native and naturalised\)'::text) AS mi_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'NI \(native and naturalised\)'::text) AS ni_native_and_naturalised,
    (taxon_mv.taxon_distribution ~ 'AR \(native and doubtfully naturalised\)'::text) AS ar_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'ChI \(native and doubtfully naturalised\)'::text) AS chi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'CaI \(native and doubtfully naturalised\)'::text) AS cai_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'CoI \(native and doubtfully naturalised\)'::text) AS coi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'CSI \(native and doubtfully naturalised\)'::text) AS csi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'HI \(native and doubtfully naturalised\)'::text) AS hi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'LHI \(native and doubtfully naturalised\)'::text) AS lhi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'MDI \(native and doubtfully naturalised\)'::text) AS mdi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'MI \(native and doubtfully naturalised\)'::text) AS mi_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'NI \(native and doubtfully naturalised\)'::text) AS ni_native_and_doubtfully_naturalised,
    (taxon_mv.taxon_distribution ~ 'AR \(native and doubtfully naturalised and uncertain origin\)'::text) AS ar_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ChI \(native and doubtfully naturalised and uncertain origin\)'::text) AS chi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CaI \(native and doubtfully naturalised and uncertain origin\)'::text) AS cai_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CoI \(native and doubtfully naturalised and uncertain origin\)'::text) AS coi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CSI \(native and doubtfully naturalised and uncertain origin\)'::text) AS csi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'HI \(native and doubtfully naturalised and uncertain origin\)'::text) AS hi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'LHI \(native and doubtfully naturalised and uncertain origin\)'::text) AS lhi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MDI \(native and doubtfully naturalised and uncertain origin\)'::text) AS mdi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MI \(native and doubtfully naturalised and uncertain origin\)'::text) AS mi_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NI \(native and doubtfully naturalised and uncertain origin\)'::text) AS ni_native_and_doubtfully_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'AR \(native and formerly naturalised\)'::text) AS ar_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'ChI \(native and formerly naturalised\)'::text) AS chi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'CaI \(native and formerly naturalised\)'::text) AS cai_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'CoI \(native and formerly naturalised\)'::text) AS coi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'CSI \(native and formerly naturalised\)'::text) AS csi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'HI \(native and formerly naturalised\)'::text) AS hi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'LHI \(native and formerly naturalised\)'::text) AS lhi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'MDI \(native and formerly naturalised\)'::text) AS mdi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'MI \(native and formerly naturalised\)'::text) AS mi_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'NI \(native and formerly naturalised\)'::text) AS ni_native_and_formerly_naturalised,
    (taxon_mv.taxon_distribution ~ 'AR \(native and naturalised and uncertain origin\)'::text) AS ar_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ChI \(native and naturalised and uncertain origin\)'::text) AS chi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CaI \(native and naturalised and uncertain origin\)'::text) AS cai_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CoI \(native and naturalised and uncertain origin\)'::text) AS coi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CSI \(native and naturalised and uncertain origin\)'::text) AS csi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'HI \(native and naturalised and uncertain origin\)'::text) AS hi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'LHI \(native and naturalised and uncertain origin\)'::text) AS lhi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MDI \(native and naturalised and uncertain origin\)'::text) AS mdi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MI \(native and naturalised and uncertain origin\)'::text) AS mi_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NI \(native and naturalised and uncertain origin\)'::text) AS ni_native_and_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'AR \(native and uncertain origin\)'::text) AS ar_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ChI \(native and uncertain origin\)'::text) AS chi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CaI \(native and uncertain origin\)'::text) AS cai_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CoI \(native and uncertain origin\)'::text) AS coi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CSI \(native and uncertain origin\)'::text) AS csi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'HI \(native and uncertain origin\)'::text) AS hi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'LHI \(native and uncertain origin\)'::text) AS lhi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MDI \(native and uncertain origin\)'::text) AS mdi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MI \(native and uncertain origin\)'::text) AS mi_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NI \(native and uncertain origin\)'::text) AS ni_native_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'AR \(naturalised and uncertain origin\)'::text) AS ar_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ChI \(naturalised and uncertain origin\)'::text) AS chi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CaI \(naturalised and uncertain origin\)'::text) AS cai_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CoI \(naturalised and uncertain origin\)'::text) AS coi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CSI \(naturalised and uncertain origin\)'::text) AS csi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'HI \(naturalised and uncertain origin\)'::text) AS hi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'LHI \(naturalised and uncertain origin\)'::text) AS lhi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MDI \(naturalised and uncertain origin\)'::text) AS mdi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MI \(naturalised and uncertain origin\)'::text) AS mi_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NI \(naturalised and uncertain origin\)'::text) AS ni_naturalised_and_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'AR \(presumed extinct\)'::text) AS ar_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'ChI \(presumed extinct\)'::text) AS chi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'CaI \(presumed extinct\)'::text) AS cai_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'CoI \(presumed extinct\)'::text) AS coi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'CSI \(presumed extinct\)'::text) AS csi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'HI \(presumed extinct\)'::text) AS hi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'LHI \(presumed extinct\)'::text) AS lhi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'MDI \(presumed extinct\)'::text) AS mdi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'MI \(presumed extinct\)'::text) AS mi_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'NI \(presumed extinct\)'::text) AS ni_presumed_extinct,
    (taxon_mv.taxon_distribution ~ 'AR \(uncertain origin\)'::text) AS ar_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'ChI \(uncertain origin\)'::text) AS chi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CaI \(uncertain origin\)'::text) AS cai_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CoI \(uncertain origin\)'::text) AS coi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'CSI \(uncertain origin\)'::text) AS csi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'HI \(uncertain origin\)'::text) AS hi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'LHI \(uncertain origin\)'::text) AS lhi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MDI \(uncertain origin\)'::text) AS mdi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'MI \(uncertain origin\)'::text) AS mi_uncertain_origin,
    (taxon_mv.taxon_distribution ~ 'NI \(uncertain origin\)'::text) AS ni_uncertain_origin
   FROM public.taxon_mv
  WHERE (taxon_mv.taxonomic_status = 'accepted'::text);


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

CREATE VIEW public.dwc_name_v AS
 SELECT name_mv.scientific_name_id AS "scientificNameID",
    name_mv.name_type AS "nameType",
    name_mv.scientific_name AS "scientificName",
    name_mv.scientific_name_html AS "scientificNameHTML",
    name_mv.canonical_name AS "canonicalName",
    name_mv.canonical_name_html AS "canonicalNameHTML",
    name_mv.name_element AS "nameElement",
        CASE
            WHEN ((name_mv.nomenclatural_status)::text !~ '(legitimate|default|available)'::text) THEN name_mv.nomenclatural_status
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
    name_mv.scientific_name_authorship AS "scientificNameAuthorship",
    name_mv.autonym,
    name_mv.hybrid,
    name_mv.cultivar,
    name_mv.formula,
    name_mv.scientific,
    name_mv.nom_inval AS "nomInval",
    name_mv.nom_illeg AS "nomIlleg",
    name_mv.name_published_in AS "namePublishedIn",
    name_mv.name_published_in_id AS "namePublishedInID",
    name_mv.name_published_in_year AS "namePublishedInYear",
    name_mv.name_instance_type AS "nameInstanceType",
    name_mv.name_according_to_id AS "nameAccordingToID",
    name_mv.name_according_to AS "nameAccordingTo",
    name_mv.original_name_usage AS "originalNameUsage",
    name_mv.original_name_usage_id AS "originalNameUsageID",
    name_mv.original_name_usage_year AS "originalNameUsageYear",
    name_mv.type_citation AS "typeCitation",
    name_mv.kingdom,
    name_mv.family,
    name_mv.generic_name AS "genericName",
    name_mv.specific_epithet AS "specificEpithet",
    name_mv.infraspecific_epithet AS "infraspecificEpithet",
    name_mv.cultivar_epithet AS "cultivarEpithet",
    name_mv.taxon_rank AS "taxonRank",
    name_mv.taxon_rank_sort_order AS "taxonRankSortOrder",
    name_mv.taxon_rank_abbreviation AS "taxonRankAbbreviation",
    name_mv.first_hybrid_parent_name AS "firstHybridParentName",
    name_mv.first_hybrid_parent_name_id AS "firstHybridParentNameID",
    name_mv.second_hybrid_parent_name AS "secondHybridParentName",
    name_mv.second_hybrid_parent_name_id AS "secondHybridParentNameID",
    name_mv.created,
    name_mv.modified,
    name_mv.nomenclatural_code AS "nomenclaturalCode",
    name_mv.dataset_name AS "datasetName",
    name_mv.taxonomic_status AS "taxonomicStatus",
    name_mv.status_according_to AS "statusAccordingTo",
    name_mv.license,
    name_mv.cc_attribution_iri AS "ccAttributionIRI"
   FROM public.name_mv;


--
-- Name: VIEW dwc_name_v; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.dwc_name_v IS 'Based on NAME_MV, a camelCase listing of a shard''s scientific_names with "status_according_to" the current "accepted_tree", using Darwin_Core semantics where available';


--
-- Name: dwc_taxon_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dwc_taxon_v AS
 SELECT taxon_mv.taxon_id AS "taxonID",
    taxon_mv.name_type AS "nameType",
    taxon_mv.accepted_name_usage_id AS "acceptedNameUsageID",
    taxon_mv.accepted_name_usage AS "acceptedNameUsage",
        CASE
            WHEN ((taxon_mv.nomenclatural_status)::text !~ '(legitimate|default|available)'::text) THEN taxon_mv.nomenclatural_status
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
    taxon_mv.nom_illeg AS "nomIlleg",
    taxon_mv.nom_inval AS "nomInval",
    taxon_mv.taxonomic_status AS "taxonomicStatus",
    taxon_mv.pro_parte AS "proParte",
    taxon_mv.scientific_name AS "scientificName",
    taxon_mv.scientific_name_id AS "scientificNameID",
    taxon_mv.canonical_name AS "canonicalName",
    taxon_mv.scientific_name_authorship AS "scientificNameAuthorship",
    taxon_mv.parent_name_usage_id AS "parentNameUsageID",
    taxon_mv.taxon_rank AS "taxonRank",
    taxon_mv.taxon_rank_sort_order AS "taxonRankSortOrder",
    taxon_mv.kingdom,
    taxon_mv.class,
    taxon_mv.subclass,
    taxon_mv.family,
    taxon_mv.taxon_concept_id AS "taxonConceptID",
    taxon_mv.name_according_to AS "nameAccordingTo",
    taxon_mv.name_according_to_id AS "nameAccordingToID",
    taxon_mv.taxon_remarks AS "taxonRemarks",
    taxon_mv.taxon_distribution AS "taxonDistribution",
    taxon_mv.higher_classification AS "higherClassification",
    taxon_mv.first_hybrid_parent_name AS "firstHybridParentName",
    taxon_mv.first_hybrid_parent_name_id AS "firstHybridParentNameID",
    taxon_mv.second_hybrid_parent_name AS "secondHybridParentName",
    taxon_mv.second_hybrid_parent_name_id AS "secondHybridParentNameID",
    taxon_mv.nomenclatural_code AS "nomenclaturalCode",
    taxon_mv.created,
    taxon_mv.modified,
    taxon_mv.dataset_name AS "datasetName",
    taxon_mv.dataset_id AS "dataSetID",
    taxon_mv.license,
    taxon_mv.cc_attribution_iri AS "ccAttributionIRI"
   FROM public.taxon_mv;


--
-- Name: VIEW dwc_taxon_v; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.dwc_taxon_v IS 'Based on TAXON_MV, a camelCase DarwinCore view of the shard''s taxonomy using the current default tree version';


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

CREATE VIEW public.name_view AS
 SELECT name_mv.name_id,
    name_mv.scientific_name_id AS "scientificNameID",
    name_mv.name_type AS "nameType",
    name_mv.scientific_name AS "scientificName",
    name_mv.scientific_name_html AS "scientificNameHTML",
    name_mv.canonical_name AS "canonicalName",
    name_mv.canonical_name_html AS "canonicalNameHTML",
    name_mv.name_element AS "nameElement",
        CASE
            WHEN ((name_mv.nomenclatural_status)::text !~ '(legitimate|default|available)'::text) THEN name_mv.nomenclatural_status
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
    name_mv.scientific_name_authorship AS "scientificNameAuthorship",
    name_mv.autonym,
    name_mv.hybrid,
    name_mv.cultivar,
    name_mv.formula,
    name_mv.scientific,
    name_mv.nom_inval AS "nomInval",
    name_mv.nom_illeg AS "nomIlleg",
    name_mv.name_published_in AS "namePublishedIn",
    name_mv.name_published_in_id AS "namePublishedInID",
    name_mv.name_published_in_year AS "namePublishedInYear",
    name_mv.name_instance_type AS "nameInstanceType",
    name_mv.name_according_to_id AS "nameAccordingToID",
    name_mv.name_according_to AS "nameAccordingTo",
    name_mv.original_name_usage AS "originalNameUsage",
    name_mv.original_name_usage_id AS "originalNameUsageID",
    name_mv.original_name_usage_year AS "originalNameUsageYear",
    name_mv.type_citation AS "typeCitation",
    name_mv.kingdom,
    name_mv.family,
    name_mv.generic_name AS "genericName",
    name_mv.specific_epithet AS "specificEpithet",
    name_mv.infraspecific_epithet AS "infraspecificEpithet",
    name_mv.cultivar_epithet AS "cultivarEpithet",
    name_mv.taxon_rank AS "taxonRank",
    name_mv.taxon_rank_sort_order AS "taxonRankSortOrder",
    name_mv.taxon_rank_abbreviation AS "taxonRankAbbreviation",
    name_mv.first_hybrid_parent_name AS "firstHybridParentName",
    name_mv.first_hybrid_parent_name_id AS "firstHybridParentNameID",
    name_mv.second_hybrid_parent_name AS "secondHybridParentName",
    name_mv.second_hybrid_parent_name_id AS "secondHybridParentNameID",
    name_mv.created,
    name_mv.modified,
    name_mv.nomenclatural_code AS "nomenclaturalCode",
    name_mv.dataset_name AS "datasetName",
    name_mv.taxonomic_status AS "taxonomicStatus",
    name_mv.status_according_to AS "statusAccordingTo",
    name_mv.license,
    name_mv.cc_attribution_iri AS "ccAttributionIRI"
   FROM public.name_mv;


--
-- Name: VIEW name_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.name_view IS 'Based on NAME_MV, a camelCase listing of a shard''s scientific_names with "status_according_to" the current "accepted_tree", using Darwin_Core semantics where available';


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
/*
CREATE VIEW public.nsl_taxon_cv AS
 SELECT taxon_cv."treeName",
    taxon_cv."treeVersionId",
    taxon_cv.identifier,
    taxon_cv.title,
    taxon_cv."treeElementId",
    taxon_cv."taxonNameUsageLabel",
    taxon_cv."taxonId",
    taxon_cv."parentTaxonId",
    taxon_cv."nameId",
    taxon_cv."referenceId",
    taxon_cv."publicationYear",
    taxon_cv."publicationCitation",
    taxon_cv."publicationDate",
    taxon_cv."fullName",
    taxon_cv."taxonConceptId",
    taxon_cv."isExcluded",
    taxon_cv."taxonomicStatus",
    taxon_cv.modified,
    taxon_cv.depth,
    taxon_cv."namePath",
    taxon_cv."lTreePath",
    taxon_cv."datasetName",
    taxon_cv."treeRDFId",
    taxon_cv."isTrue"
   FROM apc.taxon_cv;
*/

--
-- Name: nsl_tree_closure_cv; Type: VIEW; Schema: public; Owner: -
--
/*
CREATE VIEW public.nsl_tree_closure_cv AS
 SELECT tree_closure_cv."ancestorId",
    tree_closure_cv."nodeId",
    tree_closure_cv.depth
   FROM apc.tree_closure_cv;
*/

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
    api_date timestamp with time zone
);


--
-- Name: TABLE product; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product IS 'Describes a product available within the NSL infrastructure.';


--
-- Name: COLUMN product.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.id IS 'A system wide unique identifier allocated to each profile product.';


--
-- Name: COLUMN product.tree_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.tree_id IS 'The tree (taxonomy) used for this product.';


--
-- Name: COLUMN product.reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.reference_id IS 'The highest level reference for this product.';


--
-- Name: COLUMN product.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.name IS 'The standard acronym for this profile product. i.e. FOA, APC.';


--
-- Name: COLUMN product.description_html; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.description_html IS 'The full name for this profile product. i.e. Flora of Australia.';


--
-- Name: COLUMN product.is_current; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.is_current IS 'Indicates this product is currently being maintained and published.';


--
-- Name: COLUMN product.is_available; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.is_available IS 'Indicates this product is publicly available.';


--
-- Name: COLUMN product.is_name_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.is_name_index IS 'Indicates this product is THE name index for this dataset/shard.';


--
-- Name: COLUMN product.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.source_id IS 'The key at the source system imported on migration.';


--
-- Name: COLUMN product.source_system; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN product.source_id_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN product.namespace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.namespace_id IS 'The auNSL dataset that physically contains this profile text.';


--
-- Name: COLUMN product.internal_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.internal_notes IS 'Team notes about the management or maintenance of this product.';


--
-- Name: COLUMN product.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN product.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN product.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN product.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN product.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN product.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN product.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product.api_date IS 'The date when a script, jira or services task last changed this record.';


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

COMMENT ON TABLE public.product_item_config IS 'The profile item type(s) available for a specific Product and the customisation for that product.';


--
-- Name: COLUMN product_item_config.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.id IS 'A system wide unique identifier allocated to each profile item config record.';


--
-- Name: COLUMN product_item_config.product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.product_id IS 'The product that uses this profile item type.';


--
-- Name: COLUMN product_item_config.profile_item_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.profile_item_type_id IS 'A profile item type used by this product.';


--
-- Name: COLUMN product_item_config.sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.sort_order IS 'The order of the profile item in a product. Determines the order presented to the user within the editor.';


--
-- Name: COLUMN product_item_config.tool_tip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.tool_tip IS 'The helper text associated with this profile item type in a profile product.';


--
-- Name: COLUMN product_item_config.is_deprecated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.is_deprecated IS 'Profile item type no longer available for editing in this product.';


--
-- Name: COLUMN product_item_config.is_hidden; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.is_hidden IS 'Profile item type hidden from public output.';


--
-- Name: COLUMN product_item_config.internal_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.internal_notes IS 'Team notes about the management or maintenance of this item type.';


--
-- Name: COLUMN product_item_config.external_context; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.external_context IS 'Export profile content to this external source.';


--
-- Name: COLUMN product_item_config.external_mapping; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.external_mapping IS 'Export profile content to this external source mapping.';


--
-- Name: COLUMN product_item_config.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN product_item_config.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN product_item_config.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN product_item_config.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN product_item_config.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.api_name IS 'The name of a system user, script, jira or services task which last changed this record.';


--
-- Name: COLUMN product_item_config.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.product_item_config.api_date IS 'The date when a system user, script, jira or services task last changed this record.';


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(50) NOT NULL check(name = lower(name)),
    description text DEFAULT 'Please describe this role'::text NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


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

COMMENT ON TABLE public.profile_item IS 'The use of a statement/content for a taxon concept by a product. The specific statement/content is recorded based on its explicit data type (text, reference, distribution etc).';


--
-- Name: COLUMN profile_item.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.id IS 'A system wide unique identifier allocated to each profile item record.';


--
-- Name: COLUMN profile_item.instance_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.instance_id IS 'The taxon concept (as the accepted taxon name usage instance) for which this statement/content is being made.';


--
-- Name: COLUMN profile_item.product_item_config_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.product_item_config_id IS 'The category of statement/content for this profile item (as the profile item type).';


--
-- Name: COLUMN profile_item.profile_object_rdf_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.profile_object_rdf_id IS 'The data object which contains the statement/content for this profile item.';


--
-- Name: COLUMN profile_item.source_profile_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.source_profile_item_id IS 'The statement/content (as profile item) being re-used for this profile.';


--
-- Name: COLUMN profile_item.is_draft; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.is_draft IS 'A boolean to indicate this profile item is in draft mode and is not publicly available.';


--
-- Name: COLUMN profile_item.published_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.published_date IS 'The date this version of the content was published. Used to manage versions of content within the same taxon concept.';


--
-- Name: COLUMN profile_item.end_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.end_date IS 'The date when this version of the content was replaced or ended. Used to manage versions of content within the same taxon concept.';


--
-- Name: COLUMN profile_item.statement_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.statement_type IS 'Indicates whether this statement/content is original content (fact) or re-use (link) of original content.';


--
-- Name: COLUMN profile_item.profile_text_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.profile_text_id IS 'The profile text for this profile item.';


--
-- Name: COLUMN profile_item.is_object_type_reference; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.is_object_type_reference IS 'A placeholder to indicate this profile item is for a list of references available in profile_references. 1=is a profile_reference data, null = not a profile reference. Used to constrain an item type to only one object type.';


--
-- Name: COLUMN profile_item.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.source_id IS 'The key at the source system imported on migration';


--
-- Name: COLUMN profile_item.source_id_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile_item.source_system; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile_item.namespace_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.namespace_id IS 'The auNSL dataset that physically contains this profile text.';


--
-- Name: COLUMN profile_item.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_item.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_item.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_item.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_item.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_item.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.api_name IS 'The name of a system user, script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_item.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item.api_date IS 'The date when a system user, script, jira or services task last changed this record.';


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

COMMENT ON TABLE public.profile_item_annotation IS 'An annotation made on a profile item.';


--
-- Name: COLUMN profile_item_annotation.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.id IS 'A system wide unique identifier allocated to each profile annotation record.';


--
-- Name: COLUMN profile_item_annotation.profile_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.profile_item_id IS 'The profile item about which this annotation is made.';


--
-- Name: COLUMN profile_item_annotation.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.value IS 'The annotation statement.';


--
-- Name: COLUMN profile_item_annotation.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.source_id IS 'The key at the source system imported on migration';


--
-- Name: COLUMN profile_item_annotation.source_id_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile_item_annotation.source_system; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile_item_annotation.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_item_annotation.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_item_annotation.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_item_annotation.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_item_annotation.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_item_annotation.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.api_name IS 'The name of a system user, script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_item_annotation.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_annotation.api_date IS 'The date when a system user, script, jira or services task last changed this record.';


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

COMMENT ON TABLE public.profile_item_reference IS 'The use of a reference for a profile i.e. list of general references for the taxon being described by this profile.';


--
-- Name: COLUMN profile_item_reference.profile_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.profile_item_id IS 'The profile item which is using this reference.';


--
-- Name: COLUMN profile_item_reference.reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.reference_id IS 'The reference which is being used by this profile item.';


--
-- Name: COLUMN profile_item_reference.pages; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.pages IS 'The page number(s) for this usage of the reference.';


--
-- Name: COLUMN profile_item_reference.annotation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.annotation IS 'An annotation made by the profile editor about the use of this reference.';


--
-- Name: COLUMN profile_item_reference.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_item_reference.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_item_reference.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_item_reference.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_item_reference.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_item_reference.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.api_name IS 'The name of a system user, script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_item_reference.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_reference.api_date IS 'The date when a system user, script, jira or services task last changed this record.';


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

COMMENT ON TABLE public.profile_item_type IS 'The superset of terms for Products arranged hierarchically and the object type associated with this term.';


--
-- Name: COLUMN profile_item_type.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.id IS 'A system wide unique identifier allocated to each profile item type.';


--
-- Name: COLUMN profile_item_type.profile_object_type_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.profile_object_type_id IS 'The object type for this profile item type.';


--
-- Name: COLUMN profile_item_type.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.name IS 'The full path to this profile item type as a Postgres btree.';


--
-- Name: COLUMN profile_item_type.rdf_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.rdf_id IS 'Alternate unique key with an english (like) value i.e. morphology.';


--
-- Name: COLUMN profile_item_type.description_html; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.description_html IS 'The global definition of this term.';


--
-- Name: COLUMN profile_item_type.sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.sort_order IS 'The default sort order for the superset of terms.';


--
-- Name: COLUMN profile_item_type.is_deprecated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.is_deprecated IS 'Object type no longer available for use.';


--
-- Name: COLUMN profile_item_type.internal_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.internal_notes IS 'Team notes about the management or maintenance of this item type.';


--
-- Name: COLUMN profile_item_type.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.lock_version IS 'Internal Postgres management for record locking.';


--
-- Name: COLUMN profile_item_type.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_item_type.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_item_type.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_item_type.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_item_type.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.api_name IS 'The name of a system user, script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_item_type.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_item_type.api_date IS 'The date when a system user, script, jira or services task last changed this record.';


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

COMMENT ON TABLE public.profile_object_type IS 'The supported object types within the National Species List infrastructure i.e text, reference, (later distribution etc)';


--
-- Name: COLUMN profile_object_type.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.id IS 'A system wide unique identifier allocated to each profile object type.';


--
-- Name: COLUMN profile_object_type.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.name IS 'The name of the table which contains this data type.';


--
-- Name: COLUMN profile_object_type.rdf_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.rdf_id IS 'Alternate unique key with english (like) value i.e. text.';


--
-- Name: COLUMN profile_object_type.is_deprecated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.is_deprecated IS 'Object type no longer available for use.';


--
-- Name: COLUMN profile_object_type.internal_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.internal_notes IS 'Team notes about the management or maintenance of this object type.';


--
-- Name: COLUMN profile_object_type.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.lock_version IS 'Internal Postgres management for record locking.';


--
-- Name: COLUMN profile_object_type.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_object_type.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_object_type.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_object_type.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_object_type.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_object_type.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_object_type.api_date IS 'The date when a script, jira or services task last changed this record.';


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

COMMENT ON TABLE public.profile_text IS 'Text based content for a taxon concept about a profile item type. It has one original source (fact) and can be quoted (or linked to) many times.';


--
-- Name: COLUMN profile_text.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.id IS 'A system wide unique identifier allocated to each profile text record.';


--
-- Name: COLUMN profile_text.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.value IS 'The original text written for a defined category of information, for a taxon in a profile.';


--
-- Name: COLUMN profile_text.value_md; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.value_md IS 'The mark down version of the text.';


--
-- Name: COLUMN profile_text.source_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.source_id IS 'The key at the source system imported on migration';


--
-- Name: COLUMN profile_text.source_system; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile_text.source_id_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile_text.lock_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_text.created_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_text.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_text.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_text.updated_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_text.api_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.api_name IS 'The name of a system user, script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_text.api_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profile_text.api_date IS 'The date when a system user, script, jira or services task last changed this record.';


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

CREATE TABLE public.taxon_mv_compare (
    taxon_id text,
    mv json,
    taxon_mv text,
    new json,
    taxon_mv_new text
);


--
-- Name: taxon_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.taxon_view AS
 SELECT taxon_mv.taxon_id AS "taxonID",
    taxon_mv.name_type AS "nameType",
    taxon_mv.accepted_name_usage_id AS "acceptedNameUsageID",
    taxon_mv.accepted_name_usage AS "acceptedNameUsage",
        CASE
            WHEN ((taxon_mv.nomenclatural_status)::text !~ '(legitimate|default|available)'::text) THEN taxon_mv.nomenclatural_status
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
    taxon_mv.nom_illeg AS "nomIlleg",
    taxon_mv.nom_inval AS "nomInval",
    taxon_mv.taxonomic_status AS "taxonomicStatus",
    taxon_mv.pro_parte AS "proParte",
    taxon_mv.scientific_name AS "scientificName",
    taxon_mv.scientific_name_id AS "scientificNameID",
    taxon_mv.canonical_name AS "canonicalName",
    taxon_mv.scientific_name_authorship AS "scientificNameAuthorship",
    taxon_mv.parent_name_usage_id AS "parentNameUsageID",
    taxon_mv.taxon_rank AS "taxonRank",
    taxon_mv.taxon_rank_sort_order AS "taxonRankSortOrder",
    taxon_mv.kingdom,
    taxon_mv.class,
    taxon_mv.subclass,
    taxon_mv.family,
    taxon_mv.taxon_concept_id AS "taxonConceptID",
    taxon_mv.name_according_to AS "nameAccordingTo",
    taxon_mv.name_according_to_id AS "nameAccordingToID",
    taxon_mv.taxon_remarks AS "taxonRemarks",
    taxon_mv.taxon_distribution AS "taxonDistribution",
    taxon_mv.higher_classification AS "higherClassification",
    taxon_mv.first_hybrid_parent_name AS "firstHybridParentName",
    taxon_mv.first_hybrid_parent_name_id AS "firstHybridParentNameID",
    taxon_mv.second_hybrid_parent_name AS "secondHybridParentName",
    taxon_mv.second_hybrid_parent_name_id AS "secondHybridParentNameID",
    taxon_mv.nomenclatural_code AS "nomenclaturalCode",
    taxon_mv.created,
    taxon_mv.modified,
    taxon_mv.dataset_name AS "datasetName",
    taxon_mv.dataset_id AS "dataSetID",
    taxon_mv.license,
    taxon_mv.cc_attribution_iri AS "ccAttributionIRI"
   FROM public.taxon_mv;


--
-- Name: VIEW taxon_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.taxon_view IS 'Based on TAXON_MV, a camelCase DarwinCore view of the shard''s taxonomy using the current default tree version';


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
-- Name: product_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_role (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    product_id bigint NOT NULL,
    role_id bigint NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
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
    product.id AS product_id,
    roles.id AS role_id
   FROM ((((((public.user_product_role upr
     JOIN public.users ON ((upr.user_id = users.id)))
     JOIN public.product_role pr ON ((upr.product_role_id = pr.id)))
     JOIN public.product ON ((pr.product_id = product.id)))
     JOIN public.roles ON ((pr.role_id = roles.id)))
     LEFT JOIN public.reference ref ON ((product.reference_id = ref.id)))
     LEFT JOIN public.tree ON ((product.tree_id = tree.id)))
  ORDER BY users.user_name, product.name, roles.name;


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
-- Name: wfo_export; Type: VIEW; Schema: public; Owner: -
--
/*
CREATE VIEW public.wfo_export AS
 SELECT (((s.url)::text || '/'::text) || (res.path)::text) AS wfo_link,
    ((('https://'::text || (host.host_name)::text) || '/'::text) || n.uri) AS name_id,
    n.full_name_html,
    n.full_name
   FROM (((((public.resource res
     JOIN public.resource_type rt ON ((res.resource_type_id = rt.id)))
     JOIN public.site s ON ((res.site_id = s.id)))
     JOIN public.name_resources nr ON ((res.id = nr.resource_id)))
     JOIN public.name n ON ((nr.name_id = n.id)))
     JOIN mapper.host host ON (host.preferred));


--
-- Name: VIEW wfo_export; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.wfo_export IS 'This provides a link of World Flora Online (WFO) IDs to APNI names as provided by the WFO';


--
-- Name: COLUMN wfo_export.wfo_link; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wfo_export.wfo_link IS 'Link to World Flora Online.';


--
-- Name: COLUMN wfo_export.name_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wfo_export.name_id IS 'ID (link) to the Name in APNI';


--
-- Name: COLUMN wfo_export.full_name_html; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wfo_export.full_name_html IS 'The name including the authority with HTML mark up.';


--
-- Name: COLUMN wfo_export.full_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.wfo_export.full_name IS 'The name including the authority without HTML mark up.';
*/

--
-- Name: xpg; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xpg (
    id integer,
    line text
);


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
-- Name: roles role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


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
-- Name: roles roles_unique_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_unique_name UNIQUE (name);


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
-- Name: user_product_role user_product_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_product_role
    ADD CONSTRAINT user_product_role_pkey PRIMARY KEY (user_id, product_role_id);


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

CREATE INDEX accepted_name_anuid_i ON public.taxon_mv USING btree (accepted_name_usage_id, relationship, synonym);


--
-- Name: accepted_name_id_i; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accepted_name_id_i ON public.taxon_mv USING btree (taxon_id, accepted_name_usage_id);


--
-- Name: accepted_name_instance_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accepted_name_instance_i ON public.taxon_mv USING btree (instance_id);


--
-- Name: accepted_name_name_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accepted_name_name_i ON public.taxon_mv USING btree (scientific_name);


--
-- Name: accepted_name_name_id_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accepted_name_name_id_i ON public.taxon_mv USING btree (scientific_name_id);


--
-- Name: accepted_name_txid_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accepted_name_txid_i ON public.taxon_mv USING btree (accepted_id);


--
-- Name: accepted_name_version_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX accepted_name_version_i ON public.taxon_mv USING btree (tree_version_id);


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

CREATE INDEX name_mv_canonical_i ON public.name_mv USING btree (canonical_name);


--
-- Name: name_mv_family_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_mv_family_i ON public.name_mv USING btree (family);


--
-- Name: name_mv_id_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_mv_id_i ON public.name_mv USING btree (name_id);


--
-- Name: name_mv_name_i; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_mv_name_i ON public.name_mv USING btree (scientific_name);


--
-- Name: name_mv_name_id_i; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX name_mv_name_id_i ON public.name_mv USING btree (scientific_name_id);


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

CREATE INDEX nsl_tree_accepted_name_index ON public.trees_mv USING btree (name_id) WHERE (accepted_tree AND is_accepted);


--
-- Name: nsl_tree_excluded_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nsl_tree_excluded_name_index ON public.trees_mv USING btree (name_id) WHERE (accepted_tree AND is_excluded);


--
-- Name: nsl_tree_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nsl_tree_name_index ON public.trees_mv USING btree (name_id) WHERE accepted_tree;


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

CREATE INDEX taxon_compare_id_i ON public.taxon_mv_compare USING btree (taxon_id);


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

CREATE INDEX trees_id_index ON public.trees_mv USING btree (tree_id);


--
-- Name: trees_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_name_index ON public.trees_mv USING btree (tree_name);


--
-- Name: trees_name_path_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_name_path_id_index ON public.trees_mv USING gin (name_path public.gin_trgm_ops);


--
-- Name: trees_parent_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_parent_id_index ON public.trees_mv USING btree (parent_element_id);


--
-- Name: trees_parent_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_parent_taxon_id_index ON public.trees_mv USING btree (parent_taxon_id);


--
-- Name: trees_path_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_path_id_index ON public.trees_mv USING btree (tree_element_id);


--
-- Name: trees_path_instance_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_path_instance_id_index ON public.trees_mv USING btree (instance_id);


--
-- Name: trees_path_ltree_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_path_ltree_path_index ON public.trees_mv USING gist (ltree_path);


--
-- Name: trees_path_name_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_path_name_id_index ON public.trees_mv USING btree (name_id, is_excluded);


--
-- Name: trees_path_sort_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trees_path_sort_name_index ON public.trees_mv USING btree (sort_name);


--
-- Name: trees_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX trees_taxon_id_index ON public.trees_mv USING btree (taxon_id);


--
-- Name: author audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--
/*
CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', 'i', '{id,abbrev,duplicate_of_id,full_name,name,notes,ipni_id,valid_record}', '{created_at,created_by,updated_at,updated_by}');


--
-- Name: comment audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.comment FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', 'i', '{id,author_id,name_id,reference_id,instance_id,text}', '{created_at,created_by,updated_at,updated_by}');


--
-- Name: instance audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.instance FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', 'i', '{id,bhl_url,cites_id,cited_by_id,draft,instance_type_id,name_id,page,page_qualifier,parent_id,reference_id,verbatim_name_string,nomenclatural_status,valid_record}', '{created_at,created_by,updated_at,updated_by}');


--
-- Name: instance_note audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.instance_note FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', 'i', '{id,instance_note_key_id,value}', '{created_at,created_by,updated_at,updated_by}');


--
-- Name: name audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', 'i', '{id,author_id,base_author_id,duplicate_of_id,ex_author_id,ex_base_author_id,family_id,full_name,name_rank_id,name_status_id,name_type_id,parent_id,sanctioning_author_id,second_parent_id,verbatim_name_string,orth_var,changed_combination,valid_record,published_year}', '{created_at,created_by,updated_at,updated_by}');


--
-- Name: reference audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.reference FOR EACH ROW EXECUTE FUNCTION audit.if_modified_func('true', 'i', '{id,bhl_url,doi,duplicate_of_id,edition,isbn,iso_publication_date,issn,language_id,notes,pages,parent_id,publication_date,published,published_location,publisher,ref_author_role_id,ref_type_id,title,volume,year,tl2,valid_record,verbatim_author,verbatim_citation,verbatim_reference}', '{created_at,created_by,updated_at,updated_by}');


--
-- Name: tree_element audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.tree_element FOR EACH ROW EXECUTE FUNCTION audit.if_modified_tree_element('true', 'i', '{id}');


--
-- Name: author audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.author FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: comment audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.comment FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: instance audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.instance FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: instance_note audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.instance_note FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: name audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.name FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: reference audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.reference FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_func('true');


--
-- Name: tree_element audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.tree_element FOR EACH STATEMENT EXECUTE FUNCTION audit.if_modified_tree_element('true');
*/


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
-- Name: tree_element tree_element_first_tree_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT tree_element_first_tree_version_id_fkey FOREIGN KEY (first_tree_version_id) REFERENCES public.tree_version(id);


ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT product_role_pkey PRIMARY KEY (id);

--
-- Name: user_product_role upr_product_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_product_role
    ADD CONSTRAINT upr_product_role_fk FOREIGN KEY (product_role_id) REFERENCES public.product_role(id);


--
-- Name: product_role upr_roles_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT pr_unique_product_role UNIQUE (product_id, role_id);

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT pr_roles_fk FOREIGN KEY (role_id) REFERENCES public.roles(id);

ALTER TABLE ONLY public.product_role
    ADD CONSTRAINT pr_product_fk FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- Name: user_product_role upr_users_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_product_role
    ADD CONSTRAINT upr_users_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


ALTER TABLE only public.author
ADD CONSTRAINT abbrev_length_check
CHECK (char_length(abbrev) <= 150);

--
-- PostgreSQL database dump complete
--

SET search_path TO public,loader;



