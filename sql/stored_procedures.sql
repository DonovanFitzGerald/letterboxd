-- Drop any procedures if they exist
DROP PROCEDURE IF EXISTS create_user;
DROP PROCEDURE IF EXISTS log_watch;
DROP PROCEDURE IF EXISTS follow_user;
DROP PROCEDURE IF EXISTS unfollow_user;
DROP PROCEDURE IF EXISTS create_movie_list;
DROP PROCEDURE IF EXISTS add_movie_to_list;
DROP PROCEDURE IF EXISTS search_movie;
DROP PROCEDURE IF EXISTS delete_user;
DROP PROCEDURE IF EXISTS sp_create_user;
DROP PROCEDURE IF EXISTS sp_get_user_profile;
DROP PROCEDURE IF EXISTS sp_update_user_profile;
DROP PROCEDURE IF EXISTS sp_log_watch;
DROP PROCEDURE IF EXISTS sp_search_movies;
DROP PROCEDURE IF EXISTS sp_search_person;
DROP PROCEDURE IF EXISTS sp_follow_user;
DROP PROCEDURE IF EXISTS sp_unfollow_user;
DROP PROCEDURE IF EXISTS sp_create_list;
DROP PROCEDURE IF EXISTS sp_add_movie_to_list;
DROP PROCEDURE IF EXISTS sp_get_movie_stats;
DROP PROCEDURE IF EXISTS sp_get_user_feed;
DROP PROCEDURE IF EXISTS sp_get_watchlist;
DROP PROCEDURE IF EXISTS sp_remove_from_watchlist;
DROP PROCEDURE IF EXISTS sp_delete_user;

-- create an account
DELIMITER $$

-- create a new user
CREATE PROCEDURE sp_create_user (
    IN p_name VARCHAR(50),
    IN p_email VARCHAR(50),
    IN p_password CHAR(64),
    IN p_profile_image CHAR(200)
)
BEGIN
    INSERT INTO users (name, email, password, profile_image, created_at, updated_at)
    VALUES (p_name, p_email, p_password, p_profile_image, NOW(), NOW());

    SELECT LAST_INSERT_ID() AS user_id;
END $$


-- get user profile with follower and following counts
CREATE PROCEDURE sp_get_user_profile (
    IN p_user_id BIGINT
)
BEGIN
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
    WHERE u.id = p_user_id
    GROUP BY u.id;
END $$


-- update user profile
CREATE PROCEDURE sp_update_user_profile (
    IN p_user_id BIGINT,
    IN p_name VARCHAR(50),
    IN p_profile_image CHAR(200)
)
BEGIN
    UPDATE users
    SET 
        name = p_name,
        profile_image = p_profile_image,
        updated_at = NOW()
    WHERE id = p_user_id;
END $$




-- create a watch log and remove from watchlist
CREATE PROCEDURE sp_log_watch (
    IN p_user_id BIGINT,
    IN p_movie_id BIGINT,
    IN p_liked TINYINT,
    IN p_is_private TINYINT,
    IN p_rating INT,
    IN p_review_text TEXT
)
BEGIN
    START TRANSACTION;

    INSERT INTO watches (
        liked, is_private, rating, review_text,
        movie_id, user_id, created_at, updated_at
    )
    VALUES (
        p_liked, p_is_private, p_rating, p_review_text,
        p_movie_id, p_user_id, NOW(), NOW()
    );

    DELETE FROM movie_lists_movie
    WHERE movie_id = p_movie_id
    AND movie_list_id IN (
        SELECT id FROM movie_lists
        WHERE user_id = p_user_id AND is_watch_list = 1
    );

    COMMIT;
END $$




-- search movies by title
CREATE PROCEDURE sp_search_movies (
    IN p_query VARCHAR(100)
)
BEGIN
    SELECT id, title, release_date, overview
    FROM movie
    WHERE LOWER(title) LIKE CONCAT('%', LOWER(p_query), '%');
END $$


-- search person by name
CREATE PROCEDURE sp_search_person (
    IN p_query VARCHAR(100)
)
BEGIN
    SELECT DISTINCT p.*
    FROM person p
    WHERE LOWER(p.name) LIKE CONCAT('%', LOWER(p_query), '%');
END $$




-- follow a user
CREATE PROCEDURE sp_follow_user (
    IN p_user_id BIGINT,
    IN p_follow_user_id BIGINT
)
BEGIN
    INSERT IGNORE INTO user_follows (user_id, follow_user_id, created_at)
    VALUES (p_user_id, p_follow_user_id, NOW());
END $$


