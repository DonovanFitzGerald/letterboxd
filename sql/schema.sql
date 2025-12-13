-- Drop tables in reverse order
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS movie_releases;
DROP TABLE IF EXISTS releases;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS countries;
DROP TABLE IF EXISTS movie_studios;
DROP TABLE IF EXISTS studios;
DROP TABLE IF EXISTS movie_languages;
DROP TABLE IF EXISTS languages;
DROP TABLE IF EXISTS movie_lists_tags;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS movie_lists_movie;
DROP TABLE IF EXISTS movie_lists;
DROP TABLE IF EXISTS watch_comments;
DROP TABLE IF EXISTS watches;
DROP TABLE IF EXISTS user_follows;
DROP TABLE IF EXISTS users;        

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- MARK: Create all tables
-- ---------------------------------------------------------


CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  email VARCHAR(50) NOT NULL UNIQUE,
  profile_image CHAR(200),
  password CHAR(64) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);


CREATE TABLE user_follows (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  follow_user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (follow_user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, follow_user_id)
);


CREATE TABLE watches (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  liked TINYINT NOT NULL,
  is_private TINYINT NOT NULL,
  rating INT(10),
  review_text TEXT,
  movie_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (movie_id) REFERENCES movie(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);


CREATE TABLE watch_comments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  liked TINYINT NOT NULL,
  comment_text TEXT,
  user_id BIGINT UNSIGNED NOT NULL,
  watch_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (watch_id) REFERENCES watches(id) ON DELETE CASCADE
);


CREATE TABLE movie_lists (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  is_watch_list TINYINT NOT NULL,
  is_private TINYINT NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE movie_lists_movie (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  movie_list_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (movie_list_id) REFERENCES movie_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (movie_id) REFERENCES movie(id) ON DELETE CASCADE,
  UNIQUE (movie_list_id, movie_id)
);


CREATE TABLE tags (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE TABLE movie_lists_tags (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  is_primary TINYINT NOT NULL,
  movie_list_id BIGINT UNSIGNED NOT NULL,
  tag_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (movie_list_id) REFERENCES movie_lists(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
  UNIQUE (movie_list_id, tag_id)
);

CREATE TABLE languages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE TABLE movie_languages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  is_primary TINYINT NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  language_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (movie_id) REFERENCES movie(id) ON DELETE CASCADE,
  FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE,
  UNIQUE (movie_id, language_id)
);


CREATE TABLE studios (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  bio TEXT NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE TABLE movie_studios (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  movie_id BIGINT UNSIGNED NOT NULL,
  studio_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (movie_id) REFERENCES movie(id) ON DELETE CASCADE,
  FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE,
  UNIQUE (movie_id, studio_id)
);


CREATE TABLE countries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  flag_url CHAR(50) NOT NULL
);

CREATE TABLE events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  date DATE NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE TABLE releases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name CHAR(50) NOT NULL,
  date DATE NOT NULL,
  release_type ENUM('theatrical','digital','dvd','festival') NOT NULL,
  event_id BIGINT UNSIGNED,
  country_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (event_id) REFERENCES events(id),
  FOREIGN KEY (country_id) REFERENCES countries(id)
);

CREATE TABLE movie_releases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  movie_id BIGINT UNSIGNED NOT NULL,
  release_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (movie_id) REFERENCES movie(id) ON DELETE CASCADE,
  FOREIGN KEY (release_id) REFERENCES releases(id) ON DELETE CASCADE,
  UNIQUE (movie_id, release_id)
);