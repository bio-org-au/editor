create or replace 
view loader.batch_stack_v
as
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
            (to_char(loader_batch.created_at, 'yyyymmdd'::text) || 'A batch '::text) || loader_batch.name::text AS order_by
           FROM loader_batch
        UNION
         SELECT 'Batch Review in stack'::text AS display_as,
            br.id,
            br.name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            br.created_at,
            br.created_at,
            (to_char(lb.created_at, 'yyyymmdd'::text) || (('A batch '::text || lb.name::text) || ' B review '::text)) || br.name::text AS order_by
           FROM batch_review br
             JOIN loader_batch lb ON br.loader_batch_id = lb.id
        UNION
         SELECT 'Review Period in stack'::text AS display_as,
            brp.id,
            ((((brp.name::text || ' ('::text) || to_char(brp.start_date::timestamp with time zone, 'DD-Mon-YYYY'::text)) ||
                CASE brp.end_date IS NULL
                    WHEN true THEN ' - '::text
                    ELSE ' end: '::text
                END) || COALESCE(to_char(brp.end_date::timestamp with time zone, 'DD-Mon-YYYY'::text), ''::text)) || ')'::text AS name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            brp.created_at,
            brp.start_date,
            (to_char(lb.created_at, 'yyyymmdd'::text) || (((('A batch '::text || lb.name::text) || ' B review '::text) || br.name::text) || ' C period '::text)) || brp.start_date AS order_by
           FROM batch_review_period brp
             JOIN batch_review br ON brp.batch_review_id = br.id
             JOIN loader_batch lb ON br.loader_batch_id = lb.id
        UNION
         SELECT 'Batch Reviewer in stack'::text AS display_as,
            brer.id,
            (((((users.given_name::text || ' '::text) || users.family_name::text) || ' for '::text) || org.abbrev::text) || ' as '::text) || brrole.name::text AS name,
            lb.name AS batch_name,
            lb.id AS batch_id,
            ''::text AS description,
            brer.created_at,
            brer.created_at,
            (to_char(lb.created_at, 'yyyymmdd'::text) || (((('A batch '::text || lb.name::text) || ' B review '::text) || br.name::text)  || ' '::text)) || users.name::text AS order_by
           FROM batch_reviewer brer
             JOIN batch_review br ON br.id = brer.batch_review_id
             JOIN users ON brer.user_id = users.id
             JOIN loader_batch lb ON br.loader_batch_id = lb.id
             JOIN org ON brer.org_id = org.id
             JOIN batch_review_role brrole ON brer.batch_review_role_id = brrole.id) subq
  ORDER BY subq.order_by;




grant select on loader.batch_stack_v to webapni;

