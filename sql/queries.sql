-- Create user
CALL sp_create_user('Alice', 'alice@mail.com', 'hashed_pw', NULL);

-- Get user profile
CALL sp_get_user_profile(1);

-- Update profile
CALL sp_update_user_profile(1, 'Alice Updated', NULL);

-- Log a watch
CALL sp_log_watch(1, 11, 1, 0, 5, 'Amazing movie');

-- Search movies
CALL sp_search_movies('matrix');

-- Search person
CALL sp_search_person('nolan');

-- Follow a user
CALL sp_follow_user(1, 2);

-- Unfollow a user
CALL sp_unfollow_user(1, 2);

-- Get feed/activity from followed users (user_id, limit, offset)
CALL sp_get_user_feed(1, 20, 0);

-- Create watchlist
CALL sp_create_list(1, 'My Watchlist', 1, 0);

-- Add movie to list
CALL sp_add_movie_to_list(1, 10);

-- Get watchlist with movie details
CALL sp_get_watchlist(1);

-- Remove movie from watchlist
CALL sp_remove_from_watchlist(1, 10);

-- Movie stats (includes average rating and watch counts by timeframe)
CALL sp_get_movie_stats(10);

-- Delete user
CALL sp_delete_user(1);
