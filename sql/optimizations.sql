-----------------------------------------------------------
-- MARK: Indexes
-----------------------------------------------------------

-- Following lookups
CREATE INDEX idx_user_follows_user_id
    ON user_follows (user_id);

CREATE INDEX idx_user_follows_follow_user_id
    ON user_follows (follow_user_id);

-- Filter movie_lists by user + watch_list flag
CREATE INDEX idx_movie_lists_user_watchlist
    ON movie_lists (user_id, is_watch_list);

-- Lookup for movie_lists pivot table
CREATE INDEX idx_movie_lists_movies_list_movie
    ON movie_lists_movies (movie_list_id, movie_id);

-- Full text search on movie titles
CREATE FULLTEXT INDEX ft_movies_name
    ON movies (name);

-- Text search on people names
CREATE FULLTEXT INDEX ft_people_name
    ON people (name);

-- Get watches for a user ordered by recency
CREATE INDEX idx_watches_user_created_at
    ON watches (user_id, created_at);

-- Ordering by added_at within a list
CREATE INDEX idx_movie_lists_movies_list_created_at
    ON movie_lists_movies (movie_list_id, created_at);

-- Query ratings for a movie quickly
CREATE INDEX idx_watches_movie_rating
    ON watches (movie_id, rating);

-- Speed up lookups of list membership per movie
CREATE INDEX idx_movie_lists_movies_movie
    ON movie_lists_movies (movie_id);
