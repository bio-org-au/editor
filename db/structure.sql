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
-- Name: apc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA apc;


--
-- Name: apni; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA apni;


--
-- Name: archive; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA archive;


--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: SCHEMA audit; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA audit IS 'Out-of-table audit/history logging tables and trigger functions';


--
-- Name: bhl_doi_load; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bhl_doi_load;


--
-- Name: ftree; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ftree;


--
-- Name: hep; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA hep;


--
-- Name: loader; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA loader;


--
-- Name: mapper; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mapper;


--
-- Name: temp_nsl4419; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA temp_nsl4419;


--
-- Name: temp_profile; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA temp_profile;


--
-- Name: SCHEMA temp_profile; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA temp_profile IS 'Place to include new Profile DDL for now';


--
-- Name: uncited; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA uncited;


--
-- Name: SCHEMA uncited; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA uncited IS 'Archive of name records "uncited" by instance; along with name_tags and comments';


--
-- Name: xfungi; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA xfungi;


--
-- Name: xmoss; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA xmoss;


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: audit_table(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$_$;


--
-- Name: FUNCTION audit_table(target_table regclass); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass) IS '
Add auditing support to the given table. Row-level changes will be logged with full client query text. No cols are ignored.
';


--
-- Name: audit_table(regclass, boolean, boolean); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, $2, $3, NULL, ARRAY[]::text[]);
$_$;


--
-- Name: audit_table(regclass, boolean, boolean, text[]); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
  _q_txt text;
  _ignored_cols_snip text = '';
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;

    IF audit_rows THEN
        IF array_length(ignored_cols,1) > 0 THEN
            _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
        END IF;
        _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func(' ||
                 quote_literal(audit_query_text) || _ignored_cols_snip || ');';
        RAISE NOTICE '%',_q_txt;
        EXECUTE _q_txt;
        stm_targets = 'TRUNCATE';
    ELSE
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%',_q_txt;
    EXECUTE _q_txt;

END;
$$;


--
-- Name: FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) IS '
Add auditing support to a table.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
   audit_rows:       Record each row change, or only audit at a statement level
   audit_query_text: Record the text of the client query that triggered the audit event?
   ignored_cols:     Columns to exclude from update diffs, ignore updates that change only ignored cols.
';


--
-- Name: audit_table(regclass, boolean, boolean, text, text[]); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, column_style text, cols text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
    _q_txt text;
    _cols_snip text = '';
    _style text = '';
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;

    IF audit_rows THEN
        IF array_length(cols,1) > 0 THEN
            _cols_snip = ', ' || quote_literal(cols);
        END IF;
        IF column_style IS NOT NULL THEN
            _style = ', ' || column_style;
        END IF;
        _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func(' ||
                 quote_literal(audit_query_text) || _style || _cols_snip || ');';
        RAISE NOTICE 'XXXX %',_q_txt;
        EXECUTE _q_txt;
        stm_targets = 'TRUNCATE';
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%',_q_txt;
    EXECUTE _q_txt;
END;
$$;


--
-- Name: audit_table(regclass, boolean, boolean, text, text[], text[]); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, column_style text, cols text[], xtra_cols text[]) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, $2, $3, $4, $5, $6, 'audit.if_modified_func');
$_$;


--
-- Name: audit_table(regclass, boolean, boolean, text, text[], text[], text); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, column_style text, cols text[], xtra_cols text[], audit_func text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
    _q_txt text;
    _cols_snip text = '';
    _xtra_cols_snip text = '';
    _style text = '';
