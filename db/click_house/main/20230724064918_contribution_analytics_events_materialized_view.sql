CREATE MATERIALIZED VIEW contribution_analytics_events_mv
TO contribution_analytics_events
AS
SELECT
    id,
    argMax(path, events.updated_at) as path,
    argMax(author_id, events.updated_at) as author_id,
    argMax(target_type, events.updated_at) as target_type,
    argMax(action, events.updated_at) as action,
    argMax(date(created_at), events.updated_at) as created_at,
    max(events.updated_at) as updated_at
FROM events
where (("events"."action" = 5 AND "events"."target_type" = '')
   OR ("events"."action" IN (1, 3, 7, 12)
  AND "events"."target_type" IN ('MergeRequest', 'Issue')))
GROUP BY id
