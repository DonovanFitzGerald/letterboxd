-- Create roles
DROP ROLE IF EXISTS 'role_data_analyst';
DROP ROLE IF EXISTS 'role_content_manager';
DROP ROLE IF EXISTS 'role_admin';

CREATE ROLE 'role_data_analyst';
CREATE ROLE 'role_content_manager';
CREATE ROLE 'role_admin';

-- ---------------------------------------------------------
-- Data Analyst - read-only access to all data
-- ---------------------------------------------------------
GRANT SELECT ON letterboxd.* TO 'role_data_analyst';

-- ---------------------------------------------------------
-- Content Manager - modify film metadata, cast info, and handle content
-- ---------------------------------------------------------

-- Film metadata
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie          TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.genre          TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_genre   TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.studios         TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_studios  TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.languages       TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_languages TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.countries       TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.events          TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.releases        TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_releases TO 'role_content_manager';

-- Cast & crew info
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.person          TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.cast     TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.crew     TO 'role_content_manager';

-- Content moderation
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.tags            TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_lists     TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_lists_movie TO 'role_content_manager';
GRANT SELECT, INSERT, UPDATE, DELETE
    ON letterboxd.movie_lists_tags   TO 'role_content_manager';
GRANT SELECT, UPDATE, DELETE
    ON letterboxd.watch_comments  TO 'role_content_manager';

-- Read access for sensitive tables
GRANT SELECT ON letterboxd.users   TO 'role_content_manager';
GRANT SELECT ON letterboxd.watches TO 'role_content_manager';

-- ---------------------------------------------------------
-- Admin - full access
-- ---------------------------------------------------------
GRANT ALL PRIVILEGES ON letterboxd.* TO 'role_admin' WITH GRANT OPTION;

-- ---------------------------------------------------------
-- Assign roles to users 
-- ---------------------------------------------------------
GRANT 'role_data_analyst'     TO 'analyst_readonly'@'localhost';
GRANT 'role_content_manager'  TO 'content_mgr'@'localhost';
GRANT 'role_admin'            TO 'admin'@'localhost';