BEGIN

    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;
    IF audit_func IS NULL THEN
        audit_func = 'audit.if_modified_func';
    END IF;
    IF audit_rows THEN
        IF array_length(cols,1) > 0 THEN
            _cols_snip = ', ' || quote_literal(cols);
        END IF;
        IF array_length(xtra_cols,1) > 0 THEN
            _xtra_cols_snip = ', ' || quote_literal(xtra_cols);
        END IF;
        IF column_style IS NOT NULL THEN
            _style = ', ' || column_style;
        END IF;
        _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE ' || audit_func || '(' ||
                 quote_literal(audit_query_text) || _style || _cols_snip || _xtra_cols_snip || ');';
        RAISE NOTICE '%',_q_txt;
        EXECUTE _q_txt;
        stm_targets = 'TRUNCATE';
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE ' || audit_func || '('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%',_q_txt;
    EXECUTE _q_txt;
END;
$$;


--
-- Name: if_modified_func(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    audit_row audit.logged_actions;
    excluded_cols text[] = ARRAY[]::text[];
    included_cols text[];
    xtra_cols text[];
    monitored_fields hstore;
BEGIN
    IF TG_WHEN <> 'AFTER' THEN
        RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
    END IF;
    audit_row = ROW(
        nextval('audit.logged_actions_event_id_seq'), -- event_id
        TG_TABLE_SCHEMA::text,                        -- schema_name
        TG_TABLE_NAME::text,                          -- table_name
        TG_RELID,                                     -- relation OID for much quicker searches
                session_user::text,                           -- session_user_name
                current_timestamp,                            -- action_tstamp_tx
        statement_timestamp(),                        -- action_tstamp_stm
        clock_timestamp(),                            -- action_tstamp_clk
        txid_current(),                               -- transaction ID
        current_setting('application_name'),          -- client application
        inet_client_addr(),                           -- client_addr
        inet_client_port(),                           -- client_port
        current_query(),                              -- top-level query or queries (if multistatement) from client
        substring(TG_OP,1,1),                         -- action
        NULL, NULL,                                   -- row_data, changed_fields
        'f',                                           -- statement_only
        NULL                                        -- id of tuple
        );

    IF NOT TG_ARGV[0]::boolean IS DISTINCT FROM 'f'::boolean THEN
        audit_row.client_query = NULL;
    END IF;

    IF TG_LEVEL = 'ROW' THEN
        IF TG_ARGV[1] = 'i' THEN
            included_cols = TG_ARGV[2]::text[];
        ELSIF TG_ARGV[1] = 'e' THEN
            excluded_cols = TG_ARGV[2]::text[];
        END IF;
        xtra_cols = TG_ARGV[3]::text[];
        IF TG_OP = 'UPDATE' THEN
            audit_row.row_data = hstore(OLD.*);
            monitored_fields = (slice(hstore(NEW.*),included_cols) - audit_row.row_data) - excluded_cols;
            audit_row.changed_fields = monitored_fields || slice(hstore(NEW.*),xtra_cols);
            IF monitored_fields = hstore('') THEN
                -- All changed fields are ignored. Skip this update.
                RETURN NULL;
            END IF;
        ELSIF TG_OP = 'DELETE' THEN
            audit_row.row_data = (slice(hstore(OLD.*),included_cols) - excluded_cols) || slice(hstore(OLD.*),xtra_cols);
        ELSIF TG_OP = 'INSERT' THEN
            audit_row.row_data = (slice(hstore(NEW.*),included_cols) - excluded_cols) || slice(hstore(NEW.*),xtra_cols);
        END IF;
    ELSIF (TG_LEVEL = 'STATEMENT' AND TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
        audit_row.statement_only = 't';
    ELSE
        RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger for unhandled case: %, %',TG_OP, TG_LEVEL;
        RETURN NULL;
    END IF;
    INSERT INTO audit.logged_actions VALUES (audit_row.*);
    RETURN NULL;
END;
$$;


--
-- Name: FUNCTION if_modified_func(); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.if_modified_func() IS '
Track changes to a table at the statement and/or row level.

Optional parameters to trigger in CREATE TRIGGER call:

param 0: boolean, whether to log the query text. Default ''t''.

param 1: text[], columns to ignore in updates. Default [].

         Updates to ignored cols are omitted from changed_fields.

         Updates with only ignored cols changed are not inserted
         into the audit log.

         Almost all the processing work is still done for updates
         that ignored. If you need to save the load, you need to use
         WHEN clause on the trigger instead.

         No warning or error is issued if ignored_cols contains columns
         that do not exist in the target table. This lets you specify
         a standard set of ignored columns.

There is no parameter to disable logging of values. Add this trigger as
a ''FOR EACH STATEMENT'' rather than ''FOR EACH ROW'' trigger if you do not
want to log row values.

Note that the user name logged is the login role for the session. The audit trigger
cannot obtain the active role because it is reset by the SECURITY DEFINER invocation
of the audit trigger its self.
';


--
-- Name: if_modified_tree_element(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.if_modified_tree_element() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    audit_row audit.logged_actions;
    excluded_cols text[] = ARRAY[]::text[];
    included_cols text[];
    xtra_cols text[];
    monitored_fields hstore;
    old_distribution text;
    old_comment text;
    new_distribution text;
    new_comment text;
    updated_at text;
    updated_by text;
    tree record;
BEGIN
    select * from tree into tree;
    IF TG_WHEN <> 'AFTER' THEN
        RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
    END IF;
    audit_row = ROW(
        nextval('audit.logged_actions_event_id_seq'), -- event_id
        TG_TABLE_SCHEMA::text,                        -- schema_name
        TG_TABLE_NAME::text,                          -- table_name
        TG_RELID,                                     -- relation OID for much quicker searches
                session_user::text,                           -- session_user_name
                current_timestamp,                            -- action_tstamp_tx
        statement_timestamp(),                        -- action_tstamp_stm
        clock_timestamp(),                            -- action_tstamp_clk
        txid_current(),                               -- transaction ID
        current_setting('application_name'),          -- client application
        inet_client_addr(),                           -- client_addr
        inet_client_port(),                           -- client_port
        current_query(),                              -- top-level query or queries (if multistatement) from client
        substring(TG_OP,1,1),                         -- action
        NULL, NULL,                                   -- row_data, changed_fields
        'f',                                           -- statement_only
        NULL                                        -- id of tuple
        );

    IF NOT TG_ARGV[0]::boolean IS DISTINCT FROM 'f'::boolean THEN
        audit_row.client_query = NULL;
    END IF;

    IF TG_LEVEL = 'ROW' THEN
        IF TG_ARGV[1] = 'i' THEN
            included_cols = TG_ARGV[2]::text[];
        ELSIF TG_ARGV[1] = 'e' THEN
            excluded_cols = TG_ARGV[2]::text[];
        END IF;
        xtra_cols = TG_ARGV[3]::text[];
        IF TG_OP = 'UPDATE' THEN
            audit_row.row_data = hstore(OLD.*);
            monitored_fields = (slice(hstore(NEW.*),included_cols) - audit_row.row_data) - excluded_cols;
            new_distribution = NEW.profile -> (tree.config ->> 'distribution_key') ->> 'value';
            new_comment = NEW.profile -> (tree.config ->> 'comment_key') ->> 'value';
            old_distribution = OLD.profile -> (tree.config ->> 'distribution_key') ->> 'value';
            old_comment = OLD.profile -> (tree.config ->> 'comment_key') ->> 'value';
            IF old_distribution <> new_distribution or old_distribution is null or new_distribution is null THEN
                updated_at = NEW.profile -> (tree.config ->> 'distribution_key') ->> 'updated_at';
                updated_at = REPLACE(updated_at, 'T', ' ');
                updated_by = NEW.profile -> (tree.config ->> 'distribution_key') ->> 'updated_by';
                audit_row.changed_fields = hstore(ARRAY['id', NEW.id::text, 'distribution', new_distribution, 'updated_at', updated_at, 'updated_by', updated_by]);
                updated_at = OLD.profile -> (tree.config ->> 'distribution_key') ->> 'updated_at';
                updated_at = REPLACE(updated_at, 'T', ' ');
                updated_by = OLD.profile -> (tree.config ->> 'distribution_key') ->> 'updated_by';
                audit_row.row_data = hstore(ARRAY['id', OLD.id::text, 'distribution', old_distribution, 'updated_at', updated_at, 'updated_by', updated_by]);
                INSERT INTO audit.logged_actions VALUES (audit_row.*);
            END IF;
            IF old_comment <> new_comment or old_comment is null or new_comment is null THEN
                audit_row.event_id = nextval('audit.logged_actions_event_id_seq');
                updated_at = NEW.profile -> (tree.config ->> 'comment_key') ->> 'updated_at';
                updated_at = REPLACE(updated_at, 'T', ' ');
                updated_by = NEW.profile -> (tree.config ->> 'comment_key') ->> 'updated_by';
                audit_row.changed_fields = hstore(ARRAY['id', NEW.id::text, 'comment', new_comment, 'updated_at', updated_at, 'updated_by', updated_by]);
                updated_at = OLD.profile -> (tree.config ->> 'comment_key') ->> 'updated_at';
                updated_at = REPLACE(updated_at, 'T', ' ');
                updated_by = OLD.profile -> (tree.config ->> 'comment_key') ->> 'updated_by';
                audit_row.row_data = hstore(ARRAY['id', OLD.id::text, 'comment', old_comment, 'updated_at', updated_at, 'updated_by', updated_by]);
                INSERT INTO audit.logged_actions VALUES (audit_row.*);
            END IF;
        ELSIF TG_OP = 'DELETE' THEN
        ELSIF TG_OP = 'INSERT' THEN
        END IF;
    ELSIF (TG_LEVEL = 'STATEMENT' AND TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
        audit_row.statement_only = 't';
        INSERT INTO audit.logged_actions VALUES (audit_row.*);
    ELSE
        RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger for unhandled case: %, %',TG_OP, TG_LEVEL;
        RETURN NULL;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: FUNCTION if_modified_tree_element(); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.if_modified_tree_element() IS '
Track changes to tree_element at the statement and/or row level.
';


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

CREATE SEQUENCE loader.nsl_global_seq;

SET default_tablespace = '';

SET default_table_access_method = heap;

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
    updated_by character varying(255) NOT NULL
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
            ((mapper_host.value)::text || n.uri) AS scientific_name_id,
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
                    WHEN ((COALESCE(primary_ref.abbrev_title, 'null'::character varying))::text <> 'AFD'::text) THEN (((((mapper_host.value)::text || 'reference/'::text) || (path.value)::text) || '/'::text) || primary_ref.id)
                    ELSE NULL::text
                END AS name_published_in_id,
                CASE
                    WHEN ((COALESCE(primary_ref.abbrev_title, 'null'::character varying))::text <> 'AFD'::text) THEN (COALESCE(substr((primary_ref.iso_publication_date)::text, 1, 4), (primary_ref.year)::text))::integer
                    ELSE NULL::integer
                END AS name_published_in_year,
            primary_it.name AS name_instance_type,
            ((mapper_host.value)::text || primary_inst.uri) AS name_according_to_id,
            ((primary_auth.name)::text ||
                CASE
                    WHEN (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying) IS NOT NULL) THEN ((' ('::text || (COALESCE(primary_ref.iso_publication_date, ((primary_ref.year)::text)::character varying))::text) || ')'::text)
                    ELSE NULL::text
                END) AS name_according_to,
            basionym.full_name AS original_name_usage,
                CASE
                    WHEN (basionym_inst.id IS NOT NULL) THEN ((mapper_host.value)::text || basionym_inst.uri)
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
                    WHEN ((code.value)::text = 'ICN'::text) THEN 'Plantae'::text
                    WHEN ((code.value)::text = 'ICZN'::text) THEN 'Animalia'::text
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
            ((mapper_host.value)::text || first_hybrid_parent.uri) AS first_hybrid_parent_name_id,
            second_hybrid_parent.full_name AS second_hybrid_parent_name,
            ((mapper_host.value)::text || second_hybrid_parent.uri) AS second_hybrid_parent_name_id,
            n.created_at AS created,
            n.updated_at AS modified,
            (COALESCE(code.value, 'ICN'::character varying))::text AS nomenclatural_code,
            dataset.value AS dataset_name,
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
            accepted_tree.name AS status_according_to,
            'https://creativecommons.org/licenses/by/3.0/'::text AS license,
            ((mapper_host.value)::text || n.uri) AS cc_attribution_iri
           FROM (((((((((((((((((((((((((public.name n
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
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
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
     LEFT JOIN pi ai ON (((pp.id = ai.name_id) AND ((pi.publication_usage_type)::text ~ 'autonym'::text))));


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
    (rk.rk OPERATOR(public.->) 'kingdom'::text) AS kingdom,
    (rk.rk OPERATOR(public.->) 'class'::text) AS class,
    (rk.rk OPERATOR(public.->) 'subclass'::text) AS subclass,
    (rk.rk OPERATOR(public.->) 'family'::text) AS family,
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
        CASE
            WHEN (i.cited_by_id IS NOT NULL) THEN false
            ELSE e.excluded
        END AS excluded_name,
        CASE
            WHEN (i.cited_by_id IS NOT NULL) THEN false
            ELSE true
        END AS accepted,
    tve.taxon_id AS accepted_id,
    k.rdf_id AS rank_rdf_id,
    name_space.value AS name_space,
    d.value AS tree_description,
    l.value AS tree_label,
    (rk.rk OPERATOR(public.->) 'order'::text) AS "order",
    (rk.rk OPERATOR(public.->) 'genus'::text) AS generic_name,
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
  ORDER BY (rk.rk OPERATOR(public.->) 'family'::text), COALESCE(x.full_name, n.full_name), ((((it.itorder ||
        CASE
            WHEN it.nomenclatural THEN '0000'::text
            ELSE COALESCE(substr((pi.primary_date)::text, 1, 4), '9999'::text)
        END) ||
        CASE
            WHEN (pi.autonym_of_id = COALESCE(x.id, n.id)) THEN '0'::text
            ELSE '1'::text
        END) || COALESCE(lpad((pi.primary_id)::text, 8, '0'::text), lpad((i.id)::text, 8, '0'::text))) || (COALESCE(pi.publication_date, '9999'::character varying))::text)
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
-- Name: moss; Type: SERVER; Schema: -; Owner: -
--

CREATE SERVER moss FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'moss',
    host 'pgsql-prod1-ibis.it.csiro.au',
    port '5432'
);


--
-- Name: USER MAPPING nsl SERVER moss; Type: USER MAPPING; Schema: -; Owner: -
--

CREATE USER MAPPING FOR nsl SERVER moss OPTIONS (
    password 'pvq0;yv!t4s3=lld602!',
    "user" 'nsl'
);


--
-- Name: xfungi; Type: SERVER; Schema: -; Owner: -
--

CREATE SERVER xfungi FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'fungi',
    host 'pgsql-prod1.biodiversity.org.au',
    port '5432'
);


--
-- Name: USER MAPPING nsl SERVER xfungi; Type: USER MAPPING; Schema: -; Owner: -
--

CREATE USER MAPPING FOR nsl SERVER xfungi OPTIONS (
    password '_BHE.4sc2y7n.@A-!NzAta8Y7r6AghH',
    "user" 'nsl'
);


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
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
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
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
     LEFT JOIN public.shard_config mapper_host ON (((mapper_host.name)::text = 'mapper host'::text)))
     LEFT JOIN public.name pn ON (((ntv.parent_name_id = pn.id) AND ((dataset.value)::text = 'AFD'::text) AND ((ntv.parent_rank_id)::text ~ '(species|subgenus|species-aggregate)'::text))))
     LEFT JOIN public.name gn ON (((ntv.parent_parent_name_id = gn.id) AND ((dataset.value)::text = 'AFD'::text) AND ((ntv.parent_parent_rank_id)::text ~ '(subgenus|species-aggregate)'::text))));


--
-- Name: taxon_cv; Type: VIEW; Schema: apc; Owner: -
--

CREATE VIEW apc.taxon_cv AS
 SELECT taxon_v.tree_name AS "treeName",
    taxon_v.tree_version_id AS "treeVersionId",
    taxon_v.identifier,
    taxon_v.title,
    taxon_v.tree_element_id AS "treeElementId",
    taxon_v.name_usage_label AS "taxonNameUsageLabel",
    taxon_v.taxon_id AS "taxonId",
    taxon_v.parent_taxon_id AS "parentTaxonId",
    taxon_v.name_id AS "nameId",
    taxon_v.reference_id AS "referenceId",
    taxon_v.publication_year AS "publicationYear",
    taxon_v.publication_citation AS "publicationCitation",
    taxon_v.publication_date AS "publicationDate",
    taxon_v.full_name AS "fullName",
    taxon_v.taxon_concept_id AS "taxonConceptId",
    taxon_v.is_excluded AS "isExcluded",
    taxon_v.taxonomic_status AS "taxonomicStatus",
    taxon_v.updated_at AS modified,
    taxon_v.depth,
    taxon_v.name_path AS "namePath",
    taxon_v.ltree_path AS "lTreePath",
    taxon_v.tree_name AS "datasetName",
    taxon_v.tree_rdf_id AS "treeRDFId",
    taxon_v.is_true AS "isTrue"
   FROM public.taxon_v
  WHERE (taxon_v.tree_rdf_id = 'apc'::text);


--
-- Name: tree_closure_cv; Type: VIEW; Schema: apc; Owner: -
--

CREATE VIEW apc.tree_closure_cv AS
 SELECT a.taxon_id AS "ancestorId",
    c.taxon_id AS "nodeId",
    a.depth
   FROM (public.trees_mv c
     JOIN public.trees_mv a ON ((a.ltree_path OPERATOR(public.@>) c.ltree_path)))
  WHERE (c.tree_rdf_id = 'apc'::text);


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
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
             LEFT JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))
          WHERE (a.duplicate_of_id IS NULL)) auth_v;


--
-- Name: author_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.author_cv AS
 SELECT author_v.author_id AS "authorId",
    author_v.identifier,
    author_v.standard_form AS "standardForm",
    author_v.see_also AS "seeAlso",
    author_v.author_name AS "authorName",
    author_v.author_full_name AS "authorFullName",
    author_v.dataset_name AS "datasetName"
   FROM public.author_v;


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
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
             LEFT JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))) ru;


--
-- Name: cited_usage_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.cited_usage_cv AS
 SELECT cited_usage_v.instance_id AS "relationshipId",
    cited_usage_v.identifier,
    cited_usage_v.name_id AS "nameId",
    cited_usage_v.reference_id AS "referenceId",
    cited_usage_v.author_id AS "authorId",
    cited_usage_v.usage_type_id AS "usageTypeId",
    cited_usage_v.usage_type_rdf_id AS "usageTypeRDFId",
    cited_usage_v.full_name AS "fullName",
    cited_usage_v.cited_identifier AS "citedIdentifier",
    cited_usage_v.publication_author AS "publicationAuthor",
    cited_usage_v.publication_year AS "publicationYear",
    cited_usage_v.iso_publication_date AS "publicationDate",
    cited_usage_v.publication_citation AS "publicationCitation",
    cited_usage_v.page_citation AS "pageCitation",
    cited_usage_v.bhl_url AS "BHLURL",
    cited_usage_v.verbatim_name_string AS "verbatimNameString",
    cited_usage_v.relationship_notes AS "relationshipNotes",
    cited_usage_v.cited_usage_notes AS "citedUsageNotes",
    cited_usage_v.cited_by_id AS "acceptedUsageId",
    cited_usage_v.cites_id AS "citedUsageId",
    cited_usage_v.is_current_relationship AS "isCurrentRelationship",
    cited_usage_v.is_relationship AS "isRelationship",
    cited_usage_v.is_synonym AS "isSynonym",
    cited_usage_v.is_homotypic AS "isHomotypic",
    cited_usage_v.is_heterotypic AS "isHeterotypic",
    cited_usage_v.is_misapplication AS "isMisapplication",
    cited_usage_v.is_pro_parte AS "isProParte",
    cited_usage_v.is_vernacular AS "isVernacular",
    cited_usage_v.is_isonym AS "isIsonym",
    cited_usage_v.is_secondary_source AS "isSecondarySource",
    cited_usage_v.is_generic_combination AS "isGenericCombination",
    cited_usage_v.is_uncited AS "isUncited",
    cited_usage_v.usage_order AS "usageOrder",
    cited_usage_v.dataset_name AS "datasetName",
    cited_usage_v.host,
    cited_usage_v.is_true AS "isTrue"
   FROM public.cited_usage_v
  WHERE cited_usage_v.is_relationship;


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
-- Name: name_status_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.name_status_cv AS
 SELECT name_status_v.name_status_id AS "nameStatusId",
    name_status_v.deprecated AS "isDeprecated",
    name_status_v.name_status_label AS "nameStatusLabel",
    name_status_v.display_as AS "isDisplayed",
    name_status_v.name_group_id AS "nameGroupId",
    name_status_v.is_nom_illeg AS "isNomIlleg",
    name_status_v.is_nom_inval AS "isNomInval",
    name_status_v.description_html AS "descriptionHTML",
    name_status_v.name_status_rdf_id AS "nameStatusRDFId"
   FROM public.name_status_v;


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
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
          WHERE (r.duplicate_of_id IS NULL)) ref_v;


--
-- Name: reference_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.reference_cv AS
 SELECT reference_v.reference_id AS "referenceId",
    reference_v.reference_type AS "referenceType",
    reference_v.is_published AS "isPublished",
    reference_v.identifier,
    reference_v.title,
    reference_v.author_id AS "authorId",
    reference_v.author_name AS "authorName",
    reference_v.author_role AS "authorRole",
    reference_v.citation,
    reference_v.volume,
    reference_v.year,
    reference_v.edition,
    reference_v.pages,
    reference_v.publication_date AS "publicationDate",
    reference_v.iso_publication_date AS "isoPublicationDate",
    reference_v.publisher,
    reference_v.published_location AS "publishedLocation",
    reference_v.uri,
    reference_v.short_title AS "shortTitle",
    reference_v.display_title AS "displayTitle",
    reference_v.reference_notes AS "referenceNotes",
    reference_v.doi,
    reference_v.isbn,
    reference_v.issn,
    reference_v.parent_id AS "parentId",
    reference_v.ref_author_role_id AS "refAuthorRoleId",
    reference_v.ref_type_id AS "refTypeId",
    reference_v.language,
    reference_v.tl2,
    reference_v.verbatim_author AS "verbatimAuthor",
    reference_v.dataset_name AS "datasetName",
    reference_v.is_true AS "isTrue"
   FROM public.reference_v;


--
-- Name: taxon_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.taxon_cv AS
 SELECT taxon_v.taxon_id AS "taxonId",
    taxon_v.identifier,
    taxon_v.taxon_concept_id AS "taxonConceptId",
    taxon_v.is_excluded AS "isExcluded",
    taxon_v.taxonomic_status AS "taxonomicStatus",
    taxon_v.parent_taxon_id AS "parentTaxonId",
    taxon_v.tree_element_id AS "treeElementId",
    taxon_v.tree_id AS "treeId",
    taxon_v.tree_name AS "treeName",
    taxon_v.tree_version_id AS "treeVersionId",
    taxon_v.title,
    taxon_v.name_usage_label AS "taxonNameUsageLabel",
    taxon_v.name_id AS "nameId",
    taxon_v.parent_name_id AS "parentNameId",
    taxon_v.reference_id AS "referenceId",
    taxon_v.publication_citation AS "publicationCitation",
    taxon_v.publication_year AS "publicationYear",
    taxon_v.publication_date AS "publicationDate",
    taxon_v.full_name AS "fullName",
    taxon_v.updated_at AS modified,
    taxon_v.depth,
    taxon_v.name_path AS "namePath",
    taxon_v.ltree_path AS "lTreePath",
    taxon_v.tree_rdf_id AS "treeRDFId",
    taxon_v.dataset_name AS "datasetName",
    taxon_v.accepted_tree AS "isAcceptedTree",
    taxon_v.is_true AS "isTrue"
   FROM public.taxon_v;


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
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM public.nsl_tree_mv ntv
                      WHERE ((ntv.name_id = n.id) AND ntv.is_accepted))) THEN 'accepted'::text
                    WHEN (EXISTS ( SELECT 1
                       FROM public.nsl_tree_mv ntv
                      WHERE ((ntv.name_id = n.id) AND ntv.is_excluded))) THEN 'excluded'::text
                    WHEN (EXISTS ( SELECT 1
                       FROM ((public.instance s
                         JOIN public.nsl_tree_mv ntv ON ((s.cited_by_id = ntv.instance_id)))
                         JOIN public.instance_type st ON ((st.id = s.instance_type_id)))
                      WHERE ((s.name_id = n.id) AND ntv.is_accepted AND st.synonym))) THEN 'included'::text
                    WHEN (EXISTS ( SELECT 1
                       FROM ((public.instance s
                         JOIN public.nsl_tree_mv ntv ON ((s.cited_by_id = ntv.instance_id)))
                         JOIN public.instance_type st ON ((st.id = s.instance_type_id)))
                      WHERE ((s.name_id = n.id) AND ntv.is_excluded AND st.synonym))) THEN 'excluded'::text
                    ELSE 'unplaced'::text
                END AS nsl_status,
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
            COALESCE(nv.kingdom,
                CASE
                    WHEN ((code.value)::text = 'ICN'::text) THEN 'Plantae'::text
                    WHEN ((code.value)::text = 'ICZN'::text) THEN 'Animalia'::text
                    ELSE NULL::text
                END) AS kingdom,
                CASE
                    WHEN (rank.sort_order > family.sort_order) THEN COALESCE(nv.family, (family_name.name_element)::text)
                    ELSE NULL::text
                END AS family,
                CASE
                    WHEN (((COALESCE(n.simple_name, ' '::character varying))::text !~ '\s'::text) AND ((n.simple_name)::text = (n.name_element)::text) AND nt.scientific AND (rank.sort_order <= genus.sort_order)) THEN n.simple_name
                    ELSE NULL::character varying
                END AS uninomial,
                CASE
                    WHEN (((pk.rdf_id)::text = 'genus'::text) AND nt.scientific AND ((rank.rdf_id)::text <> 'species'::text)) THEN n.name_element
                    ELSE NULL::character varying
                END AS infrageneric_epithet,
                CASE
                    WHEN ((rank.sort_order >= genus.sort_order) AND nt.scientific) THEN COALESCE(((array_remove(string_to_array(regexp_replace(rtrim(substr((n.simple_name)::text, 1, (length((n.simple_name)::text) - length((n.name_element)::text)))), '(^cf\. |^aff[,.] )'::text, ''::text, 'i'::text), ' '::text), 'x'::text) || (n.name_element)::text))[1], nv.generic_name)
                    ELSE NULL::text
                END AS generic_name,
                CASE
                    WHEN ((rank.sort_order > species.sort_order) AND nt.scientific) THEN COALESCE(((array_remove(string_to_array(regexp_replace(rtrim(substr((n.simple_name)::text, 1, (length((n.simple_name)::text) - length((n.name_element)::text)))), '(^cf\. |^aff[,.] )'::text, ''::text, 'i'::text), ' '::text), 'x'::text) || (n.name_element)::text))[2], nv.specific_epithet)
                    WHEN ((rank.sort_order = species.sort_order) AND nt.scientific) THEN (n.name_element)::text
                    ELSE NULL::text
                END AS specific_epithet,
                CASE
                    WHEN ((rank.sort_order > species.sort_order) AND nt.scientific) THEN n.name_element
                    ELSE NULL::character varying
                END AS infraspecific_epithet,
                CASE
                    WHEN (nt.cultivar = true) THEN n.name_element
                    ELSE NULL::character varying
                END AS cultivar_epithet,
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
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
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
-- Name: taxon_name_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.taxon_name_cv AS
 SELECT taxon_name_v.name_id AS "nameId",
    taxon_name_v.identifier,
    taxon_name_v.name_type AS "nameType",
    taxon_name_v.rank,
    taxon_name_v.full_name AS "fullName",
    taxon_name_v.title,
    taxon_name_v.nomenclatural_status AS "nomenclaturalStatus",
    taxon_name_v.name_status_id AS "nameStatusId",
    taxon_name_v.nsl_status AS "NSLStatus",
    taxon_name_v.simple_name AS "simpleName",
    taxon_name_v.authorship,
    taxon_name_v.publication_citation AS "publicationCitation",
    taxon_name_v.publication_year AS "publicationYear",
    taxon_name_v.author_id AS "authorId",
    taxon_name_v.basionym_id AS "basionymId",
    taxon_name_v.basionym_author_id AS "basionymAuthorId",
    taxon_name_v.primary_usage_id AS "primaryUsageId",
    taxon_name_v.combination_usage_id AS "combinationUsageId",
    taxon_name_v.publication_usage_type AS "publicationUsageType",
    taxon_name_v.rank_rdf_id AS "rankRDFId",
    taxon_name_v.rank_abbreviation AS "rankAbbreviation",
    taxon_name_v.is_changed_combination AS "isChangedCombination",
    taxon_name_v.is_autonym AS "isAutonym",
    taxon_name_v.is_cultivar AS "isCultivar",
    taxon_name_v.is_name_formula AS "isNameFormula",
    taxon_name_v.is_scientific AS "isScientific",
    taxon_name_v.is_nom_inval AS "isNomInval",
    taxon_name_v.is_nom_illeg AS "isNomIlleg",
    taxon_name_v.type_citation AS "typeCitation",
    taxon_name_v.kingdom,
    taxon_name_v.family,
    taxon_name_v.uninomial,
    taxon_name_v.infrageneric_epithet AS "infragenericEpithet",
    taxon_name_v.generic_name AS "genericName",
    taxon_name_v.specific_epithet AS "specificEpithet",
    taxon_name_v.infraspecific_epithet AS "infraspecificEpithet",
    taxon_name_v.cultivar_epithet AS "cultivarEpithet",
    taxon_name_v.is_hybrid AS "isHybrid",
    taxon_name_v.first_hybrid_parent_name AS "firstHybridParentName",
    taxon_name_v.first_hybrid_parent_name_id AS "firstHybridParentNameId",
    taxon_name_v.second_hybrid_parent_name AS "secondHybridParentName",
    taxon_name_v.second_hybrid_parent_name_id AS "secondHybridParentNameId",
    taxon_name_v.created,
    taxon_name_v.modified,
    taxon_name_v.nomenclatural_code AS "nomenclaturalCode",
    taxon_name_v.dataset_name AS "datasetName",
    taxon_name_v.license,
    taxon_name_v.cc_attribution_iri AS "ccAttributionIRI",
    taxon_name_v.source_id AS "sourceId",
    taxon_name_v.source_id_string AS "sourceIdString",
    taxon_name_v.sort_name AS "sortName",
    taxon_name_v.taxon_rank_sort_order AS "taxonRankSortOrder",
    taxon_name_v.is_true AS "isTrue"
   FROM public.taxon_name_v;


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
                    WHEN it.misapplied THEN concat_ws(' '::text, un.simple_name, ' auct. non. ', (('('::text || (ba.abbrev)::text) || ')'::text), na.abbrev, ' sensu ', ca.name, "left"((cr.iso_publication_date)::text, 4), ' sec.', ua.name, (', '::text || "left"((ur.iso_publication_date)::text, 4)))
                    ELSE concat_ws(' '::text, un.full_name,
                    CASE
                        WHEN it.alignment THEN concat_ws(' '::text, 'sensu', ca.name, (', '::text || "left"((cr.iso_publication_date)::text, 4)), 'sec.', ua.name, (', '::text || "left"((ur.iso_publication_date)::text, 4)))
                        WHEN nt.scientific THEN
                        CASE
                            WHEN (ns.nom_inval AND ((code.value)::text = 'ICN'::text)) THEN concat_ws(' '::text, (','::text || (ns.name)::text), ' sec.', ua.name, (', '::text || "left"((ur.iso_publication_date)::text, 4)))
                            ELSE NULL::text
                        END
                        ELSE NULL::text
                    END)
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
             LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
             LEFT JOIN public.shard_config host ON (((host.name)::text = 'mapper host'::text)))
             LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)))) nu;


--
-- Name: taxon_name_usage_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.taxon_name_usage_cv AS
 SELECT taxon_name_usage_v.instance_id AS "usageId",
    taxon_name_usage_v.identifier,
    taxon_name_usage_v.title,
    taxon_name_usage_v.name_id AS "nameId",
    taxon_name_usage_v.instance_type_id AS "instanceTypeId",
    taxon_name_usage_v.reference_id AS "referenceId",
    taxon_name_usage_v.bhl_url AS "BHLURL",
    taxon_name_usage_v.usage_type_id AS "usageTypeId",
    taxon_name_usage_v.usage_type_rdf_id AS "usageTypeRDFId",
    taxon_name_usage_v.author_id AS "authorId",
    taxon_name_usage_v.full_name AS "fullName",
    taxon_name_usage_v.publication_author AS "publicationAuthor",
    taxon_name_usage_v.publication_year AS "publicationYear",
    taxon_name_usage_v.publication_citation AS "publicationCitation",
    taxon_name_usage_v.page_citation AS "pageCitation",
    taxon_name_usage_v.iso_publication_date AS "publicationDate",
    taxon_name_usage_v.verbatim_name_string AS "verbatimNameString",
    taxon_name_usage_v.usage_notes AS "usageNotes",
    taxon_name_usage_v.cited_by_id AS "citedById",
    taxon_name_usage_v.cites_id AS "citesId",
    taxon_name_usage_v.concept_id AS "conceptId",
        CASE
            WHEN taxon_name_usage_v.is_current_usage THEN true
            WHEN taxon_name_usage_v.is_current_relationship THEN true
            ELSE false
        END AS "isNSLUsage",
    taxon_name_usage_v.is_current_relationship AS iscurrentrelationship,
    taxon_name_usage_v.is_current_usage AS iscurrentusage,
    taxon_name_usage_v.is_combination_instance AS "isCombinationUsage",
    taxon_name_usage_v.is_primary_instance AS "isPrimaryUsage",
    taxon_name_usage_v.primary_instance_id AS "primaryUsageId",
    taxon_name_usage_v.is_standalone AS "isStandalone",
    taxon_name_usage_v.is_relationship AS "isRelationship",
    taxon_name_usage_v.is_synonym AS "isSynonym",
    taxon_name_usage_v.is_homotypic AS "isHomotypic",
    taxon_name_usage_v.is_heterotypic AS "isHeterotypic",
    taxon_name_usage_v.is_misapplication AS "isMisapplication",
    taxon_name_usage_v.is_pro_parte AS "isProParte",
    taxon_name_usage_v.is_isonym AS "isIsonym",
    taxon_name_usage_v.is_vernacular AS "isVernacular",
    taxon_name_usage_v.is_secondary_source AS "isSecondarySource",
    taxon_name_usage_v.is_generic_combination AS "isGenericCombination",
    taxon_name_usage_v.is_uncited AS "isUncited",
    taxon_name_usage_v.dataset_name AS "datasetName",
    taxon_name_usage_v.is_true AS "isTrue",
    taxon_name_usage_v.usage_order AS "usageOrder"
   FROM public.taxon_name_usage_v;


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
-- Name: taxonomic_status_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.taxonomic_status_cv AS
 SELECT taxonomic_status_v.tree_name AS "treeName",
    taxonomic_status_v.taxon_id AS "taxonId",
    taxonomic_status_v.accepted_name_usage_id AS "acceptedNameUsageId",
    taxonomic_status_v.name_usage_id AS "nameUsageId",
    taxonomic_status_v.accepted_name_id AS "acceptedNameId",
    taxonomic_status_v.name_id AS "nameId",
    taxonomic_status_v.tree_status AS "treeStatus",
    taxonomic_status_v.usage_type AS "usageType"
   FROM public.taxonomic_status_v;


--
-- Name: tree_closure_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tree_closure_v AS
 SELECT a.taxon_id AS ancestor_id,
    c.taxon_id AS node_id,
    (c.depth - a.depth) AS depth,
    c.tree_name AS dataset_name,
    t.accepted_tree
   FROM ((public.trees_mv c
     JOIN public.trees_mv a ON ((a.ltree_path OPERATOR(public.@>) c.ltree_path)))
     JOIN public.tree t ON ((c.tree_id = t.id)));


--
-- Name: tree_closure_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.tree_closure_cv AS
 SELECT tree_closure_v.ancestor_id AS "ancestorId",
    tree_closure_v.node_id AS "nodeId",
    tree_closure_v.depth
   FROM public.tree_closure_v;


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
     LEFT JOIN public.shard_config dataset ON (((dataset.name)::text = 'name space'::text)))
     LEFT JOIN public.shard_config code ON (((code.name)::text = 'nomenclatural code'::text)));


--
-- Name: tree_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.tree_cv AS
 SELECT tree_v.tree_id AS "treeId",
    tree_v.tree_name AS "treeName",
    tree_v.tree_reference_id AS "treeReferenceId",
    tree_v.identifier,
    tree_v.tree_description_html AS "treeDescriptionHtml",
    tree_v.tree_home_page AS "treeHomePage",
    tree_v.current_tree_version_id AS "currentTreeVersionId",
    tree_v.default_draft_tree_version_id AS "defaultDraftTreeVersionId",
    tree_v.dataset_name AS "datasetName",
    tree_v.code
   FROM public.tree_v;


--
-- Name: usage_note_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.usage_note_cv AS
 SELECT n.id AS "usageNoteId",
    k.name AS "usageNoteLabel",
    n.instance_id AS "usageId",
    n.value AS "usageNoteText",
        CASE
            WHEN ((k.rdf_id)::text ~ 'type'::text) THEN true
            ELSE false
        END AS "isTypeNote",
        CASE
            WHEN ((k.rdf_id)::text ~ 'dist'::text) THEN true
            ELSE false
        END AS "isDistributionNote",
        CASE
            WHEN ((k.rdf_id)::text !~ '(type|dist)'::text) THEN true
            ELSE false
        END AS "isOtherNote",
        CASE
            WHEN ((k.rdf_id)::text ~ 'qualification'::text) THEN true
            ELSE false
        END AS "isQualification",
    k.rdf_id AS "usageNoteKeyRDFId",
    n.instance_note_key_id AS "UsageNoteKeyId",
    k.sort_order AS "usageNoteKeyOrder"
   FROM (public.instance_note n
     JOIN public.instance_note_key k ON ((n.instance_note_key_id = k.id)))
  WHERE (NOT k.deprecated);


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
-- Name: usage_type_cv; Type: VIEW; Schema: apni; Owner: -
--

CREATE VIEW apni.usage_type_cv AS
 SELECT usage_type_v.usage_type_id AS "usageTypeId",
    usage_type_v.usage_type_label AS "usageTypeLabel",
    usage_type_v.usage_type_rdf_id AS "usageTypeRDFId",
    usage_type_v.description_html AS "descriptionHTML",
    usage_type_v.usage_type_has_label AS "usageTypeHasLabel",
    usage_type_v.usage_type_of_label AS "usageTypeOfLabel",
    usage_type_v.sort_order AS "sortOrder",
    usage_type_v.is_doubtful AS "isDoubtful",
    usage_type_v.is_misapplied AS "isMisapplied",
    usage_type_v.is_homotypic AS "isHomotypic",
    usage_type_v.is_primary_instance AS "isPrimaryInstance",
    usage_type_v.is_pro_parte AS "isProParte",
    usage_type_v.is_protologue AS "isProtologue",
    usage_type_v.is_relationship AS "isRelationship",
    usage_type_v.is_secondary AS "isSecondary",
    usage_type_v.is_treatment AS "isTreatment",
    usage_type_v.is_synonym AS "isSynonym",
    usage_type_v.is_heterotypic AS "isHeterotypic",
    usage_type_v.is_unsourced AS "isUnsourced",
    usage_type_v.is_bidirectional AS "isBidirectional",
    usage_type_v.usage_type_order AS "usageTypeOrder"
   FROM public.usage_type_v;


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
-- Name: loader_batch_raw_names_02_feb_2023; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_02_feb_2023 (
    id bigint NOT NULL,
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
-- Name: loader_batch_raw_names_20_mar_2023; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_20_mar_2023 (
    id bigint NOT NULL,
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
-- Name: loader_batch_raw_names_26_sep_2023; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_26_sep_2023 (
    id bigint NOT NULL,
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
-- Name: loader_batch_raw_names_list_105; Type: TABLE; Schema: archive; Owner: -
--

CREATE TABLE archive.loader_batch_raw_names_list_105 (
    id bigint NOT NULL,
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
-- Name: logged_actions; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.logged_actions (
    event_id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    relid oid NOT NULL,
    session_user_name text,
    action_tstamp_tx timestamp with time zone NOT NULL,
    action_tstamp_stm timestamp with time zone NOT NULL,
    action_tstamp_clk timestamp with time zone NOT NULL,
    transaction_id bigint,
    application_name text,
    client_addr inet,
    client_port integer,
    client_query text,
    action text NOT NULL,
    row_data public.hstore,
    changed_fields public.hstore,
    statement_only boolean NOT NULL,
    id bigint,
    CONSTRAINT logged_actions_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text, 'T'::text])))
);


--
-- Name: TABLE logged_actions; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON TABLE audit.logged_actions IS 'History of auditable actions on audited tables, from audit.if_modified_func()';


--
-- Name: COLUMN logged_actions.event_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.event_id IS 'Unique identifier for each auditable event';


--
-- Name: COLUMN logged_actions.schema_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.schema_name IS 'Database schema audited table for this event is in';


--
-- Name: COLUMN logged_actions.table_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.table_name IS 'Non-schema-qualified table name of table event occured in';


--
-- Name: COLUMN logged_actions.relid; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::regclass';


--
-- Name: COLUMN logged_actions.session_user_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.session_user_name IS 'Login / session user whose statement caused the audited event';


--
-- Name: COLUMN logged_actions.action_tstamp_tx; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_stm; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_clk; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';


--
-- Name: COLUMN logged_actions.transaction_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.transaction_id IS 'Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.';


--
-- Name: COLUMN logged_actions.application_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.application_name IS 'Application name set when this audit event occurred. Can be changed in-session by client.';


--
-- Name: COLUMN logged_actions.client_addr; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';


--
-- Name: COLUMN logged_actions.client_port; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_port IS 'Remote peer IP port address of client that issued query. Undefined for unix socket.';


--
-- Name: COLUMN logged_actions.client_query; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_query IS 'Top-level query that caused this auditable event. May be more than one statement.';


--
-- Name: COLUMN logged_actions.action; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';


--
-- Name: COLUMN logged_actions.row_data; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';


--
-- Name: COLUMN logged_actions.changed_fields; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.changed_fields IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';


--
-- Name: COLUMN logged_actions.statement_only; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.logged_actions_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.logged_actions_event_id_seq OWNED BY audit.logged_actions.event_id;


--
-- Name: bhl_doi_data; Type: TABLE; Schema: bhl_doi_load; Owner: -
--

CREATE TABLE bhl_doi_load.bhl_doi_data (
    instance_id integer,
    scientific_name text,
    doi text,
    bhl_page_no integer,
    bhl_page_url text,
    citation text,
    notes text,
    formatted text
);


--
-- Name: lost_identifiers; Type: TABLE; Schema: ftree; Owner: -
--

CREATE TABLE ftree.lost_identifiers (
    identifier_id bigint,
    match_id bigint
);


--
-- Name: match; Type: TABLE; Schema: ftree; Owner: -
--

CREATE TABLE ftree.match (
    id bigint,
    uri character varying(255),
    deprecated boolean,
    updated_at timestamp with time zone,
    updated_by character varying(255),
    nsl_id bigint,
    object_type text,
    identifier_id bigint,
    version_number bigint
);


--
-- Name: apni; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.apni (
    id bigint,
    family_id bigint,
    parent_id bigint,
    second_parent_id bigint,
    duplicate_of_id bigint
);


--
-- Name: TABLE apni; Type: COMMENT; Schema: hep; Owner: -
--

COMMENT ON TABLE hep.apni IS 'the names to remain';


--
-- Name: apni_instance; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.apni_instance (
    id bigint,
    lock_version bigint,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    draft boolean,
    instance_type_id bigint,
    name_id bigint,
    namespace_id bigint,
    nomenclatural_status character varying(50),
    page character varying(255),
    page_qualifier character varying(255),
    parent_id bigint,
    reference_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone,
    updated_by character varying(1000),
    valid_record boolean,
    verbatim_name_string character varying(255),
    uri text,
    cached_synonymy_html text
);


--
-- Name: apni_name; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.apni_name (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: author; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.author (
    id bigint,
    lock_version bigint,
    abbrev character varying(100),
    created_at timestamp with time zone,
    created_by character varying(255),
    date_range character varying(50),
    duplicate_of_id bigint,
    full_name character varying(255),
    ipni_id character varying(50),
    name character varying(1000),
    namespace_id bigint,
    notes character varying(1000),
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    valid_record boolean,
    uri text
);


--
-- Name: comment; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.comment (
    id bigint,
    lock_version bigint,
    author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text,
    updated_at timestamp with time zone,
    updated_by character varying(50)
);


--
-- Name: fix_identifier; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.fix_identifier (
    id bigint,
    id_number bigint,
    name_space character varying(255),
    object_type character varying(255),
    deleted boolean,
    reason_deleted character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    preferred_uri_id bigint,
    version_number bigint,
    match_id bigint
);


--
-- Name: fix_match; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.fix_match (
    id bigint,
    uri character varying(255),
    deprecated boolean,
    updated_at timestamp with time zone,
    updated_by character varying(255),
    taxon_id bigint,
    tree_version_id bigint,
    identifier_id bigint,
    object_type text
);


--
-- Name: identifier; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.identifier (
    id bigint,
    id_number bigint,
    name_space character varying(255),
    object_type character varying(255),
    deleted boolean,
    reason_deleted character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    preferred_uri_id bigint,
    version_number bigint,
    match_id bigint
);


--
-- Name: identifier_list; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.identifier_list (
    id bigint,
    "?column?" text
);


--
-- Name: instance; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.instance (
    id bigint,
    lock_version bigint,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    draft boolean,
    instance_type_id bigint,
    name_id bigint,
    namespace_id bigint,
    nomenclatural_status character varying(50),
    page character varying(255),
    page_qualifier character varying(255),
    parent_id bigint,
    reference_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone,
    updated_by character varying(1000),
    valid_record boolean,
    verbatim_name_string character varying(255),
    uri text,
    cached_synonymy_html text
);


--
-- Name: instance_note; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.instance_note (
    id bigint,
    lock_version bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    instance_id bigint,
    instance_note_key_id bigint,
    namespace_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone,
    updated_by character varying(50),
    value character varying(4000)
);


--
-- Name: instance_note_key; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.instance_note_key (
    id bigint,
    lock_version bigint,
    deprecated boolean,
    name character varying(255),
    sort_order integer,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: instance_resources; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.instance_resources (
    instance_id bigint,
    resource_id bigint
);


--
-- Name: instance_type; Type: VIEW; Schema: hep; Owner: -
--

CREATE VIEW hep.instance_type AS
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
    instance_type.bidirectional
   FROM public.instance_type
  WHERE (instance_type.id IN ( SELECT instance.instance_type_id
           FROM hep.instance));


--
-- Name: match; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.match (
    id bigint,
    uri character varying(255),
    deprecated boolean,
    updated_at timestamp with time zone,
    updated_by character varying(255),
    tree_element_id bigint,
    tree_version_id bigint,
    identifier_id bigint
);


--
-- Name: name; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.name (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: reference; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.reference (
    id bigint,
    lock_version bigint,
    abbrev_title character varying(2000),
    author_id bigint,
    bhl_url character varying(4000),
    citation character varying(4000),
    citation_html character varying(4000),
    created_at timestamp with time zone,
    created_by character varying(255),
    display_title character varying(2000),
    doi character varying(255),
    duplicate_of_id bigint,
    edition character varying(100),
    isbn character varying(16),
    issn character varying(16),
    language_id bigint,
    namespace_id bigint,
    notes character varying(1000),
    pages character varying(1000),
    parent_id bigint,
    publication_date character varying(50),
    published boolean,
    published_location character varying(1000),
    publisher character varying(1000),
    ref_author_role_id bigint,
    ref_type_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    title character varying(2000),
    tl2 character varying(30),
    updated_at timestamp with time zone,
    updated_by character varying(1000),
    valid_record boolean,
    verbatim_author character varying(1000),
    verbatim_citation character varying(2000),
    verbatim_reference character varying(1000),
    volume character varying(100),
    year integer,
    uri text,
    iso_publication_date character varying(10)
);


--
-- Name: removable_instance; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.removable_instance (
    id bigint,
    lock_version bigint,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    draft boolean,
    instance_type_id bigint,
    name_id bigint,
    namespace_id bigint,
    nomenclatural_status character varying(50),
    page character varying(255),
    page_qualifier character varying(255),
    parent_id bigint,
    reference_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    updated_at timestamp with time zone,
    updated_by character varying(1000),
    valid_record boolean,
    verbatim_name_string character varying(255),
    uri text,
    cached_synonymy_html text
);


--
-- Name: removable_name; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.removable_name (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: resource; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.resource (
    id bigint,
    lock_version bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    path character varying(2400),
    site_id bigint,
    updated_at timestamp with time zone,
    updated_by character varying(50),
    resource_type_id bigint
);


--
-- Name: resource_type; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.resource_type (
    id bigint,
    lock_version bigint,
    css_icon text,
    deprecated boolean,
    description text,
    display boolean,
    media_icon_id bigint,
    name text,
    rdf_id character varying(50)
);


--
-- Name: tree; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.tree (
    id bigint,
    lock_version bigint,
    accepted_tree boolean,
    config jsonb,
    current_tree_version_id bigint,
    default_draft_tree_version_id bigint,
    description_html text,
    group_name text,
    host_name text,
    link_to_home_page text,
    name text,
    reference_id bigint
);


--
-- Name: tree_element; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.tree_element (
    id bigint,
    lock_version bigint,
    display_html text,
    excluded boolean,
    instance_id bigint,
    instance_link text,
    name_element character varying(255),
    name_id bigint,
    name_link text,
    previous_element_id bigint,
    profile jsonb,
    rank character varying(50),
    simple_name text,
    source_element_link text,
    source_shard text,
    synonyms jsonb,
    synonyms_html text,
    updated_at timestamp with time zone,
    updated_by character varying(255)
);


--
-- Name: tree_element_distribution_entries; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.tree_element_distribution_entries (
    dist_entry_id bigint,
    tree_element_id bigint
);


--
-- Name: tree_version; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.tree_version (
    id bigint,
    lock_version bigint,
    created_at timestamp with time zone,
    created_by character varying(255),
    draft_name text,
    log_entry text,
    previous_version_id bigint,
    published boolean,
    published_at timestamp with time zone,
    published_by character varying(100),
    tree_id bigint
);


--
-- Name: tree_version_element; Type: TABLE; Schema: hep; Owner: -
--

CREATE TABLE hep.tree_version_element (
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
    default_reference_id bigint,
    use_sort_key_for_ordering boolean DEFAULT true NOT NULL
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
-- Name: batch_stack_v; Type: VIEW; Schema: loader; Owner: -
--

CREATE VIEW loader.batch_stack_v AS
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
            ((to_char(loader_batch.created_at, 'yyyymmdd'::text) || 'A batch '::text) || (loader_batch.name)::text) AS order_by
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
            ((to_char(lb.created_at, 'yyyymmdd'::text) || (('A batch '::text || (lb.name)::text) || ' B review '::text)) || (br.name)::text) AS order_by
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
            ((to_char(lb.created_at, 'yyyymmdd'::text) || (((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' C period '::text)) || brp.start_date) AS order_by
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
            ((to_char(lb.created_at, 'yyyymmdd'::text) || (((((('A batch '::text || (lb.name)::text) || ' B review '::text) || (br.name)::text) || ' C period '::text) || brp.start_date) || ' '::text)) || (users.name)::text) AS order_by
           FROM ((((((loader.batch_reviewer brer
             JOIN loader.batch_review_period brp ON ((brer.batch_review_period_id = brp.id)))
             JOIN public.users ON ((brer.user_id = users.id)))
             JOIN loader.batch_review br ON ((brp.batch_review_id = br.id)))
             JOIN loader.loader_batch lb ON ((br.loader_batch_id = lb.id)))
             JOIN public.org ON ((brer.org_id = org.id)))
             JOIN loader.batch_review_role brrole ON ((brer.batch_review_role_id = brrole.id)))) subq
  ORDER BY subq.order_by;


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
    loaded_from_instance_id bigint
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
    CONSTRAINT name_review_comment_context_check CHECK (((context)::text ~ 'accepted|excluded|distribution|concept-note|synonym|misapplied|unknown'::text))
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
-- Name: db_version; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: mapper_sequence; Type: SEQUENCE; Schema: mapper; Owner: -
--

CREATE SEQUENCE mapper.mapper_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.host (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    host_name character varying(512) NOT NULL,
    preferred boolean DEFAULT false NOT NULL
);


--
-- Name: identifier; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.identifier (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    id_number bigint NOT NULL,
    name_space character varying(255) NOT NULL,
    object_type character varying(255) NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    reason_deleted character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    preferred_uri_id bigint,
    version_number bigint
);


--
-- Name: identifier_identities; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.identifier_identities (
    match_id bigint NOT NULL,
    identifier_id bigint NOT NULL
);


--
-- Name: match; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.match (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    uri character varying(255) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone,
    updated_by character varying(255)
);


--
-- Name: match_host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.match_host (
    match_hosts_id bigint,
    host_id bigint
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
-- Name: bdr_prefix_v; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bdr_prefix_v AS
 SELECT d.value AS tree_description,
    l.value AS tree_label,
    t.value AS tree_context,
    n.value AS name_context
   FROM ((((public.shard_config c
     JOIN jsonb_each_text('{"AFD": "afd", "APNI": "apc", "Algae": "aal", "Fungi": "afl", "Lichen": "alc", "AusMoss": "abl"}'::jsonb) t(key, value) ON ((t.key = (c.value)::text)))
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
    'https://id.biodiversity.org.au/tree/abl/'::text AS abl,
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


--
-- Name: nsl_tree_closure_cv; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nsl_tree_closure_cv AS
 SELECT tree_closure_cv."ancestorId",
    tree_closure_cv."nodeId",
    tree_closure_cv.depth
   FROM apc.tree_closure_cv;


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


--
-- Name: xpg; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xpg (
    id integer,
    line text
);


--
-- Name: match; Type: TABLE; Schema: temp_nsl4419; Owner: -
--

CREATE TABLE temp_nsl4419.match (
    id bigint,
    uri character varying(255),
    deprecated boolean,
    updated_at timestamp with time zone,
    updated_by character varying(255),
    id_number bigint,
    object_type text,
    identifier_id bigint,
    version_number bigint
);


--
-- Name: nsl4419_identifier; Type: TABLE; Schema: temp_nsl4419; Owner: -
--

CREATE TABLE temp_nsl4419.nsl4419_identifier (
    id bigint,
    id_number bigint,
    name_space character varying(255),
    object_type character varying(255),
    preferred_uri_id bigint,
    version_number bigint,
    new_taxon_id bigint,
    new_identifier_id bigint,
    new_preferred_uri bigint
);


--
-- Name: nsl4419_match; Type: TABLE; Schema: temp_nsl4419; Owner: -
--

CREATE TABLE temp_nsl4419.nsl4419_match (
    match_id bigint,
    uri character varying(255),
    deprecated boolean,
    new_deprecated boolean,
    taxon_id bigint,
    di_id bigint,
    new_taxon_id bigint,
    replace boolean
);


--
-- Name: profile; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    tree_id bigint,
    name text,
    name_full text,
    is_current boolean,
    is_available boolean,
    internal_notes text,
    source_id bigint,
    source_system character varying(50),
    source_id_string character varying(100),
    namespace_id bigint,
    lock_version bigint DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile IS 'The settings for a profile product.';


--
-- Name: COLUMN profile.id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.id IS 'A system wide unique identifier allocated to each profile product.';


--
-- Name: COLUMN profile.tree_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.tree_id IS 'The tree (classification) used for this profile product.';


--
-- Name: COLUMN profile.name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.name IS 'The standard acronym for this profile product. i.e. FOA, APC.';


--
-- Name: COLUMN profile.name_full; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.name_full IS 'The full name for this profile product. i.e. Flora of Australia.';


--
-- Name: COLUMN profile.is_current; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.is_current IS 'Indicates this profile product is currently being maintained and published.';


--
-- Name: COLUMN profile.is_available; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.is_available IS 'Indicates this profile product is publicly available for view only.';


--
-- Name: COLUMN profile.internal_notes; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.internal_notes IS 'Notes about the management or maintenance of this profile product.';


--
-- Name: COLUMN profile.source_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.source_id IS 'The key at the source system imported on migration.';


--
-- Name: COLUMN profile.source_system; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile.source_id_string; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile.namespace_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.namespace_id IS 'The auNSL dataset that physically contains this profile text.';


--
-- Name: COLUMN profile.lock_version; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: profile_annotation; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile_annotation (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    profile_item_id bigint NOT NULL,
    value text NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system text,
    lock_version bigint DEFAULT 0,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_annotation; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile_annotation IS 'An annotation made on a profile.';


--
-- Name: COLUMN profile_annotation.id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.id IS 'A system wide unique identifier allocated to each profile annotation record.';


--
-- Name: COLUMN profile_annotation.profile_item_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.profile_item_id IS 'The profile item about which this annotation is made.';


--
-- Name: COLUMN profile_annotation.value; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.value IS 'The annotation statement.';


--
-- Name: COLUMN profile_annotation.source_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.source_id IS 'The key at the source system imported on migration';


--
-- Name: COLUMN profile_annotation.source_id_string; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile_annotation.source_system; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile_annotation.lock_version; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_annotation.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_annotation.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_annotation.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_annotation.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_annotation.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_annotation.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_annotation.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: profile_item; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile_item (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    profile_item_config_id bigint NOT NULL,
    instance_id bigint NOT NULL,
    is_draft boolean DEFAULT true NOT NULL,
    is_original boolean DEFAULT true NOT NULL,
    is_quote boolean DEFAULT false NOT NULL,
    quotes_profile_item_id bigint NOT NULL,
    is_assertion boolean DEFAULT false NOT NULL,
    profile_text_id bigint,
    profile_image_id bigint,
    profile_general_ref character(1),
    tree_id bigint,
    min_tree_version_id bigint,
    max_tree_version_id bigint,
    uri text,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    namespace_id bigint NOT NULL,
    lock_version bigint DEFAULT 0,
    updated_at timestamp with time zone NOT NULL,
    updated_by text NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone,
    CONSTRAINT one_object_check CHECK (((((profile_text_id IS NOT NULL))::integer + ((profile_general_ref IS NOT NULL))::integer) = 1))
);


--
-- Name: TABLE profile_item; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile_item IS 'The usage of a profile object (text, reference, distribution etc) for a taxon in a profile product.';


--
-- Name: COLUMN profile_item.id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.id IS 'A system wide unique identifier allocated to each profile item record.';


--
-- Name: COLUMN profile_item.profile_item_config_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.profile_item_config_id IS 'The local usage of this statement in a profile. The has an associated object type.';


--
-- Name: COLUMN profile_item.instance_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.instance_id IS 'The instance (accepted taxon name usage) for which this profile item is being stated.';


--
-- Name: COLUMN profile_item.is_draft; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.is_draft IS 'A boolean to indicate this profile item is in draft mode and is not publicly available.';


--
-- Name: COLUMN profile_item.is_original; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.is_original IS 'A boolean to indicate this profile item is making an original statement (fact).';


--
-- Name: COLUMN profile_item.is_quote; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.is_quote IS 'A boolean to indicate this profile item is re-using an original statement unchanged (quote).';


--
-- Name: COLUMN profile_item.quotes_profile_item_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.quotes_profile_item_id IS 'The id of the original statement being quoted. Used when is_quote = true.';


--
-- Name: COLUMN profile_item.is_assertion; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.is_assertion IS 'A boolean to indicate this profile text is making an assertion about a statement from a different profile product. i.e. Flora of Australian is quoting the APC distribution unchanged.';


--
-- Name: COLUMN profile_item.profile_text_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.profile_text_id IS 'The profile text this profile item is using.';


--
-- Name: COLUMN profile_item.profile_image_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.profile_image_id IS 'A profile image this profile item is using.';


--
-- Name: COLUMN profile_item.profile_general_ref; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.profile_general_ref IS 'A placeholder (Y or null) to indicate this profile item is for a list of references available in profile_references. Used to constrain an item type to only one object type.';


--
-- Name: COLUMN profile_item.tree_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.tree_id IS 'The classification (tree) that this profile item is associated with.';


--
-- Name: COLUMN profile_item.min_tree_version_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.min_tree_version_id IS 'The identifier of the first tree version where this profile item was included.';


--
-- Name: COLUMN profile_item.max_tree_version_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.max_tree_version_id IS 'The identifier of the last tree version where this profile item was included.';


--
-- Name: COLUMN profile_item.uri; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.uri IS '????.';


--
-- Name: COLUMN profile_item.source_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.source_id IS 'The key at the source system imported on migration';


--
-- Name: COLUMN profile_item.source_id_string; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile_item.source_system; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile_item.namespace_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.namespace_id IS 'The XXXXX.';


--
-- Name: COLUMN profile_item.lock_version; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_item.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_item.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_item.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_item.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_item.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_item.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: profile_item_config; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile_item_config (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    profile_id bigint NOT NULL,
    profile_object_type_id bigint NOT NULL,
    heading_text text,
    heading_html text,
    heading_level numeric,
    is_heading_visible boolean,
    sort_order numeric(5,2),
    is_current boolean,
    is_available boolean,
    tool_tip text,
    external_context text,
    external_mapping text,
    lock_version bigint DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_item_config; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile_item_config IS 'The objects available for a given Profile Product and the local customisation for that product.';


--
-- Name: COLUMN profile_item_config.id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.id IS 'A system wide unique identifier allocated to each profile item config record.';


--
-- Name: COLUMN profile_item_config.profile_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.profile_id IS 'The profile product which uses a profile object.';


--
-- Name: COLUMN profile_item_config.profile_object_type_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.profile_object_type_id IS 'A profile object used by this profile product.';


--
-- Name: COLUMN profile_item_config.heading_text; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.heading_text IS 'The heading text under which this profile data is to appear to the user in a product.';


--
-- Name: COLUMN profile_item_config.heading_html; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.heading_html IS 'The heading text as html (markdown) under which this profile data is to appear to the user in a product.';


--
-- Name: COLUMN profile_item_config.heading_level; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.heading_level IS 'The heading level associated with this heading text in this profile product.';


--
-- Name: COLUMN profile_item_config.sort_order; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.sort_order IS 'The order of the profile item in a profile product. Determines the order on public display and within the editor.';


--
-- Name: COLUMN profile_item_config.is_current; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.is_current IS 'Indicates this profile item type is currently being maintained and published.';


--
-- Name: COLUMN profile_item_config.is_available; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.is_available IS 'Indicates this profile item type is publicly available for view only. Allows specific attributes to be deprecated and not visible.';


--
-- Name: COLUMN profile_item_config.tool_tip; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.tool_tip IS 'The helper text associated with this profile item type in a profile product.';


--
-- Name: COLUMN profile_item_config.external_context; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.external_context IS 'The external product that profile item data is being delivered to.';


--
-- Name: COLUMN profile_item_config.external_mapping; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.external_mapping IS 'The term used by the external context system. The internal term will be mapped to the external term.';


--
-- Name: COLUMN profile_item_config.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_item_config.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_item_config.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_item_config.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_item_config.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_item_config.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_item_config.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: profile_object_type; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile_object_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    object_type text NOT NULL,
    object_group text NOT NULL,
    object_subgroup text,
    object_data text,
    rdf_id text,
    sort_order numeric(5,2),
    lock_version bigint DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_object_type; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile_object_type IS 'The supported object types within all Profile Products and their associated type of object, categorisation and process associated with that object type.';


--
-- Name: COLUMN profile_object_type.id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.id IS 'A system wide unique identifier allocated to each profile object config record.';


--
-- Name: COLUMN profile_object_type.object_type; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.object_type IS 'A standard value to indicate the type of profile data and by inference the data structure and editor component required to maintain this data.';


--
-- Name: COLUMN profile_object_type.object_group; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.object_group IS 'A standard value to reference a particular group of data in all profile products.';


--
-- Name: COLUMN profile_object_type.object_subgroup; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.object_subgroup IS 'A standard value to reference a sub group of data with a group.';


--
-- Name: COLUMN profile_object_type.rdf_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.rdf_id IS 'NOT sure yet - could this be the group? ie. rdf_id and rdf_group_id?.';


--
-- Name: COLUMN profile_object_type.sort_order; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.sort_order IS 'The global sort order of all profile objects for aggregated outputs.';


--
-- Name: COLUMN profile_object_type.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_object_type.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_object_type.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_object_type.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_object_type.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_object_type.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_object_type.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: profile_reference; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile_reference (
    profile_item_id bigint NOT NULL,
    reference_id bigint NOT NULL,
    pages text,
    annotation text,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_reference; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile_reference IS 'The use of a reference for a profile i.e. list of general references for the taxon being described by this profile.';


--
-- Name: COLUMN profile_reference.profile_item_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.profile_item_id IS 'The profile item which is using this reference.';


--
-- Name: COLUMN profile_reference.reference_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.reference_id IS 'The reference which is being used by this profile item.';


--
-- Name: COLUMN profile_reference.pages; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.pages IS 'The page number(s) for this usage of the reference.';


--
-- Name: COLUMN profile_reference.annotation; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.annotation IS 'An annotation made by the profile editor about the use of this reference.';


--
-- Name: COLUMN profile_reference.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_reference.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_reference.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_reference.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_reference.lock_version; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_reference.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_reference.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_reference.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: profile_text; Type: TABLE; Schema: temp_profile; Owner: -
--

CREATE TABLE temp_profile.profile_text (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    profile_object_type_id bigint NOT NULL,
    value text NOT NULL,
    value_html text,
    source_id bigint,
    source_system character varying(50),
    source_id_string character varying(100),
    namespace_id bigint NOT NULL,
    lock_version bigint DEFAULT 0,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    api_name character varying(50),
    api_date timestamp with time zone
);


--
-- Name: TABLE profile_text; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON TABLE temp_profile.profile_text IS 'A profile object that contains the original text statement written for a defined category of information, for a taxon in a profile product.';


--
-- Name: COLUMN profile_text.id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.id IS 'A system wide unique identifier allocated to each profile text record.';


--
-- Name: COLUMN profile_text.profile_object_type_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.profile_object_type_id IS 'The object type associated with this text statement.';


--
-- Name: COLUMN profile_text.value; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.value IS 'The original text written for a defined category of information, for a taxon in a profile.';


--
-- Name: COLUMN profile_text.value_html; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.value_html IS '???? DO WE STILL WANT THIS - or ';


--
-- Name: COLUMN profile_text.source_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.source_id IS 'The key at the source system imported on migration';


--
-- Name: COLUMN profile_text.source_system; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.source_system IS 'The source system that this profile text was imported from.';


--
-- Name: COLUMN profile_text.source_id_string; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.source_id_string IS 'The identifier from the source system that this profile text was imported from.';


--
-- Name: COLUMN profile_text.namespace_id; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.namespace_id IS 'The auNSL dataset that physically contains this profile text.';


--
-- Name: COLUMN profile_text.lock_version; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.lock_version IS 'A system field to manage row level locking.';


--
-- Name: COLUMN profile_text.created_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.created_at IS 'The date and time this data was created.';


--
-- Name: COLUMN profile_text.created_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.created_by IS 'The user id of the person who created this data';


--
-- Name: COLUMN profile_text.updated_at; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.updated_at IS 'The date and time this data was updated.';


--
-- Name: COLUMN profile_text.updated_by; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.updated_by IS 'The user id of the person who last updated this data';


--
-- Name: COLUMN profile_text.api_name; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.api_name IS 'The name of a script, jira or services task which last changed this record.';


--
-- Name: COLUMN profile_text.api_date; Type: COMMENT; Schema: temp_profile; Owner: -
--

COMMENT ON COLUMN temp_profile.profile_text.api_date IS 'The date when a script, jira or services task last changed this record.';


--
-- Name: all_links; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.all_links (
    id bigint,
    link bigint,
    sp text,
    rm boolean
);


--
-- Name: TABLE all_links; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.all_links IS 'All of the internal name references: parent, second_parent, family, duplicate';


--
-- Name: apni; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.apni (
    id bigint,
    family_id bigint,
    parent_id bigint,
    second_parent_id bigint,
    duplicate_of_id bigint
);


--
-- Name: TABLE apni; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.apni IS 'the names to remain';


--
-- Name: candidate; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.candidate (
    id bigint,
    link bigint,
    name character varying(512),
    depth integer,
    n_path text,
    id_path bigint[],
    cited boolean[]
);


--
-- Name: comment; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.comment (
    id bigint,
    lock_version bigint,
    author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text,
    updated_at timestamp with time zone,
    updated_by character varying(50)
);


--
-- Name: TABLE comment; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.comment IS 'The comments referencing uncited names';


--
-- Name: linked_name; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.linked_name (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: TABLE linked_name; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.linked_name IS 'uncited names with dependants';


--
-- Name: name; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.name (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: TABLE name; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.name IS 'All uncited names';


--
-- Name: name_bkp; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.name_bkp (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: TABLE name_bkp; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.name_bkp IS 'All names prior to uncited cull';


--
-- Name: name_tag_name; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.name_tag_name (
    name_id bigint,
    tag_id bigint,
    created_at timestamp with time zone,
    created_by character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255)
);


--
-- Name: TABLE name_tag_name; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.name_tag_name IS 'The name_tag_names referencing uncited names';


--
-- Name: unlinked_name; Type: TABLE; Schema: uncited; Owner: -
--

CREATE TABLE uncited.unlinked_name (
    id bigint,
    lock_version bigint,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone,
    created_by character varying(50),
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint,
    name_status_id bigint,
    name_type_id bigint,
    namespace_id bigint,
    orth_var boolean,
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
    updated_at timestamp with time zone,
    updated_by character varying(50),
    valid_record boolean,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text,
    uri text,
    changed_combination boolean,
    published_year integer,
    apni_json jsonb
);


--
-- Name: TABLE unlinked_name; Type: COMMENT; Schema: uncited; Owner: -
--

COMMENT ON TABLE uncited.unlinked_name IS 'No dependent links to clean up before deletion';


--
-- Name: all_identifiers; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.all_identifiers (
    id bigint,
    rel text,
    date timestamp with time zone,
    created_by character varying,
    rep_id bigint,
    replace boolean
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'all_identifiers'
);
ALTER FOREIGN TABLE xfungi.all_identifiers ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.all_identifiers ALTER COLUMN rel OPTIONS (
    column_name 'rel'
);
ALTER FOREIGN TABLE xfungi.all_identifiers ALTER COLUMN date OPTIONS (
    column_name 'date'
);
ALTER FOREIGN TABLE xfungi.all_identifiers ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.all_identifiers ALTER COLUMN rep_id OPTIONS (
    column_name 'rep_id'
);
ALTER FOREIGN TABLE xfungi.all_identifiers ALTER COLUMN replace OPTIONS (
    column_name 'replace'
);


--
-- Name: author; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.author (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
    valid_record boolean NOT NULL,
    uri text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'author'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN abbrev OPTIONS (
    column_name 'abbrev'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN date_range OPTIONS (
    column_name 'date_range'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN ipni_id OPTIONS (
    column_name 'ipni_id'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xfungi.author ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);


--
-- Name: bdr_alt_labels_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_alt_labels_v (
    _id text,
    _type jsonb,
    "skos__prefLabel" character varying(512),
    dct__identifier text,
    "dwc__scientificName" character varying(512),
    "dwc__scientificNameAuthorship" text,
    "dwc__nomenclaturalStatus" character varying,
    "boa__canonicalLabel" character varying(250),
    "dwc__taxonRank" character varying(50),
    "dwc__taxonomicStatus" character varying,
    skos__definition jsonb,
    tree_version_id bigint,
    name_id bigint,
    accepted_name_usage_id text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_alt_labels_v'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "skos__prefLabel" OPTIONS (
    column_name 'skos__prefLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN dct__identifier OPTIONS (
    column_name 'dct__identifier'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "dwc__scientificName" OPTIONS (
    column_name 'dwc__scientificName'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "dwc__scientificNameAuthorship" OPTIONS (
    column_name 'dwc__scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "dwc__nomenclaturalStatus" OPTIONS (
    column_name 'dwc__nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "boa__canonicalLabel" OPTIONS (
    column_name 'boa__canonicalLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "dwc__taxonRank" OPTIONS (
    column_name 'dwc__taxonRank'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN "dwc__taxonomicStatus" OPTIONS (
    column_name 'dwc__taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN skos__definition OPTIONS (
    column_name 'skos__definition'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.bdr_alt_labels_v ALTER COLUMN accepted_name_usage_id OPTIONS (
    column_name 'accepted_name_usage_id'
);


--
-- Name: bdr_concept_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_concept_v (
    _id text,
    _type jsonb,
    dct__identifier text,
    "dwc__taxonID" text,
    "dwc__scientificName" character varying(512),
    "dwc__scientificNameAuthorship" text,
    "dwc__nomenclaturalStatus" character varying,
    "skos__prefLabel" character varying(512),
    "boa__canonicalLabel" character varying(250),
    "dwc__taxonRank" character varying(50),
    skos__broader jsonb,
    "skos__inScheme" jsonb,
    "dwc__taxonomicStatus" character varying,
    skos__definition jsonb,
    "boa__hasHomotypicLabel" jsonb,
    "boa__hasHeterotypicLabel" jsonb,
    "boa__hasOrthographicLabel" jsonb,
    "boa__hasMisappliedLabel" jsonb,
    "boa__hasSynonymicLabel" jsonb,
    tree_version_id bigint,
    name_id bigint,
    taxon_id text,
    higher_classification text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_concept_v'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN dct__identifier OPTIONS (
    column_name 'dct__identifier'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "dwc__taxonID" OPTIONS (
    column_name 'dwc__taxonID'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "dwc__scientificName" OPTIONS (
    column_name 'dwc__scientificName'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "dwc__scientificNameAuthorship" OPTIONS (
    column_name 'dwc__scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "dwc__nomenclaturalStatus" OPTIONS (
    column_name 'dwc__nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "skos__prefLabel" OPTIONS (
    column_name 'skos__prefLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "boa__canonicalLabel" OPTIONS (
    column_name 'boa__canonicalLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "dwc__taxonRank" OPTIONS (
    column_name 'dwc__taxonRank'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN skos__broader OPTIONS (
    column_name 'skos__broader'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "skos__inScheme" OPTIONS (
    column_name 'skos__inScheme'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "dwc__taxonomicStatus" OPTIONS (
    column_name 'dwc__taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN skos__definition OPTIONS (
    column_name 'skos__definition'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "boa__hasHomotypicLabel" OPTIONS (
    column_name 'boa__hasHomotypicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "boa__hasHeterotypicLabel" OPTIONS (
    column_name 'boa__hasHeterotypicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "boa__hasOrthographicLabel" OPTIONS (
    column_name 'boa__hasOrthographicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "boa__hasMisappliedLabel" OPTIONS (
    column_name 'boa__hasMisappliedLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN "boa__hasSynonymicLabel" OPTIONS (
    column_name 'boa__hasSynonymicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.bdr_concept_v ALTER COLUMN higher_classification OPTIONS (
    column_name 'higher_classification'
);


--
-- Name: bdr_context_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_context_v (
    rdf text,
    prefix text,
    http text,
    dc text,
    dct text,
    gvp text,
    skos text,
    skosxl text,
    xsd text,
    tn text,
    rdfs text,
    dwc text,
    prov text,
    sdo text,
    pav text,
    dcterms text,
    owl text,
    boa text,
    aunsl text,
    apc text,
    afd text,
    abl text,
    aal text,
    afl text,
    "all" text,
    apni text,
    afdi text,
    alni text,
    abni text,
    aani text,
    afni text,
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_context_v'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN rdf OPTIONS (
    column_name 'rdf'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN prefix OPTIONS (
    column_name 'prefix'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN http OPTIONS (
    column_name 'http'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN dc OPTIONS (
    column_name 'dc'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN dct OPTIONS (
    column_name 'dct'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN gvp OPTIONS (
    column_name 'gvp'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN skos OPTIONS (
    column_name 'skos'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN skosxl OPTIONS (
    column_name 'skosxl'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN xsd OPTIONS (
    column_name 'xsd'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN tn OPTIONS (
    column_name 'tn'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN rdfs OPTIONS (
    column_name 'rdfs'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN dwc OPTIONS (
    column_name 'dwc'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN prov OPTIONS (
    column_name 'prov'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN sdo OPTIONS (
    column_name 'sdo'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN pav OPTIONS (
    column_name 'pav'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN dcterms OPTIONS (
    column_name 'dcterms'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN owl OPTIONS (
    column_name 'owl'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN boa OPTIONS (
    column_name 'boa'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN aunsl OPTIONS (
    column_name 'aunsl'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN apc OPTIONS (
    column_name 'apc'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN afd OPTIONS (
    column_name 'afd'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN abl OPTIONS (
    column_name 'abl'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN aal OPTIONS (
    column_name 'aal'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN afl OPTIONS (
    column_name 'afl'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN "all" OPTIONS (
    column_name 'all'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN apni OPTIONS (
    column_name 'apni'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN afdi OPTIONS (
    column_name 'afdi'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN alni OPTIONS (
    column_name 'alni'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN abni OPTIONS (
    column_name 'abni'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN aani OPTIONS (
    column_name 'aani'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN afni OPTIONS (
    column_name 'afni'
);
ALTER FOREIGN TABLE xfungi.bdr_context_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: bdr_graph_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_graph_v (
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_graph_v'
);
ALTER FOREIGN TABLE xfungi.bdr_graph_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: bdr_labels_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_labels_v (
    _id json,
    "rdfs__subPropertyOf" jsonb,
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_labels_v'
);
ALTER FOREIGN TABLE xfungi.bdr_labels_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_labels_v ALTER COLUMN "rdfs__subPropertyOf" OPTIONS (
    column_name 'rdfs__subPropertyOf'
);
ALTER FOREIGN TABLE xfungi.bdr_labels_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: bdr_prefix_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_prefix_v (
    tree_description character varying(5000),
    tree_label character varying(5000),
    tree_context text,
    name_context text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_prefix_v'
);
ALTER FOREIGN TABLE xfungi.bdr_prefix_v ALTER COLUMN tree_description OPTIONS (
    column_name 'tree_description'
);
ALTER FOREIGN TABLE xfungi.bdr_prefix_v ALTER COLUMN tree_label OPTIONS (
    column_name 'tree_label'
);
ALTER FOREIGN TABLE xfungi.bdr_prefix_v ALTER COLUMN tree_context OPTIONS (
    column_name 'tree_context'
);
ALTER FOREIGN TABLE xfungi.bdr_prefix_v ALTER COLUMN name_context OPTIONS (
    column_name 'name_context'
);


--
-- Name: bdr_schema_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_schema_v (
    _id text,
    _type text,
    dct__created jsonb,
    dct__creator json,
    dct__modified jsonb,
    dct__publisher json,
    skos__definition jsonb,
    "skos__hasTopConcept" jsonb,
    "skos__prefLabel" jsonb,
    "dcterms__isVersionOf" jsonb,
    "owl__versionIRI" jsonb,
    "pav__previousVersion" jsonb,
    top_concept_id bigint,
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_schema_v'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN dct__created OPTIONS (
    column_name 'dct__created'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN dct__creator OPTIONS (
    column_name 'dct__creator'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN dct__modified OPTIONS (
    column_name 'dct__modified'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN dct__publisher OPTIONS (
    column_name 'dct__publisher'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN skos__definition OPTIONS (
    column_name 'skos__definition'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN "skos__hasTopConcept" OPTIONS (
    column_name 'skos__hasTopConcept'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN "skos__prefLabel" OPTIONS (
    column_name 'skos__prefLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN "dcterms__isVersionOf" OPTIONS (
    column_name 'dcterms__isVersionOf'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN "owl__versionIRI" OPTIONS (
    column_name 'owl__versionIRI'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN "pav__previousVersion" OPTIONS (
    column_name 'pav__previousVersion'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN top_concept_id OPTIONS (
    column_name 'top_concept_id'
);
ALTER FOREIGN TABLE xfungi.bdr_schema_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: bdr_sdo_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_sdo_v (
    _id text,
    _type text,
    sdo__name text,
    "sdo__parentOrganization" jsonb,
    sdo__url jsonb,
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_sdo_v'
);
ALTER FOREIGN TABLE xfungi.bdr_sdo_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_sdo_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_sdo_v ALTER COLUMN sdo__name OPTIONS (
    column_name 'sdo__name'
);
ALTER FOREIGN TABLE xfungi.bdr_sdo_v ALTER COLUMN "sdo__parentOrganization" OPTIONS (
    column_name 'sdo__parentOrganization'
);
ALTER FOREIGN TABLE xfungi.bdr_sdo_v ALTER COLUMN sdo__url OPTIONS (
    column_name 'sdo__url'
);
ALTER FOREIGN TABLE xfungi.bdr_sdo_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: bdr_top_concept_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_top_concept_v (
    _id text,
    _type jsonb,
    dct__identifier text,
    "dwc__taxonID" text,
    "dwc__scientificName" character varying(512),
    "dwc__scientificNameAuthorship" text,
    "dwc__nomenclaturalStatus" character varying,
    "dwc__taxonRank" character varying(50),
    "dwc__taxonomicStatus" character varying,
    skos__definition jsonb,
    "skos__inScheme" jsonb,
    "skos__prefLabel" character varying(512),
    "boa__canonicalLabel" character varying(250),
    "skos__topConceptOf" jsonb,
    "boa__hasHomotypicLabel" jsonb,
    "boa__hasHeterotypicLabel" jsonb,
    "boa__hasOrthographicLabel" jsonb,
    "boa__hasMisappliedLabel" jsonb,
    "boa__hasSynonymicLabel" jsonb,
    tree_version_id bigint,
    name_id bigint,
    taxon_id text,
    higher_classification text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_top_concept_v'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN dct__identifier OPTIONS (
    column_name 'dct__identifier'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "dwc__taxonID" OPTIONS (
    column_name 'dwc__taxonID'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "dwc__scientificName" OPTIONS (
    column_name 'dwc__scientificName'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "dwc__scientificNameAuthorship" OPTIONS (
    column_name 'dwc__scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "dwc__nomenclaturalStatus" OPTIONS (
    column_name 'dwc__nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "dwc__taxonRank" OPTIONS (
    column_name 'dwc__taxonRank'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "dwc__taxonomicStatus" OPTIONS (
    column_name 'dwc__taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN skos__definition OPTIONS (
    column_name 'skos__definition'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "skos__inScheme" OPTIONS (
    column_name 'skos__inScheme'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "skos__prefLabel" OPTIONS (
    column_name 'skos__prefLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "boa__canonicalLabel" OPTIONS (
    column_name 'boa__canonicalLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "skos__topConceptOf" OPTIONS (
    column_name 'skos__topConceptOf'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "boa__hasHomotypicLabel" OPTIONS (
    column_name 'boa__hasHomotypicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "boa__hasHeterotypicLabel" OPTIONS (
    column_name 'boa__hasHeterotypicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "boa__hasOrthographicLabel" OPTIONS (
    column_name 'boa__hasOrthographicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "boa__hasMisappliedLabel" OPTIONS (
    column_name 'boa__hasMisappliedLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN "boa__hasSynonymicLabel" OPTIONS (
    column_name 'boa__hasSynonymicLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.bdr_top_concept_v ALTER COLUMN higher_classification OPTIONS (
    column_name 'higher_classification'
);


--
-- Name: bdr_tree_schema_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_tree_schema_v (
    _id text,
    _type text,
    "skos__prefLabel" jsonb,
    skos__definition jsonb,
    "pav__hasCurrentVersion" json,
    "pav__hasVersion" jsonb,
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_tree_schema_v'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN "skos__prefLabel" OPTIONS (
    column_name 'skos__prefLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN skos__definition OPTIONS (
    column_name 'skos__definition'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN "pav__hasCurrentVersion" OPTIONS (
    column_name 'pav__hasCurrentVersion'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN "pav__hasVersion" OPTIONS (
    column_name 'pav__hasVersion'
);
ALTER FOREIGN TABLE xfungi.bdr_tree_schema_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: bdr_unplaced_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.bdr_unplaced_v (
    _id text,
    _type jsonb,
    "dwc__taxonomicStatus" text,
    "skos__prefLabel" character varying(512),
    dct__identifier text,
    "dwc__scientificName" character varying(512),
    "dwc__scientificNameAuthorship" text,
    "dwc__nomenclaturalStatus" character varying,
    "boa__canonicalLabel" character varying(250),
    "dwc__taxonRank" character varying(50),
    "skos__inScheme" jsonb,
    skos__definition jsonb,
    name_id bigint,
    tree_version_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'bdr_unplaced_v'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN _id OPTIONS (
    column_name '_id'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN _type OPTIONS (
    column_name '_type'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "dwc__taxonomicStatus" OPTIONS (
    column_name 'dwc__taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "skos__prefLabel" OPTIONS (
    column_name 'skos__prefLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN dct__identifier OPTIONS (
    column_name 'dct__identifier'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "dwc__scientificName" OPTIONS (
    column_name 'dwc__scientificName'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "dwc__scientificNameAuthorship" OPTIONS (
    column_name 'dwc__scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "dwc__nomenclaturalStatus" OPTIONS (
    column_name 'dwc__nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "boa__canonicalLabel" OPTIONS (
    column_name 'boa__canonicalLabel'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "dwc__taxonRank" OPTIONS (
    column_name 'dwc__taxonRank'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN "skos__inScheme" OPTIONS (
    column_name 'skos__inScheme'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN skos__definition OPTIONS (
    column_name 'skos__definition'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.bdr_unplaced_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);


--
-- Name: comment; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.comment (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'comment'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN author_id OPTIONS (
    column_name 'author_id'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN text OPTIONS (
    column_name 'text'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.comment ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: data_identifiers; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.data_identifiers (
    id bigint,
    rel text,
    date timestamp with time zone,
    created_by character varying,
    rep_id bigint,
    replace boolean,
    is_duplicate_id boolean,
    new_element_link text,
    new_parent_id text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'data_identifiers'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN rel OPTIONS (
    column_name 'rel'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN date OPTIONS (
    column_name 'date'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN rep_id OPTIONS (
    column_name 'rep_id'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN replace OPTIONS (
    column_name 'replace'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN is_duplicate_id OPTIONS (
    column_name 'is_duplicate_id'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN new_element_link OPTIONS (
    column_name 'new_element_link'
);
ALTER FOREIGN TABLE xfungi.data_identifiers ALTER COLUMN new_parent_id OPTIONS (
    column_name 'new_parent_id'
);


--
-- Name: db_version; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'db_version'
);
ALTER FOREIGN TABLE xfungi.db_version ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.db_version ALTER COLUMN version OPTIONS (
    column_name 'version'
);


--
-- Name: delayed_jobs; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.delayed_jobs (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'delayed_jobs'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN attempts OPTIONS (
    column_name 'attempts'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN failed_at OPTIONS (
    column_name 'failed_at'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN handler OPTIONS (
    column_name 'handler'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN last_error OPTIONS (
    column_name 'last_error'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN locked_at OPTIONS (
    column_name 'locked_at'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN locked_by OPTIONS (
    column_name 'locked_by'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN priority OPTIONS (
    column_name 'priority'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN queue OPTIONS (
    column_name 'queue'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN run_at OPTIONS (
    column_name 'run_at'
);
ALTER FOREIGN TABLE xfungi.delayed_jobs ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


--
-- Name: dist_entry; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_entry (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    display character varying(255) NOT NULL,
    region_id bigint NOT NULL,
    sort_order integer NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_entry'
);
ALTER FOREIGN TABLE xfungi.dist_entry ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.dist_entry ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.dist_entry ALTER COLUMN display OPTIONS (
    column_name 'display'
);
ALTER FOREIGN TABLE xfungi.dist_entry ALTER COLUMN region_id OPTIONS (
    column_name 'region_id'
);
ALTER FOREIGN TABLE xfungi.dist_entry ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: dist_entry_dist_status; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_entry_dist_status (
    dist_entry_status_id bigint,
    dist_status_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_entry_dist_status'
);
ALTER FOREIGN TABLE xfungi.dist_entry_dist_status ALTER COLUMN dist_entry_status_id OPTIONS (
    column_name 'dist_entry_status_id'
);
ALTER FOREIGN TABLE xfungi.dist_entry_dist_status ALTER COLUMN dist_status_id OPTIONS (
    column_name 'dist_status_id'
);


--
-- Name: dist_granular_booleans_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_granular_booleans_v (
    taxon_id text,
    name_type character varying(255),
    accepted_name_usage_id text,
    accepted_name_usage character varying(512),
    nomenclatural_status character varying,
    nom_illeg boolean,
    nom_inval boolean,
    taxonomic_status character varying,
    pro_parte boolean,
    scientific_name character varying(512),
    scientific_name_id text,
    canonical_name character varying(250),
    scientific_name_authorship text,
    parent_name_usage_id text,
    taxon_rank character varying(50),
    taxon_rank_sort_order integer,
    kingdom text,
    class text,
    subclass text,
    family text,
    taxon_concept_id text,
    name_according_to character varying(4000),
    name_according_to_id text,
    taxon_remarks text,
    taxon_distribution text,
    higher_classification text,
    first_hybrid_parent_name character varying,
    first_hybrid_parent_name_id text,
    second_hybrid_parent_name character varying,
    second_hybrid_parent_name_id text,
    nomenclatural_code text,
    created timestamp with time zone,
    modified timestamp with time zone,
    dataset_name text,
    dataset_id text,
    license text,
    cc_attribution_iri text,
    tree_version_id bigint,
    tree_element_id bigint,
    instance_id bigint,
    name_id bigint,
    homotypic boolean,
    heterotypic boolean,
    misapplied boolean,
    relationship boolean,
    synonym boolean,
    excluded_name boolean,
    accepted boolean,
    accepted_id bigint,
    rank_rdf_id character varying(50),
    name_space character varying(5000),
    tree_description character varying(5000),
    tree_label character varying(5000),
    act_unqualified_native boolean,
    nsw_unqualified_native boolean,
    nt_unqualified_native boolean,
    qld_unqualified_native boolean,
    sa_unqualified_native boolean,
    tas_unqualified_native boolean,
    vic_unqualified_native boolean,
    wa_unqualified_native boolean,
    ar_unqualified_native boolean,
    lhi_unqualified_native boolean,
    chi_unqualified_native boolean,
    cai_unqualified_native boolean,
    csi_unqualified_native boolean,
    coi_unqualified_native boolean,
    hi_unqualified_native boolean,
    mdi_unqualified_native boolean,
    mi_unqualified_native boolean,
    ni_unqualified_native boolean,
    act_naturalised boolean,
    nsw_naturalised boolean,
    nt_naturalised boolean,
    qld_naturalised boolean,
    sa_naturalised boolean,
    tas_naturalised boolean,
    vic_naturalised boolean,
    wa_naturalised boolean,
    act_doubtfully_naturalised boolean,
    nsw_doubtfully_naturalised boolean,
    nt_doubtfully_naturalised boolean,
    qld_doubtfully_naturalised boolean,
    sa_doubtfully_naturalised boolean,
    tas_doubtfully_naturalised boolean,
    vic_doubtfully_naturalised boolean,
    wa_doubtfully_naturalised boolean,
    act_formerly_naturalised boolean,
    nsw_formerly_naturalised boolean,
    nt_formerly_naturalised boolean,
    qld_formerly_naturalised boolean,
    sa_formerly_naturalised boolean,
    tas_formerly_naturalised boolean,
    vic_formerly_naturalised boolean,
    wa_formerly_naturalised boolean,
    act_native_and_naturalised boolean,
    nsw_native_and_naturalised boolean,
    nt_native_and_naturalised boolean,
    qld_native_and_naturalised boolean,
    sa_native_and_naturalised boolean,
    tas_native_and_naturalised boolean,
    vic_native_and_naturalised boolean,
    wa_native_and_naturalised boolean,
    act_native_and_doubtfully_naturalised boolean,
    nsw_native_and_doubtfully_naturalised boolean,
    nt_native_and_doubtfully_naturalised boolean,
    qld_native_and_doubtfully_naturalised boolean,
    sa_native_and_doubtfully_naturalised boolean,
    tas_native_and_doubtfully_naturalised boolean,
    vic_native_and_doubtfully_naturalised boolean,
    wa_native_and_doubtfully_naturalised boolean,
    act_native_and_formerly_naturalised boolean,
    nsw_native_and_formerly_naturalised boolean,
    nt_native_and_formerly_naturalised boolean,
    qld_native_and_formerly_naturalised boolean,
    sa_native_and_formerly_naturalised boolean,
    tas_native_and_formerly_naturalised boolean,
    vic_native_and_formerly_naturalised boolean,
    wa_native_and_formerly_naturalised boolean,
    act_native_and_naturalised_and_uncertain_origin boolean,
    nsw_native_and_naturalised_and_uncertain_origin boolean,
    nt_native_and_naturalised_and_uncertain_origin boolean,
    qld_native_and_naturalised_and_uncertain_origin boolean,
    sa_native_and_naturalised_and_uncertain_origin boolean,
    tas_native_and_naturalised_and_uncertain_origin boolean,
    vic_native_and_naturalised_and_uncertain_origin boolean,
    wa_native_and_naturalised_and_uncertain_origin boolean,
    act_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    nsw_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    nt_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    qld_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    sa_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    tas_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    vic_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    wa_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    act_native_and_uncertain_origin boolean,
    nsw_native_and_uncertain_origin boolean,
    nt_native_and_uncertain_origin boolean,
    qld_native_and_uncertain_origin boolean,
    sa_native_and_uncertain_origin boolean,
    tas_native_and_uncertain_origin boolean,
    vic_native_and_uncertain_origin boolean,
    wa_native_and_uncertain_origin boolean,
    act_naturalised_and_uncertain_origin boolean,
    nsw_naturalised_and_uncertain_origin boolean,
    nt_naturalised_and_uncertain_origin boolean,
    qld_naturalised_and_uncertain_origin boolean,
    sa_naturalised_and_uncertain_origin boolean,
    tas_naturalised_and_uncertain_origin boolean,
    vic_naturalised_and_uncertain_origin boolean,
    wa_naturalised_and_uncertain_origin boolean,
    act_presumed_extinct boolean,
    nsw_presumed_extinct boolean,
    nt_presumed_extinct boolean,
    qld_presumed_extinct boolean,
    sa_presumed_extinct boolean,
    tas_presumed_extinct boolean,
    vic_presumed_extinct boolean,
    wa_presumed_extinct boolean,
    act_uncertain_origin boolean,
    nsw_uncertain_origin boolean,
    nt_uncertain_origin boolean,
    qld_uncertain_origin boolean,
    sa_uncertain_origin boolean,
    tas_uncertain_origin boolean,
    vic_uncertain_origin boolean,
    wa_uncertain_origin boolean,
    ar_naturalised boolean,
    chi_naturalised boolean,
    cai_naturalised boolean,
    coi_naturalised boolean,
    csi_naturalised boolean,
    hi_naturalised boolean,
    lhi_naturalised boolean,
    mdi_naturalised boolean,
    mi_naturalised boolean,
    ni_naturalised boolean,
    ar_doubtfully_naturalised boolean,
    chi_doubtfully_naturalised boolean,
    cai_doubtfully_naturalised boolean,
    coi_doubtfully_naturalised boolean,
    csi_doubtfully_naturalised boolean,
    hi_doubtfully_naturalised boolean,
    lhi_doubtfully_naturalised boolean,
    mdi_doubtfully_naturalised boolean,
    mi_doubtfully_naturalised boolean,
    ni_doubtfully_naturalised boolean,
    ar_formerly_naturalised boolean,
    chi_formerly_naturalised boolean,
    cai_formerly_naturalised boolean,
    coi_formerly_naturalised boolean,
    csi_formerly_naturalised boolean,
    hi_formerly_naturalised boolean,
    lhi_formerly_naturalised boolean,
    mdi_formerly_naturalised boolean,
    mi_formerly_naturalised boolean,
    ni_formerly_naturalised boolean,
    ar_native_and_naturalised boolean,
    chi_native_and_naturalised boolean,
    cai_native_and_naturalised boolean,
    coi_native_and_naturalised boolean,
    csi_native_and_naturalised boolean,
    hi_native_and_naturalised boolean,
    lhi_native_and_naturalised boolean,
    mdi_native_and_naturalised boolean,
    mi_native_and_naturalised boolean,
    ni_native_and_naturalised boolean,
    ar_native_and_doubtfully_naturalised boolean,
    chi_native_and_doubtfully_naturalised boolean,
    cai_native_and_doubtfully_naturalised boolean,
    coi_native_and_doubtfully_naturalised boolean,
    csi_native_and_doubtfully_naturalised boolean,
    hi_native_and_doubtfully_naturalised boolean,
    lhi_native_and_doubtfully_naturalised boolean,
    mdi_native_and_doubtfully_naturalised boolean,
    mi_native_and_doubtfully_naturalised boolean,
    ni_native_and_doubtfully_naturalised boolean,
    ar_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    chi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    cai_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    coi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    csi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    hi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    lhi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    mdi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    mi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    ni_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    ar_native_and_formerly_naturalised boolean,
    chi_native_and_formerly_naturalised boolean,
    cai_native_and_formerly_naturalised boolean,
    coi_native_and_formerly_naturalised boolean,
    csi_native_and_formerly_naturalised boolean,
    hi_native_and_formerly_naturalised boolean,
    lhi_native_and_formerly_naturalised boolean,
    mdi_native_and_formerly_naturalised boolean,
    mi_native_and_formerly_naturalised boolean,
    ni_native_and_formerly_naturalised boolean,
    ar_native_and_naturalised_and_uncertain_origin boolean,
    chi_native_and_naturalised_and_uncertain_origin boolean,
    cai_native_and_naturalised_and_uncertain_origin boolean,
    coi_native_and_naturalised_and_uncertain_origin boolean,
    csi_native_and_naturalised_and_uncertain_origin boolean,
    hi_native_and_naturalised_and_uncertain_origin boolean,
    lhi_native_and_naturalised_and_uncertain_origin boolean,
    mdi_native_and_naturalised_and_uncertain_origin boolean,
    mi_native_and_naturalised_and_uncertain_origin boolean,
    ni_native_and_naturalised_and_uncertain_origin boolean,
    ar_native_and_uncertain_origin boolean,
    chi_native_and_uncertain_origin boolean,
    cai_native_and_uncertain_origin boolean,
    coi_native_and_uncertain_origin boolean,
    csi_native_and_uncertain_origin boolean,
    hi_native_and_uncertain_origin boolean,
    lhi_native_and_uncertain_origin boolean,
    mdi_native_and_uncertain_origin boolean,
    mi_native_and_uncertain_origin boolean,
    ni_native_and_uncertain_origin boolean,
    ar_naturalised_and_uncertain_origin boolean,
    chi_naturalised_and_uncertain_origin boolean,
    cai_naturalised_and_uncertain_origin boolean,
    coi_naturalised_and_uncertain_origin boolean,
    csi_naturalised_and_uncertain_origin boolean,
    hi_naturalised_and_uncertain_origin boolean,
    lhi_naturalised_and_uncertain_origin boolean,
    mdi_naturalised_and_uncertain_origin boolean,
    mi_naturalised_and_uncertain_origin boolean,
    ni_naturalised_and_uncertain_origin boolean,
    ar_presumed_extinct boolean,
    chi_presumed_extinct boolean,
    cai_presumed_extinct boolean,
    coi_presumed_extinct boolean,
    csi_presumed_extinct boolean,
    hi_presumed_extinct boolean,
    lhi_presumed_extinct boolean,
    mdi_presumed_extinct boolean,
    mi_presumed_extinct boolean,
    ni_presumed_extinct boolean,
    ar_uncertain_origin boolean,
    chi_uncertain_origin boolean,
    cai_uncertain_origin boolean,
    coi_uncertain_origin boolean,
    csi_uncertain_origin boolean,
    hi_uncertain_origin boolean,
    lhi_uncertain_origin boolean,
    mdi_uncertain_origin boolean,
    mi_uncertain_origin boolean,
    ni_uncertain_origin boolean
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_granular_booleans_v'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN name_type OPTIONS (
    column_name 'name_type'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN accepted_name_usage_id OPTIONS (
    column_name 'accepted_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN accepted_name_usage OPTIONS (
    column_name 'accepted_name_usage'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxonomic_status OPTIONS (
    column_name 'taxonomic_status'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN pro_parte OPTIONS (
    column_name 'pro_parte'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN scientific_name OPTIONS (
    column_name 'scientific_name'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN scientific_name_id OPTIONS (
    column_name 'scientific_name_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN canonical_name OPTIONS (
    column_name 'canonical_name'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN scientific_name_authorship OPTIONS (
    column_name 'scientific_name_authorship'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN parent_name_usage_id OPTIONS (
    column_name 'parent_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxon_rank OPTIONS (
    column_name 'taxon_rank'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxon_rank_sort_order OPTIONS (
    column_name 'taxon_rank_sort_order'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN class OPTIONS (
    column_name 'class'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN subclass OPTIONS (
    column_name 'subclass'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxon_concept_id OPTIONS (
    column_name 'taxon_concept_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN name_according_to OPTIONS (
    column_name 'name_according_to'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN name_according_to_id OPTIONS (
    column_name 'name_according_to_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxon_remarks OPTIONS (
    column_name 'taxon_remarks'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN taxon_distribution OPTIONS (
    column_name 'taxon_distribution'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN higher_classification OPTIONS (
    column_name 'higher_classification'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN first_hybrid_parent_name OPTIONS (
    column_name 'first_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN first_hybrid_parent_name_id OPTIONS (
    column_name 'first_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN second_hybrid_parent_name OPTIONS (
    column_name 'second_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN second_hybrid_parent_name_id OPTIONS (
    column_name 'second_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nomenclatural_code OPTIONS (
    column_name 'nomenclatural_code'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN dataset_name OPTIONS (
    column_name 'dataset_name'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN dataset_id OPTIONS (
    column_name 'dataset_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cc_attribution_iri OPTIONS (
    column_name 'cc_attribution_iri'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN homotypic OPTIONS (
    column_name 'homotypic'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN heterotypic OPTIONS (
    column_name 'heterotypic'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN misapplied OPTIONS (
    column_name 'misapplied'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN relationship OPTIONS (
    column_name 'relationship'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN synonym OPTIONS (
    column_name 'synonym'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN excluded_name OPTIONS (
    column_name 'excluded_name'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN accepted OPTIONS (
    column_name 'accepted'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN accepted_id OPTIONS (
    column_name 'accepted_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN rank_rdf_id OPTIONS (
    column_name 'rank_rdf_id'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN name_space OPTIONS (
    column_name 'name_space'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tree_description OPTIONS (
    column_name 'tree_description'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tree_label OPTIONS (
    column_name 'tree_label'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_unqualified_native OPTIONS (
    column_name 'act_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_unqualified_native OPTIONS (
    column_name 'nsw_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_unqualified_native OPTIONS (
    column_name 'nt_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_unqualified_native OPTIONS (
    column_name 'qld_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_unqualified_native OPTIONS (
    column_name 'sa_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_unqualified_native OPTIONS (
    column_name 'tas_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_unqualified_native OPTIONS (
    column_name 'vic_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_unqualified_native OPTIONS (
    column_name 'wa_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_unqualified_native OPTIONS (
    column_name 'ar_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_unqualified_native OPTIONS (
    column_name 'lhi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_unqualified_native OPTIONS (
    column_name 'chi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_unqualified_native OPTIONS (
    column_name 'cai_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_unqualified_native OPTIONS (
    column_name 'csi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_unqualified_native OPTIONS (
    column_name 'coi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_unqualified_native OPTIONS (
    column_name 'hi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_unqualified_native OPTIONS (
    column_name 'mdi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_unqualified_native OPTIONS (
    column_name 'mi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_unqualified_native OPTIONS (
    column_name 'ni_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_naturalised OPTIONS (
    column_name 'act_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_naturalised OPTIONS (
    column_name 'nsw_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_naturalised OPTIONS (
    column_name 'nt_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_naturalised OPTIONS (
    column_name 'qld_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_naturalised OPTIONS (
    column_name 'sa_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_naturalised OPTIONS (
    column_name 'tas_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_naturalised OPTIONS (
    column_name 'vic_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_naturalised OPTIONS (
    column_name 'wa_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_doubtfully_naturalised OPTIONS (
    column_name 'act_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_doubtfully_naturalised OPTIONS (
    column_name 'nsw_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_doubtfully_naturalised OPTIONS (
    column_name 'nt_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_doubtfully_naturalised OPTIONS (
    column_name 'qld_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_doubtfully_naturalised OPTIONS (
    column_name 'sa_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_doubtfully_naturalised OPTIONS (
    column_name 'tas_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_doubtfully_naturalised OPTIONS (
    column_name 'vic_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_doubtfully_naturalised OPTIONS (
    column_name 'wa_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_formerly_naturalised OPTIONS (
    column_name 'act_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_formerly_naturalised OPTIONS (
    column_name 'nsw_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_formerly_naturalised OPTIONS (
    column_name 'nt_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_formerly_naturalised OPTIONS (
    column_name 'qld_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_formerly_naturalised OPTIONS (
    column_name 'sa_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_formerly_naturalised OPTIONS (
    column_name 'tas_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_formerly_naturalised OPTIONS (
    column_name 'vic_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_formerly_naturalised OPTIONS (
    column_name 'wa_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_native_and_naturalised OPTIONS (
    column_name 'act_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_native_and_naturalised OPTIONS (
    column_name 'nsw_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_native_and_naturalised OPTIONS (
    column_name 'nt_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_native_and_naturalised OPTIONS (
    column_name 'qld_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_native_and_naturalised OPTIONS (
    column_name 'sa_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_native_and_naturalised OPTIONS (
    column_name 'tas_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_native_and_naturalised OPTIONS (
    column_name 'vic_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_native_and_naturalised OPTIONS (
    column_name 'wa_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_native_and_doubtfully_naturalised OPTIONS (
    column_name 'act_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_native_and_doubtfully_naturalised OPTIONS (
    column_name 'nsw_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_native_and_doubtfully_naturalised OPTIONS (
    column_name 'nt_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_native_and_doubtfully_naturalised OPTIONS (
    column_name 'qld_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_native_and_doubtfully_naturalised OPTIONS (
    column_name 'sa_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_native_and_doubtfully_naturalised OPTIONS (
    column_name 'tas_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_native_and_doubtfully_naturalised OPTIONS (
    column_name 'vic_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_native_and_doubtfully_naturalised OPTIONS (
    column_name 'wa_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_native_and_formerly_naturalised OPTIONS (
    column_name 'act_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_native_and_formerly_naturalised OPTIONS (
    column_name 'nsw_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_native_and_formerly_naturalised OPTIONS (
    column_name 'nt_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_native_and_formerly_naturalised OPTIONS (
    column_name 'qld_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_native_and_formerly_naturalised OPTIONS (
    column_name 'sa_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_native_and_formerly_naturalised OPTIONS (
    column_name 'tas_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_native_and_formerly_naturalised OPTIONS (
    column_name 'vic_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_native_and_formerly_naturalised OPTIONS (
    column_name 'wa_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'act_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nsw_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nt_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'qld_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'sa_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'tas_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'vic_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'wa_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'act_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nsw_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nt_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'qld_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'sa_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'tas_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'vic_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'wa_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_native_and_uncertain_origin OPTIONS (
    column_name 'act_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_native_and_uncertain_origin OPTIONS (
    column_name 'nsw_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_native_and_uncertain_origin OPTIONS (
    column_name 'nt_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_native_and_uncertain_origin OPTIONS (
    column_name 'qld_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_native_and_uncertain_origin OPTIONS (
    column_name 'sa_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_native_and_uncertain_origin OPTIONS (
    column_name 'tas_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_native_and_uncertain_origin OPTIONS (
    column_name 'vic_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_native_and_uncertain_origin OPTIONS (
    column_name 'wa_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_naturalised_and_uncertain_origin OPTIONS (
    column_name 'act_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nsw_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nt_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_naturalised_and_uncertain_origin OPTIONS (
    column_name 'qld_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_naturalised_and_uncertain_origin OPTIONS (
    column_name 'sa_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_naturalised_and_uncertain_origin OPTIONS (
    column_name 'tas_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_naturalised_and_uncertain_origin OPTIONS (
    column_name 'vic_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_naturalised_and_uncertain_origin OPTIONS (
    column_name 'wa_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_presumed_extinct OPTIONS (
    column_name 'act_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_presumed_extinct OPTIONS (
    column_name 'nsw_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_presumed_extinct OPTIONS (
    column_name 'nt_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_presumed_extinct OPTIONS (
    column_name 'qld_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_presumed_extinct OPTIONS (
    column_name 'sa_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_presumed_extinct OPTIONS (
    column_name 'tas_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_presumed_extinct OPTIONS (
    column_name 'vic_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_presumed_extinct OPTIONS (
    column_name 'wa_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN act_uncertain_origin OPTIONS (
    column_name 'act_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nsw_uncertain_origin OPTIONS (
    column_name 'nsw_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN nt_uncertain_origin OPTIONS (
    column_name 'nt_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN qld_uncertain_origin OPTIONS (
    column_name 'qld_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN sa_uncertain_origin OPTIONS (
    column_name 'sa_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN tas_uncertain_origin OPTIONS (
    column_name 'tas_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN vic_uncertain_origin OPTIONS (
    column_name 'vic_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN wa_uncertain_origin OPTIONS (
    column_name 'wa_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_naturalised OPTIONS (
    column_name 'ar_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_naturalised OPTIONS (
    column_name 'chi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_naturalised OPTIONS (
    column_name 'cai_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_naturalised OPTIONS (
    column_name 'coi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_naturalised OPTIONS (
    column_name 'csi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_naturalised OPTIONS (
    column_name 'hi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_naturalised OPTIONS (
    column_name 'lhi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_naturalised OPTIONS (
    column_name 'mdi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_naturalised OPTIONS (
    column_name 'mi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_naturalised OPTIONS (
    column_name 'ni_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_doubtfully_naturalised OPTIONS (
    column_name 'ar_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_doubtfully_naturalised OPTIONS (
    column_name 'chi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_doubtfully_naturalised OPTIONS (
    column_name 'cai_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_doubtfully_naturalised OPTIONS (
    column_name 'coi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_doubtfully_naturalised OPTIONS (
    column_name 'csi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_doubtfully_naturalised OPTIONS (
    column_name 'hi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_doubtfully_naturalised OPTIONS (
    column_name 'lhi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_doubtfully_naturalised OPTIONS (
    column_name 'mdi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_doubtfully_naturalised OPTIONS (
    column_name 'mi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_doubtfully_naturalised OPTIONS (
    column_name 'ni_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_formerly_naturalised OPTIONS (
    column_name 'ar_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_formerly_naturalised OPTIONS (
    column_name 'chi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_formerly_naturalised OPTIONS (
    column_name 'cai_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_formerly_naturalised OPTIONS (
    column_name 'coi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_formerly_naturalised OPTIONS (
    column_name 'csi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_formerly_naturalised OPTIONS (
    column_name 'hi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_formerly_naturalised OPTIONS (
    column_name 'lhi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_formerly_naturalised OPTIONS (
    column_name 'mdi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_formerly_naturalised OPTIONS (
    column_name 'mi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_formerly_naturalised OPTIONS (
    column_name 'ni_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_native_and_naturalised OPTIONS (
    column_name 'ar_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_native_and_naturalised OPTIONS (
    column_name 'chi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_native_and_naturalised OPTIONS (
    column_name 'cai_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_native_and_naturalised OPTIONS (
    column_name 'coi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_native_and_naturalised OPTIONS (
    column_name 'csi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_native_and_naturalised OPTIONS (
    column_name 'hi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_native_and_naturalised OPTIONS (
    column_name 'lhi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_native_and_naturalised OPTIONS (
    column_name 'mdi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_native_and_naturalised OPTIONS (
    column_name 'mi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_native_and_naturalised OPTIONS (
    column_name 'ni_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_native_and_doubtfully_naturalised OPTIONS (
    column_name 'ar_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'chi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_native_and_doubtfully_naturalised OPTIONS (
    column_name 'cai_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'coi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'csi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'hi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'lhi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'mdi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'mi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_native_and_doubtfully_naturalised OPTIONS (
    column_name 'ni_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ar_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'chi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'cai_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'coi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'csi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'hi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'lhi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mdi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ni_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_native_and_formerly_naturalised OPTIONS (
    column_name 'ar_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_native_and_formerly_naturalised OPTIONS (
    column_name 'chi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_native_and_formerly_naturalised OPTIONS (
    column_name 'cai_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_native_and_formerly_naturalised OPTIONS (
    column_name 'coi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_native_and_formerly_naturalised OPTIONS (
    column_name 'csi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_native_and_formerly_naturalised OPTIONS (
    column_name 'hi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_native_and_formerly_naturalised OPTIONS (
    column_name 'lhi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_native_and_formerly_naturalised OPTIONS (
    column_name 'mdi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_native_and_formerly_naturalised OPTIONS (
    column_name 'mi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_native_and_formerly_naturalised OPTIONS (
    column_name 'ni_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ar_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'chi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'cai_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'coi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'csi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'hi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'lhi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mdi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ni_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_native_and_uncertain_origin OPTIONS (
    column_name 'ar_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_native_and_uncertain_origin OPTIONS (
    column_name 'chi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_native_and_uncertain_origin OPTIONS (
    column_name 'cai_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_native_and_uncertain_origin OPTIONS (
    column_name 'coi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_native_and_uncertain_origin OPTIONS (
    column_name 'csi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_native_and_uncertain_origin OPTIONS (
    column_name 'hi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_native_and_uncertain_origin OPTIONS (
    column_name 'lhi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_native_and_uncertain_origin OPTIONS (
    column_name 'mdi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_native_and_uncertain_origin OPTIONS (
    column_name 'mi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_native_and_uncertain_origin OPTIONS (
    column_name 'ni_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ar_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'chi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_naturalised_and_uncertain_origin OPTIONS (
    column_name 'cai_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'coi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'csi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'hi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'lhi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mdi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ni_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_presumed_extinct OPTIONS (
    column_name 'ar_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_presumed_extinct OPTIONS (
    column_name 'chi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_presumed_extinct OPTIONS (
    column_name 'cai_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_presumed_extinct OPTIONS (
    column_name 'coi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_presumed_extinct OPTIONS (
    column_name 'csi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_presumed_extinct OPTIONS (
    column_name 'hi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_presumed_extinct OPTIONS (
    column_name 'lhi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_presumed_extinct OPTIONS (
    column_name 'mdi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_presumed_extinct OPTIONS (
    column_name 'mi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_presumed_extinct OPTIONS (
    column_name 'ni_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ar_uncertain_origin OPTIONS (
    column_name 'ar_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN chi_uncertain_origin OPTIONS (
    column_name 'chi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN cai_uncertain_origin OPTIONS (
    column_name 'cai_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN coi_uncertain_origin OPTIONS (
    column_name 'coi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN csi_uncertain_origin OPTIONS (
    column_name 'csi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN hi_uncertain_origin OPTIONS (
    column_name 'hi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN lhi_uncertain_origin OPTIONS (
    column_name 'lhi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mdi_uncertain_origin OPTIONS (
    column_name 'mdi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN mi_uncertain_origin OPTIONS (
    column_name 'mi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_granular_booleans_v ALTER COLUMN ni_uncertain_origin OPTIONS (
    column_name 'ni_uncertain_origin'
);


--
-- Name: dist_native_taxa_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_native_taxa_v (
    taxon_id text,
    name_type character varying(255),
    accepted_name_usage_id text,
    accepted_name_usage character varying(512),
    nomenclatural_status character varying,
    nom_illeg boolean,
    nom_inval boolean,
    taxonomic_status character varying,
    pro_parte boolean,
    scientific_name character varying(512),
    scientific_name_id text,
    canonical_name character varying(250),
    scientific_name_authorship text,
    parent_name_usage_id text,
    taxon_rank character varying(50),
    taxon_rank_sort_order integer,
    kingdom text,
    class text,
    subclass text,
    family text,
    taxon_concept_id text,
    name_according_to character varying(4000),
    name_according_to_id text,
    taxon_remarks text,
    taxon_distribution text,
    higher_classification text,
    first_hybrid_parent_name character varying,
    first_hybrid_parent_name_id text,
    second_hybrid_parent_name character varying,
    second_hybrid_parent_name_id text,
    nomenclatural_code text,
    created timestamp with time zone,
    modified timestamp with time zone,
    dataset_name text,
    dataset_id text,
    license text,
    cc_attribution_iri text,
    tree_version_id bigint,
    tree_element_id bigint,
    instance_id bigint,
    name_id bigint,
    homotypic boolean,
    heterotypic boolean,
    misapplied boolean,
    relationship boolean,
    synonym boolean,
    excluded_name boolean,
    accepted boolean,
    accepted_id bigint,
    rank_rdf_id character varying(50),
    name_space character varying(5000),
    tree_description character varying(5000),
    tree_label character varying(5000),
    act_unqualified_native boolean,
    nsw_unqualified_native boolean,
    nt_unqualified_native boolean,
    qld_unqualified_native boolean,
    sa_unqualified_native boolean,
    tas_unqualified_native boolean,
    vic_unqualified_native boolean,
    wa_unqualified_native boolean,
    ar_unqualified_native boolean,
    lhi_unqualified_native boolean,
    chi_unqualified_native boolean,
    cai_unqualified_native boolean,
    csi_unqualified_native boolean,
    coi_unqualified_native boolean,
    hi_unqualified_native boolean,
    mdi_unqualified_native boolean,
    mi_unqualified_native boolean,
    ni_unqualified_native boolean,
    act_naturalised boolean,
    nsw_naturalised boolean,
    nt_naturalised boolean,
    qld_naturalised boolean,
    sa_naturalised boolean,
    tas_naturalised boolean,
    vic_naturalised boolean,
    wa_naturalised boolean,
    act_doubtfully_naturalised boolean,
    nsw_doubtfully_naturalised boolean,
    nt_doubtfully_naturalised boolean,
    qld_doubtfully_naturalised boolean,
    sa_doubtfully_naturalised boolean,
    tas_doubtfully_naturalised boolean,
    vic_doubtfully_naturalised boolean,
    wa_doubtfully_naturalised boolean,
    act_formerly_naturalised boolean,
    nsw_formerly_naturalised boolean,
    nt_formerly_naturalised boolean,
    qld_formerly_naturalised boolean,
    sa_formerly_naturalised boolean,
    tas_formerly_naturalised boolean,
    vic_formerly_naturalised boolean,
    wa_formerly_naturalised boolean,
    act_native_and_naturalised boolean,
    nsw_native_and_naturalised boolean,
    nt_native_and_naturalised boolean,
    qld_native_and_naturalised boolean,
    sa_native_and_naturalised boolean,
    tas_native_and_naturalised boolean,
    vic_native_and_naturalised boolean,
    wa_native_and_naturalised boolean,
    act_native_and_doubtfully_naturalised boolean,
    nsw_native_and_doubtfully_naturalised boolean,
    nt_native_and_doubtfully_naturalised boolean,
    qld_native_and_doubtfully_naturalised boolean,
    sa_native_and_doubtfully_naturalised boolean,
    tas_native_and_doubtfully_naturalised boolean,
    vic_native_and_doubtfully_naturalised boolean,
    wa_native_and_doubtfully_naturalised boolean,
    act_native_and_formerly_naturalised boolean,
    nsw_native_and_formerly_naturalised boolean,
    nt_native_and_formerly_naturalised boolean,
    qld_native_and_formerly_naturalised boolean,
    sa_native_and_formerly_naturalised boolean,
    tas_native_and_formerly_naturalised boolean,
    vic_native_and_formerly_naturalised boolean,
    wa_native_and_formerly_naturalised boolean,
    act_native_and_naturalised_and_uncertain_origin boolean,
    nsw_native_and_naturalised_and_uncertain_origin boolean,
    nt_native_and_naturalised_and_uncertain_origin boolean,
    qld_native_and_naturalised_and_uncertain_origin boolean,
    sa_native_and_naturalised_and_uncertain_origin boolean,
    tas_native_and_naturalised_and_uncertain_origin boolean,
    vic_native_and_naturalised_and_uncertain_origin boolean,
    wa_native_and_naturalised_and_uncertain_origin boolean,
    act_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    nsw_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    nt_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    qld_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    sa_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    tas_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    vic_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    wa_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    act_native_and_uncertain_origin boolean,
    nsw_native_and_uncertain_origin boolean,
    nt_native_and_uncertain_origin boolean,
    qld_native_and_uncertain_origin boolean,
    sa_native_and_uncertain_origin boolean,
    tas_native_and_uncertain_origin boolean,
    vic_native_and_uncertain_origin boolean,
    wa_native_and_uncertain_origin boolean,
    act_naturalised_and_uncertain_origin boolean,
    nsw_naturalised_and_uncertain_origin boolean,
    nt_naturalised_and_uncertain_origin boolean,
    qld_naturalised_and_uncertain_origin boolean,
    sa_naturalised_and_uncertain_origin boolean,
    tas_naturalised_and_uncertain_origin boolean,
    vic_naturalised_and_uncertain_origin boolean,
    wa_naturalised_and_uncertain_origin boolean,
    act_presumed_extinct boolean,
    nsw_presumed_extinct boolean,
    nt_presumed_extinct boolean,
    qld_presumed_extinct boolean,
    sa_presumed_extinct boolean,
    tas_presumed_extinct boolean,
    vic_presumed_extinct boolean,
    wa_presumed_extinct boolean,
    act_uncertain_origin boolean,
    nsw_uncertain_origin boolean,
    nt_uncertain_origin boolean,
    qld_uncertain_origin boolean,
    sa_uncertain_origin boolean,
    tas_uncertain_origin boolean,
    vic_uncertain_origin boolean,
    wa_uncertain_origin boolean,
    ar_naturalised boolean,
    chi_naturalised boolean,
    cai_naturalised boolean,
    coi_naturalised boolean,
    csi_naturalised boolean,
    hi_naturalised boolean,
    lhi_naturalised boolean,
    mdi_naturalised boolean,
    mi_naturalised boolean,
    ni_naturalised boolean,
    ar_doubtfully_naturalised boolean,
    chi_doubtfully_naturalised boolean,
    cai_doubtfully_naturalised boolean,
    coi_doubtfully_naturalised boolean,
    csi_doubtfully_naturalised boolean,
    hi_doubtfully_naturalised boolean,
    lhi_doubtfully_naturalised boolean,
    mdi_doubtfully_naturalised boolean,
    mi_doubtfully_naturalised boolean,
    ni_doubtfully_naturalised boolean,
    ar_formerly_naturalised boolean,
    chi_formerly_naturalised boolean,
    cai_formerly_naturalised boolean,
    coi_formerly_naturalised boolean,
    csi_formerly_naturalised boolean,
    hi_formerly_naturalised boolean,
    lhi_formerly_naturalised boolean,
    mdi_formerly_naturalised boolean,
    mi_formerly_naturalised boolean,
    ni_formerly_naturalised boolean,
    ar_native_and_naturalised boolean,
    chi_native_and_naturalised boolean,
    cai_native_and_naturalised boolean,
    coi_native_and_naturalised boolean,
    csi_native_and_naturalised boolean,
    hi_native_and_naturalised boolean,
    lhi_native_and_naturalised boolean,
    mdi_native_and_naturalised boolean,
    mi_native_and_naturalised boolean,
    ni_native_and_naturalised boolean,
    ar_native_and_doubtfully_naturalised boolean,
    chi_native_and_doubtfully_naturalised boolean,
    cai_native_and_doubtfully_naturalised boolean,
    coi_native_and_doubtfully_naturalised boolean,
    csi_native_and_doubtfully_naturalised boolean,
    hi_native_and_doubtfully_naturalised boolean,
    lhi_native_and_doubtfully_naturalised boolean,
    mdi_native_and_doubtfully_naturalised boolean,
    mi_native_and_doubtfully_naturalised boolean,
    ni_native_and_doubtfully_naturalised boolean,
    ar_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    chi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    cai_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    coi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    csi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    hi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    lhi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    mdi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    mi_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    ni_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    ar_native_and_formerly_naturalised boolean,
    chi_native_and_formerly_naturalised boolean,
    cai_native_and_formerly_naturalised boolean,
    coi_native_and_formerly_naturalised boolean,
    csi_native_and_formerly_naturalised boolean,
    hi_native_and_formerly_naturalised boolean,
    lhi_native_and_formerly_naturalised boolean,
    mdi_native_and_formerly_naturalised boolean,
    mi_native_and_formerly_naturalised boolean,
    ni_native_and_formerly_naturalised boolean,
    ar_native_and_naturalised_and_uncertain_origin boolean,
    chi_native_and_naturalised_and_uncertain_origin boolean,
    cai_native_and_naturalised_and_uncertain_origin boolean,
    coi_native_and_naturalised_and_uncertain_origin boolean,
    csi_native_and_naturalised_and_uncertain_origin boolean,
    hi_native_and_naturalised_and_uncertain_origin boolean,
    lhi_native_and_naturalised_and_uncertain_origin boolean,
    mdi_native_and_naturalised_and_uncertain_origin boolean,
    mi_native_and_naturalised_and_uncertain_origin boolean,
    ni_native_and_naturalised_and_uncertain_origin boolean,
    ar_native_and_uncertain_origin boolean,
    chi_native_and_uncertain_origin boolean,
    cai_native_and_uncertain_origin boolean,
    coi_native_and_uncertain_origin boolean,
    csi_native_and_uncertain_origin boolean,
    hi_native_and_uncertain_origin boolean,
    lhi_native_and_uncertain_origin boolean,
    mdi_native_and_uncertain_origin boolean,
    mi_native_and_uncertain_origin boolean,
    ni_native_and_uncertain_origin boolean,
    ar_naturalised_and_uncertain_origin boolean,
    chi_naturalised_and_uncertain_origin boolean,
    cai_naturalised_and_uncertain_origin boolean,
    coi_naturalised_and_uncertain_origin boolean,
    csi_naturalised_and_uncertain_origin boolean,
    hi_naturalised_and_uncertain_origin boolean,
    lhi_naturalised_and_uncertain_origin boolean,
    mdi_naturalised_and_uncertain_origin boolean,
    mi_naturalised_and_uncertain_origin boolean,
    ni_naturalised_and_uncertain_origin boolean,
    ar_presumed_extinct boolean,
    chi_presumed_extinct boolean,
    cai_presumed_extinct boolean,
    coi_presumed_extinct boolean,
    csi_presumed_extinct boolean,
    hi_presumed_extinct boolean,
    lhi_presumed_extinct boolean,
    mdi_presumed_extinct boolean,
    mi_presumed_extinct boolean,
    ni_presumed_extinct boolean,
    ar_uncertain_origin boolean,
    chi_uncertain_origin boolean,
    cai_uncertain_origin boolean,
    coi_uncertain_origin boolean,
    csi_uncertain_origin boolean,
    hi_uncertain_origin boolean,
    lhi_uncertain_origin boolean,
    mdi_uncertain_origin boolean,
    mi_uncertain_origin boolean,
    ni_uncertain_origin boolean,
    mainland_unqualified_native boolean,
    island_unqualified_native boolean,
    mainland_naturalised boolean,
    mainland_doubtfully_naturalised boolean,
    island_naturalised boolean,
    island_doubtfully_naturalised boolean,
    mainland_native_and_naturalised boolean,
    island_native_and_naturalised boolean,
    island_native_and_doubtfully_naturalised boolean,
    mainland_native_and_doubtfully_naturalised boolean,
    mainland_native_and_naturalised_and_uncertain_origin boolean,
    island_native_and_naturalised_and_uncertain_origin boolean,
    mainland_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    island_native_and_doubtfully_naturalised_and_uncertain_origin boolean,
    mainland_uncertain_origin boolean,
    island_uncertain_origin boolean,
    mainland_formerly_naturalised boolean,
    island_formerly_naturalised boolean,
    mainland_native_and_formerly_naturalised boolean,
    island_native_and_formerly_naturalised boolean,
    mainland_presumed_extinct boolean,
    island_presumed_extinct boolean
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_native_taxa_v'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN name_type OPTIONS (
    column_name 'name_type'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN accepted_name_usage_id OPTIONS (
    column_name 'accepted_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN accepted_name_usage OPTIONS (
    column_name 'accepted_name_usage'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxonomic_status OPTIONS (
    column_name 'taxonomic_status'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN pro_parte OPTIONS (
    column_name 'pro_parte'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN scientific_name OPTIONS (
    column_name 'scientific_name'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN scientific_name_id OPTIONS (
    column_name 'scientific_name_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN canonical_name OPTIONS (
    column_name 'canonical_name'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN scientific_name_authorship OPTIONS (
    column_name 'scientific_name_authorship'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN parent_name_usage_id OPTIONS (
    column_name 'parent_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxon_rank OPTIONS (
    column_name 'taxon_rank'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxon_rank_sort_order OPTIONS (
    column_name 'taxon_rank_sort_order'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN class OPTIONS (
    column_name 'class'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN subclass OPTIONS (
    column_name 'subclass'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxon_concept_id OPTIONS (
    column_name 'taxon_concept_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN name_according_to OPTIONS (
    column_name 'name_according_to'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN name_according_to_id OPTIONS (
    column_name 'name_according_to_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxon_remarks OPTIONS (
    column_name 'taxon_remarks'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN taxon_distribution OPTIONS (
    column_name 'taxon_distribution'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN higher_classification OPTIONS (
    column_name 'higher_classification'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN first_hybrid_parent_name OPTIONS (
    column_name 'first_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN first_hybrid_parent_name_id OPTIONS (
    column_name 'first_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN second_hybrid_parent_name OPTIONS (
    column_name 'second_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN second_hybrid_parent_name_id OPTIONS (
    column_name 'second_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nomenclatural_code OPTIONS (
    column_name 'nomenclatural_code'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN dataset_name OPTIONS (
    column_name 'dataset_name'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN dataset_id OPTIONS (
    column_name 'dataset_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cc_attribution_iri OPTIONS (
    column_name 'cc_attribution_iri'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN homotypic OPTIONS (
    column_name 'homotypic'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN heterotypic OPTIONS (
    column_name 'heterotypic'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN misapplied OPTIONS (
    column_name 'misapplied'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN relationship OPTIONS (
    column_name 'relationship'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN synonym OPTIONS (
    column_name 'synonym'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN excluded_name OPTIONS (
    column_name 'excluded_name'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN accepted OPTIONS (
    column_name 'accepted'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN accepted_id OPTIONS (
    column_name 'accepted_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN rank_rdf_id OPTIONS (
    column_name 'rank_rdf_id'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN name_space OPTIONS (
    column_name 'name_space'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tree_description OPTIONS (
    column_name 'tree_description'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tree_label OPTIONS (
    column_name 'tree_label'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_unqualified_native OPTIONS (
    column_name 'act_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_unqualified_native OPTIONS (
    column_name 'nsw_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_unqualified_native OPTIONS (
    column_name 'nt_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_unqualified_native OPTIONS (
    column_name 'qld_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_unqualified_native OPTIONS (
    column_name 'sa_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_unqualified_native OPTIONS (
    column_name 'tas_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_unqualified_native OPTIONS (
    column_name 'vic_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_unqualified_native OPTIONS (
    column_name 'wa_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_unqualified_native OPTIONS (
    column_name 'ar_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_unqualified_native OPTIONS (
    column_name 'lhi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_unqualified_native OPTIONS (
    column_name 'chi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_unqualified_native OPTIONS (
    column_name 'cai_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_unqualified_native OPTIONS (
    column_name 'csi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_unqualified_native OPTIONS (
    column_name 'coi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_unqualified_native OPTIONS (
    column_name 'hi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_unqualified_native OPTIONS (
    column_name 'mdi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_unqualified_native OPTIONS (
    column_name 'mi_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_unqualified_native OPTIONS (
    column_name 'ni_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_naturalised OPTIONS (
    column_name 'act_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_naturalised OPTIONS (
    column_name 'nsw_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_naturalised OPTIONS (
    column_name 'nt_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_naturalised OPTIONS (
    column_name 'qld_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_naturalised OPTIONS (
    column_name 'sa_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_naturalised OPTIONS (
    column_name 'tas_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_naturalised OPTIONS (
    column_name 'vic_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_naturalised OPTIONS (
    column_name 'wa_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_doubtfully_naturalised OPTIONS (
    column_name 'act_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_doubtfully_naturalised OPTIONS (
    column_name 'nsw_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_doubtfully_naturalised OPTIONS (
    column_name 'nt_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_doubtfully_naturalised OPTIONS (
    column_name 'qld_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_doubtfully_naturalised OPTIONS (
    column_name 'sa_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_doubtfully_naturalised OPTIONS (
    column_name 'tas_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_doubtfully_naturalised OPTIONS (
    column_name 'vic_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_doubtfully_naturalised OPTIONS (
    column_name 'wa_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_formerly_naturalised OPTIONS (
    column_name 'act_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_formerly_naturalised OPTIONS (
    column_name 'nsw_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_formerly_naturalised OPTIONS (
    column_name 'nt_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_formerly_naturalised OPTIONS (
    column_name 'qld_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_formerly_naturalised OPTIONS (
    column_name 'sa_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_formerly_naturalised OPTIONS (
    column_name 'tas_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_formerly_naturalised OPTIONS (
    column_name 'vic_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_formerly_naturalised OPTIONS (
    column_name 'wa_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_native_and_naturalised OPTIONS (
    column_name 'act_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_native_and_naturalised OPTIONS (
    column_name 'nsw_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_native_and_naturalised OPTIONS (
    column_name 'nt_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_native_and_naturalised OPTIONS (
    column_name 'qld_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_native_and_naturalised OPTIONS (
    column_name 'sa_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_native_and_naturalised OPTIONS (
    column_name 'tas_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_native_and_naturalised OPTIONS (
    column_name 'vic_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_native_and_naturalised OPTIONS (
    column_name 'wa_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_native_and_doubtfully_naturalised OPTIONS (
    column_name 'act_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_native_and_doubtfully_naturalised OPTIONS (
    column_name 'nsw_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_native_and_doubtfully_naturalised OPTIONS (
    column_name 'nt_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_native_and_doubtfully_naturalised OPTIONS (
    column_name 'qld_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_native_and_doubtfully_naturalised OPTIONS (
    column_name 'sa_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_native_and_doubtfully_naturalised OPTIONS (
    column_name 'tas_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_native_and_doubtfully_naturalised OPTIONS (
    column_name 'vic_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_native_and_doubtfully_naturalised OPTIONS (
    column_name 'wa_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_native_and_formerly_naturalised OPTIONS (
    column_name 'act_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_native_and_formerly_naturalised OPTIONS (
    column_name 'nsw_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_native_and_formerly_naturalised OPTIONS (
    column_name 'nt_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_native_and_formerly_naturalised OPTIONS (
    column_name 'qld_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_native_and_formerly_naturalised OPTIONS (
    column_name 'sa_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_native_and_formerly_naturalised OPTIONS (
    column_name 'tas_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_native_and_formerly_naturalised OPTIONS (
    column_name 'vic_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_native_and_formerly_naturalised OPTIONS (
    column_name 'wa_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'act_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nsw_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nt_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'qld_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'sa_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'tas_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'vic_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'wa_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'act_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nsw_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nt_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'qld_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'sa_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'tas_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'vic_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'wa_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_native_and_uncertain_origin OPTIONS (
    column_name 'act_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_native_and_uncertain_origin OPTIONS (
    column_name 'nsw_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_native_and_uncertain_origin OPTIONS (
    column_name 'nt_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_native_and_uncertain_origin OPTIONS (
    column_name 'qld_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_native_and_uncertain_origin OPTIONS (
    column_name 'sa_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_native_and_uncertain_origin OPTIONS (
    column_name 'tas_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_native_and_uncertain_origin OPTIONS (
    column_name 'vic_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_native_and_uncertain_origin OPTIONS (
    column_name 'wa_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_naturalised_and_uncertain_origin OPTIONS (
    column_name 'act_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nsw_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_naturalised_and_uncertain_origin OPTIONS (
    column_name 'nt_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_naturalised_and_uncertain_origin OPTIONS (
    column_name 'qld_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_naturalised_and_uncertain_origin OPTIONS (
    column_name 'sa_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_naturalised_and_uncertain_origin OPTIONS (
    column_name 'tas_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_naturalised_and_uncertain_origin OPTIONS (
    column_name 'vic_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_naturalised_and_uncertain_origin OPTIONS (
    column_name 'wa_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_presumed_extinct OPTIONS (
    column_name 'act_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_presumed_extinct OPTIONS (
    column_name 'nsw_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_presumed_extinct OPTIONS (
    column_name 'nt_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_presumed_extinct OPTIONS (
    column_name 'qld_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_presumed_extinct OPTIONS (
    column_name 'sa_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_presumed_extinct OPTIONS (
    column_name 'tas_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_presumed_extinct OPTIONS (
    column_name 'vic_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_presumed_extinct OPTIONS (
    column_name 'wa_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN act_uncertain_origin OPTIONS (
    column_name 'act_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nsw_uncertain_origin OPTIONS (
    column_name 'nsw_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN nt_uncertain_origin OPTIONS (
    column_name 'nt_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN qld_uncertain_origin OPTIONS (
    column_name 'qld_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN sa_uncertain_origin OPTIONS (
    column_name 'sa_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN tas_uncertain_origin OPTIONS (
    column_name 'tas_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN vic_uncertain_origin OPTIONS (
    column_name 'vic_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN wa_uncertain_origin OPTIONS (
    column_name 'wa_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_naturalised OPTIONS (
    column_name 'ar_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_naturalised OPTIONS (
    column_name 'chi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_naturalised OPTIONS (
    column_name 'cai_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_naturalised OPTIONS (
    column_name 'coi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_naturalised OPTIONS (
    column_name 'csi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_naturalised OPTIONS (
    column_name 'hi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_naturalised OPTIONS (
    column_name 'lhi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_naturalised OPTIONS (
    column_name 'mdi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_naturalised OPTIONS (
    column_name 'mi_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_naturalised OPTIONS (
    column_name 'ni_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_doubtfully_naturalised OPTIONS (
    column_name 'ar_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_doubtfully_naturalised OPTIONS (
    column_name 'chi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_doubtfully_naturalised OPTIONS (
    column_name 'cai_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_doubtfully_naturalised OPTIONS (
    column_name 'coi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_doubtfully_naturalised OPTIONS (
    column_name 'csi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_doubtfully_naturalised OPTIONS (
    column_name 'hi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_doubtfully_naturalised OPTIONS (
    column_name 'lhi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_doubtfully_naturalised OPTIONS (
    column_name 'mdi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_doubtfully_naturalised OPTIONS (
    column_name 'mi_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_doubtfully_naturalised OPTIONS (
    column_name 'ni_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_formerly_naturalised OPTIONS (
    column_name 'ar_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_formerly_naturalised OPTIONS (
    column_name 'chi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_formerly_naturalised OPTIONS (
    column_name 'cai_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_formerly_naturalised OPTIONS (
    column_name 'coi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_formerly_naturalised OPTIONS (
    column_name 'csi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_formerly_naturalised OPTIONS (
    column_name 'hi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_formerly_naturalised OPTIONS (
    column_name 'lhi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_formerly_naturalised OPTIONS (
    column_name 'mdi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_formerly_naturalised OPTIONS (
    column_name 'mi_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_formerly_naturalised OPTIONS (
    column_name 'ni_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_native_and_naturalised OPTIONS (
    column_name 'ar_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_native_and_naturalised OPTIONS (
    column_name 'chi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_native_and_naturalised OPTIONS (
    column_name 'cai_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_native_and_naturalised OPTIONS (
    column_name 'coi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_native_and_naturalised OPTIONS (
    column_name 'csi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_native_and_naturalised OPTIONS (
    column_name 'hi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_native_and_naturalised OPTIONS (
    column_name 'lhi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_native_and_naturalised OPTIONS (
    column_name 'mdi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_native_and_naturalised OPTIONS (
    column_name 'mi_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_native_and_naturalised OPTIONS (
    column_name 'ni_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_native_and_doubtfully_naturalised OPTIONS (
    column_name 'ar_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'chi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_native_and_doubtfully_naturalised OPTIONS (
    column_name 'cai_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'coi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'csi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'hi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'lhi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'mdi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_native_and_doubtfully_naturalised OPTIONS (
    column_name 'mi_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_native_and_doubtfully_naturalised OPTIONS (
    column_name 'ni_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ar_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'chi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'cai_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'coi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'csi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'hi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'lhi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mdi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mi_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ni_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_native_and_formerly_naturalised OPTIONS (
    column_name 'ar_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_native_and_formerly_naturalised OPTIONS (
    column_name 'chi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_native_and_formerly_naturalised OPTIONS (
    column_name 'cai_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_native_and_formerly_naturalised OPTIONS (
    column_name 'coi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_native_and_formerly_naturalised OPTIONS (
    column_name 'csi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_native_and_formerly_naturalised OPTIONS (
    column_name 'hi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_native_and_formerly_naturalised OPTIONS (
    column_name 'lhi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_native_and_formerly_naturalised OPTIONS (
    column_name 'mdi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_native_and_formerly_naturalised OPTIONS (
    column_name 'mi_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_native_and_formerly_naturalised OPTIONS (
    column_name 'ni_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ar_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'chi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'cai_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'coi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'csi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'hi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'lhi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mdi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mi_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ni_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_native_and_uncertain_origin OPTIONS (
    column_name 'ar_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_native_and_uncertain_origin OPTIONS (
    column_name 'chi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_native_and_uncertain_origin OPTIONS (
    column_name 'cai_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_native_and_uncertain_origin OPTIONS (
    column_name 'coi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_native_and_uncertain_origin OPTIONS (
    column_name 'csi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_native_and_uncertain_origin OPTIONS (
    column_name 'hi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_native_and_uncertain_origin OPTIONS (
    column_name 'lhi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_native_and_uncertain_origin OPTIONS (
    column_name 'mdi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_native_and_uncertain_origin OPTIONS (
    column_name 'mi_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_native_and_uncertain_origin OPTIONS (
    column_name 'ni_native_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ar_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'chi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_naturalised_and_uncertain_origin OPTIONS (
    column_name 'cai_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'coi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'csi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'hi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'lhi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mdi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mi_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_naturalised_and_uncertain_origin OPTIONS (
    column_name 'ni_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_presumed_extinct OPTIONS (
    column_name 'ar_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_presumed_extinct OPTIONS (
    column_name 'chi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_presumed_extinct OPTIONS (
    column_name 'cai_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_presumed_extinct OPTIONS (
    column_name 'coi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_presumed_extinct OPTIONS (
    column_name 'csi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_presumed_extinct OPTIONS (
    column_name 'hi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_presumed_extinct OPTIONS (
    column_name 'lhi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_presumed_extinct OPTIONS (
    column_name 'mdi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_presumed_extinct OPTIONS (
    column_name 'mi_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_presumed_extinct OPTIONS (
    column_name 'ni_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ar_uncertain_origin OPTIONS (
    column_name 'ar_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN chi_uncertain_origin OPTIONS (
    column_name 'chi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN cai_uncertain_origin OPTIONS (
    column_name 'cai_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN coi_uncertain_origin OPTIONS (
    column_name 'coi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN csi_uncertain_origin OPTIONS (
    column_name 'csi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN hi_uncertain_origin OPTIONS (
    column_name 'hi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN lhi_uncertain_origin OPTIONS (
    column_name 'lhi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mdi_uncertain_origin OPTIONS (
    column_name 'mdi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mi_uncertain_origin OPTIONS (
    column_name 'mi_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN ni_uncertain_origin OPTIONS (
    column_name 'ni_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_unqualified_native OPTIONS (
    column_name 'mainland_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_unqualified_native OPTIONS (
    column_name 'island_unqualified_native'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_naturalised OPTIONS (
    column_name 'mainland_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_doubtfully_naturalised OPTIONS (
    column_name 'mainland_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_naturalised OPTIONS (
    column_name 'island_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_doubtfully_naturalised OPTIONS (
    column_name 'island_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_native_and_naturalised OPTIONS (
    column_name 'mainland_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_native_and_naturalised OPTIONS (
    column_name 'island_native_and_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_native_and_doubtfully_naturalised OPTIONS (
    column_name 'island_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_native_and_doubtfully_naturalised OPTIONS (
    column_name 'mainland_native_and_doubtfully_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mainland_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_native_and_naturalised_and_uncertain_origin OPTIONS (
    column_name 'island_native_and_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'mainland_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_native_and_doubtfully_naturalised_and_uncertain_origin OPTIONS (
    column_name 'island_native_and_doubtfully_naturalised_and_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_uncertain_origin OPTIONS (
    column_name 'mainland_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_uncertain_origin OPTIONS (
    column_name 'island_uncertain_origin'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_formerly_naturalised OPTIONS (
    column_name 'mainland_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_formerly_naturalised OPTIONS (
    column_name 'island_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_native_and_formerly_naturalised OPTIONS (
    column_name 'mainland_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_native_and_formerly_naturalised OPTIONS (
    column_name 'island_native_and_formerly_naturalised'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN mainland_presumed_extinct OPTIONS (
    column_name 'mainland_presumed_extinct'
);
ALTER FOREIGN TABLE xfungi.dist_native_taxa_v ALTER COLUMN island_presumed_extinct OPTIONS (
    column_name 'island_presumed_extinct'
);


--
-- Name: dist_region; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_region (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    def_link character varying(255),
    name character varying(255) NOT NULL,
    sort_order integer NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_region'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN def_link OPTIONS (
    column_name 'def_link'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.dist_region ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: dist_status; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_status (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    def_link character varying(255),
    name character varying(255) NOT NULL,
    sort_order integer NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_status'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN def_link OPTIONS (
    column_name 'def_link'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.dist_status ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: dist_status_dist_status; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dist_status_dist_status (
    dist_status_combining_status_id bigint,
    dist_status_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dist_status_dist_status'
);
ALTER FOREIGN TABLE xfungi.dist_status_dist_status ALTER COLUMN dist_status_combining_status_id OPTIONS (
    column_name 'dist_status_combining_status_id'
);
ALTER FOREIGN TABLE xfungi.dist_status_dist_status ALTER COLUMN dist_status_id OPTIONS (
    column_name 'dist_status_id'
);


--
-- Name: dwc_name_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dwc_name_v (
    "scientificNameID" text,
    "nameType" character varying(50),
    "scientificName" character varying(512),
    "scientificNameHTML" character varying(2048),
    "canonicalName" character varying(250),
    "canonicalNameHTML" character varying(2048),
    "nameElement" character varying(255),
    "nomenclaturalStatus" character varying,
    "scientificNameAuthorship" text,
    autonym boolean,
    hybrid boolean,
    cultivar boolean,
    formula boolean,
    scientific boolean,
    "nomInval" boolean,
    "nomIlleg" boolean,
    "namePublishedIn" text,
    "namePublishedInID" text,
    "namePublishedInYear" integer,
    "nameInstanceType" character varying(255),
    "nameAccordingToID" text,
    "nameAccordingTo" text,
    "originalNameUsage" character varying(512),
    "originalNameUsageID" text,
    "originalNameUsageYear" text,
    "typeCitation" text,
    kingdom text,
    family text,
    "genericName" text,
    "specificEpithet" text,
    "infraspecificEpithet" character varying,
    "cultivarEpithet" character varying,
    "taxonRank" character varying(50),
    "taxonRankSortOrder" integer,
    "taxonRankAbbreviation" character varying(20),
    "firstHybridParentName" character varying(512),
    "firstHybridParentNameID" text,
    "secondHybridParentName" character varying(512),
    "secondHybridParentNameID" text,
    created timestamp with time zone,
    modified timestamp with time zone,
    "nomenclaturalCode" text,
    "datasetName" character varying(5000),
    "taxonomicStatus" text,
    "statusAccordingTo" text,
    license text,
    "ccAttributionIRI" text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dwc_name_v'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "scientificNameID" OPTIONS (
    column_name 'scientificNameID'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nameType" OPTIONS (
    column_name 'nameType'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "scientificName" OPTIONS (
    column_name 'scientificName'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "scientificNameHTML" OPTIONS (
    column_name 'scientificNameHTML'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "canonicalName" OPTIONS (
    column_name 'canonicalName'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "canonicalNameHTML" OPTIONS (
    column_name 'canonicalNameHTML'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nameElement" OPTIONS (
    column_name 'nameElement'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nomenclaturalStatus" OPTIONS (
    column_name 'nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "scientificNameAuthorship" OPTIONS (
    column_name 'scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nomInval" OPTIONS (
    column_name 'nomInval'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nomIlleg" OPTIONS (
    column_name 'nomIlleg'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "namePublishedIn" OPTIONS (
    column_name 'namePublishedIn'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "namePublishedInID" OPTIONS (
    column_name 'namePublishedInID'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "namePublishedInYear" OPTIONS (
    column_name 'namePublishedInYear'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nameInstanceType" OPTIONS (
    column_name 'nameInstanceType'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nameAccordingToID" OPTIONS (
    column_name 'nameAccordingToID'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nameAccordingTo" OPTIONS (
    column_name 'nameAccordingTo'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "originalNameUsage" OPTIONS (
    column_name 'originalNameUsage'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "originalNameUsageID" OPTIONS (
    column_name 'originalNameUsageID'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "originalNameUsageYear" OPTIONS (
    column_name 'originalNameUsageYear'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "typeCitation" OPTIONS (
    column_name 'typeCitation'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "genericName" OPTIONS (
    column_name 'genericName'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "specificEpithet" OPTIONS (
    column_name 'specificEpithet'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "infraspecificEpithet" OPTIONS (
    column_name 'infraspecificEpithet'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "cultivarEpithet" OPTIONS (
    column_name 'cultivarEpithet'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "taxonRank" OPTIONS (
    column_name 'taxonRank'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "taxonRankSortOrder" OPTIONS (
    column_name 'taxonRankSortOrder'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "taxonRankAbbreviation" OPTIONS (
    column_name 'taxonRankAbbreviation'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "firstHybridParentName" OPTIONS (
    column_name 'firstHybridParentName'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "firstHybridParentNameID" OPTIONS (
    column_name 'firstHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "secondHybridParentName" OPTIONS (
    column_name 'secondHybridParentName'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "secondHybridParentNameID" OPTIONS (
    column_name 'secondHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "nomenclaturalCode" OPTIONS (
    column_name 'nomenclaturalCode'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "datasetName" OPTIONS (
    column_name 'datasetName'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "taxonomicStatus" OPTIONS (
    column_name 'taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "statusAccordingTo" OPTIONS (
    column_name 'statusAccordingTo'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.dwc_name_v ALTER COLUMN "ccAttributionIRI" OPTIONS (
    column_name 'ccAttributionIRI'
);


--
-- Name: dwc_taxon_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.dwc_taxon_v (
    "taxonID" text,
    "nameType" character varying(255),
    "acceptedNameUsageID" text,
    "acceptedNameUsage" character varying(512),
    "nomenclaturalStatus" character varying,
    "nomIlleg" boolean,
    "nomInval" boolean,
    "taxonomicStatus" character varying,
    "proParte" boolean,
    "scientificName" character varying(512),
    "scientificNameID" text,
    "canonicalName" character varying(250),
    "scientificNameAuthorship" text,
    "parentNameUsageID" text,
    "taxonRank" character varying(50),
    "taxonRankSortOrder" integer,
    kingdom text,
    class text,
    subclass text,
    family text,
    "taxonConceptID" text,
    "nameAccordingTo" character varying(4000),
    "nameAccordingToID" text,
    "taxonRemarks" text,
    "taxonDistribution" text,
    "higherClassification" text,
    "firstHybridParentName" character varying,
    "firstHybridParentNameID" text,
    "secondHybridParentName" character varying,
    "secondHybridParentNameID" text,
    "nomenclaturalCode" text,
    created timestamp with time zone,
    modified timestamp with time zone,
    "datasetName" text,
    "dataSetID" text,
    license text,
    "ccAttributionIRI" text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'dwc_taxon_v'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonID" OPTIONS (
    column_name 'taxonID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nameType" OPTIONS (
    column_name 'nameType'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "acceptedNameUsageID" OPTIONS (
    column_name 'acceptedNameUsageID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "acceptedNameUsage" OPTIONS (
    column_name 'acceptedNameUsage'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nomenclaturalStatus" OPTIONS (
    column_name 'nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nomIlleg" OPTIONS (
    column_name 'nomIlleg'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nomInval" OPTIONS (
    column_name 'nomInval'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonomicStatus" OPTIONS (
    column_name 'taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "proParte" OPTIONS (
    column_name 'proParte'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "scientificName" OPTIONS (
    column_name 'scientificName'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "scientificNameID" OPTIONS (
    column_name 'scientificNameID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "canonicalName" OPTIONS (
    column_name 'canonicalName'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "scientificNameAuthorship" OPTIONS (
    column_name 'scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "parentNameUsageID" OPTIONS (
    column_name 'parentNameUsageID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonRank" OPTIONS (
    column_name 'taxonRank'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonRankSortOrder" OPTIONS (
    column_name 'taxonRankSortOrder'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN class OPTIONS (
    column_name 'class'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN subclass OPTIONS (
    column_name 'subclass'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonConceptID" OPTIONS (
    column_name 'taxonConceptID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nameAccordingTo" OPTIONS (
    column_name 'nameAccordingTo'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nameAccordingToID" OPTIONS (
    column_name 'nameAccordingToID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonRemarks" OPTIONS (
    column_name 'taxonRemarks'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "taxonDistribution" OPTIONS (
    column_name 'taxonDistribution'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "higherClassification" OPTIONS (
    column_name 'higherClassification'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "firstHybridParentName" OPTIONS (
    column_name 'firstHybridParentName'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "firstHybridParentNameID" OPTIONS (
    column_name 'firstHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "secondHybridParentName" OPTIONS (
    column_name 'secondHybridParentName'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "secondHybridParentNameID" OPTIONS (
    column_name 'secondHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "nomenclaturalCode" OPTIONS (
    column_name 'nomenclaturalCode'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "datasetName" OPTIONS (
    column_name 'datasetName'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "dataSetID" OPTIONS (
    column_name 'dataSetID'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.dwc_taxon_v ALTER COLUMN "ccAttributionIRI" OPTIONS (
    column_name 'ccAttributionIRI'
);


--
-- Name: event_record; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.event_record (
    id bigint NOT NULL,
    version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    data jsonb,
    dealt_with boolean NOT NULL,
    type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'event_record'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN version OPTIONS (
    column_name 'version'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN data OPTIONS (
    column_name 'data'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN dealt_with OPTIONS (
    column_name 'dealt_with'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN type OPTIONS (
    column_name 'type'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.event_record ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: id_mapper; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.id_mapper (
    id bigint NOT NULL,
    from_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    system character varying(20) NOT NULL,
    to_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'id_mapper'
);
ALTER FOREIGN TABLE xfungi.id_mapper ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.id_mapper ALTER COLUMN from_id OPTIONS (
    column_name 'from_id'
);
ALTER FOREIGN TABLE xfungi.id_mapper ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xfungi.id_mapper ALTER COLUMN system OPTIONS (
    column_name 'system'
);
ALTER FOREIGN TABLE xfungi.id_mapper ALTER COLUMN to_id OPTIONS (
    column_name 'to_id'
);


--
-- Name: instance; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.instance (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    draft boolean NOT NULL,
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
    valid_record boolean NOT NULL,
    verbatim_name_string character varying(255),
    uri text,
    cached_synonymy_html text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'instance'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN bhl_url OPTIONS (
    column_name 'bhl_url'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN draft OPTIONS (
    column_name 'draft'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN instance_type_id OPTIONS (
    column_name 'instance_type_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN page OPTIONS (
    column_name 'page'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN page_qualifier OPTIONS (
    column_name 'page_qualifier'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN verbatim_name_string OPTIONS (
    column_name 'verbatim_name_string'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);
ALTER FOREIGN TABLE xfungi.instance ALTER COLUMN cached_synonymy_html OPTIONS (
    column_name 'cached_synonymy_html'
);


--
-- Name: instance_note; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.instance_note (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'instance_note'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN instance_note_key_id OPTIONS (
    column_name 'instance_note_key_id'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.instance_note ALTER COLUMN value OPTIONS (
    column_name 'value'
);


--
-- Name: instance_note_key; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.instance_note_key (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    name character varying(255) NOT NULL,
    rdf_id character varying(50),
    sort_order integer NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'instance_note_key'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xfungi.instance_note_key ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: instance_resource_vw; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.instance_resource_vw (
    site_name character varying(100),
    site_description character varying(1000),
    site_url character varying(500),
    resource_path character varying(2400),
    url text,
    instance_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'instance_resource_vw'
);
ALTER FOREIGN TABLE xfungi.instance_resource_vw ALTER COLUMN site_name OPTIONS (
    column_name 'site_name'
);
ALTER FOREIGN TABLE xfungi.instance_resource_vw ALTER COLUMN site_description OPTIONS (
    column_name 'site_description'
);
ALTER FOREIGN TABLE xfungi.instance_resource_vw ALTER COLUMN site_url OPTIONS (
    column_name 'site_url'
);
ALTER FOREIGN TABLE xfungi.instance_resource_vw ALTER COLUMN resource_path OPTIONS (
    column_name 'resource_path'
);
ALTER FOREIGN TABLE xfungi.instance_resource_vw ALTER COLUMN url OPTIONS (
    column_name 'url'
);
ALTER FOREIGN TABLE xfungi.instance_resource_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);


--
-- Name: instance_resources; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.instance_resources (
    instance_id bigint NOT NULL,
    resource_id bigint NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'instance_resources'
);
ALTER FOREIGN TABLE xfungi.instance_resources ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.instance_resources ALTER COLUMN resource_id OPTIONS (
    column_name 'resource_id'
);


--
-- Name: instance_type; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.instance_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    bidirectional boolean NOT NULL,
    citing boolean NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    doubtful boolean NOT NULL,
    has_label character varying(255) NOT NULL,
    misapplied boolean NOT NULL,
    name character varying(255) NOT NULL,
    nomenclatural boolean NOT NULL,
    of_label character varying(255) NOT NULL,
    primary_instance boolean NOT NULL,
    pro_parte boolean NOT NULL,
    protologue boolean NOT NULL,
    rdf_id character varying(50),
    relationship boolean NOT NULL,
    secondary_instance boolean NOT NULL,
    sort_order integer NOT NULL,
    standalone boolean NOT NULL,
    synonym boolean NOT NULL,
    taxonomic boolean NOT NULL,
    unsourced boolean NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'instance_type'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN bidirectional OPTIONS (
    column_name 'bidirectional'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN citing OPTIONS (
    column_name 'citing'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN doubtful OPTIONS (
    column_name 'doubtful'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN has_label OPTIONS (
    column_name 'has_label'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN misapplied OPTIONS (
    column_name 'misapplied'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN nomenclatural OPTIONS (
    column_name 'nomenclatural'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN of_label OPTIONS (
    column_name 'of_label'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN primary_instance OPTIONS (
    column_name 'primary_instance'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN pro_parte OPTIONS (
    column_name 'pro_parte'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN protologue OPTIONS (
    column_name 'protologue'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN relationship OPTIONS (
    column_name 'relationship'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN secondary_instance OPTIONS (
    column_name 'secondary_instance'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN standalone OPTIONS (
    column_name 'standalone'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN synonym OPTIONS (
    column_name 'synonym'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN taxonomic OPTIONS (
    column_name 'taxonomic'
);
ALTER FOREIGN TABLE xfungi.instance_type ALTER COLUMN unsourced OPTIONS (
    column_name 'unsourced'
);


--
-- Name: language; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.language (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    iso6391code character varying(2),
    iso6393code character varying(3) NOT NULL,
    name character varying(50) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'language'
);
ALTER FOREIGN TABLE xfungi.language ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.language ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.language ALTER COLUMN iso6391code OPTIONS (
    column_name 'iso6391code'
);
ALTER FOREIGN TABLE xfungi.language ALTER COLUMN iso6393code OPTIONS (
    column_name 'iso6393code'
);
ALTER FOREIGN TABLE xfungi.language ALTER COLUMN name OPTIONS (
    column_name 'name'
);


--
-- Name: media; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.media (
    id bigint NOT NULL,
    version bigint NOT NULL,
    data bytea NOT NULL,
    description text NOT NULL,
    file_name text NOT NULL,
    mime_type text NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'media'
);
ALTER FOREIGN TABLE xfungi.media ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.media ALTER COLUMN version OPTIONS (
    column_name 'version'
);
ALTER FOREIGN TABLE xfungi.media ALTER COLUMN data OPTIONS (
    column_name 'data'
);
ALTER FOREIGN TABLE xfungi.media ALTER COLUMN description OPTIONS (
    column_name 'description'
);
ALTER FOREIGN TABLE xfungi.media ALTER COLUMN file_name OPTIONS (
    column_name 'file_name'
);
ALTER FOREIGN TABLE xfungi.media ALTER COLUMN mime_type OPTIONS (
    column_name 'mime_type'
);


--
-- Name: name; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    family_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_path text NOT NULL,
    name_rank_id bigint NOT NULL,
    name_status_id bigint NOT NULL,
    name_type_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    orth_var boolean NOT NULL,
    parent_id bigint,
    sanctioning_author_id bigint,
    second_parent_id bigint,
    simple_name character varying(250),
    simple_name_html character varying(2048),
    sort_name character varying(250),
    source_dup_of_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    status_summary character varying(50),
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    valid_record boolean NOT NULL,
    verbatim_rank character varying(50),
    uri text,
    changed_combination boolean NOT NULL,
    published_year integer,
    apni_json jsonb,
    basionym_id bigint,
    primary_instance_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN author_id OPTIONS (
    column_name 'author_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN base_author_id OPTIONS (
    column_name 'base_author_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN ex_author_id OPTIONS (
    column_name 'ex_author_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN ex_base_author_id OPTIONS (
    column_name 'ex_base_author_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN family_id OPTIONS (
    column_name 'family_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN name_path OPTIONS (
    column_name 'name_path'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN name_rank_id OPTIONS (
    column_name 'name_rank_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN name_status_id OPTIONS (
    column_name 'name_status_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN name_type_id OPTIONS (
    column_name 'name_type_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN orth_var OPTIONS (
    column_name 'orth_var'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN sanctioning_author_id OPTIONS (
    column_name 'sanctioning_author_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN second_parent_id OPTIONS (
    column_name 'second_parent_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN simple_name_html OPTIONS (
    column_name 'simple_name_html'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN sort_name OPTIONS (
    column_name 'sort_name'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN source_dup_of_id OPTIONS (
    column_name 'source_dup_of_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN status_summary OPTIONS (
    column_name 'status_summary'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN verbatim_rank OPTIONS (
    column_name 'verbatim_rank'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN changed_combination OPTIONS (
    column_name 'changed_combination'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN published_year OPTIONS (
    column_name 'published_year'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN apni_json OPTIONS (
    column_name 'apni_json'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN basionym_id OPTIONS (
    column_name 'basionym_id'
);
ALTER FOREIGN TABLE xfungi.name ALTER COLUMN primary_instance_id OPTIONS (
    column_name 'primary_instance_id'
);


--
-- Name: name_category; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_category (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(50) NOT NULL,
    rdf_id character varying(50),
    sort_order integer NOT NULL,
    max_parents_allowed integer NOT NULL,
    min_parents_required integer NOT NULL,
    parent_1_help_text text,
    parent_2_help_text text,
    requires_family boolean NOT NULL,
    requires_higher_ranked_parent boolean NOT NULL,
    requires_name_element boolean NOT NULL,
    takes_author_only boolean NOT NULL,
    takes_authors boolean NOT NULL,
    takes_cultivar_scoped_parent boolean NOT NULL,
    takes_hybrid_scoped_parent boolean NOT NULL,
    takes_name_element boolean NOT NULL,
    takes_verbatim_rank boolean NOT NULL,
    takes_rank boolean NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_category'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN max_parents_allowed OPTIONS (
    column_name 'max_parents_allowed'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN min_parents_required OPTIONS (
    column_name 'min_parents_required'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN parent_1_help_text OPTIONS (
    column_name 'parent_1_help_text'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN parent_2_help_text OPTIONS (
    column_name 'parent_2_help_text'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN requires_family OPTIONS (
    column_name 'requires_family'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN requires_higher_ranked_parent OPTIONS (
    column_name 'requires_higher_ranked_parent'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN requires_name_element OPTIONS (
    column_name 'requires_name_element'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_author_only OPTIONS (
    column_name 'takes_author_only'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_authors OPTIONS (
    column_name 'takes_authors'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_cultivar_scoped_parent OPTIONS (
    column_name 'takes_cultivar_scoped_parent'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_hybrid_scoped_parent OPTIONS (
    column_name 'takes_hybrid_scoped_parent'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_name_element OPTIONS (
    column_name 'takes_name_element'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_verbatim_rank OPTIONS (
    column_name 'takes_verbatim_rank'
);
ALTER FOREIGN TABLE xfungi.name_category ALTER COLUMN takes_rank OPTIONS (
    column_name 'takes_rank'
);


--
-- Name: name_detail_commons_vw; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_detail_commons_vw (
    cited_by_id bigint,
    entry text,
    id bigint,
    cites_id bigint,
    instance_type_name character varying(255),
    instance_type_sort_order integer,
    full_name character varying(512),
    full_name_html character varying(2048),
    name character varying(50),
    name_id bigint,
    instance_id bigint,
    name_detail_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_detail_commons_vw'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN entry OPTIONS (
    column_name 'entry'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN instance_type_name OPTIONS (
    column_name 'instance_type_name'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN instance_type_sort_order OPTIONS (
    column_name 'instance_type_sort_order'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_commons_vw ALTER COLUMN name_detail_id OPTIONS (
    column_name 'name_detail_id'
);


--
-- Name: name_detail_synonyms_vw; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_detail_synonyms_vw (
    cited_by_id bigint,
    entry text,
    id bigint,
    cites_id bigint,
    instance_type_name character varying(255),
    instance_type_sort_order integer,
    full_name character varying(512),
    full_name_html character varying(2048),
    name character varying(50),
    name_id bigint,
    instance_id bigint,
    name_detail_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_detail_synonyms_vw'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN entry OPTIONS (
    column_name 'entry'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN instance_type_name OPTIONS (
    column_name 'instance_type_name'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN instance_type_sort_order OPTIONS (
    column_name 'instance_type_sort_order'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.name_detail_synonyms_vw ALTER COLUMN name_detail_id OPTIONS (
    column_name 'name_detail_id'
);


--
-- Name: name_details_vw; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_details_vw (
    id bigint,
    full_name character varying(512),
    simple_name character varying(250),
    status_name character varying(50),
    rank_name character varying(50),
    rank_visible_in_name boolean,
    rank_sort_order integer,
    type_name character varying(255),
    type_scientific boolean,
    type_cultivar boolean,
    instance_id bigint,
    reference_year integer,
    reference_id bigint,
    reference_citation_html character varying(4000),
    instance_type_name character varying(255),
    instance_type_id bigint,
    primary_instance boolean,
    instance_standalone boolean,
    synonym_standalone boolean,
    synonym_type_name character varying(255),
    page character varying(255),
    page_qualifier character varying(255),
    cited_by_id bigint,
    cites_id bigint,
    primary_instance_first text,
    synonym_full_name character varying(512),
    author_name character varying(1000),
    name_id bigint,
    sort_name character varying(250),
    entry text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_details_vw'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN status_name OPTIONS (
    column_name 'status_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN rank_name OPTIONS (
    column_name 'rank_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN rank_visible_in_name OPTIONS (
    column_name 'rank_visible_in_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN rank_sort_order OPTIONS (
    column_name 'rank_sort_order'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN type_name OPTIONS (
    column_name 'type_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN type_scientific OPTIONS (
    column_name 'type_scientific'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN type_cultivar OPTIONS (
    column_name 'type_cultivar'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN reference_year OPTIONS (
    column_name 'reference_year'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN reference_citation_html OPTIONS (
    column_name 'reference_citation_html'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN instance_type_name OPTIONS (
    column_name 'instance_type_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN instance_type_id OPTIONS (
    column_name 'instance_type_id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN primary_instance OPTIONS (
    column_name 'primary_instance'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN instance_standalone OPTIONS (
    column_name 'instance_standalone'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN synonym_standalone OPTIONS (
    column_name 'synonym_standalone'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN synonym_type_name OPTIONS (
    column_name 'synonym_type_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN page OPTIONS (
    column_name 'page'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN page_qualifier OPTIONS (
    column_name 'page_qualifier'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN primary_instance_first OPTIONS (
    column_name 'primary_instance_first'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN synonym_full_name OPTIONS (
    column_name 'synonym_full_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN author_name OPTIONS (
    column_name 'author_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN sort_name OPTIONS (
    column_name 'sort_name'
);
ALTER FOREIGN TABLE xfungi.name_details_vw ALTER COLUMN entry OPTIONS (
    column_name 'entry'
);


--
-- Name: name_group; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_group (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(50),
    rdf_id character varying(50)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_group'
);
ALTER FOREIGN TABLE xfungi.name_group ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_group ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name_group ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.name_group ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_group ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: name_mv; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_mv (
    name_id bigint,
    basionym_id bigint,
    scientific_name character varying(512),
    scientific_name_html character varying(2048),
    canonical_name character varying(250),
    canonical_name_html character varying(2048),
    name_element character varying(255),
    scientific_name_id text,
    name_type character varying(50),
    nomenclatural_status character varying,
    scientific_name_authorship text,
    changed_combination boolean,
    autonym boolean,
    hybrid boolean,
    cultivar boolean,
    formula boolean,
    scientific boolean,
    nom_inval boolean,
    nom_illeg boolean,
    name_published_in text,
    name_published_in_id text,
    name_published_in_year integer,
    name_instance_type character varying(255),
    name_according_to_id text,
    name_according_to text,
    original_name_usage character varying(512),
    original_name_usage_id text,
    original_name_usage_year text,
    type_citation text,
    kingdom text,
    family text,
    uninomial character varying,
    infrageneric_epithet character varying,
    generic_name text,
    specific_epithet text,
    infraspecific_epithet character varying,
    cultivar_epithet character varying,
    rank_rdf_id character varying(50),
    taxon_rank character varying(50),
    taxon_rank_sort_order integer,
    taxon_rank_abbreviation character varying(20),
    first_hybrid_parent_name character varying(512),
    first_hybrid_parent_name_id text,
    second_hybrid_parent_name character varying(512),
    second_hybrid_parent_name_id text,
    created timestamp with time zone,
    modified timestamp with time zone,
    nomenclatural_code text,
    dataset_name character varying(5000),
    taxonomic_status text,
    status_according_to text,
    license text,
    cc_attribution_iri text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_mv'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN basionym_id OPTIONS (
    column_name 'basionym_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN scientific_name OPTIONS (
    column_name 'scientific_name'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN scientific_name_html OPTIONS (
    column_name 'scientific_name_html'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN canonical_name OPTIONS (
    column_name 'canonical_name'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN canonical_name_html OPTIONS (
    column_name 'canonical_name_html'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN scientific_name_id OPTIONS (
    column_name 'scientific_name_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_type OPTIONS (
    column_name 'name_type'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN scientific_name_authorship OPTIONS (
    column_name 'scientific_name_authorship'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN changed_combination OPTIONS (
    column_name 'changed_combination'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_published_in OPTIONS (
    column_name 'name_published_in'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_published_in_id OPTIONS (
    column_name 'name_published_in_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_published_in_year OPTIONS (
    column_name 'name_published_in_year'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_instance_type OPTIONS (
    column_name 'name_instance_type'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_according_to_id OPTIONS (
    column_name 'name_according_to_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN name_according_to OPTIONS (
    column_name 'name_according_to'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN original_name_usage OPTIONS (
    column_name 'original_name_usage'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN original_name_usage_id OPTIONS (
    column_name 'original_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN original_name_usage_year OPTIONS (
    column_name 'original_name_usage_year'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN type_citation OPTIONS (
    column_name 'type_citation'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN uninomial OPTIONS (
    column_name 'uninomial'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN infrageneric_epithet OPTIONS (
    column_name 'infrageneric_epithet'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN generic_name OPTIONS (
    column_name 'generic_name'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN specific_epithet OPTIONS (
    column_name 'specific_epithet'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN infraspecific_epithet OPTIONS (
    column_name 'infraspecific_epithet'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN cultivar_epithet OPTIONS (
    column_name 'cultivar_epithet'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN rank_rdf_id OPTIONS (
    column_name 'rank_rdf_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN taxon_rank OPTIONS (
    column_name 'taxon_rank'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN taxon_rank_sort_order OPTIONS (
    column_name 'taxon_rank_sort_order'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN taxon_rank_abbreviation OPTIONS (
    column_name 'taxon_rank_abbreviation'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN first_hybrid_parent_name OPTIONS (
    column_name 'first_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN first_hybrid_parent_name_id OPTIONS (
    column_name 'first_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN second_hybrid_parent_name OPTIONS (
    column_name 'second_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN second_hybrid_parent_name_id OPTIONS (
    column_name 'second_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN nomenclatural_code OPTIONS (
    column_name 'nomenclatural_code'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN dataset_name OPTIONS (
    column_name 'dataset_name'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN taxonomic_status OPTIONS (
    column_name 'taxonomic_status'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN status_according_to OPTIONS (
    column_name 'status_according_to'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.name_mv ALTER COLUMN cc_attribution_iri OPTIONS (
    column_name 'cc_attribution_iri'
);


--
-- Name: name_rank; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_rank (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    abbrev character varying(20) NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    has_parent boolean NOT NULL,
    italicize boolean NOT NULL,
    major boolean NOT NULL,
    name character varying(50) NOT NULL,
    name_group_id bigint NOT NULL,
    parent_rank_id bigint,
    rdf_id character varying(50),
    sort_order integer NOT NULL,
    use_verbatim_rank boolean NOT NULL,
    visible_in_name boolean NOT NULL,
    display_name text NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_rank'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN abbrev OPTIONS (
    column_name 'abbrev'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN has_parent OPTIONS (
    column_name 'has_parent'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN italicize OPTIONS (
    column_name 'italicize'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN major OPTIONS (
    column_name 'major'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN name_group_id OPTIONS (
    column_name 'name_group_id'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN parent_rank_id OPTIONS (
    column_name 'parent_rank_id'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN use_verbatim_rank OPTIONS (
    column_name 'use_verbatim_rank'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN visible_in_name OPTIONS (
    column_name 'visible_in_name'
);
ALTER FOREIGN TABLE xfungi.name_rank ALTER COLUMN display_name OPTIONS (
    column_name 'display_name'
);


--
-- Name: name_resources; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_resources (
    resource_id bigint NOT NULL,
    name_id bigint NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_resources'
);
ALTER FOREIGN TABLE xfungi.name_resources ALTER COLUMN resource_id OPTIONS (
    column_name 'resource_id'
);
ALTER FOREIGN TABLE xfungi.name_resources ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);


--
-- Name: name_status; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_status (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    display boolean NOT NULL,
    name character varying(50),
    name_group_id bigint NOT NULL,
    name_status_id bigint,
    nom_illeg boolean NOT NULL,
    nom_inval boolean NOT NULL,
    rdf_id character varying(50)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_status'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN display OPTIONS (
    column_name 'display'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN name_group_id OPTIONS (
    column_name 'name_group_id'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN name_status_id OPTIONS (
    column_name 'name_status_id'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xfungi.name_status ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: name_tag; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_tag (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    name character varying(255) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_tag'
);
ALTER FOREIGN TABLE xfungi.name_tag ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_tag ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name_tag ALTER COLUMN name OPTIONS (
    column_name 'name'
);


--
-- Name: name_tag_name; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_tag_name (
    name_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_tag_name'
);
ALTER FOREIGN TABLE xfungi.name_tag_name ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.name_tag_name ALTER COLUMN tag_id OPTIONS (
    column_name 'tag_id'
);
ALTER FOREIGN TABLE xfungi.name_tag_name ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.name_tag_name ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.name_tag_name ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.name_tag_name ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: name_type; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    autonym boolean NOT NULL,
    connector character varying(1),
    cultivar boolean NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    formula boolean NOT NULL,
    hybrid boolean NOT NULL,
    name character varying(255) NOT NULL,
    name_category_id bigint NOT NULL,
    name_group_id bigint NOT NULL,
    rdf_id character varying(50),
    scientific boolean NOT NULL,
    sort_order integer NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_type'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN connector OPTIONS (
    column_name 'connector'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN name_category_id OPTIONS (
    column_name 'name_category_id'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN name_group_id OPTIONS (
    column_name 'name_group_id'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xfungi.name_type ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: name_view; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.name_view (
    name_id bigint,
    "scientificNameID" text,
    "nameType" character varying(50),
    "scientificName" character varying(512),
    "scientificNameHTML" character varying(2048),
    "canonicalName" character varying(250),
    "canonicalNameHTML" character varying(2048),
    "nameElement" character varying(255),
    "nomenclaturalStatus" character varying,
    "scientificNameAuthorship" text,
    autonym boolean,
    hybrid boolean,
    cultivar boolean,
    formula boolean,
    scientific boolean,
    "nomInval" boolean,
    "nomIlleg" boolean,
    "namePublishedIn" text,
    "namePublishedInID" text,
    "namePublishedInYear" integer,
    "nameInstanceType" character varying(255),
    "nameAccordingToID" text,
    "nameAccordingTo" text,
    "originalNameUsage" character varying(512),
    "originalNameUsageID" text,
    "originalNameUsageYear" text,
    "typeCitation" text,
    kingdom text,
    family text,
    "genericName" text,
    "specificEpithet" text,
    "infraspecificEpithet" character varying,
    "cultivarEpithet" character varying,
    "taxonRank" character varying(50),
    "taxonRankSortOrder" integer,
    "taxonRankAbbreviation" character varying(20),
    "firstHybridParentName" character varying(512),
    "firstHybridParentNameID" text,
    "secondHybridParentName" character varying(512),
    "secondHybridParentNameID" text,
    created timestamp with time zone,
    modified timestamp with time zone,
    "nomenclaturalCode" text,
    "datasetName" character varying(5000),
    "taxonomicStatus" text,
    "statusAccordingTo" text,
    license text,
    "ccAttributionIRI" text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'name_view'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "scientificNameID" OPTIONS (
    column_name 'scientificNameID'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nameType" OPTIONS (
    column_name 'nameType'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "scientificName" OPTIONS (
    column_name 'scientificName'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "scientificNameHTML" OPTIONS (
    column_name 'scientificNameHTML'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "canonicalName" OPTIONS (
    column_name 'canonicalName'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "canonicalNameHTML" OPTIONS (
    column_name 'canonicalNameHTML'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nameElement" OPTIONS (
    column_name 'nameElement'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nomenclaturalStatus" OPTIONS (
    column_name 'nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "scientificNameAuthorship" OPTIONS (
    column_name 'scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nomInval" OPTIONS (
    column_name 'nomInval'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nomIlleg" OPTIONS (
    column_name 'nomIlleg'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "namePublishedIn" OPTIONS (
    column_name 'namePublishedIn'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "namePublishedInID" OPTIONS (
    column_name 'namePublishedInID'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "namePublishedInYear" OPTIONS (
    column_name 'namePublishedInYear'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nameInstanceType" OPTIONS (
    column_name 'nameInstanceType'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nameAccordingToID" OPTIONS (
    column_name 'nameAccordingToID'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nameAccordingTo" OPTIONS (
    column_name 'nameAccordingTo'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "originalNameUsage" OPTIONS (
    column_name 'originalNameUsage'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "originalNameUsageID" OPTIONS (
    column_name 'originalNameUsageID'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "originalNameUsageYear" OPTIONS (
    column_name 'originalNameUsageYear'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "typeCitation" OPTIONS (
    column_name 'typeCitation'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "genericName" OPTIONS (
    column_name 'genericName'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "specificEpithet" OPTIONS (
    column_name 'specificEpithet'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "infraspecificEpithet" OPTIONS (
    column_name 'infraspecificEpithet'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "cultivarEpithet" OPTIONS (
    column_name 'cultivarEpithet'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "taxonRank" OPTIONS (
    column_name 'taxonRank'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "taxonRankSortOrder" OPTIONS (
    column_name 'taxonRankSortOrder'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "taxonRankAbbreviation" OPTIONS (
    column_name 'taxonRankAbbreviation'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "firstHybridParentName" OPTIONS (
    column_name 'firstHybridParentName'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "firstHybridParentNameID" OPTIONS (
    column_name 'firstHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "secondHybridParentName" OPTIONS (
    column_name 'secondHybridParentName'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "secondHybridParentNameID" OPTIONS (
    column_name 'secondHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "nomenclaturalCode" OPTIONS (
    column_name 'nomenclaturalCode'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "datasetName" OPTIONS (
    column_name 'datasetName'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "taxonomicStatus" OPTIONS (
    column_name 'taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "statusAccordingTo" OPTIONS (
    column_name 'statusAccordingTo'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.name_view ALTER COLUMN "ccAttributionIRI" OPTIONS (
    column_name 'ccAttributionIRI'
);


--
-- Name: namespace; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.namespace (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(255) NOT NULL,
    rdf_id character varying(50)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'namespace'
);
ALTER FOREIGN TABLE xfungi.namespace ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.namespace ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.namespace ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.namespace ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.namespace ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: notification; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.notification (
    id bigint NOT NULL,
    version bigint NOT NULL,
    message character varying(255) NOT NULL,
    object_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'notification'
);
ALTER FOREIGN TABLE xfungi.notification ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.notification ALTER COLUMN version OPTIONS (
    column_name 'version'
);
ALTER FOREIGN TABLE xfungi.notification ALTER COLUMN message OPTIONS (
    column_name 'message'
);
ALTER FOREIGN TABLE xfungi.notification ALTER COLUMN object_id OPTIONS (
    column_name 'object_id'
);


--
-- Name: nsl4415_temp_tve_mapper; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.nsl4415_temp_tve_mapper (
    taxon_id bigint,
    taxon_mapper_id bigint,
    tree_element_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'nsl4415_temp_tve_mapper'
);
ALTER FOREIGN TABLE xfungi.nsl4415_temp_tve_mapper ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.nsl4415_temp_tve_mapper ALTER COLUMN taxon_mapper_id OPTIONS (
    column_name 'taxon_mapper_id'
);
ALTER FOREIGN TABLE xfungi.nsl4415_temp_tve_mapper ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);


--
-- Name: ref_author_role; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.ref_author_role (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(255) NOT NULL,
    rdf_id character varying(50)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'ref_author_role'
);
ALTER FOREIGN TABLE xfungi.ref_author_role ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.ref_author_role ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.ref_author_role ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.ref_author_role ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.ref_author_role ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: ref_type; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.ref_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(50) NOT NULL,
    parent_id bigint,
    parent_optional boolean NOT NULL,
    rdf_id character varying(50),
    use_parent_details boolean NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'ref_type'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN parent_optional OPTIONS (
    column_name 'parent_optional'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xfungi.ref_type ALTER COLUMN use_parent_details OPTIONS (
    column_name 'use_parent_details'
);


--
-- Name: reference; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.reference (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
    published boolean NOT NULL,
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
    valid_record boolean NOT NULL,
    verbatim_author character varying(1000),
    verbatim_citation character varying(2000),
    verbatim_reference character varying(1000),
    volume character varying(100),
    year integer,
    uri text,
    iso_publication_date character varying(10)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'reference'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN abbrev_title OPTIONS (
    column_name 'abbrev_title'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN author_id OPTIONS (
    column_name 'author_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN bhl_url OPTIONS (
    column_name 'bhl_url'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN citation OPTIONS (
    column_name 'citation'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN citation_html OPTIONS (
    column_name 'citation_html'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN display_title OPTIONS (
    column_name 'display_title'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN doi OPTIONS (
    column_name 'doi'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN edition OPTIONS (
    column_name 'edition'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN isbn OPTIONS (
    column_name 'isbn'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN issn OPTIONS (
    column_name 'issn'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN language_id OPTIONS (
    column_name 'language_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN pages OPTIONS (
    column_name 'pages'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN publication_date OPTIONS (
    column_name 'publication_date'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN published OPTIONS (
    column_name 'published'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN published_location OPTIONS (
    column_name 'published_location'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN publisher OPTIONS (
    column_name 'publisher'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN ref_author_role_id OPTIONS (
    column_name 'ref_author_role_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN ref_type_id OPTIONS (
    column_name 'ref_type_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN title OPTIONS (
    column_name 'title'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN tl2 OPTIONS (
    column_name 'tl2'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN verbatim_author OPTIONS (
    column_name 'verbatim_author'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN verbatim_citation OPTIONS (
    column_name 'verbatim_citation'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN verbatim_reference OPTIONS (
    column_name 'verbatim_reference'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN volume OPTIONS (
    column_name 'volume'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN year OPTIONS (
    column_name 'year'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);
ALTER FOREIGN TABLE xfungi.reference ALTER COLUMN iso_publication_date OPTIONS (
    column_name 'iso_publication_date'
);


--
-- Name: resource; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.resource (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    path character varying(2400) NOT NULL,
    site_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    resource_type_id bigint NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'resource'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN path OPTIONS (
    column_name 'path'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN site_id OPTIONS (
    column_name 'site_id'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.resource ALTER COLUMN resource_type_id OPTIONS (
    column_name 'resource_type_id'
);


--
-- Name: resource_type; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.resource_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    css_icon text,
    deprecated boolean NOT NULL,
    description text NOT NULL,
    display boolean NOT NULL,
    media_icon_id bigint,
    name text NOT NULL,
    rdf_id character varying(50)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'resource_type'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN css_icon OPTIONS (
    column_name 'css_icon'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN description OPTIONS (
    column_name 'description'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN display OPTIONS (
    column_name 'display'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN media_icon_id OPTIONS (
    column_name 'media_icon_id'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.resource_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: shard_config; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.shard_config (
    id bigint NOT NULL,
    deprecated boolean NOT NULL,
    name character varying(255) NOT NULL,
    use_notes character varying(255),
    value character varying(5000) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'shard_config'
);
ALTER FOREIGN TABLE xfungi.shard_config ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.shard_config ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xfungi.shard_config ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.shard_config ALTER COLUMN use_notes OPTIONS (
    column_name 'use_notes'
);
ALTER FOREIGN TABLE xfungi.shard_config ALTER COLUMN value OPTIONS (
    column_name 'value'
);


--
-- Name: site; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.site (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    description character varying(1000) NOT NULL,
    name character varying(100) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    url character varying(500) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'site'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN description OPTIONS (
    column_name 'description'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.site ALTER COLUMN url OPTIONS (
    column_name 'url'
);


--
-- Name: taxon_mv; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.taxon_mv (
    taxon_id text,
    name_type character varying(255),
    accepted_name_usage_id text,
    accepted_name_usage character varying(512),
    nomenclatural_status character varying,
    nom_illeg boolean,
    nom_inval boolean,
    taxonomic_status character varying,
    pro_parte boolean,
    scientific_name character varying(512),
    scientific_name_id text,
    canonical_name character varying(250),
    scientific_name_authorship text,
    parent_name_usage_id text,
    taxon_rank character varying(50),
    taxon_rank_sort_order integer,
    kingdom text,
    class text,
    subclass text,
    family text,
    taxon_concept_id text,
    name_according_to character varying(4000),
    name_according_to_id text,
    taxon_remarks text,
    taxon_distribution text,
    higher_classification text,
    first_hybrid_parent_name character varying,
    first_hybrid_parent_name_id text,
    second_hybrid_parent_name character varying,
    second_hybrid_parent_name_id text,
    nomenclatural_code text,
    created timestamp with time zone,
    modified timestamp with time zone,
    dataset_name text,
    dataset_id text,
    license text,
    cc_attribution_iri text,
    tree_version_id bigint,
    tree_element_id bigint,
    instance_id bigint,
    name_id bigint,
    homotypic boolean,
    heterotypic boolean,
    misapplied boolean,
    relationship boolean,
    synonym boolean,
    excluded_name boolean,
    accepted boolean,
    accepted_id bigint,
    rank_rdf_id character varying(50),
    name_space character varying(5000),
    tree_description character varying(5000),
    tree_label character varying(5000)
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'taxon_mv'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN name_type OPTIONS (
    column_name 'name_type'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN accepted_name_usage_id OPTIONS (
    column_name 'accepted_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN accepted_name_usage OPTIONS (
    column_name 'accepted_name_usage'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxonomic_status OPTIONS (
    column_name 'taxonomic_status'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN pro_parte OPTIONS (
    column_name 'pro_parte'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN scientific_name OPTIONS (
    column_name 'scientific_name'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN scientific_name_id OPTIONS (
    column_name 'scientific_name_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN canonical_name OPTIONS (
    column_name 'canonical_name'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN scientific_name_authorship OPTIONS (
    column_name 'scientific_name_authorship'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN parent_name_usage_id OPTIONS (
    column_name 'parent_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxon_rank OPTIONS (
    column_name 'taxon_rank'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxon_rank_sort_order OPTIONS (
    column_name 'taxon_rank_sort_order'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN class OPTIONS (
    column_name 'class'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN subclass OPTIONS (
    column_name 'subclass'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxon_concept_id OPTIONS (
    column_name 'taxon_concept_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN name_according_to OPTIONS (
    column_name 'name_according_to'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN name_according_to_id OPTIONS (
    column_name 'name_according_to_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxon_remarks OPTIONS (
    column_name 'taxon_remarks'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN taxon_distribution OPTIONS (
    column_name 'taxon_distribution'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN higher_classification OPTIONS (
    column_name 'higher_classification'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN first_hybrid_parent_name OPTIONS (
    column_name 'first_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN first_hybrid_parent_name_id OPTIONS (
    column_name 'first_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN second_hybrid_parent_name OPTIONS (
    column_name 'second_hybrid_parent_name'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN second_hybrid_parent_name_id OPTIONS (
    column_name 'second_hybrid_parent_name_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN nomenclatural_code OPTIONS (
    column_name 'nomenclatural_code'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN dataset_name OPTIONS (
    column_name 'dataset_name'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN dataset_id OPTIONS (
    column_name 'dataset_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN cc_attribution_iri OPTIONS (
    column_name 'cc_attribution_iri'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN homotypic OPTIONS (
    column_name 'homotypic'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN heterotypic OPTIONS (
    column_name 'heterotypic'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN misapplied OPTIONS (
    column_name 'misapplied'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN relationship OPTIONS (
    column_name 'relationship'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN synonym OPTIONS (
    column_name 'synonym'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN excluded_name OPTIONS (
    column_name 'excluded_name'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN accepted OPTIONS (
    column_name 'accepted'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN accepted_id OPTIONS (
    column_name 'accepted_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN rank_rdf_id OPTIONS (
    column_name 'rank_rdf_id'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN name_space OPTIONS (
    column_name 'name_space'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN tree_description OPTIONS (
    column_name 'tree_description'
);
ALTER FOREIGN TABLE xfungi.taxon_mv ALTER COLUMN tree_label OPTIONS (
    column_name 'tree_label'
);


--
-- Name: taxon_view; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.taxon_view (
    "taxonID" text,
    "nameType" character varying(255),
    "acceptedNameUsageID" text,
    "acceptedNameUsage" character varying(512),
    "nomenclaturalStatus" character varying,
    "nomIlleg" boolean,
    "nomInval" boolean,
    "taxonomicStatus" character varying,
    "proParte" boolean,
    "scientificName" character varying(512),
    "scientificNameID" text,
    "canonicalName" character varying(250),
    "scientificNameAuthorship" text,
    "parentNameUsageID" text,
    "taxonRank" character varying(50),
    "taxonRankSortOrder" integer,
    kingdom text,
    class text,
    subclass text,
    family text,
    "taxonConceptID" text,
    "nameAccordingTo" character varying(4000),
    "nameAccordingToID" text,
    "taxonRemarks" text,
    "taxonDistribution" text,
    "higherClassification" text,
    "firstHybridParentName" character varying,
    "firstHybridParentNameID" text,
    "secondHybridParentName" character varying,
    "secondHybridParentNameID" text,
    "nomenclaturalCode" text,
    created timestamp with time zone,
    modified timestamp with time zone,
    "datasetName" text,
    "dataSetID" text,
    license text,
    "ccAttributionIRI" text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'taxon_view'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonID" OPTIONS (
    column_name 'taxonID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nameType" OPTIONS (
    column_name 'nameType'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "acceptedNameUsageID" OPTIONS (
    column_name 'acceptedNameUsageID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "acceptedNameUsage" OPTIONS (
    column_name 'acceptedNameUsage'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nomenclaturalStatus" OPTIONS (
    column_name 'nomenclaturalStatus'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nomIlleg" OPTIONS (
    column_name 'nomIlleg'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nomInval" OPTIONS (
    column_name 'nomInval'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonomicStatus" OPTIONS (
    column_name 'taxonomicStatus'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "proParte" OPTIONS (
    column_name 'proParte'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "scientificName" OPTIONS (
    column_name 'scientificName'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "scientificNameID" OPTIONS (
    column_name 'scientificNameID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "canonicalName" OPTIONS (
    column_name 'canonicalName'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "scientificNameAuthorship" OPTIONS (
    column_name 'scientificNameAuthorship'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "parentNameUsageID" OPTIONS (
    column_name 'parentNameUsageID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonRank" OPTIONS (
    column_name 'taxonRank'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonRankSortOrder" OPTIONS (
    column_name 'taxonRankSortOrder'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN class OPTIONS (
    column_name 'class'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN subclass OPTIONS (
    column_name 'subclass'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonConceptID" OPTIONS (
    column_name 'taxonConceptID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nameAccordingTo" OPTIONS (
    column_name 'nameAccordingTo'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nameAccordingToID" OPTIONS (
    column_name 'nameAccordingToID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonRemarks" OPTIONS (
    column_name 'taxonRemarks'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "taxonDistribution" OPTIONS (
    column_name 'taxonDistribution'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "higherClassification" OPTIONS (
    column_name 'higherClassification'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "firstHybridParentName" OPTIONS (
    column_name 'firstHybridParentName'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "firstHybridParentNameID" OPTIONS (
    column_name 'firstHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "secondHybridParentName" OPTIONS (
    column_name 'secondHybridParentName'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "secondHybridParentNameID" OPTIONS (
    column_name 'secondHybridParentNameID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "nomenclaturalCode" OPTIONS (
    column_name 'nomenclaturalCode'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "datasetName" OPTIONS (
    column_name 'datasetName'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "dataSetID" OPTIONS (
    column_name 'dataSetID'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.taxon_view ALTER COLUMN "ccAttributionIRI" OPTIONS (
    column_name 'ccAttributionIRI'
);


--
-- Name: tede_old; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tede_old (
    dist_entry_id bigint NOT NULL,
    tree_element_id bigint NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tede_old'
);
ALTER FOREIGN TABLE xfungi.tede_old ALTER COLUMN dist_entry_id OPTIONS (
    column_name 'dist_entry_id'
);
ALTER FOREIGN TABLE xfungi.tede_old ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);


--
-- Name: tmp_distribution; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tmp_distribution (
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
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tmp_distribution'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN dist OPTIONS (
    column_name 'dist'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN apc_te_id OPTIONS (
    column_name 'apc_te_id'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN wa OPTIONS (
    column_name 'wa'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN coi OPTIONS (
    column_name 'coi'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN chi OPTIONS (
    column_name 'chi'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN ar OPTIONS (
    column_name 'ar'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN cai OPTIONS (
    column_name 'cai'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN nt OPTIONS (
    column_name 'nt'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN sa OPTIONS (
    column_name 'sa'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN qld OPTIONS (
    column_name 'qld'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN csi OPTIONS (
    column_name 'csi'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN nsw OPTIONS (
    column_name 'nsw'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN lhi OPTIONS (
    column_name 'lhi'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN ni OPTIONS (
    column_name 'ni'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN act OPTIONS (
    column_name 'act'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN vic OPTIONS (
    column_name 'vic'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN tas OPTIONS (
    column_name 'tas'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN hi OPTIONS (
    column_name 'hi'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN mdi OPTIONS (
    column_name 'mdi'
);
ALTER FOREIGN TABLE xfungi.tmp_distribution ALTER COLUMN mi OPTIONS (
    column_name 'mi'
);


--
-- Name: tnu_index_v; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tnu_index_v (
    family text,
    tnu_label text,
    accepted_name_usage character varying(512),
    dct_identifier text,
    taxonomic_status character varying(50),
    accepted_name_usage_id text,
    primary_usage_id text,
    original_name_usage_id text,
    name_according_to character varying(4000),
    tnu_publication_date character varying(10),
    name_according_to_id text,
    scientific_name_id text,
    scientific_name character varying(512),
    canonical_name character varying(250),
    scientific_name_authorship text,
    taxon_rank character varying(50),
    name_published_in_year integer,
    nomenclatural_status character varying,
    is_changed_combination boolean,
    is_primary_usage boolean,
    is_relationship boolean,
    is_homotypic_usage boolean,
    is_heterotypic_usage boolean,
    dataset_name character varying(5000),
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    cited_by_id bigint,
    cites_id bigint,
    license text,
    higher_classification text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tnu_index_v'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN tnu_label OPTIONS (
    column_name 'tnu_label'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN accepted_name_usage OPTIONS (
    column_name 'accepted_name_usage'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN dct_identifier OPTIONS (
    column_name 'dct_identifier'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN taxonomic_status OPTIONS (
    column_name 'taxonomic_status'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN accepted_name_usage_id OPTIONS (
    column_name 'accepted_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN primary_usage_id OPTIONS (
    column_name 'primary_usage_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN original_name_usage_id OPTIONS (
    column_name 'original_name_usage_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN name_according_to OPTIONS (
    column_name 'name_according_to'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN tnu_publication_date OPTIONS (
    column_name 'tnu_publication_date'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN name_according_to_id OPTIONS (
    column_name 'name_according_to_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN scientific_name_id OPTIONS (
    column_name 'scientific_name_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN scientific_name OPTIONS (
    column_name 'scientific_name'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN canonical_name OPTIONS (
    column_name 'canonical_name'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN scientific_name_authorship OPTIONS (
    column_name 'scientific_name_authorship'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN taxon_rank OPTIONS (
    column_name 'taxon_rank'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN name_published_in_year OPTIONS (
    column_name 'name_published_in_year'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN is_changed_combination OPTIONS (
    column_name 'is_changed_combination'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN is_primary_usage OPTIONS (
    column_name 'is_primary_usage'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN is_relationship OPTIONS (
    column_name 'is_relationship'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN is_homotypic_usage OPTIONS (
    column_name 'is_homotypic_usage'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN is_heterotypic_usage OPTIONS (
    column_name 'is_heterotypic_usage'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN dataset_name OPTIONS (
    column_name 'dataset_name'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xfungi.tnu_index_v ALTER COLUMN higher_classification OPTIONS (
    column_name 'higher_classification'
);


--
-- Name: tree; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tree (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    accepted_tree boolean NOT NULL,
    config jsonb,
    current_tree_version_id bigint,
    default_draft_tree_version_id bigint,
    description_html text NOT NULL,
    group_name text NOT NULL,
    host_name text NOT NULL,
    link_to_home_page text,
    name text NOT NULL,
    reference_id bigint
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tree'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN accepted_tree OPTIONS (
    column_name 'accepted_tree'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN config OPTIONS (
    column_name 'config'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN current_tree_version_id OPTIONS (
    column_name 'current_tree_version_id'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN default_draft_tree_version_id OPTIONS (
    column_name 'default_draft_tree_version_id'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN group_name OPTIONS (
    column_name 'group_name'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN host_name OPTIONS (
    column_name 'host_name'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN link_to_home_page OPTIONS (
    column_name 'link_to_home_page'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.tree ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);


--
-- Name: tree_element; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tree_element (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    display_html text NOT NULL,
    excluded boolean NOT NULL,
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
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tree_element'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN display_html OPTIONS (
    column_name 'display_html'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN excluded OPTIONS (
    column_name 'excluded'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN instance_link OPTIONS (
    column_name 'instance_link'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN name_link OPTIONS (
    column_name 'name_link'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN previous_element_id OPTIONS (
    column_name 'previous_element_id'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN profile OPTIONS (
    column_name 'profile'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN rank OPTIONS (
    column_name 'rank'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN source_element_link OPTIONS (
    column_name 'source_element_link'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN source_shard OPTIONS (
    column_name 'source_shard'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN synonyms OPTIONS (
    column_name 'synonyms'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN synonyms_html OPTIONS (
    column_name 'synonyms_html'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.tree_element ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: tree_element_distribution_entries; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tree_element_distribution_entries (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    dist_entry_id bigint NOT NULL,
    tree_element_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tree_element_distribution_entries'
);
ALTER FOREIGN TABLE xfungi.tree_element_distribution_entries ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.tree_element_distribution_entries ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.tree_element_distribution_entries ALTER COLUMN dist_entry_id OPTIONS (
    column_name 'dist_entry_id'
);
ALTER FOREIGN TABLE xfungi.tree_element_distribution_entries ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xfungi.tree_element_distribution_entries ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.tree_element_distribution_entries ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: tree_version; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tree_version (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    draft_name text NOT NULL,
    log_entry text,
    previous_version_id bigint,
    published boolean NOT NULL,
    published_at timestamp with time zone,
    published_by character varying(100),
    tree_id bigint NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tree_version'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN draft_name OPTIONS (
    column_name 'draft_name'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN log_entry OPTIONS (
    column_name 'log_entry'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN previous_version_id OPTIONS (
    column_name 'previous_version_id'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN published OPTIONS (
    column_name 'published'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN published_at OPTIONS (
    column_name 'published_at'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN published_by OPTIONS (
    column_name 'published_by'
);
ALTER FOREIGN TABLE xfungi.tree_version ALTER COLUMN tree_id OPTIONS (
    column_name 'tree_id'
);


--
-- Name: tree_version_element; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tree_version_element (
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
    merge_conflict boolean NOT NULL
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tree_version_element'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN element_link OPTIONS (
    column_name 'element_link'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN depth OPTIONS (
    column_name 'depth'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN name_path OPTIONS (
    column_name 'name_path'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN taxon_link OPTIONS (
    column_name 'taxon_link'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN tree_path OPTIONS (
    column_name 'tree_path'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xfungi.tree_version_element ALTER COLUMN merge_conflict OPTIONS (
    column_name 'merge_conflict'
);


--
-- Name: tree_vw; Type: FOREIGN TABLE; Schema: xfungi; Owner: -
--

CREATE FOREIGN TABLE xfungi.tree_vw (
    tree_id bigint,
    accepted_tree boolean,
    config jsonb,
    current_tree_version_id bigint,
    default_draft_tree_version_id bigint,
    description_html text,
    group_name text,
    host_name text,
    link_to_home_page text,
    name text,
    reference_id bigint,
    tree_version_id bigint,
    draft_name text,
    log_entry text,
    previous_version_id bigint,
    published boolean,
    published_at timestamp with time zone,
    published_by character varying(100),
    element_link text,
    depth integer,
    name_path text,
    parent_id text,
    taxon_id bigint,
    taxon_link text,
    tree_element_id_fk bigint,
    tree_path text,
    tree_version_id_fk bigint,
    merge_conflict boolean,
    tree_element_id bigint,
    display_html text,
    excluded boolean,
    instance_id bigint,
    instance_link text,
    name_element character varying(255),
    name_id bigint,
    name_link text,
    previous_element_id bigint,
    profile jsonb,
    rank character varying(50),
    simple_name text,
    source_element_link text,
    source_shard text,
    synonyms jsonb,
    synonyms_html text
)
SERVER xfungi
OPTIONS (
    schema_name 'public',
    table_name 'tree_vw'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN tree_id OPTIONS (
    column_name 'tree_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN accepted_tree OPTIONS (
    column_name 'accepted_tree'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN config OPTIONS (
    column_name 'config'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN current_tree_version_id OPTIONS (
    column_name 'current_tree_version_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN default_draft_tree_version_id OPTIONS (
    column_name 'default_draft_tree_version_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN group_name OPTIONS (
    column_name 'group_name'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN host_name OPTIONS (
    column_name 'host_name'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN link_to_home_page OPTIONS (
    column_name 'link_to_home_page'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN draft_name OPTIONS (
    column_name 'draft_name'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN log_entry OPTIONS (
    column_name 'log_entry'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN previous_version_id OPTIONS (
    column_name 'previous_version_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN published OPTIONS (
    column_name 'published'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN published_at OPTIONS (
    column_name 'published_at'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN published_by OPTIONS (
    column_name 'published_by'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN element_link OPTIONS (
    column_name 'element_link'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN depth OPTIONS (
    column_name 'depth'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN name_path OPTIONS (
    column_name 'name_path'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN taxon_link OPTIONS (
    column_name 'taxon_link'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN tree_element_id_fk OPTIONS (
    column_name 'tree_element_id_fk'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN tree_path OPTIONS (
    column_name 'tree_path'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN tree_version_id_fk OPTIONS (
    column_name 'tree_version_id_fk'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN merge_conflict OPTIONS (
    column_name 'merge_conflict'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN display_html OPTIONS (
    column_name 'display_html'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN excluded OPTIONS (
    column_name 'excluded'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN instance_link OPTIONS (
    column_name 'instance_link'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN name_link OPTIONS (
    column_name 'name_link'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN previous_element_id OPTIONS (
    column_name 'previous_element_id'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN profile OPTIONS (
    column_name 'profile'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN rank OPTIONS (
    column_name 'rank'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN source_element_link OPTIONS (
    column_name 'source_element_link'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN source_shard OPTIONS (
    column_name 'source_shard'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN synonyms OPTIONS (
    column_name 'synonyms'
);
ALTER FOREIGN TABLE xfungi.tree_vw ALTER COLUMN synonyms_html OPTIONS (
    column_name 'synonyms_html'
);


--
-- Name: author; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.author (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
    valid_record boolean NOT NULL,
    uri text
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'author'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN abbrev OPTIONS (
    column_name 'abbrev'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN date_range OPTIONS (
    column_name 'date_range'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN ipni_id OPTIONS (
    column_name 'ipni_id'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xmoss.author ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);


--
-- Name: author_old; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.author_old (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    abbrev character varying(100),
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    date_range character varying(50),
    duplicate_of_id bigint,
    full_name character varying(255),
    ipni_id character varying(50),
    name character varying(255),
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    trash boolean NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    valid_record boolean NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'author_old'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN abbrev OPTIONS (
    column_name 'abbrev'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN date_range OPTIONS (
    column_name 'date_range'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN ipni_id OPTIONS (
    column_name 'ipni_id'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN trash OPTIONS (
    column_name 'trash'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.author_old ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);


--
-- Name: comment; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.comment (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'comment'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN author_id OPTIONS (
    column_name 'author_id'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN text OPTIONS (
    column_name 'text'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.comment ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: db_version; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'db_version'
);
ALTER FOREIGN TABLE xmoss.db_version ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.db_version ALTER COLUMN version OPTIONS (
    column_name 'version'
);


--
-- Name: delayed_jobs; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.delayed_jobs (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'delayed_jobs'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN attempts OPTIONS (
    column_name 'attempts'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN failed_at OPTIONS (
    column_name 'failed_at'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN handler OPTIONS (
    column_name 'handler'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN last_error OPTIONS (
    column_name 'last_error'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN locked_at OPTIONS (
    column_name 'locked_at'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN locked_by OPTIONS (
    column_name 'locked_by'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN priority OPTIONS (
    column_name 'priority'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN queue OPTIONS (
    column_name 'queue'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN run_at OPTIONS (
    column_name 'run_at'
);
ALTER FOREIGN TABLE xmoss.delayed_jobs ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);


--
-- Name: dist_entry; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.dist_entry (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    display character varying(255) NOT NULL,
    region_id bigint NOT NULL,
    sort_order integer NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'dist_entry'
);
ALTER FOREIGN TABLE xmoss.dist_entry ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.dist_entry ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.dist_entry ALTER COLUMN display OPTIONS (
    column_name 'display'
);
ALTER FOREIGN TABLE xmoss.dist_entry ALTER COLUMN region_id OPTIONS (
    column_name 'region_id'
);
ALTER FOREIGN TABLE xmoss.dist_entry ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: dist_entry_dist_status; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.dist_entry_dist_status (
    dist_entry_status_id bigint,
    dist_status_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'dist_entry_dist_status'
);
ALTER FOREIGN TABLE xmoss.dist_entry_dist_status ALTER COLUMN dist_entry_status_id OPTIONS (
    column_name 'dist_entry_status_id'
);
ALTER FOREIGN TABLE xmoss.dist_entry_dist_status ALTER COLUMN dist_status_id OPTIONS (
    column_name 'dist_status_id'
);


--
-- Name: dist_region; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.dist_region (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    def_link character varying(255),
    name character varying(255) NOT NULL,
    sort_order integer NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'dist_region'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN def_link OPTIONS (
    column_name 'def_link'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.dist_region ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: dist_status; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.dist_status (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    def_link character varying(255),
    name character varying(255) NOT NULL,
    sort_order integer NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'dist_status'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN def_link OPTIONS (
    column_name 'def_link'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.dist_status ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: dist_status_dist_status; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.dist_status_dist_status (
    dist_status_combining_status_id bigint,
    dist_status_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'dist_status_dist_status'
);
ALTER FOREIGN TABLE xmoss.dist_status_dist_status ALTER COLUMN dist_status_combining_status_id OPTIONS (
    column_name 'dist_status_combining_status_id'
);
ALTER FOREIGN TABLE xmoss.dist_status_dist_status ALTER COLUMN dist_status_id OPTIONS (
    column_name 'dist_status_id'
);


--
-- Name: event_record; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.event_record (
    id bigint NOT NULL,
    version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    data jsonb,
    dealt_with boolean NOT NULL,
    type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'event_record'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN version OPTIONS (
    column_name 'version'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN data OPTIONS (
    column_name 'data'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN dealt_with OPTIONS (
    column_name 'dealt_with'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN type OPTIONS (
    column_name 'type'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.event_record ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: id_mapper; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.id_mapper (
    id bigint NOT NULL,
    from_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    system character varying(20) NOT NULL,
    to_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'id_mapper'
);
ALTER FOREIGN TABLE xmoss.id_mapper ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.id_mapper ALTER COLUMN from_id OPTIONS (
    column_name 'from_id'
);
ALTER FOREIGN TABLE xmoss.id_mapper ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.id_mapper ALTER COLUMN system OPTIONS (
    column_name 'system'
);
ALTER FOREIGN TABLE xmoss.id_mapper ALTER COLUMN to_id OPTIONS (
    column_name 'to_id'
);


--
-- Name: instance; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    draft boolean NOT NULL,
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
    valid_record boolean NOT NULL,
    verbatim_name_string character varying(255),
    uri text,
    cached_synonymy_html text
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN bhl_url OPTIONS (
    column_name 'bhl_url'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN draft OPTIONS (
    column_name 'draft'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN instance_type_id OPTIONS (
    column_name 'instance_type_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN nomenclatural_status OPTIONS (
    column_name 'nomenclatural_status'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN page OPTIONS (
    column_name 'page'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN page_qualifier OPTIONS (
    column_name 'page_qualifier'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN verbatim_name_string OPTIONS (
    column_name 'verbatim_name_string'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);
ALTER FOREIGN TABLE xmoss.instance ALTER COLUMN cached_synonymy_html OPTIONS (
    column_name 'cached_synonymy_html'
);


--
-- Name: instance_note; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance_note (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance_note'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN instance_note_key_id OPTIONS (
    column_name 'instance_note_key_id'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.instance_note ALTER COLUMN value OPTIONS (
    column_name 'value'
);


--
-- Name: instance_note_key; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance_note_key (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    name character varying(255) NOT NULL,
    rdf_id character varying(50),
    sort_order integer NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance_note_key'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.instance_note_key ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: instance_paths; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance_paths (
    id bigint,
    instance_path text,
    parent_instance_path text,
    name_path text,
    instance_id bigint,
    name_id bigint,
    excluded boolean,
    declared_bt boolean,
    depth integer,
    nodes jsonb,
    versions jsonb,
    ver_node_map jsonb
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance_paths'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN instance_path OPTIONS (
    column_name 'instance_path'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN parent_instance_path OPTIONS (
    column_name 'parent_instance_path'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN name_path OPTIONS (
    column_name 'name_path'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN excluded OPTIONS (
    column_name 'excluded'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN declared_bt OPTIONS (
    column_name 'declared_bt'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN depth OPTIONS (
    column_name 'depth'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN nodes OPTIONS (
    column_name 'nodes'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN versions OPTIONS (
    column_name 'versions'
);
ALTER FOREIGN TABLE xmoss.instance_paths ALTER COLUMN ver_node_map OPTIONS (
    column_name 'ver_node_map'
);


--
-- Name: instance_resource_vw; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance_resource_vw (
    site_name character varying(100),
    site_description character varying(1000),
    site_url character varying(500),
    resource_path character varying(2400),
    url text,
    instance_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance_resource_vw'
);
ALTER FOREIGN TABLE xmoss.instance_resource_vw ALTER COLUMN site_name OPTIONS (
    column_name 'site_name'
);
ALTER FOREIGN TABLE xmoss.instance_resource_vw ALTER COLUMN site_description OPTIONS (
    column_name 'site_description'
);
ALTER FOREIGN TABLE xmoss.instance_resource_vw ALTER COLUMN site_url OPTIONS (
    column_name 'site_url'
);
ALTER FOREIGN TABLE xmoss.instance_resource_vw ALTER COLUMN resource_path OPTIONS (
    column_name 'resource_path'
);
ALTER FOREIGN TABLE xmoss.instance_resource_vw ALTER COLUMN url OPTIONS (
    column_name 'url'
);
ALTER FOREIGN TABLE xmoss.instance_resource_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);


--
-- Name: instance_resources; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance_resources (
    instance_id bigint NOT NULL,
    resource_id bigint NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance_resources'
);
ALTER FOREIGN TABLE xmoss.instance_resources ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.instance_resources ALTER COLUMN resource_id OPTIONS (
    column_name 'resource_id'
);


--
-- Name: instance_type; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.instance_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    citing boolean NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    doubtful boolean NOT NULL,
    misapplied boolean NOT NULL,
    name character varying(255) NOT NULL,
    nomenclatural boolean NOT NULL,
    primary_instance boolean NOT NULL,
    pro_parte boolean NOT NULL,
    protologue boolean NOT NULL,
    rdf_id character varying(50),
    relationship boolean NOT NULL,
    secondary_instance boolean NOT NULL,
    sort_order integer NOT NULL,
    standalone boolean NOT NULL,
    synonym boolean NOT NULL,
    taxonomic boolean NOT NULL,
    unsourced boolean NOT NULL,
    has_label character varying(255) NOT NULL,
    of_label character varying(255) NOT NULL,
    bidirectional boolean NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'instance_type'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN citing OPTIONS (
    column_name 'citing'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN doubtful OPTIONS (
    column_name 'doubtful'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN misapplied OPTIONS (
    column_name 'misapplied'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN nomenclatural OPTIONS (
    column_name 'nomenclatural'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN primary_instance OPTIONS (
    column_name 'primary_instance'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN pro_parte OPTIONS (
    column_name 'pro_parte'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN protologue OPTIONS (
    column_name 'protologue'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN relationship OPTIONS (
    column_name 'relationship'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN secondary_instance OPTIONS (
    column_name 'secondary_instance'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN standalone OPTIONS (
    column_name 'standalone'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN synonym OPTIONS (
    column_name 'synonym'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN taxonomic OPTIONS (
    column_name 'taxonomic'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN unsourced OPTIONS (
    column_name 'unsourced'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN has_label OPTIONS (
    column_name 'has_label'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN of_label OPTIONS (
    column_name 'of_label'
);
ALTER FOREIGN TABLE xmoss.instance_type ALTER COLUMN bidirectional OPTIONS (
    column_name 'bidirectional'
);


--
-- Name: language; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.language (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    iso6391code character varying(2),
    iso6393code character varying(3) NOT NULL,
    name character varying(50) NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'language'
);
ALTER FOREIGN TABLE xmoss.language ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.language ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.language ALTER COLUMN iso6391code OPTIONS (
    column_name 'iso6391code'
);
ALTER FOREIGN TABLE xmoss.language ALTER COLUMN iso6393code OPTIONS (
    column_name 'iso6393code'
);
ALTER FOREIGN TABLE xmoss.language ALTER COLUMN name OPTIONS (
    column_name 'name'
);


--
-- Name: media; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.media (
    id bigint NOT NULL,
    version bigint NOT NULL,
    data bytea NOT NULL,
    description text NOT NULL,
    file_name text NOT NULL,
    mime_type text NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'media'
);
ALTER FOREIGN TABLE xmoss.media ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.media ALTER COLUMN version OPTIONS (
    column_name 'version'
);
ALTER FOREIGN TABLE xmoss.media ALTER COLUMN data OPTIONS (
    column_name 'data'
);
ALTER FOREIGN TABLE xmoss.media ALTER COLUMN description OPTIONS (
    column_name 'description'
);
ALTER FOREIGN TABLE xmoss.media ALTER COLUMN file_name OPTIONS (
    column_name 'file_name'
);
ALTER FOREIGN TABLE xmoss.media ALTER COLUMN mime_type OPTIONS (
    column_name 'mime_type'
);


--
-- Name: name; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
    orth_var boolean NOT NULL,
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
    valid_record boolean NOT NULL,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text NOT NULL,
    uri text,
    changed_combination boolean NOT NULL,
    published_year integer,
    apni_json jsonb
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN author_id OPTIONS (
    column_name 'author_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN base_author_id OPTIONS (
    column_name 'base_author_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN ex_author_id OPTIONS (
    column_name 'ex_author_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN ex_base_author_id OPTIONS (
    column_name 'ex_base_author_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN name_rank_id OPTIONS (
    column_name 'name_rank_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN name_status_id OPTIONS (
    column_name 'name_status_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN name_type_id OPTIONS (
    column_name 'name_type_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN orth_var OPTIONS (
    column_name 'orth_var'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN sanctioning_author_id OPTIONS (
    column_name 'sanctioning_author_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN second_parent_id OPTIONS (
    column_name 'second_parent_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN simple_name_html OPTIONS (
    column_name 'simple_name_html'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN source_dup_of_id OPTIONS (
    column_name 'source_dup_of_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN status_summary OPTIONS (
    column_name 'status_summary'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN verbatim_rank OPTIONS (
    column_name 'verbatim_rank'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN sort_name OPTIONS (
    column_name 'sort_name'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN family_id OPTIONS (
    column_name 'family_id'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN name_path OPTIONS (
    column_name 'name_path'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN changed_combination OPTIONS (
    column_name 'changed_combination'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN published_year OPTIONS (
    column_name 'published_year'
);
ALTER FOREIGN TABLE xmoss.name ALTER COLUMN apni_json OPTIONS (
    column_name 'apni_json'
);


--
-- Name: name_category; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_category (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(50) NOT NULL,
    rdf_id character varying(50),
    sort_order integer NOT NULL,
    max_parents_allowed integer NOT NULL,
    min_parents_required integer NOT NULL,
    parent_1_help_text text,
    parent_2_help_text text,
    requires_family boolean NOT NULL,
    requires_higher_ranked_parent boolean NOT NULL,
    requires_name_element boolean NOT NULL,
    takes_author_only boolean NOT NULL,
    takes_authors boolean NOT NULL,
    takes_cultivar_scoped_parent boolean NOT NULL,
    takes_hybrid_scoped_parent boolean NOT NULL,
    takes_name_element boolean NOT NULL,
    takes_verbatim_rank boolean NOT NULL,
    takes_rank boolean NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_category'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN max_parents_allowed OPTIONS (
    column_name 'max_parents_allowed'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN min_parents_required OPTIONS (
    column_name 'min_parents_required'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN parent_1_help_text OPTIONS (
    column_name 'parent_1_help_text'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN parent_2_help_text OPTIONS (
    column_name 'parent_2_help_text'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN requires_family OPTIONS (
    column_name 'requires_family'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN requires_higher_ranked_parent OPTIONS (
    column_name 'requires_higher_ranked_parent'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN requires_name_element OPTIONS (
    column_name 'requires_name_element'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_author_only OPTIONS (
    column_name 'takes_author_only'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_authors OPTIONS (
    column_name 'takes_authors'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_cultivar_scoped_parent OPTIONS (
    column_name 'takes_cultivar_scoped_parent'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_hybrid_scoped_parent OPTIONS (
    column_name 'takes_hybrid_scoped_parent'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_name_element OPTIONS (
    column_name 'takes_name_element'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_verbatim_rank OPTIONS (
    column_name 'takes_verbatim_rank'
);
ALTER FOREIGN TABLE xmoss.name_category ALTER COLUMN takes_rank OPTIONS (
    column_name 'takes_rank'
);


--
-- Name: name_detail_commons_vw; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_detail_commons_vw (
    cited_by_id bigint,
    entry text,
    id bigint,
    cites_id bigint,
    instance_type_name character varying(255),
    instance_type_sort_order integer,
    full_name character varying(512),
    full_name_html character varying(2048),
    name character varying(50),
    name_id bigint,
    instance_id bigint,
    name_detail_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_detail_commons_vw'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN entry OPTIONS (
    column_name 'entry'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN instance_type_name OPTIONS (
    column_name 'instance_type_name'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN instance_type_sort_order OPTIONS (
    column_name 'instance_type_sort_order'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_commons_vw ALTER COLUMN name_detail_id OPTIONS (
    column_name 'name_detail_id'
);


--
-- Name: name_detail_synonyms_vw; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_detail_synonyms_vw (
    cited_by_id bigint,
    entry text,
    id bigint,
    cites_id bigint,
    instance_type_name character varying(255),
    instance_type_sort_order integer,
    full_name character varying(512),
    full_name_html character varying(2048),
    name character varying(50),
    name_id bigint,
    instance_id bigint,
    name_detail_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_detail_synonyms_vw'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN entry OPTIONS (
    column_name 'entry'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN instance_type_name OPTIONS (
    column_name 'instance_type_name'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN instance_type_sort_order OPTIONS (
    column_name 'instance_type_sort_order'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.name_detail_synonyms_vw ALTER COLUMN name_detail_id OPTIONS (
    column_name 'name_detail_id'
);


--
-- Name: name_details_vw; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_details_vw (
    id bigint,
    full_name character varying(512),
    simple_name character varying(250),
    status_name character varying(50),
    rank_name character varying(50),
    rank_visible_in_name boolean,
    rank_sort_order integer,
    type_name character varying(255),
    type_scientific boolean,
    type_cultivar boolean,
    instance_id bigint,
    reference_year integer,
    reference_id bigint,
    reference_citation_html character varying(4000),
    instance_type_name character varying(255),
    instance_type_id bigint,
    primary_instance boolean,
    instance_standalone boolean,
    synonym_standalone boolean,
    synonym_type_name character varying(255),
    page character varying(255),
    page_qualifier character varying(255),
    cited_by_id bigint,
    cites_id bigint,
    bhl_url character varying(4000),
    primary_instance_first text,
    synonym_full_name character varying(512),
    author_name character varying(1000),
    name_id bigint,
    sort_name character varying(250),
    entry text
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_details_vw'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN full_name OPTIONS (
    column_name 'full_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN status_name OPTIONS (
    column_name 'status_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN rank_name OPTIONS (
    column_name 'rank_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN rank_visible_in_name OPTIONS (
    column_name 'rank_visible_in_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN rank_sort_order OPTIONS (
    column_name 'rank_sort_order'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN type_name OPTIONS (
    column_name 'type_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN type_scientific OPTIONS (
    column_name 'type_scientific'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN type_cultivar OPTIONS (
    column_name 'type_cultivar'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN reference_year OPTIONS (
    column_name 'reference_year'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN reference_citation_html OPTIONS (
    column_name 'reference_citation_html'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN instance_type_name OPTIONS (
    column_name 'instance_type_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN instance_type_id OPTIONS (
    column_name 'instance_type_id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN primary_instance OPTIONS (
    column_name 'primary_instance'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN instance_standalone OPTIONS (
    column_name 'instance_standalone'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN synonym_standalone OPTIONS (
    column_name 'synonym_standalone'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN synonym_type_name OPTIONS (
    column_name 'synonym_type_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN page OPTIONS (
    column_name 'page'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN page_qualifier OPTIONS (
    column_name 'page_qualifier'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN cited_by_id OPTIONS (
    column_name 'cited_by_id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN cites_id OPTIONS (
    column_name 'cites_id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN bhl_url OPTIONS (
    column_name 'bhl_url'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN primary_instance_first OPTIONS (
    column_name 'primary_instance_first'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN synonym_full_name OPTIONS (
    column_name 'synonym_full_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN author_name OPTIONS (
    column_name 'author_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN sort_name OPTIONS (
    column_name 'sort_name'
);
ALTER FOREIGN TABLE xmoss.name_details_vw ALTER COLUMN entry OPTIONS (
    column_name 'entry'
);


--
-- Name: name_group; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_group (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(50),
    rdf_id character varying(50)
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_group'
);
ALTER FOREIGN TABLE xmoss.name_group ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_group ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name_group ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.name_group ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_group ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: name_rank; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_rank (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    abbrev character varying(20) NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    has_parent boolean NOT NULL,
    italicize boolean NOT NULL,
    major boolean NOT NULL,
    name character varying(50) NOT NULL,
    name_group_id bigint NOT NULL,
    parent_rank_id bigint,
    rdf_id character varying(50),
    sort_order integer NOT NULL,
    visible_in_name boolean NOT NULL,
    use_verbatim_rank boolean NOT NULL,
    display_name text NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_rank'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN abbrev OPTIONS (
    column_name 'abbrev'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN has_parent OPTIONS (
    column_name 'has_parent'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN italicize OPTIONS (
    column_name 'italicize'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN major OPTIONS (
    column_name 'major'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN name_group_id OPTIONS (
    column_name 'name_group_id'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN parent_rank_id OPTIONS (
    column_name 'parent_rank_id'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN visible_in_name OPTIONS (
    column_name 'visible_in_name'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN use_verbatim_rank OPTIONS (
    column_name 'use_verbatim_rank'
);
ALTER FOREIGN TABLE xmoss.name_rank ALTER COLUMN display_name OPTIONS (
    column_name 'display_name'
);


--
-- Name: name_resources; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_resources (
    resource_id bigint NOT NULL,
    name_id bigint NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_resources'
);
ALTER FOREIGN TABLE xmoss.name_resources ALTER COLUMN resource_id OPTIONS (
    column_name 'resource_id'
);
ALTER FOREIGN TABLE xmoss.name_resources ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);


--
-- Name: name_status; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_status (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    display boolean NOT NULL,
    name character varying(50),
    name_group_id bigint NOT NULL,
    name_status_id bigint,
    nom_illeg boolean NOT NULL,
    nom_inval boolean NOT NULL,
    rdf_id character varying(50),
    deprecated boolean NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_status'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN display OPTIONS (
    column_name 'display'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN name_group_id OPTIONS (
    column_name 'name_group_id'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN name_status_id OPTIONS (
    column_name 'name_status_id'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.name_status ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);


--
-- Name: name_tag; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_tag (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    name character varying(255) NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_tag'
);
ALTER FOREIGN TABLE xmoss.name_tag ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_tag ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name_tag ALTER COLUMN name OPTIONS (
    column_name 'name'
);


--
-- Name: name_tag_name; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_tag_name (
    name_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_tag_name'
);
ALTER FOREIGN TABLE xmoss.name_tag_name ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.name_tag_name ALTER COLUMN tag_id OPTIONS (
    column_name 'tag_id'
);
ALTER FOREIGN TABLE xmoss.name_tag_name ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.name_tag_name ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.name_tag_name ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.name_tag_name ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: name_type; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    autonym boolean NOT NULL,
    connector character varying(1),
    cultivar boolean NOT NULL,
    deprecated boolean NOT NULL,
    description_html text,
    formula boolean NOT NULL,
    hybrid boolean NOT NULL,
    name character varying(255) NOT NULL,
    name_category_id bigint NOT NULL,
    name_group_id bigint NOT NULL,
    rdf_id character varying(50),
    scientific boolean NOT NULL,
    sort_order integer NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_type'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN connector OPTIONS (
    column_name 'connector'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN name_category_id OPTIONS (
    column_name 'name_category_id'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN name_group_id OPTIONS (
    column_name 'name_group_id'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xmoss.name_type ALTER COLUMN sort_order OPTIONS (
    column_name 'sort_order'
);


--
-- Name: name_view; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.name_view (
    "scientificName" character varying(512),
    "scientificNameHTML" character varying(2048),
    "canonicalName" character varying(250),
    "canonicalNameHTML" character varying(2048),
    "nameElement" character varying(255),
    "scientificNameID" text,
    "nameType" character varying(255),
    "taxonomicStatus" text,
    "nomenclaturalStatus" character varying,
    "scientificNameAuthorship" text,
    "cultivarEpithet" character varying,
    autonym boolean,
    hybrid boolean,
    cultivar boolean,
    formula boolean,
    scientific boolean,
    "nomInval" boolean,
    "nomIlleg" boolean,
    "namePublishedIn" character varying,
    "namePublishedInYear" integer,
    "nameInstanceType" character varying(255),
    "originalNameUsage" character varying(512),
    "originalNameUsageID" text,
    "typeCitation" text,
    kingdom text,
    family character varying(255),
    "genericName" text,
    "specificEpithet" text,
    "infraspecificEpithet" text,
    "taxonRank" character varying(50),
    "taxonRankSortOrder" integer,
    "taxonRankAbbreviation" character varying(20),
    "firstHybridParentName" character varying(512),
    "firstHybridParentNameID" text,
    "secondHybridParentName" character varying(512),
    "secondHybridParentNameID" text,
    created timestamp with time zone,
    modified timestamp with time zone,
    "nomenclaturalCode" text,
    "datasetName" character varying(5000),
    license text,
    "ccAttributionIRI" text
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'name_view'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "scientificName" OPTIONS (
    column_name 'scientificName'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "scientificNameHTML" OPTIONS (
    column_name 'scientificNameHTML'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "canonicalName" OPTIONS (
    column_name 'canonicalName'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "canonicalNameHTML" OPTIONS (
    column_name 'canonicalNameHTML'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nameElement" OPTIONS (
    column_name 'nameElement'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "scientificNameID" OPTIONS (
    column_name 'scientificNameID'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nameType" OPTIONS (
    column_name 'nameType'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "taxonomicStatus" OPTIONS (
    column_name 'taxonomicStatus'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nomenclaturalStatus" OPTIONS (
    column_name 'nomenclaturalStatus'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "scientificNameAuthorship" OPTIONS (
    column_name 'scientificNameAuthorship'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "cultivarEpithet" OPTIONS (
    column_name 'cultivarEpithet'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nomInval" OPTIONS (
    column_name 'nomInval'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nomIlleg" OPTIONS (
    column_name 'nomIlleg'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "namePublishedIn" OPTIONS (
    column_name 'namePublishedIn'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "namePublishedInYear" OPTIONS (
    column_name 'namePublishedInYear'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nameInstanceType" OPTIONS (
    column_name 'nameInstanceType'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "originalNameUsage" OPTIONS (
    column_name 'originalNameUsage'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "originalNameUsageID" OPTIONS (
    column_name 'originalNameUsageID'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "typeCitation" OPTIONS (
    column_name 'typeCitation'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "genericName" OPTIONS (
    column_name 'genericName'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "specificEpithet" OPTIONS (
    column_name 'specificEpithet'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "infraspecificEpithet" OPTIONS (
    column_name 'infraspecificEpithet'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "taxonRank" OPTIONS (
    column_name 'taxonRank'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "taxonRankSortOrder" OPTIONS (
    column_name 'taxonRankSortOrder'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "taxonRankAbbreviation" OPTIONS (
    column_name 'taxonRankAbbreviation'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "firstHybridParentName" OPTIONS (
    column_name 'firstHybridParentName'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "firstHybridParentNameID" OPTIONS (
    column_name 'firstHybridParentNameID'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "secondHybridParentName" OPTIONS (
    column_name 'secondHybridParentName'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "secondHybridParentNameID" OPTIONS (
    column_name 'secondHybridParentNameID'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "nomenclaturalCode" OPTIONS (
    column_name 'nomenclaturalCode'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "datasetName" OPTIONS (
    column_name 'datasetName'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xmoss.name_view ALTER COLUMN "ccAttributionIRI" OPTIONS (
    column_name 'ccAttributionIRI'
);


--
-- Name: namespace; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.namespace (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(255) NOT NULL,
    rdf_id character varying(50)
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'namespace'
);
ALTER FOREIGN TABLE xmoss.namespace ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.namespace ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.namespace ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.namespace ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.namespace ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: new_identifiers; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.new_identifiers (
    tree_id bigint,
    tree_version_id bigint,
    new_root bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'new_identifiers'
);
ALTER FOREIGN TABLE xmoss.new_identifiers ALTER COLUMN tree_id OPTIONS (
    column_name 'tree_id'
);
ALTER FOREIGN TABLE xmoss.new_identifiers ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xmoss.new_identifiers ALTER COLUMN new_root OPTIONS (
    column_name 'new_root'
);


--
-- Name: notification; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.notification (
    id bigint NOT NULL,
    version bigint NOT NULL,
    message character varying(255) NOT NULL,
    object_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'notification'
);
ALTER FOREIGN TABLE xmoss.notification ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.notification ALTER COLUMN version OPTIONS (
    column_name 'version'
);
ALTER FOREIGN TABLE xmoss.notification ALTER COLUMN message OPTIONS (
    column_name 'message'
);
ALTER FOREIGN TABLE xmoss.notification ALTER COLUMN object_id OPTIONS (
    column_name 'object_id'
);


--
-- Name: nsl_simple_name_export; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.nsl_simple_name_export (
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
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'nsl_simple_name_export'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_comment OPTIONS (
    column_name 'apc_comment'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_distribution OPTIONS (
    column_name 'apc_distribution'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_excluded OPTIONS (
    column_name 'apc_excluded'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_familia OPTIONS (
    column_name 'apc_familia'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_instance_id OPTIONS (
    column_name 'apc_instance_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_name OPTIONS (
    column_name 'apc_name'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_proparte OPTIONS (
    column_name 'apc_proparte'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apc_relationship_type OPTIONS (
    column_name 'apc_relationship_type'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN apni OPTIONS (
    column_name 'apni'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN author OPTIONS (
    column_name 'author'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN authority OPTIONS (
    column_name 'authority'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN autonym OPTIONS (
    column_name 'autonym'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN basionym OPTIONS (
    column_name 'basionym'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN base_name_author OPTIONS (
    column_name 'base_name_author'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN classifications OPTIONS (
    column_name 'classifications'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN cultivar OPTIONS (
    column_name 'cultivar'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN cultivar_name OPTIONS (
    column_name 'cultivar_name'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN ex_author OPTIONS (
    column_name 'ex_author'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN ex_base_name_author OPTIONS (
    column_name 'ex_base_name_author'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN familia OPTIONS (
    column_name 'familia'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN family_nsl_id OPTIONS (
    column_name 'family_nsl_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN formula OPTIONS (
    column_name 'formula'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN full_name_html OPTIONS (
    column_name 'full_name_html'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN genus OPTIONS (
    column_name 'genus'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN genus_nsl_id OPTIONS (
    column_name 'genus_nsl_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN homonym OPTIONS (
    column_name 'homonym'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN hybrid OPTIONS (
    column_name 'hybrid'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN infraspecies OPTIONS (
    column_name 'infraspecies'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN classis OPTIONS (
    column_name 'classis'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN subclassis OPTIONS (
    column_name 'subclassis'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN name_type_name OPTIONS (
    column_name 'name_type_name'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN nom_illeg OPTIONS (
    column_name 'nom_illeg'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN nom_inval OPTIONS (
    column_name 'nom_inval'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN nom_stat OPTIONS (
    column_name 'nom_stat'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN parent_nsl_id OPTIONS (
    column_name 'parent_nsl_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN proto_citation OPTIONS (
    column_name 'proto_citation'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN proto_instance_id OPTIONS (
    column_name 'proto_instance_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN proto_year OPTIONS (
    column_name 'proto_year'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN rank OPTIONS (
    column_name 'rank'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN rank_abbrev OPTIONS (
    column_name 'rank_abbrev'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN rank_sort_order OPTIONS (
    column_name 'rank_sort_order'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN replaced_synonym OPTIONS (
    column_name 'replaced_synonym'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN sanctioning_author OPTIONS (
    column_name 'sanctioning_author'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN scientific OPTIONS (
    column_name 'scientific'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN second_parent_nsl_id OPTIONS (
    column_name 'second_parent_nsl_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN simple_name_html OPTIONS (
    column_name 'simple_name_html'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN species OPTIONS (
    column_name 'species'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN species_nsl_id OPTIONS (
    column_name 'species_nsl_id'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN taxon_name OPTIONS (
    column_name 'taxon_name'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.nsl_simple_name_export ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: ref_author_role; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.ref_author_role (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(255) NOT NULL,
    rdf_id character varying(50)
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'ref_author_role'
);
ALTER FOREIGN TABLE xmoss.ref_author_role ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.ref_author_role ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.ref_author_role ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.ref_author_role ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.ref_author_role ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: ref_type; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.ref_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    description_html text,
    name character varying(50) NOT NULL,
    parent_id bigint,
    parent_optional boolean NOT NULL,
    rdf_id character varying(50),
    use_parent_details boolean NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'ref_type'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN parent_optional OPTIONS (
    column_name 'parent_optional'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);
ALTER FOREIGN TABLE xmoss.ref_type ALTER COLUMN use_parent_details OPTIONS (
    column_name 'use_parent_details'
);


--
-- Name: reference; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.reference (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
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
    published boolean NOT NULL,
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
    valid_record boolean NOT NULL,
    verbatim_author character varying(1000),
    verbatim_citation character varying(2000),
    verbatim_reference character varying(1000),
    volume character varying(100),
    year integer,
    uri text,
    iso_publication_date character varying(10)
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'reference'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN abbrev_title OPTIONS (
    column_name 'abbrev_title'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN author_id OPTIONS (
    column_name 'author_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN bhl_url OPTIONS (
    column_name 'bhl_url'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN citation OPTIONS (
    column_name 'citation'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN citation_html OPTIONS (
    column_name 'citation_html'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN display_title OPTIONS (
    column_name 'display_title'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN doi OPTIONS (
    column_name 'doi'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN duplicate_of_id OPTIONS (
    column_name 'duplicate_of_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN edition OPTIONS (
    column_name 'edition'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN isbn OPTIONS (
    column_name 'isbn'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN issn OPTIONS (
    column_name 'issn'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN language_id OPTIONS (
    column_name 'language_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN namespace_id OPTIONS (
    column_name 'namespace_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN notes OPTIONS (
    column_name 'notes'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN pages OPTIONS (
    column_name 'pages'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN publication_date OPTIONS (
    column_name 'publication_date'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN published OPTIONS (
    column_name 'published'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN published_location OPTIONS (
    column_name 'published_location'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN publisher OPTIONS (
    column_name 'publisher'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN ref_author_role_id OPTIONS (
    column_name 'ref_author_role_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN ref_type_id OPTIONS (
    column_name 'ref_type_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN source_id OPTIONS (
    column_name 'source_id'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN source_id_string OPTIONS (
    column_name 'source_id_string'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN source_system OPTIONS (
    column_name 'source_system'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN title OPTIONS (
    column_name 'title'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN tl2 OPTIONS (
    column_name 'tl2'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN valid_record OPTIONS (
    column_name 'valid_record'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN verbatim_author OPTIONS (
    column_name 'verbatim_author'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN verbatim_citation OPTIONS (
    column_name 'verbatim_citation'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN verbatim_reference OPTIONS (
    column_name 'verbatim_reference'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN volume OPTIONS (
    column_name 'volume'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN year OPTIONS (
    column_name 'year'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN uri OPTIONS (
    column_name 'uri'
);
ALTER FOREIGN TABLE xmoss.reference ALTER COLUMN iso_publication_date OPTIONS (
    column_name 'iso_publication_date'
);


--
-- Name: resource; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.resource (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    path character varying(2400) NOT NULL,
    site_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    resource_type_id bigint NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'resource'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN path OPTIONS (
    column_name 'path'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN site_id OPTIONS (
    column_name 'site_id'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.resource ALTER COLUMN resource_type_id OPTIONS (
    column_name 'resource_type_id'
);


--
-- Name: resource_type; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.resource_type (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    css_icon text,
    deprecated boolean NOT NULL,
    description text NOT NULL,
    display boolean NOT NULL,
    media_icon_id bigint,
    name text NOT NULL,
    rdf_id character varying(50)
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'resource_type'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN css_icon OPTIONS (
    column_name 'css_icon'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN description OPTIONS (
    column_name 'description'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN display OPTIONS (
    column_name 'display'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN media_icon_id OPTIONS (
    column_name 'media_icon_id'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.resource_type ALTER COLUMN rdf_id OPTIONS (
    column_name 'rdf_id'
);


--
-- Name: shard_config; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.shard_config (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(5000) NOT NULL,
    deprecated boolean NOT NULL,
    use_notes character varying(255)
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'shard_config'
);
ALTER FOREIGN TABLE xmoss.shard_config ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.shard_config ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.shard_config ALTER COLUMN value OPTIONS (
    column_name 'value'
);
ALTER FOREIGN TABLE xmoss.shard_config ALTER COLUMN deprecated OPTIONS (
    column_name 'deprecated'
);
ALTER FOREIGN TABLE xmoss.shard_config ALTER COLUMN use_notes OPTIONS (
    column_name 'use_notes'
);


--
-- Name: site; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.site (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    description character varying(1000) NOT NULL,
    name character varying(100) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    url character varying(500) NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'site'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN description OPTIONS (
    column_name 'description'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.site ALTER COLUMN url OPTIONS (
    column_name 'url'
);


--
-- Name: taxon_view; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.taxon_view (
    "taxonID" text,
    "nameType" character varying(255),
    "acceptedNameUsageID" text,
    "acceptedNameUsage" character varying(512),
    "nomenclaturalStatus" character varying,
    "taxonomicStatus" text,
    "proParte" boolean,
    "scientificName" character varying(512),
    "scientificNameID" text,
    "canonicalName" character varying(250),
    "scientificNameAuthorship" text,
    "parentNameUsageID" text,
    "taxonRank" character varying(50),
    "taxonRankSortOrder" integer,
    kingdom text,
    class text,
    subclass text,
    family text,
    created timestamp with time zone,
    modified timestamp with time zone,
    "datasetName" text,
    "taxonConceptID" text,
    "nameAccordingTo" text,
    "nameAccordingToID" text,
    "taxonRemarks" text,
    "taxonDistribution" text,
    "higherClassification" text,
    "firstHybridParentName" character varying,
    "firstHybridParentNameID" text,
    "secondHybridParentName" character varying,
    "secondHybridParentNameID" text,
    "nomenclaturalCode" text,
    license text,
    "ccAttributionIRI" text
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'taxon_view'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonID" OPTIONS (
    column_name 'taxonID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "nameType" OPTIONS (
    column_name 'nameType'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "acceptedNameUsageID" OPTIONS (
    column_name 'acceptedNameUsageID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "acceptedNameUsage" OPTIONS (
    column_name 'acceptedNameUsage'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "nomenclaturalStatus" OPTIONS (
    column_name 'nomenclaturalStatus'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonomicStatus" OPTIONS (
    column_name 'taxonomicStatus'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "proParte" OPTIONS (
    column_name 'proParte'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "scientificName" OPTIONS (
    column_name 'scientificName'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "scientificNameID" OPTIONS (
    column_name 'scientificNameID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "canonicalName" OPTIONS (
    column_name 'canonicalName'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "scientificNameAuthorship" OPTIONS (
    column_name 'scientificNameAuthorship'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "parentNameUsageID" OPTIONS (
    column_name 'parentNameUsageID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonRank" OPTIONS (
    column_name 'taxonRank'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonRankSortOrder" OPTIONS (
    column_name 'taxonRankSortOrder'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN kingdom OPTIONS (
    column_name 'kingdom'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN class OPTIONS (
    column_name 'class'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN subclass OPTIONS (
    column_name 'subclass'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN family OPTIONS (
    column_name 'family'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN created OPTIONS (
    column_name 'created'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN modified OPTIONS (
    column_name 'modified'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "datasetName" OPTIONS (
    column_name 'datasetName'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonConceptID" OPTIONS (
    column_name 'taxonConceptID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "nameAccordingTo" OPTIONS (
    column_name 'nameAccordingTo'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "nameAccordingToID" OPTIONS (
    column_name 'nameAccordingToID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonRemarks" OPTIONS (
    column_name 'taxonRemarks'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "taxonDistribution" OPTIONS (
    column_name 'taxonDistribution'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "higherClassification" OPTIONS (
    column_name 'higherClassification'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "firstHybridParentName" OPTIONS (
    column_name 'firstHybridParentName'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "firstHybridParentNameID" OPTIONS (
    column_name 'firstHybridParentNameID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "secondHybridParentName" OPTIONS (
    column_name 'secondHybridParentName'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "secondHybridParentNameID" OPTIONS (
    column_name 'secondHybridParentNameID'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "nomenclaturalCode" OPTIONS (
    column_name 'nomenclaturalCode'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN license OPTIONS (
    column_name 'license'
);
ALTER FOREIGN TABLE xmoss.taxon_view ALTER COLUMN "ccAttributionIRI" OPTIONS (
    column_name 'ccAttributionIRI'
);


--
-- Name: tmp_distribution; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.tmp_distribution (
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
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'tmp_distribution'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN dist OPTIONS (
    column_name 'dist'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN apc_te_id OPTIONS (
    column_name 'apc_te_id'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN wa OPTIONS (
    column_name 'wa'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN coi OPTIONS (
    column_name 'coi'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN chi OPTIONS (
    column_name 'chi'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN ar OPTIONS (
    column_name 'ar'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN cai OPTIONS (
    column_name 'cai'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN nt OPTIONS (
    column_name 'nt'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN sa OPTIONS (
    column_name 'sa'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN qld OPTIONS (
    column_name 'qld'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN csi OPTIONS (
    column_name 'csi'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN nsw OPTIONS (
    column_name 'nsw'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN lhi OPTIONS (
    column_name 'lhi'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN ni OPTIONS (
    column_name 'ni'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN act OPTIONS (
    column_name 'act'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN vic OPTIONS (
    column_name 'vic'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN tas OPTIONS (
    column_name 'tas'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN hi OPTIONS (
    column_name 'hi'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN mdi OPTIONS (
    column_name 'mdi'
);
ALTER FOREIGN TABLE xmoss.tmp_distribution ALTER COLUMN mi OPTIONS (
    column_name 'mi'
);


--
-- Name: tree; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.tree (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    accepted_tree boolean NOT NULL,
    config jsonb,
    current_tree_version_id bigint,
    default_draft_tree_version_id bigint,
    description_html text NOT NULL,
    group_name text NOT NULL,
    host_name text NOT NULL,
    link_to_home_page text,
    name text NOT NULL,
    reference_id bigint
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'tree'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN accepted_tree OPTIONS (
    column_name 'accepted_tree'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN config OPTIONS (
    column_name 'config'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN current_tree_version_id OPTIONS (
    column_name 'current_tree_version_id'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN default_draft_tree_version_id OPTIONS (
    column_name 'default_draft_tree_version_id'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN description_html OPTIONS (
    column_name 'description_html'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN group_name OPTIONS (
    column_name 'group_name'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN host_name OPTIONS (
    column_name 'host_name'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN link_to_home_page OPTIONS (
    column_name 'link_to_home_page'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN name OPTIONS (
    column_name 'name'
);
ALTER FOREIGN TABLE xmoss.tree ALTER COLUMN reference_id OPTIONS (
    column_name 'reference_id'
);


--
-- Name: tree_element; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.tree_element (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    display_html text NOT NULL,
    excluded boolean NOT NULL,
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
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'tree_element'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN display_html OPTIONS (
    column_name 'display_html'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN excluded OPTIONS (
    column_name 'excluded'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN instance_id OPTIONS (
    column_name 'instance_id'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN instance_link OPTIONS (
    column_name 'instance_link'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN name_element OPTIONS (
    column_name 'name_element'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN name_id OPTIONS (
    column_name 'name_id'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN name_link OPTIONS (
    column_name 'name_link'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN previous_element_id OPTIONS (
    column_name 'previous_element_id'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN profile OPTIONS (
    column_name 'profile'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN rank OPTIONS (
    column_name 'rank'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN simple_name OPTIONS (
    column_name 'simple_name'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN source_element_link OPTIONS (
    column_name 'source_element_link'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN source_shard OPTIONS (
    column_name 'source_shard'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN synonyms OPTIONS (
    column_name 'synonyms'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN synonyms_html OPTIONS (
    column_name 'synonyms_html'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.tree_element ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);


--
-- Name: tree_element_distribution_entries; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.tree_element_distribution_entries (
    dist_entry_id bigint NOT NULL,
    tree_element_id bigint NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'tree_element_distribution_entries'
);
ALTER FOREIGN TABLE xmoss.tree_element_distribution_entries ALTER COLUMN dist_entry_id OPTIONS (
    column_name 'dist_entry_id'
);
ALTER FOREIGN TABLE xmoss.tree_element_distribution_entries ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);


--
-- Name: tree_version; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.tree_version (
    id bigint NOT NULL,
    lock_version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    draft_name text NOT NULL,
    log_entry text,
    previous_version_id bigint,
    published boolean NOT NULL,
    published_at timestamp with time zone,
    published_by character varying(100),
    tree_id bigint NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'tree_version'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN id OPTIONS (
    column_name 'id'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN lock_version OPTIONS (
    column_name 'lock_version'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN created_at OPTIONS (
    column_name 'created_at'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN created_by OPTIONS (
    column_name 'created_by'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN draft_name OPTIONS (
    column_name 'draft_name'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN log_entry OPTIONS (
    column_name 'log_entry'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN previous_version_id OPTIONS (
    column_name 'previous_version_id'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN published OPTIONS (
    column_name 'published'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN published_at OPTIONS (
    column_name 'published_at'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN published_by OPTIONS (
    column_name 'published_by'
);
ALTER FOREIGN TABLE xmoss.tree_version ALTER COLUMN tree_id OPTIONS (
    column_name 'tree_id'
);


--
-- Name: tree_version_element; Type: FOREIGN TABLE; Schema: xmoss; Owner: -
--

CREATE FOREIGN TABLE xmoss.tree_version_element (
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
    merge_conflict boolean NOT NULL
)
SERVER moss
OPTIONS (
    schema_name 'public',
    table_name 'tree_version_element'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN element_link OPTIONS (
    column_name 'element_link'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN depth OPTIONS (
    column_name 'depth'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN name_path OPTIONS (
    column_name 'name_path'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN parent_id OPTIONS (
    column_name 'parent_id'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN taxon_id OPTIONS (
    column_name 'taxon_id'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN taxon_link OPTIONS (
    column_name 'taxon_link'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN tree_element_id OPTIONS (
    column_name 'tree_element_id'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN tree_path OPTIONS (
    column_name 'tree_path'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN tree_version_id OPTIONS (
    column_name 'tree_version_id'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN updated_at OPTIONS (
    column_name 'updated_at'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN updated_by OPTIONS (
    column_name 'updated_by'
);
ALTER FOREIGN TABLE xmoss.tree_version_element ALTER COLUMN merge_conflict OPTIONS (
    column_name 'merge_conflict'
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
-- Name: logged_actions event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logged_actions ALTER COLUMN event_id SET DEFAULT nextval('audit.logged_actions_event_id_seq'::regclass);


--
-- Name: bulk_processing_log id; Type: DEFAULT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.bulk_processing_log ALTER COLUMN id SET DEFAULT nextval('loader.bulk_processing_log_id_seq'::regclass);


--
-- Name: loader_batch_raw_names_02_feb_2023 loader_batch_raw_names_02_feb_2023_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.loader_batch_raw_names_02_feb_2023
    ADD CONSTRAINT loader_batch_raw_names_02_feb_2023_pkey PRIMARY KEY (id);


--
-- Name: loader_batch_raw_names_20_mar_2023 loader_batch_raw_names_20_mar_2023_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.loader_batch_raw_names_20_mar_2023
    ADD CONSTRAINT loader_batch_raw_names_20_mar_2023_pkey PRIMARY KEY (id);


--
-- Name: loader_batch_raw_names_26_sep_2023 loader_batch_raw_names_26_sep_2023_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.loader_batch_raw_names_26_sep_2023
    ADD CONSTRAINT loader_batch_raw_names_26_sep_2023_pkey PRIMARY KEY (id);


--
-- Name: loader_batch_raw_names_list_105 loader_batch_raw_names_list_105_pkey; Type: CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.loader_batch_raw_names_list_105
    ADD CONSTRAINT loader_batch_raw_names_list_105_pkey PRIMARY KEY (id);


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
-- Name: logged_actions logged_actions_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logged_actions
    ADD CONSTRAINT logged_actions_pkey PRIMARY KEY (event_id);


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
-- Name: batch_reviewer reviewer_has_one_role_per_period_uk; Type: CONSTRAINT; Schema: loader; Owner: -
--

ALTER TABLE ONLY loader.batch_reviewer
    ADD CONSTRAINT reviewer_has_one_role_per_period_uk UNIQUE (user_id, batch_review_period_id);


--
-- Name: db_version db_version_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: host host_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.host
    ADD CONSTRAINT host_pkey PRIMARY KEY (id);


--
-- Name: identifier_identities identifier_identities_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT identifier_identities_pkey PRIMARY KEY (identifier_id, match_id);


--
-- Name: identifier identifier_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT identifier_pkey PRIMARY KEY (id);


--
-- Name: match match_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match
    ADD CONSTRAINT match_pkey PRIMARY KEY (id);


--
-- Name: match uk_2u4bey0rox6ubtvqevg3wasp9; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match
    ADD CONSTRAINT uk_2u4bey0rox6ubtvqevg3wasp9 UNIQUE (uri);


--
-- Name: identifier unique_name_space; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT unique_name_space UNIQUE (version_number, id_number, object_type, name_space);


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
-- Name: profile_annotation profile_annotation_pkey; Type: CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_annotation
    ADD CONSTRAINT profile_annotation_pkey PRIMARY KEY (id);


--
-- Name: profile_item profile_item_pkey; Type: CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_pkey PRIMARY KEY (id);


--
-- Name: profile_item_config profile_item_type_pkey; Type: CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item_config
    ADD CONSTRAINT profile_item_type_pkey PRIMARY KEY (id);


--
-- Name: profile_object_type profile_object_type_pkey; Type: CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_object_type
    ADD CONSTRAINT profile_object_type_pkey PRIMARY KEY (id);


--
-- Name: profile profile_pkey; Type: CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (id);


--
-- Name: profile_text profile_text_pkey; Type: CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_text
    ADD CONSTRAINT profile_text_pkey PRIMARY KEY (id);


--
-- Name: orchid_name_instance_uniq; Type: INDEX; Schema: archive; Owner: -
--

CREATE UNIQUE INDEX orchid_name_instance_uniq ON archive.orchids_names USING btree (orchid_id, name_id, instance_id);


--
-- Name: logged_actions_action_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_idx ON audit.logged_actions USING btree (action);


--
-- Name: logged_actions_action_tstamp_tx_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_tstamp_tx_idx ON audit.logged_actions USING btree (action_tstamp_tx);


--
-- Name: logged_actions_action_tstamp_tx_stm_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_tstamp_tx_stm_idx ON audit.logged_actions USING btree (action_tstamp_stm);


--
-- Name: logged_actions_relid_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_relid_idx ON audit.logged_actions USING btree (relid);


--
-- Name: match_uri_i; Type: INDEX; Schema: ftree; Owner: -
--

CREATE INDEX match_uri_i ON ftree.match USING btree (uri);


--
-- Name: apni_ndx; Type: INDEX; Schema: hep; Owner: -
--

CREATE INDEX apni_ndx ON hep.apni USING btree (id);


--
-- Name: hep_id_idx; Type: INDEX; Schema: hep; Owner: -
--

CREATE INDEX hep_id_idx ON hep.identifier USING btree (id);


--
-- Name: hix_id_idx; Type: INDEX; Schema: hep; Owner: -
--

CREATE INDEX hix_id_idx ON hep.fix_identifier USING btree (id);


--
-- Name: rnm_id_idx; Type: INDEX; Schema: hep; Owner: -
--

CREATE INDEX rnm_id_idx ON hep.removable_name USING btree (id);


--
-- Name: rnm_pid_idx; Type: INDEX; Schema: hep; Owner: -
--

CREATE INDEX rnm_pid_idx ON hep.removable_name USING btree (parent_id);


--
-- Name: loader_name_lower_simple_batch_id; Type: INDEX; Schema: loader; Owner: -
--

CREATE INDEX loader_name_lower_simple_batch_id ON loader.loader_name USING btree (lower(simple_name), loader_batch_id);


--
-- Name: name_unique_case_insensitive; Type: INDEX; Schema: loader; Owner: -
--

CREATE UNIQUE INDEX name_unique_case_insensitive ON loader.loader_batch USING btree (lower((name)::text));


--
-- Name: identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_index ON mapper.identifier USING btree (id_number, name_space, object_type);


--
-- Name: identifier_prefuri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_prefuri_index ON mapper.identifier USING btree (preferred_uri_id);


--
-- Name: identifier_type_space_idx; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_type_space_idx ON mapper.identifier USING btree (object_type, name_space);


--
-- Name: identifier_version_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_version_index ON mapper.identifier USING btree (id_number, name_space, object_type, version_number);


--
-- Name: identity_uri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identity_uri_index ON mapper.match USING btree (uri);


--
-- Name: mapper_identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_identifier_index ON mapper.identifier_identities USING btree (identifier_id);


--
-- Name: mapper_match_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_match_index ON mapper.identifier_identities USING btree (match_id);


--
-- Name: match_host_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX match_host_index ON mapper.match_host USING btree (match_hosts_id);


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
-- Name: all_links_idx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX all_links_idx ON uncited.all_links USING btree (id);


--
-- Name: all_links_link_idx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX all_links_link_idx ON uncited.all_links USING btree (link);


--
-- Name: apni_ndx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX apni_ndx ON uncited.apni USING btree (id);


--
-- Name: candidate_idx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX candidate_idx ON uncited.candidate USING btree (id);


--
-- Name: linked_name_idx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX linked_name_idx ON uncited.linked_name USING btree (id);


--
-- Name: name_idx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX name_idx ON uncited.name USING btree (id);


--
-- Name: unlinked_idx; Type: INDEX; Schema: uncited; Owner: -
--

CREATE INDEX unlinked_idx ON uncited.unlinked_name USING btree (id);


--
-- Name: author audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

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
-- Name: orchids_names orchids_names_orchid_id_fkey; Type: FK CONSTRAINT; Schema: archive; Owner: -
--

ALTER TABLE ONLY archive.orchids_names
    ADD CONSTRAINT orchids_names_orchid_id_fkey FOREIGN KEY (orchid_id) REFERENCES archive.orchids(id);


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
    ADD CONSTRAINT loader_nme_mtch_r_inst_type_fk FOREIGN KEY (relationship_instance_type_id) REFERENCES public.instance_type(id);


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
-- Name: match_host fk_3unhnjvw9xhs9l3ney6tvnioq; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match_host
    ADD CONSTRAINT fk_3unhnjvw9xhs9l3ney6tvnioq FOREIGN KEY (host_id) REFERENCES mapper.host(id);


--
-- Name: match_host fk_iw1fva74t5r4ehvmoy87n37yr; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match_host
    ADD CONSTRAINT fk_iw1fva74t5r4ehvmoy87n37yr FOREIGN KEY (match_hosts_id) REFERENCES mapper.match(id);


--
-- Name: identifier fk_k2o53uoslf9gwqrd80cu2al4s; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT fk_k2o53uoslf9gwqrd80cu2al4s FOREIGN KEY (preferred_uri_id) REFERENCES mapper.match(id);


--
-- Name: identifier_identities fk_mf2dsc2dxvsa9mlximsct7uau; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT fk_mf2dsc2dxvsa9mlximsct7uau FOREIGN KEY (match_id) REFERENCES mapper.match(id);


--
-- Name: identifier_identities fk_ojfilkcwskdvvbggwsnachry2; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT fk_ojfilkcwskdvvbggwsnachry2 FOREIGN KEY (identifier_id) REFERENCES mapper.identifier(id);


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
-- Name: profile_annotation profile_annotation_profile_item_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_annotation
    ADD CONSTRAINT profile_annotation_profile_item_id_fkey FOREIGN KEY (profile_item_id) REFERENCES temp_profile.profile_item(id);


--
-- Name: profile_item profile_item_instance_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: profile_item profile_item_max_tree_version_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_max_tree_version_id_fkey FOREIGN KEY (max_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: profile_item profile_item_min_tree_version_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_min_tree_version_id_fkey FOREIGN KEY (min_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: profile_item profile_item_namespace_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: profile_item profile_item_profile_item_config_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_profile_item_config_id_fkey FOREIGN KEY (profile_item_config_id) REFERENCES temp_profile.profile_item_config(id);


--
-- Name: profile_item profile_item_profile_text_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_profile_text_id_fkey FOREIGN KEY (profile_text_id) REFERENCES temp_profile.profile_text(id);


--
-- Name: profile_item profile_item_quotes_profile_item_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_quotes_profile_item_id_fkey FOREIGN KEY (quotes_profile_item_id) REFERENCES temp_profile.profile_item(id);


--
-- Name: profile_item profile_item_tree_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item
    ADD CONSTRAINT profile_item_tree_id_fkey FOREIGN KEY (tree_id) REFERENCES public.tree(id);


--
-- Name: profile_item_config profile_item_type_profile_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item_config
    ADD CONSTRAINT profile_item_type_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES temp_profile.profile(id);


--
-- Name: profile_item_config profile_item_type_profile_object_type_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_item_config
    ADD CONSTRAINT profile_item_type_profile_object_type_id_fkey FOREIGN KEY (profile_object_type_id) REFERENCES temp_profile.profile_object_type(id);


--
-- Name: profile_reference profile_reference_profile_item_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_reference
    ADD CONSTRAINT profile_reference_profile_item_id_fkey FOREIGN KEY (profile_item_id) REFERENCES temp_profile.profile_item(id);


--
-- Name: profile_reference profile_reference_reference_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_reference
    ADD CONSTRAINT profile_reference_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: profile_text profile_text_namespace_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_text
    ADD CONSTRAINT profile_text_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: profile_text profile_text_profile_object_type_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile_text
    ADD CONSTRAINT profile_text_profile_object_type_id_fkey FOREIGN KEY (profile_object_type_id) REFERENCES temp_profile.profile_object_type(id);


--
-- Name: profile profile_tree_id_fkey; Type: FK CONSTRAINT; Schema: temp_profile; Owner: -
--

ALTER TABLE ONLY temp_profile.profile
    ADD CONSTRAINT profile_tree_id_fkey FOREIGN KEY (tree_id) REFERENCES public.tree(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public, loader, archive;



