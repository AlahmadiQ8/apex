-- 002_seed_data.sql
-- Initial sample data for the Customer Feedback app.
-- Idempotent: uses MERGE so reruns do not duplicate rows.
-- The MERGE keys on (name, email) which is sufficient for demo seeding.

MERGE INTO cf_feedback t
USING (
    SELECT 'Ada Lovelace'      AS name, 'ada@example.com'      AS email, 5 AS rating, 'Excellent product!'                          AS comments FROM dual UNION ALL
    SELECT 'Alan Turing'       AS name, 'alan@example.com'     AS email, 4 AS rating, 'Solid, with room for polish.'                AS comments FROM dual UNION ALL
    SELECT 'Grace Hopper'      AS name, 'grace@example.com'    AS email, 5 AS rating, 'Saved our team hours every week.'            AS comments FROM dual UNION ALL
    SELECT 'Linus Torvalds'    AS name, 'linus@example.com'    AS email, 3 AS rating, 'Works fine, docs could be clearer.'          AS comments FROM dual UNION ALL
    SELECT 'Margaret Hamilton' AS name, 'margaret@example.com' AS email, 5 AS rating, 'Beautifully reliable.'                       AS comments FROM dual UNION ALL
    SELECT 'Dennis Ritchie'    AS name, 'dennis@example.com'   AS email, 4 AS rating, 'Minimal and to the point.'                   AS comments FROM dual UNION ALL
    SELECT 'Barbara Liskov'    AS name, 'barbara@example.com'  AS email, 4 AS rating, 'Strong abstractions.'                        AS comments FROM dual UNION ALL
    SELECT 'Ken Thompson'      AS name, 'ken@example.com'      AS email, 2 AS rating, 'Hit a snag with the export step.'            AS comments FROM dual UNION ALL
    SELECT 'Edsger Dijkstra'   AS name, 'edsger@example.com'   AS email, 5 AS rating, 'Goto-free deployments. Excellent.'           AS comments FROM dual UNION ALL
    SELECT 'Donald Knuth'      AS name, 'donald@example.com'   AS email, 5 AS rating, 'Premature optimization avoided. Approved.'   AS comments FROM dual
) s
ON (t.name = s.name AND NVL(t.email, '~') = NVL(s.email, '~'))
WHEN NOT MATCHED THEN
    INSERT (name, email, rating, comments)
    VALUES (s.name, s.email, s.rating, s.comments);

COMMIT;
