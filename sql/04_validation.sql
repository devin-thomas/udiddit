DO $$
DECLARE
    expected_users BIGINT;
    actual_users BIGINT;
    expected_topics BIGINT;
    actual_topics BIGINT;
    expected_posts BIGINT;
    actual_posts BIGINT;
    expected_comments BIGINT;
    actual_comments BIGINT;
    expected_votes BIGINT;
    actual_votes BIGINT;
BEGIN
    WITH source_users AS (
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
    )
    SELECT count(*)
    INTO expected_users
    FROM source_users
    WHERE username IS NOT NULL
      AND username <> '';

    SELECT count(*) INTO actual_users FROM users;

    IF actual_users <> expected_users THEN
        RAISE EXCEPTION 'users count mismatch: expected %, got %', expected_users, actual_users;
    END IF;

    SELECT count(DISTINCT btrim(topic))
    INTO expected_topics
    FROM bad_posts
    WHERE topic IS NOT NULL
      AND btrim(topic) <> '';

    SELECT count(*) INTO actual_topics FROM topics;

    IF actual_topics <> expected_topics THEN
        RAISE EXCEPTION 'topics count mismatch: expected %, got %', expected_topics, actual_topics;
    END IF;

    SELECT count(*) INTO expected_posts FROM bad_posts;
    SELECT count(*) INTO actual_posts FROM posts;

    IF actual_posts <> expected_posts THEN
        RAISE EXCEPTION 'posts count mismatch: expected %, got %', expected_posts, actual_posts;
    END IF;

    SELECT count(*) INTO expected_comments FROM bad_comments;
    SELECT count(*) INTO actual_comments FROM comments;

    IF actual_comments <> expected_comments THEN
        RAISE EXCEPTION 'comments count mismatch: expected %, got %', expected_comments, actual_comments;
    END IF;

    WITH source_votes AS (
        SELECT btrim(voter) AS username
        FROM bad_posts
        CROSS JOIN LATERAL regexp_split_to_table(coalesce(upvotes, ''), ',') AS voter
        WHERE btrim(voter) <> ''

        UNION ALL

        SELECT btrim(voter) AS username
        FROM bad_posts
        CROSS JOIN LATERAL regexp_split_to_table(coalesce(downvotes, ''), ',') AS voter
        WHERE btrim(voter) <> ''
    )
    SELECT count(*) INTO expected_votes FROM source_votes;

    SELECT count(*) INTO actual_votes FROM votes;

    IF actual_votes <> expected_votes THEN
        RAISE EXCEPTION 'votes count mismatch: expected %, got %', expected_votes, actual_votes;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM posts
        WHERE (url IS NULL) = (text_content IS NULL)
    ) THEN
        RAISE EXCEPTION 'at least one post violates the one-content-source rule';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM comments
        WHERE length(btrim(text_content)) = 0
    ) THEN
        RAISE EXCEPTION 'at least one comment has blank text_content';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM votes
        WHERE vote NOT IN (-1, 1)
    ) THEN
        RAISE EXCEPTION 'at least one vote has an invalid value';
    END IF;

    IF EXISTS (
        SELECT post_id, user_id
        FROM votes
        WHERE user_id IS NOT NULL
        GROUP BY post_id, user_id
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'at least one non-null user voted more than once on the same post';
    END IF;
END $$;

SELECT
    (SELECT count(*) FROM users) AS users,
    (SELECT count(*) FROM topics) AS topics,
    (SELECT count(*) FROM posts) AS posts,
    (SELECT count(*) FROM comments) AS comments,
    (SELECT count(*) FROM votes) AS votes;
