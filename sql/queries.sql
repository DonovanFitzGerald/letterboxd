--  creating a user 

INSERT INTO users (name, email, password, profile_image, created_at, updated_at)
VALUES (?, ?, ?, ?, NOW(), NOW());

-- get profile by user id with follower and following counts 

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
WHERE u.id = ?
GROUP BY u.id;

--  update user profile 

UPDATE users
SET 
    name = ?,
    profile_image = ?,
    updated_at = NOW()
WHERE id = ?;

-- create a new watch log

INSERT INTO watches (
    liked, is_private, rating, review_text,
    movie_id, user_id, created_at, updated_at
)
VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW());

-- remove from watchlist automatically after logging

DELETE mlm
FROM movie_lists_movie mlm
JOIN movie_lists ml ON ml.id = mlm.movie_list_id
WHERE ml.user_id = ?
  AND ml.is_watch_list = 1
  AND mlm.movie_id = ?;

-- search movies by name

SELECT id, name, release_date, bio
FROM movie
WHERE LOWER(name) LIKE CONCAT('%', LOWER(?), '%');

-- search actors or crew by name

SELECT DISTINCT p.id, p.name, p.bio
FROM people p
WHERE LOWER(p.name) LIKE CONCAT('%', LOWER(?), '%');

-- follow a user

INSERT IGNORE INTO user_follows (user_id, follow_user_id, created_at)
VALUES (?, ?, NOW());

-- get activity feed from followed users

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
JOIN movie m ON m.id = w.movie_id
WHERE uf.user_id = ?
ORDER BY w.created_at DESC
LIMIT 20;

-- create a new list 

INSERT INTO movie_lists (
    name, is_watch_list, is_private,
    user_id, created_at, updated_at
)
VALUES (?, ?, ?, ?, NOW(), NOW());

-- add a movie to a user 

INSERT IGNORE INTO movie_lists_movie (
    movie_list_id, movie_id, created_at
)
VALUES (?, ?, NOW());

--  get a users watchlist with movie details

SELECT 
    m.id,
    m.name,
    m.release_date,
    m.bio,
    mlm.created_at AS added_at
FROM movie_lists ml
JOIN movie_lists_movie mlm ON ml.id = mlm.movie_list_id
JOIN movie m ON m.id = mlm.movie_id
WHERE ml.user_id = ?
  AND ml.is_watch_list = 1
ORDER BY mlm.created_at DESC;

-- average rating for a film

SELECT 
    AVG(rating) AS average_rating
FROM watches
WHERE movie_id = ? AND rating IS NOT NULL;

-- film summary statistics

SELECT
    m.id,
    m.name,
    COUNT(w.id) AS total_watches,
    SUM(CASE WHEN w.liked = 1 THEN 1 ELSE 0 END) AS total_likes,
    COUNT(DISTINCT mlm.movie_list_id) AS list_count
FROM movie m
LEFT JOIN watches w ON w.movie_id = m.id
LEFT JOIN movie_lists_movie mlm ON mlm.movie_id = m.id
WHERE m.id = ?
GROUP BY m.id, m.name;