-- unfollow a user
CREATE PROCEDURE sp_unfollow_user (
    IN p_user_id BIGINT,
    IN p_follow_user_id BIGINT
)
BEGIN
    DELETE FROM user_follows
    WHERE user_id = p_user_id
      AND follow_user_id = p_follow_user_id;
END $$





-- create a list
CREATE PROCEDURE sp_create_list (
    IN p_user_id BIGINT,
    IN p_name CHAR(50),
    IN p_is_watch_list TINYINT,
    IN p_is_private TINYINT
)
BEGIN
    INSERT INTO movie_lists (
        name, is_watch_list, is_private,
        user_id, created_at, updated_at
    )
    VALUES (p_name, p_is_watch_list, p_is_private, p_user_id, NOW(), NOW());

    SELECT LAST_INSERT_ID() AS movie_list_id;
END $$


-- add movie to list
CREATE PROCEDURE sp_add_movie_to_list (
    IN p_movie_list_id BIGINT,
    IN p_movie_id BIGINT
)
BEGIN
  INSERT IGNORE INTO movie_lists_movie
  (movie_list_id, movie_id, created_at)
  VALUES (p_movie_list_id, p_movie_id, NOW());
END$$


-- search for a movie
CREATE PROCEDURE search_movie (
  IN p_query VARCHAR(50)
)
BEGIN
  SELECT id, title, release_date
  FROM movie
  WHERE title LIKE CONCAT('%', p_query, '%');
END$$


-- get movie summary statistics with average rating and watch counts by timeframe
CREATE PROCEDURE sp_get_movie_stats (
    IN p_movie_id BIGINT
)
BEGIN
    SELECT
        m.id,
        m.title,
        AVG(w.rating) AS average_rating,
        COUNT(w.id) AS total_watches,
        SUM(CASE WHEN w.liked = 1 THEN 1 ELSE 0 END) AS total_likes,
        COUNT(DISTINCT mlm.movie_list_id) AS list_count,
        SUM(CASE WHEN w.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS watches_last_7_days,
        SUM(CASE WHEN w.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS watches_last_30_days,
        SUM(CASE WHEN w.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR) THEN 1 ELSE 0 END) AS watches_last_year
    FROM movie m
    LEFT JOIN watches w ON w.movie_id = m.id
    LEFT JOIN movie_lists_movie mlm ON mlm.movie_id = m.id
    WHERE m.id = p_movie_id
    GROUP BY m.id, m.title;
END $$


-- get user feed/activity from followed users
CREATE PROCEDURE sp_get_user_feed (
    IN p_user_id BIGINT,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT
        w.id AS watch_id,
        w.user_id,
        u.name AS user_name,
        u.profile_image,
        w.movie_id,
        m.title AS movie_title,
        m.release_date,
        w.rating,
        w.liked,
        w.review_text,
        w.created_at
    FROM watches w
    JOIN users u ON u.id = w.user_id
    JOIN movie m ON m.id = w.movie_id
    WHERE w.user_id IN (
        SELECT follow_user_id
        FROM user_follows
        WHERE user_id = p_user_id
    )
    AND w.is_private = 0
    ORDER BY w.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END $$


-- get user's watchlist with movie details
CREATE PROCEDURE sp_get_watchlist (
    IN p_user_id BIGINT
)
BEGIN
    SELECT
        mlm.id AS watchlist_item_id,
        m.id AS movie_id,
        m.title,
        m.release_date,
        m.overview,
        mlm.created_at AS added_at
    FROM movie_lists ml
    JOIN movie_lists_movie mlm ON ml.id = mlm.movie_list_id
    JOIN movie m ON m.id = mlm.movie_id
    WHERE ml.user_id = p_user_id
      AND ml.is_watch_list = 1
    ORDER BY mlm.created_at DESC;
END $$


-- remove a movie from user's watchlist
CREATE PROCEDURE sp_remove_from_watchlist (
    IN p_user_id BIGINT,
    IN p_movie_id BIGINT
)
BEGIN
    DELETE mlm FROM movie_lists_movie mlm
    JOIN movie_lists ml ON ml.id = mlm.movie_list_id
    WHERE ml.user_id = p_user_id
      AND ml.is_watch_list = 1
      AND mlm.movie_id = p_movie_id;
END $$


-- delete user with cascading delete
CREATE PROCEDURE sp_delete_user (
    IN p_user_id BIGINT
)
BEGIN
    DECLARE user_exists INT DEFAULT 0;

    -- Check if user exists
    SELECT COUNT(*) INTO user_exists FROM users WHERE id = p_user_id;

    IF user_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
    ELSE
        START TRANSACTION;

        DELETE FROM users WHERE id = p_user_id;

        COMMIT;
    END IF;
END $$

DELIMITER ;
