

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

    DELETE mlm
    FROM movie_lists_movies mlm
    JOIN movie_lists ml ON ml.id = mlm.movie_list_id
    WHERE ml.user_id = p_user_id
      AND ml.is_watch_list = 1
      AND mlm.movie_id = p_movie_id;

    COMMIT;
END $$




-- search movies by name
CREATE PROCEDURE sp_search_movies (
    IN p_query VARCHAR(100)
)
BEGIN
    SELECT id, name, release_date, bio
    FROM movies
    WHERE LOWER(name) LIKE CONCAT('%', LOWER(p_query), '%');
END $$


-- search people by name
CREATE PROCEDURE sp_search_people (
    IN p_query VARCHAR(100)
)
BEGIN
    SELECT DISTINCT p.id, p.name, p.bio
    FROM people p
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


-- get activity feed from followed users
CREATE PROCEDURE sp_get_following_activity (
    IN p_user_id BIGINT
)
BEGIN
    SELECT 
        w.id AS watch_id,
        u.id AS user_id,
        u.name AS user_name,
        m.id AS movie_id,
        m.name AS movie_name,
        w.rating,
        w.liked,
        w.review_text,
        w.created_at
    FROM watches w
    JOIN user_follows uf ON uf.follow_user_id = w.user_id
    JOIN users u ON u.id = w.user_id
    JOIN movies m ON m.id = w.movie_id
    WHERE uf.user_id = p_user_id
    ORDER BY w.created_at DESC
    LIMIT 20;
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
    INSERT IGNORE INTO movie_lists_movies (
        movie_list_id, movie_id, created_at
    )
    VALUES (p_movie_list_id, p_movie_id, NOW());
END $$


-- get user watchlist
CREATE PROCEDURE sp_get_watchlist (
    IN p_user_id BIGINT
)
BEGIN
    SELECT 
        m.id,
        m.name,
        m.release_date,
        m.bio,
        mlm.created_at AS added_at
    FROM movie_lists ml
    JOIN movie_lists_movies mlm ON ml.id = mlm.movie_list_id
    JOIN movies m ON m.id = mlm.movie_id
    WHERE ml.user_id = p_user_id
      AND ml.is_watch_list = 1
    ORDER BY mlm.created_at DESC;
END $$




-- get average movie rating
CREATE PROCEDURE sp_get_average_rating (
    IN p_movie_id BIGINT
)
BEGIN
    SELECT AVG(rating) AS average_rating
    FROM watches
    WHERE movie_id = p_movie_id
      AND rating IS NOT NULL;
END $$


-- get movie summary statistics
CREATE PROCEDURE sp_get_movie_stats (
    IN p_movie_id BIGINT
)
BEGIN
    SELECT
        m.id,
        m.name,
        COUNT(w.id) AS total_watches,
        SUM(CASE WHEN w.liked = 1 THEN 1 ELSE 0 END) AS total_likes,
        COUNT(DISTINCT mlm.movie_list_id) AS list_count
    FROM movies m
    LEFT JOIN watches w ON w.movie_id = m.id
    LEFT JOIN movie_lists_movies mlm ON mlm.movie_id = m.id
    WHERE m.id = p_movie_id
    GROUP BY m.id, m.name;
END $$

DELIMITER ;
