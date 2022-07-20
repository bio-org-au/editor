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
-- Name: archive; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA archive;


--
-- Name: loader; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA loader;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


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
-- Name: name_walk(bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_walk(nameid bigint, rank text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
    declare
        gname_id bigint;
        p bigint;
        rorder integer;
        s integer;
        gname text;
        fid bigint;
    begin
	    select sort_order into s from name_rank where rdf_id = rank;

	    SELECT into p, rorder, gname, fid parent_id, sort_order, simple_name, family_id from public.name
	        join public.name_rank on name.name_rank_id = name_rank.id
	    WHERE name.id = nameid;

	    while  rorder > s and p is not null loop

	            gname_id := p;

			    SELECT into p, rorder, gname, fid parent_id, sort_order, simple_name, family_id from public.name
				    join public.name_rank on name.name_rank_id = name_rank.id
			    WHERE name.id = gname_id;

		    end loop;

	    if s = rorder then
		    return jsonb_build_object ('id', gname_id, 'name', gname, 'family_id', fid);
	    else
	        return null;
        end if;

    end;
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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: loader_batch_raw_list_100; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_list_100 (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_list_2019_with_more_full_names; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_list_2019_with_more_full_names (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_list_2019_with_taxon_full; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_list_2019_with_taxon_full (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_names_04_mar_2022; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_04_mar_2022 (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_names_05_mar_2022; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_05_mar_2022 (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_names_07_feb_2022; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_07_feb_2022 (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_names_14_feb_2022; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_14_feb_2022 (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful text,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: loader_batch_raw_names_16_feb_2022; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_16_feb_2022 (
    id bigint,
    record_type text,
    parent_id bigint,
    family text,
    hr_comment text,
    rank text,
    rank_nsl text,
    taxon text,
    taxon_full text,
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
    doubtful boolean,
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
    note text,
    footnote text,
    distribution text,
    comment_ text,
    remark text,
    original_text text
);


--
-- Name: nsl3164; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.nsl3164 (
    id integer,
    accepted_name character varying(120),
    orthvar1 character varying(120),
    orthvar2 character varying(120),
    orthvar3 character varying(120),
    orthvar4 character varying(120),
    done boolean
);


--
-- Name: orchid_batch_job_locks; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.orchid_batch_job_locks (
    restriction integer DEFAULT 1 NOT NULL,
    name character varying(30),
    CONSTRAINT force_one_row CHECK ((restriction = 1))
);


--
-- Name: orchid_processing_logs; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.orchid_processing_logs (
    id integer NOT NULL,
    log_entry text DEFAULT 'Wat?'::text NOT NULL,
    logged_at timestamp with time zone DEFAULT now() NOT NULL,
    logged_by character varying(255) NOT NULL
);


--
-- Name: orchid_processing_logs_id_seq; Type: SEQUENCE; Schema: archive; Owner: -
--

CREATE SEQUENCE archive.orchid_processing_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orchid_processing_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: archive; Owner: -
--

ALTER SEQUENCE archive.orchid_processing_logs_id_seq OWNED BY archive.orchid_processing_logs.id;


--
-- Name: orchidaceae; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.orchidaceae (
    id integer,
    record_type text,
    parent_id integer,
    hybrid_id text,
    family text,
    hr_comment text,
    subfamily text,
    tribe text,
    subtribe text,
    rank text,
    nsl_rank text,
    taxon text,
    base_author text,
    ex_base_author text,
    comb_author text,
    ex_comb_author text,
    author_rank text,
    name_status text,
    name_comment text,
    partly text,
    auct_non text,
    synonym_type text,
    doubtful text,
    questionable text,
    hybrid_level text,
    publication text,
    note_and_publication text,
    warning text,
    footnote text,
    distribution text,
    comment text,
    original_text text
);


--
-- Name: orchids; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.orchids (
    id bigint NOT NULL,
    record_type text NOT NULL,
    parent_id bigint,
    hybrid text,
    family text NOT NULL,
    hr_comment text,
    subfamily text,
    tribe text,
    subtribe text,
    rank text,
    nsl_rank text,
    taxon text NOT NULL,
    ex_base_author text,
    base_author text,
    ex_author text,
    author text,
    author_rank text,
    name_status text,
    name_comment text,
    partly text,
    auct_non text,
    synonym_type text,
    doubtful boolean DEFAULT false NOT NULL,
    hybrid_level text,
    isonym text,
    publ_count bigint,
    article_author text,
    article_title text,
    article_title_full text,
    in_flag text,
    author_2 text,
    title text,
    title_full text,
    edition text,
    volume text,
    page text,
    year text,
    date_ text,
    publ_partly text,
    publ_note text,
    note text,
    footnote text,
    distribution text,
    comment text,
    remark text,
    original_text text,
    seq bigint DEFAULT 0 NOT NULL,
    alt_taxon_for_matching text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(255) DEFAULT 'batch'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(255) DEFAULT 'batch'::character varying NOT NULL,
    exclude_from_further_processing boolean DEFAULT false NOT NULL,
    notes text
);


--
-- Name: orchids_from_rex_csv; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.orchids_from_rex_csv (
    id bigint,
    record_type text,
    parent_id bigint,
    hybrid text,
    family text,
    hr_comment text,
    subfamily text,
    tribe text,
    subtribe text,
    rank text,
    nsl_rank text,
    taxon text,
    ex_base_author text,
    base_author text,
    ex_author text,
    author text,
    author_rank text,
    name_status text,
    name_comment text,
    partly text,
    auct_non text,
    synonym_type text,
    doubtful text,
    hybrid_level text,
    isonym text,
    publ_count bigint,
    article_author text,
    article_title text,
    article_title_full text,
    in_flag text,
    author_2 text,
    title text,
    title_full text,
    edition text,
    volume text,
    page text,
    year text,
    date_ text,
    publ_partly text,
    publ_note text,
    note text,
    footnote text,
    distribution text,
    comment text,
    remark text,
    original_text text
);


--
-- Name: orchids_names; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.orchids_names (
    id integer NOT NULL,
    orchid_id bigint NOT NULL,
    name_id bigint NOT NULL,
    instance_id bigint NOT NULL,
    relationship_instance_type_id bigint,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(255) DEFAULT 'batch'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(255) DEFAULT 'batch'::character varying NOT NULL,
    standalone_instance_created boolean DEFAULT false NOT NULL,
    standalone_instance_found boolean DEFAULT false NOT NULL,
    standalone_instance_id bigint,
    relationship_instance_created boolean DEFAULT false NOT NULL,
    relationship_instance_found boolean DEFAULT false NOT NULL,
    relationship_instance_id bigint,
    drafted boolean DEFAULT false NOT NULL,
    manually_drafted boolean DEFAULT false NOT NULL
);


--
-- Name: orchids_names_id_seq; Type: SEQUENCE; Schema: archive; Owner: -
--

CREATE SEQUENCE archive.orchids_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orchids_names_id_seq; Type: SEQUENCE OWNED BY; Schema: archive; Owner: -
--

ALTER SEQUENCE archive.orchids_names_id_seq OWNED BY archive.orchids_names.id;


--
-- Name: nsl_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nsl_global_seq
    INCREMENT BY 1
    CACHE 1;


--
-- Name: batch_review; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.batch_review (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    loader_batch_id bigint NOT NULL,
    name character varying(200) NOT NULL,
    in_progress boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: batch_review_comment; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.batch_review_comment (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    review_period_id bigint NOT NULL,
    batch_reviewer_id bigint NOT NULL,
    comment text NOT NULL,
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
    batch_review_period_id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


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
    default_reference_id bigint
);


--
-- Name: org; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(100) NOT NULL,
    abbrev character varying(30) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    no_org boolean DEFAULT false NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(30) NOT NULL,
    given_name character varying(60),
    family_name character varying(60) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) DEFAULT USER NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) DEFAULT USER NOT NULL
);


--
-- Name: batch_stack_vw; Type: VIEW; Schema: loader; Owner: -
--

CREATE VIEW loader.batch_stack_vw AS
 SELECT fred.display_as,
    fred.id,
    fred.name,
    fred.batch_name,
    fred.batch_id,
    fred.description,
    fred.created_at,
    fred.start,
    fred.order_by
   FROM ( SELECT 'Loader Batch in stack'::text AS display_as,
            loader_batch.id,
            loader_batch.name,
            loader_batch.name AS batch_name,
            loader_batch.id AS batch_id,
            loader_batch.description,
            loader_batch.created_at,
            loader_batch.created_at AS start,
            ('A batch '::text || (loader_batch.name)::text) AS order_by
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
            ((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) AS order_by
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
            ((((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' C period '::text) || brp.start_date) AS order_by
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
            brp.created_at,
            brp.start_date,
            ((((((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' C period '::text) || brp.start_date) || ' '::text) || (users.name)::text) AS order_by
           FROM ((((((loader.batch_reviewer brer
             JOIN loader.batch_review_period brp ON ((brer.batch_review_period_id = brp.id)))
             JOIN public.users ON ((brer.user_id = users.id)))
             JOIN loader.batch_review br ON ((brp.batch_review_id = br.id)))
             JOIN loader.loader_batch lb ON ((br.loader_batch_id = lb.id)))
             JOIN public.org ON ((brer.org_id = org.id)))
             JOIN loader.batch_review_role brrole ON ((brer.batch_review_role_id = brrole.id)))) fred
  ORDER BY fred.order_by;


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
    rank text,
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
    doubtful boolean NOT NULL,
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
    created_manually boolean DEFAULT false NOT NULL
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
    copy_synonyms_and_append_extras boolean DEFAULT false NOT NULL
);


--
-- Name: name_review_comment; Type: TABLE; Schema: loader; Owner: -
--

CREATE TABLE loader.name_review_comment (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    review_period_id bigint NOT NULL,
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
    CONSTRAINT name_review_comment_context_check CHECK (((context)::text ~ 'loader-name|distribution|concept-note|unknown'::text))
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
-- Name: author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.author (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev character varying(100),
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
-- Name: batch_review_period_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.batch_review_period_vw AS
 SELECT br.id,
    br.user_id,
    br.org_id,
    br.batch_review_role_id,
    br.batch_review_period_id,
    br.active,
    br.lock_version,
    br.created_at,
    br.created_by,
    br.updated_at,
    br.updated_by,
    u.name AS user_name,
    u.given_name,
    u.family_name,
    period.name AS period,
    period.start_date,
    period.end_date,
    role.name AS role_name,
    org.name AS org
   FROM ((((loader.batch_reviewer br
     JOIN public.users u ON ((br.user_id = u.id)))
     JOIN loader.batch_review_period period ON ((br.batch_review_period_id = period.id)))
     JOIN public.org ON ((br.org_id = org.id)))
     JOIN loader.batch_review_role role ON ((br.batch_review_role_id = role.id)));


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
    CONSTRAINT citescheck CHECK (((cites_id IS NULL) OR (cited_by_id IS NOT NULL)))
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
    bidirectional boolean DEFAULT false NOT NULL
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
    CONSTRAINT published_year_limits CHECK (((published_year > 0) AND (published_year < 2500)))
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
    isbn character varying(16),
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
    updated_by character varying(255) NOT NULL
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
    deprecated boolean DEFAULT false NOT NULL
);


--
-- Name: name_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.name_mv AS
 SELECT nv.name_id,
    nv.scientific_name,
    nv.scientific_name_html,
    nv.canonical_name,
    nv.canonical_name_html AS canonical_namehtml,
    nv.name_element,
    nv.scientific_name_id,
    nv.name_type,
    nv.taxonomic_status,
    nv.nomenclatural_status,
    nv.scientific_name_authorship,
    nv.cultivar_epithet,
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
    nv.infrageneric_epithet,
    nv.generic_name,
    nv.specific_epithet,
    nv.infraspecific_epithet,
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
    nv.dataset_id,
    nv.dataset_name,
    nv.license,
    nv.cc_attribution_iri
   FROM ( SELECT DISTINCT ON (n.id) n.id AS name_id,
            n.full_name AS scientific_name,
            n.full_name_html AS scientific_name_html,
            n.simple_name AS canonical_name,
            n.simple_name_html AS canonical_name_html,
            n.name_element,
            ((mapper_host.value)::text || n.uri) AS scientific_name_id,
            nt.name AS name_type,
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
                    WHEN ((ns.rdf_id)::text !~ '(legitimate|default|available)'::text) THEN ns.name
                    ELSE NULL::character varying
                END AS nomenclatural_status,
                CASE
                    WHEN nt.autonym THEN NULL::text
                    ELSE regexp_replace("substring"((n.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
                END AS scientific_name_authorship,
                CASE
                    WHEN (nt.cultivar = true) THEN n.name_element
                    ELSE NULL::character varying
                END AS cultivar_epithet,
            nt.autonym,
            nt.hybrid,
            nt.cultivar,
            nt.formula,
            nt.scientific,
            ns.nom_inval,
            ns.nom_illeg,
            COALESCE(primary_ref.citation, 'unknown'::character varying) AS name_published_in,
            primary_ref.id AS name_published_in_id,
            (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer AS name_published_in_year,
            primary_it.name AS name_instance_type,
            ((mapper_host.value)::text || primary_inst.uri) AS name_according_to_id,
            ((primary_auth.name)::text ||
                CASE
                    WHEN (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying) IS NOT NULL) THEN ((' ('::text || (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying))::text) || ')'::text)
                    ELSE NULL::text
                END) AS name_according_to,
            basionym.full_name AS original_name_usage,
                CASE
                    WHEN (basionym_inst.id IS NOT NULL) THEN ((mapper_host.value)::text || (basionym_inst.id)::text)
                    ELSE NULL::text
                END AS original_name_usage_id,
            COALESCE(substr((basionym_ref.iso_publication_date)::text, 1, 4), (basionym_ref.year)::text) AS original_name_usage_year,
                CASE
                    WHEN (nt.autonym = true) THEN (parent_name.full_name)::text
                    ELSE ( SELECT string_agg(regexp_replace((((key1.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text) AS string_agg
                       FROM (public.instance_note note
                         JOIN public.instance_note_key key1 ON (((key1.id = note.instance_note_key_id) AND ((key1.rdf_id)::text ~* 'type$'::text))))
                      WHERE (note.instance_id = ANY (ARRAY[primary_inst.id, basionym_inst.cites_id])))
                END AS type_citation,
            COALESCE(( SELECT find_tree_rank.name_element
                   FROM public.find_tree_rank(COALESCE(tve.element_link, tve2.element_link), kingdom.sort_order) find_tree_rank(name_element, rank, sort_order)),
                CASE
                    WHEN ((code.value)::text = 'ICN'::text) THEN 'Plantae'::text
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
                    WHEN (((pk.rdf_id)::text = 'genus'::text) AND ((rank.rdf_id)::text <> 'species'::text)) THEN n.name_element
                    ELSE NULL::character varying
                END AS infrageneric_epithet,
                CASE
                    WHEN (rank.sort_order >= genus.sort_order) THEN p.tk[1]
                    ELSE NULL::text
                END AS generic_name,
                CASE
                    WHEN (rank.sort_order > species.sort_order) THEN p.tk[2]
                    WHEN (rank.sort_order = species.sort_order) THEN (n.name_element)::text
                    ELSE NULL::text
                END AS specific_epithet,
                CASE
                    WHEN (rank.sort_order > species.sort_order) THEN n.name_element
                    ELSE NULL::character varying
                END AS infraspecific_epithet,
            rank.name AS taxon_rank,
            rank.sort_order AS taxon_rank_sort_order,
            rank.abbrev AS taxon_rank_abbreviation,
            first_hybrid_parent.full_name AS first_hybrid_parent_name,
            ((mapper_host.value)::text || first_hybrid_parent.uri) AS first_hybrid_parent_name_id,
            second_hybrid_parent.full_name AS second_hybrid_parent_name,
            ((mapper_host.value)::text || second_hybrid_parent.uri) AS second_hybrid_parent_name_id,
            n.created_at AS created,
            n.updated_at AS modified,
            (COALESCE(code.value, 'ICN'::character varying))::text AS nomenclatural_code,
            ((t.host_name || '/tree/'::text) || t.current_tree_version_id) AS dataset_id,
            dataset.value AS dataset_name,
            'https://creativecommons.org/licenses/by/3.0/'::text AS license,
            ((mapper_host.value)::text || n.uri) AS cc_attribution_iri
           FROM (((((((((((((((((((public.name n
             JOIN ( SELECT name.id,
                    string_to_array(regexp_replace((name.simple_name)::text, '(^cf. |^aff, )'::text, ''::text, 'i'::text), ' '::text) AS tk
                   FROM public.name) p ON ((p.id = n.id)))
             JOIN public.name_type nt ON ((n.name_type_id = nt.id)))
             JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
             LEFT JOIN public.name parent_name ON ((n.parent_id = parent_name.id)))
             LEFT JOIN public.name family_name ON ((n.family_id = family_name.id)))
             LEFT JOIN public.name first_hybrid_parent ON (((n.parent_id = first_hybrid_parent.id) AND nt.hybrid)))
             LEFT JOIN public.name second_hybrid_parent ON (((n.second_parent_id = second_hybrid_parent.id) AND nt.hybrid)))
             LEFT JOIN (((public.instance primary_inst
             JOIN public.instance_type primary_it ON (((primary_it.id = primary_inst.instance_type_id) AND primary_it.primary_instance)))
             JOIN public.reference primary_ref ON ((primary_inst.reference_id = primary_ref.id)))
             JOIN public.author primary_auth ON ((primary_ref.author_id = primary_auth.id))) ON ((primary_inst.name_id = n.id)))
             LEFT JOIN ((((public.instance basionym_rel
             JOIN public.instance_type bt ON (((bt.id = basionym_rel.instance_type_id) AND ((bt.rdf_id)::text = 'basionym'::text))))
             JOIN public.instance basionym_inst ON ((basionym_rel.cites_id = basionym_inst.id)))
             JOIN public.name basionym ON ((basionym.id = basionym_inst.name_id)))
             JOIN public.reference basionym_ref ON ((basionym_inst.reference_id = basionym_ref.id))) ON ((basionym_rel.cited_by_id = primary_inst.id)))
             LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
             LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))
             JOIN public.name_rank kingdom ON (((kingdom.rdf_id)::text ~ '(regnum|kingdom)'::text)))
             JOIN public.name_rank family ON (((family.rdf_id)::text ~ '(^family|^familia)'::text)))
             JOIN public.name_rank genus ON (((genus.rdf_id)::text = 'genus'::text)))
             JOIN public.name_rank species ON (((species.rdf_id)::text = 'species'::text)))
             JOIN (public.name_rank rank
             LEFT JOIN public.name_rank pk ON ((rank.parent_rank_id = pk.id))) ON ((n.name_rank_id = rank.id)))
             LEFT JOIN ((public.tree_element te
             JOIN public.tree_version_element tve ON ((te.id = tve.tree_element_id)))
             JOIN public.tree t ON (((tve.tree_version_id = t.current_tree_version_id) AND t.accepted_tree))) ON ((te.name_id = n.id)))
             LEFT JOIN (((public.instance s
             JOIN public.tree_element te2 ON ((te2.instance_id = s.cited_by_id)))
             JOIN public.tree_version_element tve2 ON ((te2.id = tve2.tree_element_id)))
             JOIN public.tree t2 ON (((tve2.tree_version_id = t2.current_tree_version_id) AND t2.accepted_tree))) ON ((s.name_id = n.id)))
          WHERE ((EXISTS ( SELECT 1
                   FROM public.instance
                  WHERE (instance.name_id = n.id))) AND ((nt.rdf_id)::text !~ '(common|vernacular)'::text))
          ORDER BY n.id, (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer, COALESCE(substr((basionym_ref.iso_publication_date)::text, 1, 4), (basionym_ref.year)::text)) nv
  ORDER BY nv.family, nv.generic_name, nv.specific_epithet, nv.infraspecific_epithet, nv.cultivar_epithet
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW name_mv; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.name_mv IS 'A snake_case listing of a shard''s scientific_names with status according to the current default tree version,using Darwin_Core semantics';


--
-- Name: dwc_name_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dwc_name_view AS
 SELECT name_mv.scientific_name_id AS "scientificNameID",
    name_mv.name_type AS "nameType",
    name_mv.scientific_name AS "scientificName",
    name_mv.scientific_name_html AS "scientificNameHTML",
    name_mv.canonical_name AS "canonicalName",
    name_mv.canonical_namehtml AS "canonicalNameHTML",
    name_mv.name_element AS "nameElement",
    name_mv.taxonomic_status AS "taxonomicStatus",
    name_mv.nomenclatural_status AS "nomenclaturalStatus",
    name_mv.scientific_name_authorship AS "scientificNameAuthorship",
    name_mv.cultivar_epithet AS "cultivarEpithet",
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
    name_mv.dataset_id AS "dataSetID",
    name_mv.dataset_name AS "datasetName",
    name_mv.license,
    name_mv.cc_attribution_iri AS "ccAttributionIRI"
   FROM public.name_mv;


--
-- Name: VIEW dwc_name_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.dwc_name_view IS 'Based on NAME_MV, a camelCase listing of a shard''s scientific_names with status according to the current default tree version,using Darwin_Core semantics';


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
-- Name: taxon_mv; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.taxon_mv AS
 SELECT ((tree.host_name || '/'::text) || syn_inst.uri) AS taxon_id,
    syn_nt.name AS name_type,
    (tree.host_name || tve.taxon_link) AS accepted_name_usage_id,
    acc_name.full_name AS accepted_name_usage,
        CASE
            WHEN ((syn_ns.rdf_id)::text !~ '(legitimate|default|available)'::text) THEN syn_ns.name
            ELSE NULL::character varying
        END AS nomenclatural_status,
    syn_ns.nom_illeg,
    syn_ns.nom_inval,
    syn_it.name AS taxonomic_status,
    syn_it.pro_parte,
    syn_name.full_name AS scientific_name,
    ((tree.host_name || '/'::text) || syn_name.uri) AS scientific_name_id,
    syn_name.simple_name AS canonical_name,
        CASE
            WHEN ((ng.rdf_id)::text = 'zoological'::text) THEN (( SELECT author.abbrev
               FROM public.author
              WHERE (author.id = syn_name.author_id)))::text
            WHEN syn_nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((syn_name.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS scientific_name_authorship,
    NULL::text AS parent_name_usage_id,
    syn_rank.name AS taxon_rank,
    syn_rank.sort_order AS taxon_rank_sort_order,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(regnum|kingdom)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS kingdom,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^class'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS class,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^subclass'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS subclass,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(^familia|^family)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS family,
    ((tree.host_name || '/'::text) || syn_inst.uri) AS taxon_concept_id,
    syn_ref.citation AS name_according_to,
    ((((tree.host_name || '/reference/'::text) || lower((name_space.value)::text)) || '/'::text) || syn_ref.id) AS name_according_to_id,
    NULL::text AS taxon_remarks,
    NULL::text AS taxon_distribution,
    regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text) AS higher_classification,
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS first_hybrid_parent_name,
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || firsthybridparent.uri)
            ELSE NULL::text
        END AS first_hybrid_parent_name_id,
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS second_hybrid_parent_name,
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || secondhybridparent.uri)
            ELSE NULL::text
        END AS second_hybrid_parent_name_id,
    (( SELECT COALESCE(( SELECT shard_config.value
                   FROM public.shard_config
                  WHERE ((shard_config.name)::text = 'nomenclatural code'::text)), 'ICN'::character varying) AS "coalesce"))::text AS nomenclatural_code,
    syn_name.created_at AS created,
    syn_name.updated_at AS modified,
    tree.name AS dataset_name,
    ((tree.host_name || '/tree/'::text) || tree.current_tree_version_id) AS dataset_id,
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
    ((tree.host_name || '/'::text) || syn_inst.uri) AS cc_attribution_iri
   FROM (((((((((((((((public.tree_version_element tve
     JOIN public.tree ON (((tve.tree_version_id = tree.current_tree_version_id) AND (tree.accepted_tree = true))))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)))
     JOIN public.instance acc_inst ON ((te.instance_id = acc_inst.id)))
     JOIN public.name acc_name ON ((te.name_id = acc_name.id)))
     JOIN public.instance syn_inst ON (((te.instance_id = syn_inst.cited_by_id) AND (syn_inst.name_id <> acc_name.id))))
     JOIN public.reference syn_ref ON ((syn_inst.reference_id = syn_ref.id)))
     JOIN public.instance_type syn_it ON ((syn_inst.instance_type_id = syn_it.id)))
     JOIN public.name syn_name ON ((syn_inst.name_id = syn_name.id)))
     JOIN public.name_rank syn_rank ON ((syn_name.name_rank_id = syn_rank.id)))
     JOIN public.name_type syn_nt ON ((syn_name.name_type_id = syn_nt.id)))
     JOIN public.name_group ng ON ((syn_nt.name_group_id = ng.id)))
     JOIN public.name_status syn_ns ON ((syn_name.name_status_id = syn_ns.id)))
     LEFT JOIN public.name firsthybridparent ON (((syn_name.parent_id = firsthybridparent.id) AND syn_nt.hybrid)))
     LEFT JOIN public.name secondhybridparent ON (((syn_name.second_parent_id = secondhybridparent.id) AND syn_nt.hybrid)))
     LEFT JOIN public.shard_config name_space ON (((name_space.name)::text = 'name space'::text)))
UNION
 SELECT (tree.host_name || tve.taxon_link) AS taxon_id,
    acc_nt.name AS name_type,
    (tree.host_name || tve.taxon_link) AS accepted_name_usage_id,
    acc_name.full_name AS accepted_name_usage,
        CASE
            WHEN ((acc_ns.rdf_id)::text !~ '(legitimate|default|available)'::text) THEN acc_ns.name
            ELSE NULL::character varying
        END AS nomenclatural_status,
    acc_ns.nom_illeg,
    acc_ns.nom_inval,
        CASE
            WHEN te.excluded THEN 'excluded'::text
            ELSE 'accepted'::text
        END AS taxonomic_status,
    false AS pro_parte,
    acc_name.full_name AS scientific_name,
    ((tree.host_name || '/'::text) || acc_name.uri) AS scientific_name_id,
    acc_name.simple_name AS canonical_name,
        CASE
            WHEN ((ng.rdf_id)::text = 'zoological'::text) THEN (( SELECT author.abbrev
               FROM public.author
              WHERE (author.id = acc_name.author_id)))::text
            WHEN acc_nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((acc_name.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS scientific_name_authorship,
    NULLIF((tree.host_name || pve.taxon_link), tree.host_name) AS parent_name_usage_id,
    te.rank AS taxon_rank,
    acc_rank.sort_order AS taxon_rank_sort_order,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(regnum|kingdom)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS kingdom,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^class'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS class,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^subclass'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS subclass,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(^family|^familia)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS family,
    te.instance_link AS taxon_concept_id,
    acc_ref.citation AS name_according_to,
    ((((tree.host_name || '/reference/'::text) || lower((name_space.value)::text)) || '/'::text) || acc_ref.id) AS name_according_to_id,
    ((te.profile -> (tree.config ->> 'comment_key'::text)) ->> 'value'::text) AS taxon_remarks,
    ((te.profile -> (tree.config ->> 'distribution_key'::text)) ->> 'value'::text) AS taxon_distribution,
    regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text) AS higher_classification,
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS first_hybrid_parent_name,
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || firsthybridparent.uri)
            ELSE NULL::text
        END AS first_hybrid_parent_name_id,
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS second_hybrid_parent_name,
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || secondhybridparent.uri)
            ELSE NULL::text
        END AS second_hybrid_parent_name_id,
    (( SELECT COALESCE(( SELECT shard_config.value
                   FROM public.shard_config
                  WHERE ((shard_config.name)::text = 'nomenclatural code'::text)), 'ICN'::character varying) AS "coalesce"))::text AS nomenclatural_code,
    acc_name.created_at AS created,
    acc_name.updated_at AS modified,
    tree.name AS dataset_name,
    ((tree.host_name || '/tree/'::text) || tree.current_tree_version_id) AS dataset_id,
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
    (tree.host_name || tve.taxon_link) AS cc_attribution_iri
   FROM ((((((((((((((public.tree_version_element tve
     JOIN public.tree ON (((tve.tree_version_id = tree.current_tree_version_id) AND (tree.accepted_tree = true))))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)))
     JOIN public.instance acc_inst ON ((te.instance_id = acc_inst.id)))
     JOIN public.instance_type acc_it ON ((acc_inst.instance_type_id = acc_it.id)))
     JOIN public.reference acc_ref ON ((acc_inst.reference_id = acc_ref.id)))
     JOIN public.name acc_name ON ((te.name_id = acc_name.id)))
     JOIN public.name_type acc_nt ON ((acc_name.name_type_id = acc_nt.id)))
     JOIN public.name_group ng ON ((acc_nt.name_group_id = ng.id)))
     JOIN public.name_status acc_ns ON ((acc_name.name_status_id = acc_ns.id)))
     JOIN public.name_rank acc_rank ON ((acc_name.name_rank_id = acc_rank.id)))
     LEFT JOIN public.tree_version_element pve ON ((pve.element_link = tve.parent_id)))
     LEFT JOIN public.name firsthybridparent ON (((acc_name.parent_id = firsthybridparent.id) AND acc_nt.hybrid)))
     LEFT JOIN public.name secondhybridparent ON (((acc_name.second_parent_id = secondhybridparent.id) AND acc_nt.hybrid)))
     LEFT JOIN public.shard_config name_space ON (((name_space.name)::text = 'name space'::text)))
  ORDER BY 27
  WITH NO DATA;


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
-- Name: COLUMN taxon_mv.nom_illeg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.nom_illeg IS 'The scientific_name is illegitimate (ICN)';


--
-- Name: COLUMN taxon_mv.nom_inval; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_mv.nom_inval IS 'The scientific_name is invalid';


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
-- Name: dwc_taxon_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.dwc_taxon_view AS
 SELECT taxon_mv.taxon_id AS "taxonID",
    taxon_mv.name_type AS "nameType",
    taxon_mv.accepted_name_usage_id AS "acceptedNameUsageID",
    taxon_mv.accepted_name_usage AS "acceptedNameUsage",
    taxon_mv.nomenclatural_status AS "nomenclaturalStatus",
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
-- Name: VIEW dwc_taxon_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.dwc_taxon_view IS 'Based on TAXON_MV, a camelCase DarwinCore view of the shard''s taxonomy using the current default tree version';


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
-- Name: name_view; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.name_view AS
 SELECT DISTINCT ON (n.id) n.id AS name_id,
    n.full_name AS "scientificName",
    n.full_name_html AS "scientificNameHTML",
    n.simple_name AS "canonicalName",
    n.simple_name_html AS "canonicalNameHTML",
    n.name_element AS "nameElement",
    ((mapper_host.value)::text || n.uri) AS "scientificNameID",
    nt.name AS "nameType",
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
        END AS "taxonomicStatus",
        CASE
            WHEN ((ns.name)::text !~ '(^legitimate$|^\[default\]$)'::text) THEN ns.name
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
        CASE
            WHEN nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((n.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS "scientificNameAuthorship",
        CASE
            WHEN (nt.cultivar = true) THEN n.name_element
            ELSE NULL::character varying
        END AS "cultivarEpithet",
    nt.autonym,
    nt.hybrid,
    nt.cultivar,
    nt.formula,
    nt.scientific,
    ns.nom_inval AS "nomInval",
    ns.nom_illeg AS "nomIlleg",
    COALESCE(primary_ref.citation, 'unknown'::character varying) AS "namePublishedIn",
    primary_ref.id AS "namePublishedInID",
    (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer AS "namePublishedInYear",
    primary_it.name AS "nameInstanceType",
    ((mapper_host.value)::text || primary_inst.uri) AS "nameAccordingToID",
    ((primary_auth.name)::text ||
        CASE
            WHEN (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying) IS NOT NULL) THEN ((' ('::text || (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying))::text) || ')'::text)
            ELSE NULL::text
        END) AS "nameAccordingTo",
    basionym.full_name AS "originalNameUsage",
        CASE
            WHEN (basionym_inst.id IS NOT NULL) THEN ((mapper_host.value)::text || (basionym_inst.id)::text)
            ELSE NULL::text
        END AS "originalNameUsageID",
    COALESCE(substr((basionym_ref.iso_publication_date)::text, 1, 4), (basionym_ref.year)::text) AS "originalNameUsageYear",
        CASE
            WHEN (nt.autonym = true) THEN (parent_name.full_name)::text
            ELSE ( SELECT string_agg(regexp_replace((((key1.rdf_id)::text || ': '::text) || (note.value)::text), '[\r\n]+'::text, ' '::text, 'g'::text), '; '::text) AS string_agg
               FROM (public.instance_note note
                 JOIN public.instance_note_key key1 ON (((key1.id = note.instance_note_key_id) AND ((key1.rdf_id)::text ~* 'type$'::text))))
              WHERE (note.instance_id = ANY (ARRAY[primary_inst.id, basionym_inst.cites_id])))
        END AS "typeCitation",
    COALESCE(( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(COALESCE(tve.element_link, tve2.element_link), ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(regnum|kingdom)'::text))) find_tree_rank(name_element, rank, sort_order)),
        CASE
            WHEN ((code.value)::text = 'ICN'::text) THEN 'Plantae'::text
            ELSE NULL::text
        END) AS kingdom,
    COALESCE(( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(COALESCE(tve.element_link, tve2.element_link), ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(^family|^familia)'::text))) find_tree_rank(name_element, rank, sort_order)), (family_name.name_element)::text) AS family,
    ( SELECT find_rank.name_element
           FROM public.find_rank(n.id, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text = 'genus'::text))) find_rank(name_element, rank, sort_order)) AS "genericName",
    ( SELECT find_rank.name_element
           FROM public.find_rank(n.id, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text = 'species'::text))) find_rank(name_element, rank, sort_order)) AS "specificEpithet",
    ( SELECT find_rank.name_element
           FROM public.find_rank(n.id, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text = 'subspecies'::text))) find_rank(name_element, rank, sort_order)) AS "infraspecificEpithet",
    rank.name AS "taxonRank",
    rank.sort_order AS "taxonRankSortOrder",
    rank.abbrev AS "taxonRankAbbreviation",
    first_hybrid_parent.full_name AS "firstHybridParentName",
    ((mapper_host.value)::text || first_hybrid_parent.uri) AS "firstHybridParentNameID",
    second_hybrid_parent.full_name AS "secondHybridParentName",
    ((mapper_host.value)::text || second_hybrid_parent.uri) AS "secondHybridParentNameID",
    n.created_at AS created,
    n.updated_at AS modified,
    (COALESCE(code.value, 'ICN'::character varying))::text AS "nomenclaturalCode",
    dataset.value AS "datasetName",
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
    ((mapper_host.value)::text || n.uri) AS "ccAttributionIRI"
   FROM (((((((((((((public.name n
     JOIN public.name_type nt ON ((n.name_type_id = nt.id)))
     JOIN public.name_status ns ON ((n.name_status_id = ns.id)))
     JOIN public.name_rank rank ON ((n.name_rank_id = rank.id)))
     LEFT JOIN public.name parent_name ON ((n.parent_id = parent_name.id)))
     LEFT JOIN public.name family_name ON ((n.family_id = family_name.id)))
     LEFT JOIN public.name first_hybrid_parent ON (((n.parent_id = first_hybrid_parent.id) AND nt.hybrid)))
     LEFT JOIN public.name second_hybrid_parent ON (((n.second_parent_id = second_hybrid_parent.id) AND nt.hybrid)))
     LEFT JOIN ((((public.instance primary_inst
     JOIN public.instance_type primary_it ON (((primary_it.id = primary_inst.instance_type_id) AND primary_it.primary_instance)))
     JOIN public.reference primary_ref ON ((primary_inst.reference_id = primary_ref.id)))
     JOIN public.author primary_auth ON ((primary_ref.author_id = primary_auth.id)))
     LEFT JOIN ((((public.instance basionym_rel
     JOIN public.instance_type bt ON (((bt.id = basionym_rel.instance_type_id) AND ((bt.rdf_id)::text = 'basionym'::text))))
     JOIN public.instance basionym_inst ON ((basionym_rel.cites_id = basionym_inst.id)))
     JOIN public.reference basionym_ref ON ((basionym_inst.reference_id = basionym_ref.id)))
     JOIN public.name basionym ON ((basionym.id = basionym_inst.name_id))) ON ((basionym_rel.cited_by_id = primary_inst.id))) ON ((primary_inst.name_id = n.id)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name label'::text)))
     LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))
     LEFT JOIN ((public.tree_element te
     JOIN public.tree_version_element tve ON ((te.id = tve.tree_element_id)))
     JOIN public.tree t ON (((tve.tree_version_id = t.current_tree_version_id) AND t.accepted_tree))) ON ((te.name_id = n.id)))
     LEFT JOIN (((public.instance s
     JOIN public.tree_element te2 ON ((te2.instance_id = s.cited_by_id)))
     JOIN public.tree_version_element tve2 ON ((te2.id = tve2.tree_element_id)))
     JOIN public.tree t2 ON (((tve2.tree_version_id = t2.current_tree_version_id) AND t2.accepted_tree))) ON ((s.name_id = n.id)))
  WHERE ((EXISTS ( SELECT 1
           FROM public.instance
          WHERE (instance.name_id = n.id))) AND ((nt.rdf_id)::text !~ '(common|vernacular)'::text))
  ORDER BY n.id, (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer, COALESCE(substr((basionym_ref.iso_publication_date)::text, 1, 4), (basionym_ref.year)::text)
  WITH NO DATA;


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
-- Name: orchids_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orchids_seq
    START WITH 8000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


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
-- Name: taxon_view; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.taxon_view AS
 SELECT ((tree.host_name || '/'::text) || syn_inst.uri) AS "taxonID",
    syn_nt.name AS "nameType",
    (tree.host_name || tve.taxon_link) AS "acceptedNameUsageID",
    acc_name.full_name AS "acceptedNameUsage",
        CASE
            WHEN ((syn_ns.name)::text <> ALL (ARRAY[('legitimate'::character varying)::text, ('[default]'::character varying)::text])) THEN syn_ns.name
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
    syn_it.name AS "taxonomicStatus",
    syn_it.pro_parte AS "proParte",
    syn_name.full_name AS "scientificName",
    ((tree.host_name || '/'::text) || syn_name.uri) AS "scientificNameID",
    syn_name.simple_name AS "canonicalName",
        CASE
            WHEN ((ng.rdf_id)::text = 'zoological'::text) THEN (( SELECT author.abbrev
               FROM public.author
              WHERE (author.id = syn_name.author_id)))::text
            WHEN syn_nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((syn_name.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS "scientificNameAuthorship",
    NULL::text AS "parentNameUsageID",
    syn_rank.name AS "taxonRank",
    syn_rank.sort_order AS "taxonRankSortOrder",
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(regnum|kingdom)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS kingdom,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^class'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS class,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text = '^subclass'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS subclass,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text = '(^familia|^family)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS family,
    syn_name.created_at AS created,
    syn_name.updated_at AS modified,
    tree.name AS "datasetName",
    ((tree.host_name || '/'::text) || syn_inst.uri) AS "taxonConceptID",
    syn_ref.citation AS "nameAccordingTo",
    ((((tree.host_name || '/reference/'::text) || lower((name_space.value)::text)) || '/'::text) || syn_ref.id) AS "nameAccordingToID",
    NULL::text AS "taxonRemarks",
    NULL::text AS "taxonDistribution",
    regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text) AS "higherClassification",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS "firstHybridParentName",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || firsthybridparent.uri)
            ELSE NULL::text
        END AS "firstHybridParentNameID",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS "secondHybridParentName",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || secondhybridparent.uri)
            ELSE NULL::text
        END AS "secondHybridParentNameID",
    (( SELECT COALESCE(( SELECT shard_config.value
                   FROM public.shard_config
                  WHERE ((shard_config.name)::text = 'nomenclatural code'::text)), 'ICN'::character varying) AS "coalesce"))::text AS "nomenclaturalCode",
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
    ((tree.host_name || '/'::text) || syn_inst.uri) AS "ccAttributionIRI"
   FROM (((((((((((((((public.tree_version_element tve
     JOIN public.tree ON (((tve.tree_version_id = tree.current_tree_version_id) AND (tree.accepted_tree = true))))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)))
     JOIN public.instance acc_inst ON ((te.instance_id = acc_inst.id)))
     JOIN public.name acc_name ON ((te.name_id = acc_name.id)))
     JOIN public.instance syn_inst ON (((te.instance_id = syn_inst.cited_by_id) AND (syn_inst.name_id <> acc_name.id))))
     JOIN public.reference syn_ref ON ((syn_inst.reference_id = syn_ref.id)))
     JOIN public.instance_type syn_it ON ((syn_inst.instance_type_id = syn_it.id)))
     JOIN public.name syn_name ON ((syn_inst.name_id = syn_name.id)))
     JOIN public.name_rank syn_rank ON ((syn_name.name_rank_id = syn_rank.id)))
     JOIN public.name_type syn_nt ON ((syn_name.name_type_id = syn_nt.id)))
     JOIN public.name_group ng ON ((syn_nt.name_group_id = ng.id)))
     JOIN public.name_status syn_ns ON ((syn_name.name_status_id = syn_ns.id)))
     LEFT JOIN public.name firsthybridparent ON (((syn_name.parent_id = firsthybridparent.id) AND syn_nt.hybrid)))
     LEFT JOIN public.name secondhybridparent ON (((syn_name.second_parent_id = secondhybridparent.id) AND syn_nt.hybrid)))
     LEFT JOIN public.shard_config name_space ON (((name_space.name)::text = 'name space'::text)))
UNION
 SELECT (tree.host_name || tve.taxon_link) AS "taxonID",
    acc_nt.name AS "nameType",
    (tree.host_name || tve.taxon_link) AS "acceptedNameUsageID",
    acc_name.full_name AS "acceptedNameUsage",
        CASE
            WHEN ((acc_ns.name)::text <> ALL (ARRAY[('legitimate'::character varying)::text, ('[default]'::character varying)::text])) THEN acc_ns.name
            ELSE NULL::character varying
        END AS "nomenclaturalStatus",
        CASE
            WHEN te.excluded THEN 'excluded'::text
            ELSE 'accepted'::text
        END AS "taxonomicStatus",
    false AS "proParte",
    acc_name.full_name AS "scientificName",
    ((tree.host_name || '/'::text) || acc_name.uri) AS "scientificNameID",
    acc_name.simple_name AS "canonicalName",
        CASE
            WHEN ((ng.rdf_id)::text = 'zoological'::text) THEN (( SELECT author.abbrev
               FROM public.author
              WHERE (author.id = acc_name.author_id)))::text
            WHEN acc_nt.autonym THEN NULL::text
            ELSE regexp_replace("substring"((acc_name.full_name_html)::text, '<authors>(.*)</authors>'::text), '<[^>]*>'::text, ''::text, 'g'::text)
        END AS "scientificNameAuthorship",
    NULLIF((tree.host_name || pve.taxon_link), tree.host_name) AS "parentNameUsageID",
    te.rank AS "taxonRank",
    acc_rank.sort_order AS "taxonRankSortOrder",
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(regnum|kingdom)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS kingdom,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^class'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS class,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '^subclass'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS subclass,
    ( SELECT find_tree_rank.name_element
           FROM public.find_tree_rank(tve.element_link, ( SELECT name_rank.sort_order
                   FROM public.name_rank
                  WHERE ((name_rank.rdf_id)::text ~ '(^family|^familia)'::text))) find_tree_rank(name_element, rank, sort_order)
          ORDER BY find_tree_rank.sort_order
         LIMIT 1) AS family,
    acc_name.created_at AS created,
    acc_name.updated_at AS modified,
    tree.name AS "datasetName",
    te.instance_link AS "taxonConceptID",
    acc_ref.citation AS "nameAccordingTo",
    ((((tree.host_name || '/reference/'::text) || lower((name_space.value)::text)) || '/'::text) || acc_ref.id) AS "nameAccordingToID",
    ((te.profile -> (tree.config ->> 'comment_key'::text)) ->> 'value'::text) AS "taxonRemarks",
    ((te.profile -> (tree.config ->> 'distribution_key'::text)) ->> 'value'::text) AS "taxonDistribution",
    regexp_replace(tve.name_path, '/'::text, '|'::text, 'g'::text) AS "higherClassification",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN firsthybridparent.full_name
            ELSE NULL::character varying
        END AS "firstHybridParentName",
        CASE
            WHEN (firsthybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || firsthybridparent.uri)
            ELSE NULL::text
        END AS "firstHybridParentNameID",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN secondhybridparent.full_name
            ELSE NULL::character varying
        END AS "secondHybridParentName",
        CASE
            WHEN (secondhybridparent.id IS NOT NULL) THEN ((tree.host_name || '/'::text) || secondhybridparent.uri)
            ELSE NULL::text
        END AS "secondHybridParentNameID",
    (( SELECT COALESCE(( SELECT shard_config.value
                   FROM public.shard_config
                  WHERE ((shard_config.name)::text = 'nomenclatural code'::text)), 'ICN'::character varying) AS "coalesce"))::text AS "nomenclaturalCode",
    'http://creativecommons.org/licenses/by/3.0/'::text AS license,
    (tree.host_name || tve.taxon_link) AS "ccAttributionIRI"
   FROM ((((((((((((((public.tree_version_element tve
     JOIN public.tree ON (((tve.tree_version_id = tree.current_tree_version_id) AND (tree.accepted_tree = true))))
     JOIN public.tree_element te ON ((tve.tree_element_id = te.id)))
     JOIN public.instance acc_inst ON ((te.instance_id = acc_inst.id)))
     JOIN public.instance_type acc_it ON ((acc_inst.instance_type_id = acc_it.id)))
     JOIN public.reference acc_ref ON ((acc_inst.reference_id = acc_ref.id)))
     JOIN public.name acc_name ON ((te.name_id = acc_name.id)))
     JOIN public.name_type acc_nt ON ((acc_name.name_type_id = acc_nt.id)))
     JOIN public.name_group ng ON ((acc_nt.name_group_id = ng.id)))
     JOIN public.name_status acc_ns ON ((acc_name.name_status_id = acc_ns.id)))
     JOIN public.name_rank acc_rank ON ((acc_name.name_rank_id = acc_rank.id)))
     LEFT JOIN public.tree_version_element pve ON ((pve.element_link = tve.parent_id)))
     LEFT JOIN public.name firsthybridparent ON (((acc_name.parent_id = firsthybridparent.id) AND acc_nt.hybrid)))
     LEFT JOIN public.name secondhybridparent ON (((acc_name.second_parent_id = secondhybridparent.id) AND acc_nt.hybrid)))
     LEFT JOIN public.shard_config name_space ON (((name_space.name)::text = 'name space'::text)))
  ORDER BY 27
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW taxon_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.taxon_view IS 'The Taxon View provides a listing of the "accepted" classification for the sharda as Darwin Core taxon records (almost): All taxa and their synonyms.';


--
-- Name: COLUMN taxon_view."taxonID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonID" IS 'The record identifier (URI): The node ID from the "accepted" classification for the taxon concept; the Taxon_Name_Usage (relationship instance) for a synonym. For higher taxa it uniquely identifiers the subtended branch.';


--
-- Name: COLUMN taxon_view."nameType"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nameType" IS 'A categorisation of the name, e.g. scientific, hybrid, cultivar';


--
-- Name: COLUMN taxon_view."acceptedNameUsageID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."acceptedNameUsageID" IS 'For a synonym, the "taxon_id" in this listing of the accepted concept. Self, for a taxon_record';


--
-- Name: COLUMN taxon_view."acceptedNameUsage"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."acceptedNameUsage" IS 'For a synonym, the accepted taxon name in this classification.';


--
-- Name: COLUMN taxon_view."nomenclaturalStatus"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nomenclaturalStatus" IS 'The nomencultural status of this name. http://rs.gbif.org/vocabulary/gbif/nomenclatural_status.xml';


--
-- Name: COLUMN taxon_view."taxonomicStatus"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonomicStatus" IS 'Is this record accepted, excluded or a synonym of an accepted name.';


--
-- Name: COLUMN taxon_view."proParte"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."proParte" IS 'A flag on a synonym for a partial taxonomic relationship with the accepted taxon';


--
-- Name: COLUMN taxon_view."scientificName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."scientificName" IS 'The full scientific name including authority.';


--
-- Name: COLUMN taxon_view."scientificNameID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."scientificNameID" IS 'The identifier (URI) for the scientific name in this shard.';


--
-- Name: COLUMN taxon_view."canonicalName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."canonicalName" IS 'The name without authorship.';


--
-- Name: COLUMN taxon_view."scientificNameAuthorship"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."scientificNameAuthorship" IS 'Authorship of the name.';


--
-- Name: COLUMN taxon_view."parentNameUsageID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."parentNameUsageID" IS 'The identifier ( a URI) in this listing for the parent taxon in the classification.';


--
-- Name: COLUMN taxon_view."taxonRank"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonRank" IS 'The taxonomic rank of the scientificName.';


--
-- Name: COLUMN taxon_view."taxonRankSortOrder"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonRankSortOrder" IS 'A sort order that can be applied to the rank.';


--
-- Name: COLUMN taxon_view.kingdom; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.kingdom IS 'The canonical name of the kingdom in this branch of the classification.';


--
-- Name: COLUMN taxon_view.class; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.class IS 'The canonical name of the class in this branch of the classification.';


--
-- Name: COLUMN taxon_view.subclass; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.subclass IS 'The canonical name of the subclass in this branch of the classification.';


--
-- Name: COLUMN taxon_view.family; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.family IS 'The canonical name of the family in this branch of the classification.';


--
-- Name: COLUMN taxon_view.created; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.created IS 'Date the record for this concept was created. Format ISO:86 01';


--
-- Name: COLUMN taxon_view.modified; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.modified IS 'Date the record for this concept was modified. Format ISO:86 01';


--
-- Name: COLUMN taxon_view."datasetName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."datasetName" IS 'the Name for this ibranch of the classification  (tree). e.g. APC, AusMoss';


--
-- Name: COLUMN taxon_view."taxonConceptID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonConceptID" IS 'The URI for the congruent "published" concept cited by this record.';


--
-- Name: COLUMN taxon_view."nameAccordingTo"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nameAccordingTo" IS 'The reference citation for the congruent concept.';


--
-- Name: COLUMN taxon_view."nameAccordingToID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nameAccordingToID" IS 'The identifier (URI) for the reference citation for the congriuent concept.';


--
-- Name: COLUMN taxon_view."taxonRemarks"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonRemarks" IS 'Comments made specifically about this taxon in this classification.';


--
-- Name: COLUMN taxon_view."taxonDistribution"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."taxonDistribution" IS 'The State or Territory distribution of the taxon.';


--
-- Name: COLUMN taxon_view."higherClassification"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."higherClassification" IS 'The taxon hierarchy, down to (and including) this taxon, as a list of names separated by a "|".';


--
-- Name: COLUMN taxon_view."firstHybridParentName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."firstHybridParentName" IS 'The scientificName for the first hybrid parent. For hybrids.';


--
-- Name: COLUMN taxon_view."firstHybridParentNameID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."firstHybridParentNameID" IS 'The identifier (URI) the scientificName for the first hybrid parent.';


--
-- Name: COLUMN taxon_view."secondHybridParentName"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."secondHybridParentName" IS 'The scientificName for the second hybrid parent. For hybrids.';


--
-- Name: COLUMN taxon_view."secondHybridParentNameID"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."secondHybridParentNameID" IS 'The identifier (URI) the scientificName for the second hybrid parent.';


--
-- Name: COLUMN taxon_view."nomenclaturalCode"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."nomenclaturalCode" IS 'The nomenclatural code governing this classification.';


--
-- Name: COLUMN taxon_view.license; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view.license IS 'The license by which this data is being made available.';


--
-- Name: COLUMN taxon_view."ccAttributionIRI"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.taxon_view."ccAttributionIRI" IS 'The attribution to be used when citing this concept.';


--
-- Name: tede_old; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tede_old (
    dist_entry_id bigint NOT NULL,
    tree_element_id bigint NOT NULL
);


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
-- Name: tede_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tede_v AS
 SELECT de.display AS distribution_display,
    de.sort_order,
    tede.dist_entry_id,
    tede.tree_element_id,
    tede.updated_at AS tede_updated_at,
    tede.updated_by AS tede_updated_by
   FROM (public.tree_element_distribution_entries tede
     JOIN public.dist_entry de ON ((tede.dist_entry_id = de.id)));


--
-- Name: tmp_distribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tmp_distribution (
    dist text,
    apc_te_id bigint,
    wa text,
    coi text,
    chi text,
    ar text,
    cai text,
    nt text,
    sa text,
    qld text,
    csi text,
    nsw text,
    lhi text,
    ni text,
    act text,
    vic text,
    tas text,
    hi text,
    mdi text,
    mi text
);


--
-- Name: orchid_processing_logs id; Type: DEFAULT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchid_processing_logs ALTER COLUMN id SET DEFAULT nextval('archive.orchid_processing_logs_id_seq'::regclass);


--
-- Name: orchids_names id; Type: DEFAULT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names ALTER COLUMN id SET DEFAULT nextval('archive.orchids_names_id_seq'::regclass);


--
-- Name: bulk_processing_log id; Type: DEFAULT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.bulk_processing_log ALTER COLUMN id SET DEFAULT nextval('loader.bulk_processing_log_id_seq'::regclass);


--
-- Name: orchid_batch_job_locks orchid_batch_job_locks_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchid_batch_job_locks
    ADD CONSTRAINT orchid_batch_job_locks_pkey PRIMARY KEY (restriction);


--
-- Name: orchids_names orchids_names_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_pkey PRIMARY KEY (id);


--
-- Name: orchids orchids_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids
    ADD CONSTRAINT orchids_pkey PRIMARY KEY (id);


--
-- Name: batch_review_comment batch_review_comment_pkey; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_comment
    ADD CONSTRAINT batch_review_comment_pkey PRIMARY KEY (id);


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
-- Name: batch_reviewer reviewer_has_one_role_per_period_uk; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT reviewer_has_one_role_per_period_uk UNIQUE (user_id, batch_review_period_id);


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
-- Name: tede_old tree_element_distribution_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tede_old
    ADD CONSTRAINT tree_element_distribution_entries_pkey PRIMARY KEY (tree_element_id, dist_entry_id);


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
-- Name: users users_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_name_key UNIQUE (name);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: orchid_name_instance_uniq; Type: INDEX; Schema: archive; Owner: -
--

CREATE UNIQUE INDEX orchid_name_instance_uniq ON archive.orchids_names USING btree (orchid_id, name_id, instance_id);


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
-- Name: name_group_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_group_rdfid ON public.name_group USING btree (rdf_id);


--
-- Name: name_name_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_name_element_index ON public.name USING btree (name_element);


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
-- Name: ref_author_role_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_author_role_rdfid ON public.ref_author_role USING btree (rdf_id);


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
-- Name: author author_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER author_update AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE PROCEDURE public.author_notification();


--
-- Name: instance instance_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_insert_delete AFTER INSERT OR DELETE ON public.instance FOR EACH ROW EXECUTE PROCEDURE public.instance_notification();


--
-- Name: instance instance_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_update AFTER UPDATE OF cited_by_id ON public.instance FOR EACH ROW EXECUTE PROCEDURE public.instance_notification();


--
-- Name: name name_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER name_update AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE PROCEDURE public.name_notification();


--
-- Name: reference reference_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reference_update AFTER INSERT OR DELETE OR UPDATE ON public.reference FOR EACH ROW EXECUTE PROCEDURE public.reference_notification();


--
-- Name: orchids_names orchids_names_instance_id_fkey; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: orchids_names orchids_names_name_id_fkey; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_name_id_fkey FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: orchids_names orchids_names_orchid_id_fkey; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_orchid_id_fkey FOREIGN KEY (orchid_id) REFERENCES archive.orchids(id);


--
-- Name: orchids_names orchids_names_rel_instance_id_fk; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_rel_instance_id_fk FOREIGN KEY (relationship_instance_id) REFERENCES public.instance(id);


--
-- Name: orchids_names orchids_names_relationship_instance_type_id_fkey; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_relationship_instance_type_id_fkey FOREIGN KEY (relationship_instance_type_id) REFERENCES public.instance_type(id);


--
-- Name: orchids_names orchids_names_standalone_instance_fk; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_standalone_instance_fk FOREIGN KEY (standalone_instance_id) REFERENCES public.instance(id);


--
-- Name: batch_review_comment batch_review_comme_reviewer_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_comment
    ADD CONSTRAINT batch_review_comme_reviewer_fk FOREIGN KEY (batch_reviewer_id) REFERENCES loader.batch_reviewer(id);


--
-- Name: batch_review_comment batch_review_comment_period_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_review_comment
    ADD CONSTRAINT batch_review_comment_period_fk FOREIGN KEY (review_period_id) REFERENCES loader.batch_review_period(id);


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
-- Name: batch_reviewer batch_reviewer_batch_review_period_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT batch_reviewer_batch_review_period_fk FOREIGN KEY (batch_review_period_id) REFERENCES loader.batch_review_period(id);


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
    ADD CONSTRAINT loader_nme_mtch_r_inst_type_fk FOREIGN KEY (relationship_instance_id) REFERENCES public.instance_type(id);


--
-- Name: name_review_comment name_review_comme_reviewer_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_comme_reviewer_fk FOREIGN KEY (batch_reviewer_id) REFERENCES loader.batch_reviewer(id);


--
-- Name: name_review_comment name_review_comment_period_fk; Type: FK CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.name_review_comment
    ADD CONSTRAINT name_review_comment_period_fk FOREIGN KEY (review_period_id) REFERENCES loader.batch_review_period(id);


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
-- Name: tede_old fk_fmic32f9o0fplk3xdix1yu6ha; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tede_old
    ADD CONSTRAINT fk_fmic32f9o0fplk3xdix1yu6ha FOREIGN KEY (tree_element_id) REFERENCES public.tree_element(id);


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
-- Name: tede_old fk_h7k45ugqa75w0860tysr4fgrt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tede_old
    ADD CONSTRAINT fk_h7k45ugqa75w0860tysr4fgrt FOREIGN KEY (dist_entry_id) REFERENCES public.dist_entry(id);


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
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public, loader, archive;

