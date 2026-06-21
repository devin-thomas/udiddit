-- Update the literals in the params CTEs as needed before running each query.

-- 1. List all users who have not logged in in the last year.
SELECT id, username, last_logged_in_at
FROM users
WHERE last_logged_in_at IS NULL
   OR last_logged_in_at < now() - INTERVAL '1 year'
ORDER BY username;

-- 2. List all users who have not created any post.
SELECT u.id, u.username
FROM users AS u
LEFT JOIN posts AS p
    ON p.user_id = u.id
WHERE p.id IS NULL
ORDER BY u.username;

-- 3. Find a user by username.
WITH params AS (
    SELECT 'Chesley.Will22'::VARCHAR(25) AS username
)
SELECT u.*
FROM users AS u
JOIN params AS p
    ON u.username = p.username;

-- 4. List all topics that do not have any posts.
SELECT t.id, t.name
FROM topics AS t
LEFT JOIN posts AS p
    ON p.topic_id = t.id
WHERE p.id IS NULL
ORDER BY t.name;

-- 5. Find a topic by name.
WITH params AS (
    SELECT 'Applications'::VARCHAR(30) AS topic_name
)
SELECT t.*
FROM topics AS t
JOIN params AS p
    ON t.name = p.topic_name;

-- 6. List the latest 20 posts for a given topic.
WITH params AS (
    SELECT 'Applications'::VARCHAR(30) AS topic_name
)
SELECT p.id, p.title, p.url, p.text_content, u.username
FROM posts AS p
JOIN topics AS t
    ON t.id = p.topic_id
LEFT JOIN users AS u
    ON u.id = p.user_id
JOIN params AS par
    ON t.name = par.topic_name
ORDER BY p.id DESC
LIMIT 20;

-- 7. List the latest 20 posts made by a given user.
WITH params AS (
    SELECT 'Chesley.Will22'::VARCHAR(25) AS username
)
SELECT p.id, p.title, t.name AS topic_name
FROM posts AS p
JOIN users AS u
    ON u.id = p.user_id
JOIN topics AS t
    ON t.id = p.topic_id
JOIN params AS par
    ON u.username = par.username
ORDER BY p.id DESC
LIMIT 20;

-- 8. Find all posts that link to a specific URL.
WITH params AS (
    SELECT 'http://lesley.com'::VARCHAR(4000) AS target_url
)
SELECT p.id, p.title, u.username, t.name AS topic_name
FROM posts AS p
LEFT JOIN users AS u
    ON u.id = p.user_id
JOIN topics AS t
    ON t.id = p.topic_id
JOIN params AS par
    ON p.url = par.target_url
ORDER BY p.id;

-- 9. List all top-level comments for a given post.
WITH params AS (
    SELECT 1::BIGINT AS post_id
)
SELECT c.id, c.text_content, u.username
FROM comments AS c
LEFT JOIN users AS u
    ON u.id = c.user_id
JOIN params AS par
    ON c.post_id = par.post_id
WHERE c.parent_comment_id IS NULL
ORDER BY c.id DESC;

-- 10. List all direct children of a parent comment.
WITH params AS (
    SELECT 1::BIGINT AS parent_comment_id
)
SELECT c.id, c.post_id, c.text_content, u.username
FROM comments AS c
LEFT JOIN users AS u
    ON u.id = c.user_id
JOIN params AS par
    ON c.parent_comment_id = par.parent_comment_id
ORDER BY c.id;

-- 11. List the latest 20 comments made by a given user.
WITH params AS (
    SELECT 'Chesley.Will22'::VARCHAR(25) AS username
)
SELECT c.id, c.post_id, c.text_content
FROM comments AS c
JOIN users AS u
    ON u.id = c.user_id
JOIN params AS par
    ON u.username = par.username
ORDER BY c.id DESC
LIMIT 20;

-- 12. Compute the score of a post.
WITH params AS (
    SELECT 1::BIGINT AS post_id
)
SELECT
    p.id AS post_id,
    p.title,
    coalesce(sum(v.vote), 0) AS score
FROM posts AS p
LEFT JOIN votes AS v
    ON v.post_id = p.id
JOIN params AS par
    ON p.id = par.post_id
GROUP BY p.id, p.title;

-- Stand-out: retrieve a three-level nested JSON comment tree for a post.
WITH params AS (
    SELECT 1::BIGINT AS post_id
)
SELECT jsonb_pretty(
    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'comment_id', c1.id,
                'username', u1.username,
                'text_content', c1.text_content,
                'children', (
                    SELECT coalesce(
                        jsonb_agg(
                            jsonb_build_object(
                                'comment_id', c2.id,
                                'username', u2.username,
                                'text_content', c2.text_content,
                                'children', (
                                    SELECT coalesce(
                                        jsonb_agg(
                                            jsonb_build_object(
                                                'comment_id', c3.id,
                                                'username', u3.username,
                                                'text_content', c3.text_content
                                            )
                                            ORDER BY c3.id
                                        ),
                                        '[]'::JSONB
                                    )
                                    FROM comments AS c3
                                    LEFT JOIN users AS u3
                                        ON u3.id = c3.user_id
                                    WHERE c3.parent_comment_id = c2.id
                                )
                            )
                            ORDER BY c2.id
                        ),
                        '[]'::JSONB
                    )
                    FROM comments AS c2
                    LEFT JOIN users AS u2
                        ON u2.id = c2.user_id
                    WHERE c2.parent_comment_id = c1.id
                )
            )
            ORDER BY c1.id
        ),
        '[]'::JSONB
    )
) AS comment_tree
FROM comments AS c1
LEFT JOIN users AS u1
    ON u1.id = c1.user_id
JOIN params AS par
    ON c1.post_id = par.post_id
WHERE c1.parent_comment_id IS NULL;
