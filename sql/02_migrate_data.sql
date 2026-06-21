BEGIN;

TRUNCATE TABLE votes, comments, posts, topics, users RESTART IDENTITY CASCADE;

INSERT INTO users (username)
SELECT username
FROM (
    SELECT btrim(username) AS username
    FROM bad_posts

    UNION

    SELECT btrim(username) AS username
    FROM bad_comments

    UNION

    SELECT btrim(voter) AS username
    FROM bad_posts
    CROSS JOIN LATERAL regexp_split_to_table(coalesce(upvotes, ''), ',') AS voter

    UNION

    SELECT btrim(voter) AS username
    FROM bad_posts
    CROSS JOIN LATERAL regexp_split_to_table(coalesce(downvotes, ''), ',') AS voter
) AS distinct_usernames
WHERE username IS NOT NULL
  AND username <> ''
ORDER BY username;

INSERT INTO topics (name, description, creator_user_id)
SELECT DISTINCT
    btrim(topic) AS name,
    NULL AS description,
    NULL::BIGINT AS creator_user_id
FROM bad_posts
WHERE topic IS NOT NULL
  AND btrim(topic) <> ''
ORDER BY name;

INSERT INTO posts (id, topic_id, user_id, title, url, text_content)
SELECT
    bp.id,
    t.id AS topic_id,
    u.id AS user_id,
    bp.title,
    bp.url,
    bp.text_content
FROM bad_posts AS bp
JOIN topics AS t
    ON t.name = btrim(bp.topic)
LEFT JOIN users AS u
    ON u.username = btrim(bp.username)
ORDER BY bp.id;

INSERT INTO comments (id, post_id, user_id, parent_comment_id, text_content)
SELECT
    bc.id,
    p.id AS post_id,
    u.id AS user_id,
    NULL::BIGINT AS parent_comment_id,
    bc.text_content
FROM bad_comments AS bc
JOIN posts AS p
    ON p.id = bc.post_id
LEFT JOIN users AS u
    ON u.username = btrim(bc.username)
ORDER BY bc.id;

WITH exploded_votes AS (
    SELECT
        bp.id AS post_id,
        btrim(voter) AS username,
        1::SMALLINT AS vote
    FROM bad_posts AS bp
    CROSS JOIN LATERAL regexp_split_to_table(coalesce(bp.upvotes, ''), ',') AS voter
    WHERE btrim(voter) <> ''

    UNION ALL

    SELECT
        bp.id AS post_id,
        btrim(voter) AS username,
        (-1)::SMALLINT AS vote
    FROM bad_posts AS bp
    CROSS JOIN LATERAL regexp_split_to_table(coalesce(bp.downvotes, ''), ',') AS voter
    WHERE btrim(voter) <> ''
)
INSERT INTO votes (post_id, user_id, vote)
SELECT
    ev.post_id,
    u.id AS user_id,
    ev.vote
FROM exploded_votes AS ev
JOIN users AS u
    ON u.username = ev.username
ORDER BY ev.post_id, u.id, ev.vote DESC;

SELECT setval(
    pg_get_serial_sequence('posts', 'id'),
    coalesce((SELECT max(id) FROM posts), 1),
    true
);

SELECT setval(
    pg_get_serial_sequence('comments', 'id'),
    coalesce((SELECT max(id) FROM comments), 1),
    true
);

COMMIT;
