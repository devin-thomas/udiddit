BEGIN;

DROP TABLE IF EXISTS votes CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS topics CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(25) NOT NULL,
    last_logged_in_at TIMESTAMPTZ,
    CONSTRAINT users_username_not_blank CHECK (length(btrim(username)) > 0),
    CONSTRAINT users_username_unique UNIQUE (username)
);

CREATE TABLE topics (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    description VARCHAR(500),
    creator_user_id BIGINT,
    CONSTRAINT topics_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT topics_name_unique UNIQUE (name),
    CONSTRAINT topics_description_length CHECK (
        description IS NULL OR length(description) <= 500
    ),
    CONSTRAINT topics_creator_user_id_fkey
        FOREIGN KEY (creator_user_id)
        REFERENCES users (id)
        ON DELETE SET NULL
);

-- The supplied source data includes 152 titles longer than 100 characters.
-- This schema keeps the full legacy titles so the migration remains lossless.
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    topic_id BIGINT NOT NULL,
    user_id BIGINT,
    title VARCHAR(150) NOT NULL,
    url VARCHAR(4000),
    text_content TEXT,
    CONSTRAINT posts_topic_id_fkey
        FOREIGN KEY (topic_id)
        REFERENCES topics (id)
        ON DELETE CASCADE,
    CONSTRAINT posts_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE SET NULL,
    CONSTRAINT posts_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT posts_url_not_blank CHECK (
        url IS NULL OR length(btrim(url)) > 0
    ),
    CONSTRAINT posts_text_content_not_blank CHECK (
        text_content IS NULL OR length(btrim(text_content)) > 0
    ),
    CONSTRAINT posts_exactly_one_content_source CHECK (
        (url IS NULL) <> (text_content IS NULL)
    )
);

CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT,
    parent_comment_id BIGINT,
    text_content TEXT NOT NULL,
    CONSTRAINT comments_post_id_fkey
        FOREIGN KEY (post_id)
        REFERENCES posts (id)
        ON DELETE CASCADE,
    CONSTRAINT comments_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE SET NULL,
    CONSTRAINT comments_text_content_not_blank CHECK (
        length(btrim(text_content)) > 0
    ),
    CONSTRAINT comments_id_post_id_unique UNIQUE (id, post_id),
    CONSTRAINT comments_parent_comment_same_post_fkey
        FOREIGN KEY (parent_comment_id, post_id)
        REFERENCES comments (id, post_id)
        ON DELETE CASCADE
);

CREATE TABLE votes (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT,
    vote SMALLINT NOT NULL,
    CONSTRAINT votes_post_id_fkey
        FOREIGN KEY (post_id)
        REFERENCES posts (id)
        ON DELETE CASCADE,
    CONSTRAINT votes_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE SET NULL,
    CONSTRAINT votes_vote_value_check CHECK (vote IN (-1, 1)),
    CONSTRAINT votes_user_id_post_id_unique UNIQUE (user_id, post_id)
);

CREATE INDEX users_last_logged_in_at_idx
    ON users (last_logged_in_at);

CREATE INDEX topics_creator_user_id_idx
    ON topics (creator_user_id);

CREATE INDEX posts_topic_id_post_id_desc_idx
    ON posts (topic_id, id DESC);

CREATE INDEX posts_user_id_post_id_desc_idx
    ON posts (user_id, id DESC);

CREATE INDEX posts_url_idx
    ON posts (url)
    WHERE url IS NOT NULL;

CREATE INDEX comments_post_top_level_desc_idx
    ON comments (post_id, id DESC)
    WHERE parent_comment_id IS NULL;

CREATE INDEX comments_parent_comment_id_desc_idx
    ON comments (parent_comment_id, id DESC);

CREATE INDEX comments_user_id_comment_id_desc_idx
    ON comments (user_id, id DESC);

CREATE INDEX votes_post_id_idx
    ON votes (post_id);

COMMIT;
