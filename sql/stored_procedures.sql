-- Drop any procedures if they exist
DROP PROCEDURE IF EXISTS create_user;
DROP PROCEDURE IF EXISTS log_watch;
DROP PROCEDURE IF EXISTS follow_user;
DROP PROCEDURE IF EXISTS create_movie_list;
DROP PROCEDURE IF EXISTS add_movie_to_list;
DROP PROCEDURE IF EXISTS search_movie;
DROP PROCEDURE IF EXISTS delete_user;

-- create an account
DELIMITER $$

CREATE PROCEDURE create_user (
  IN p_name VARCHAR(50),
  IN p_email VARCHAR(50),
  IN p_password CHAR(64)
)
BEGIN
  INSERT INTO users (name, email, password, created_at, updated_at)
  VALUES (p_name, p_email, p_password, NOW(), NOW());
END$$

DELIMITER ;

-- log a movie as watched

DELIMITER $$

CREATE PROCEDURE log_watch (
  IN p_user_id BIGINT,
  IN p_movie_id BIGINT,
  IN p_rating INT,
  IN p_liked TINYINT,
  IN p_review TEXT,
  IN p_is_private TINYINT
)
BEGIN
  START TRANSACTION;

  INSERT INTO watches (user_id, movie_id, rating, liked, review_text, is_private, created_at, updated_at)
  VALUES (p_user_id, p_movie_id, p_rating, p_liked, p_review, p_is_private, NOW(), NOW());

  DELETE FROM movie_lists_movie
  WHERE movie_id = p_movie_id
    AND movie_list_id IN (
      SELECT id FROM movie_lists
      WHERE user_id = p_user_id AND is_watch_list = 1
    );

  COMMIT;
END$$

DELIMITER ;

-- follow a user 

DELIMITER $$

CREATE PROCEDURE follow_user (
  IN p_user_id BIGINT,
  IN p_follow_user_id BIGINT
)
BEGIN
  INSERT IGNORE INTO user_follows (user_id, follow_user_id, created_at)
  VALUES (p_u, p_fser_idollow_user_id, NOW());
END$$

DELIMITER ;

-- create a movie list

DELIMITER $$

CREATE PROCEDURE create_movie_list (
  IN p_user_id BIGINT,
  IN p_name VARCHAR(50),
  IN p_is_private TINYINT
)
BEGIN
  INSERT INTO movie_lists (user_id, name, is_private, is_watch_list,
                           created_at, updated_at)
  VALUES (p_user_id, p_name, p_is_private, 0, NOW(), NOW());
END$$

DELIMITER ;

-- add a movie to a list

DELIMITER $$

CREATE PROCEDURE add_movie_to_list (
  IN p_list_id BIGINT,
  IN p_movie_id BIGINT
)
BEGIN
  INSERT IGNORE INTO movie_lists_movie
  (movie_list_id, movie_id, created_at)
  VALUES (p_list_id, p_movie_id, NOW());
END$$

DELIMITER ;

-- search for a movie

DELIMITER $$

CREATE PROCEDURE search_movie (
  IN p_query VARCHAR(50)
)
BEGIN
  SELECT id, name, release_date
  FROM movie
  WHERE name LIKE CONCAT('%', p_query, '%');
END$$

DELIMITER ;

-- delete a user 

DELIMITER $$

CREATE PROCEDURE delete_user (
  IN p_user_id BIGINT
)
BEGIN
  START TRANSACTION;

  DELETE FROM users WHERE id = p_user_id;

  COMMIT;
END$$

DELIMITER ;
