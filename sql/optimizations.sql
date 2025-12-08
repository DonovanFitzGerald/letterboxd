-- ---------------------------------------------------------
-- MARK: Indexes
-- ---------------------------------------------------------

-- Drop any indexes if they exist
ALTER TABLE user_follows DROP INDEX IF EXISTS idx_user_follows_user_id;
ALTER TABLE user_follows DROP INDEX IF EXISTS idx_user_follows_follow_user_id;
ALTER TABLE movie_lists DROP INDEX IF EXISTS idx_movie_lists_user_watchlist;
ALTER TABLE movie_lists_movie DROP INDEX IF EXISTS idx_movie_lists_movie_list_movie;
ALTER TABLE movie_lists_movie DROP INDEX IF EXISTS idx_movie_lists_movie_list_created_at;
ALTER TABLE movie_lists_movie DROP INDEX IF EXISTS idx_movie_lists_movie_movie;
ALTER TABLE movie DROP INDEX IF EXISTS ft_movie_title;
ALTER TABLE people DROP INDEX IF EXISTS ft_people_name;
ALTER TABLE watches DROP INDEX IF EXISTS idx_watches_user_created_at;
ALTER TABLE watches DROP INDEX IF EXISTS idx_watches_movie_rating;

-- Following lookups
CREATE INDEX idx_user_follows_user_id
    ON user_follows (user_id);

CREATE INDEX idx_user_follows_follow_user_id
    ON user_follows (follow_user_id);

-- Filter movie_lists by user + watch_list flag
CREATE INDEX idx_movie_lists_user_watchlist
    ON movie_lists (user_id, is_watch_list);

-- Lookup for movie_lists pivot table
CREATE INDEX idx_movie_lists_movie_list_movie
    ON movie_lists_movie (movie_list_id, movie_id);

-- Full text search on movie titles
CREATE FULLTEXT INDEX ft_movie_title
    ON movie (title);

-- Text search on people names
CREATE FULLTEXT INDEX ft_people_name
    ON people (name);

-- Get watches for a user ordered by recency
CREATE INDEX idx_watches_user_created_at
    ON watches (user_id, created_at);

-- Ordering by added_at within a list
CREATE INDEX idx_movie_lists_movie_list_created_at
    ON movie_lists_movie (movie_list_id, created_at);

-- Query ratings for a movie quickly
CREATE INDEX idx_watches_movie_rating
    ON watches (movie_id, rating);

-- Speed up lookups for number of lists made that contain a movie
CREATE INDEX idx_movie_lists_movie_movie
    ON movie_lists_movie (movie_id);


-- ---------------------------------------------------------
-- MARK: Views
-- ---------------------------------------------------------

-- Drop views if they exist
DROP VIEW IF EXISTS v_user_engagement;
DROP VIEW IF EXISTS v_watches_with_user_movie;
DROP VIEW IF EXISTS v_user_watchlist;
DROP VIEW IF EXISTS v_movie_stats;
DROP VIEW IF EXISTS v_movie_metadata;
DROP VIEW IF EXISTS v_user_profile_summary;

-- Aggregated user data
CREATE VIEW v_user_profile_summary AS
SELECT 
    u.id,
    u.name,
    u.email,
    u.profile_image,
    u.created_at,
    COUNT(DISTINCT f1.id) AS following_count,
    COUNT(DISTINCT f2.id) AS follower_count
FROM users u
LEFT JOIN user_follows f1 ON f1.user_id = u.id
LEFT JOIN user_follows f2 ON f2.follow_user_id = u.id
GROUP BY u.id, u.name, u.email, u.profile_image, u.created_at;

-- Movie rating and popularity stats
CREATE VIEW v_movie_stats AS
SELECT
    m.id                  AS movie_id,
    m.title                AS movie_name,
    AVG(w.rating)         AS average_rating,
    COUNT(w.id)           AS total_watches,
    SUM(CASE WHEN w.liked = 1 THEN 1 ELSE 0 END) AS total_likes,
    COUNT(DISTINCT mlm.movie_list_id)            AS list_count
FROM movie m
LEFT JOIN watches w
        ON w.movie_id = m.id AND w.rating IS NOT NULL
LEFT JOIN movie_lists_movie mlm
        ON mlm.movie_id = m.id
GROUP BY m.id, m.title;

-- User watchlist with movie details
CREATE VIEW v_user_watchlist AS
SELECT 
    ml.user_id,
    m.id            AS movie_id,
    m.title          AS movie_name,
    m.release_date,
    m.overview,
    mlm.created_at  AS added_at
FROM movie_lists ml
JOIN movie_lists_movie mlm ON ml.id = mlm.movie_list_id
JOIN movie m               ON m.id = mlm.movie_id
WHERE ml.is_watch_list = 1;

-- Watches joined with users
CREATE VIEW v_watches_with_user_movie AS
SELECT 
    w.id           AS watch_id,
    w.user_id,
    u.name         AS user_name,
    w.movie_id,
    m.title         AS movie_name,
    w.rating,
    w.liked,
    w.review_text,
    w.created_at
FROM watches w
JOIN users  u ON u.id = w.user_id
JOIN movie m ON m.id = w.movie_id;

-- User engagement summary
CREATE VIEW v_user_engagement AS
SELECT
    u.id AS user_id,
    u.name,
    u.created_at,
    COUNT(DISTINCT w.id)           AS total_watches,
    COUNT(DISTINCT wc.id)          AS total_comments,
    COUNT(DISTINCT ml.id)          AS total_lists
FROM users u
LEFT JOIN watches w
        ON w.user_id = u.id
LEFT JOIN watch_comments wc
        ON wc.user_id = u.id
LEFT JOIN movie_lists ml
        ON ml.user_id = u.id
GROUP BY u.id, u.name, u.created_at;

-- Movies with basic metadata
CREATE VIEW v_movie_metadata AS
SELECT
    m.id          AS movie_id,
    m.title        AS movie_name,
    m.release_date,
    m.overview
FROM movie m;


