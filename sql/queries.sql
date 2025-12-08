-- Create user
CALL sp_create_user('Alice', 'alice@mail.com', 'hashed_pw', NULL);

-- Get user profile
CALL sp_get_user_profile(1);

-- Update profile
CALL sp_update_user_profile(1, 'Alice Updated', NULL);

-- Log a watch
CALL sp_log_watch(1, 10, 1, 0, 5, 'Amazing movie');

-- Search movies
CALL sp_search_movies('matrix');

-- Search people
CALL sp_search_people('nolan');

-- Follow a user
CALL sp_follow_user(1, 2);

-- Get feed
CALL sp_get_following_activity(1);

-- Create watchlist
CALL sp_create_list(1, 'My Watchlist', 1, 0);

-- Add movie to list
CALL sp_add_movie_to_list(1, 10);

-- Get watchlist
CALL sp_get_watchlist(1);

-- Average rating
CALL sp_get_average_rating(10);

-- Movie stats
CALL sp_get_movie_stats(10);
