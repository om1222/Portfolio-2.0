-- ============================================================
-- Netflix Content Analytics | Schema Setup
-- Description: Creates a normalized star-schema-like model
--              for the Netflix catalog dataset (8,800+ titles)
-- ============================================================

CREATE DATABASE IF NOT EXISTS netflix_analytics;
USE netflix_analytics;

-- ─────────────────────────────────────────
-- 1. RAW STAGING TABLE  (import CSV here first)
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS raw_netflix_titles;

CREATE TABLE raw_netflix_titles (
    show_id      VARCHAR(10),
    type         VARCHAR(20),
    title        VARCHAR(300),
    director     VARCHAR(500),
    cast         TEXT,
    country      VARCHAR(500),
    date_added   VARCHAR(50),
    release_year INT,
    rating       VARCHAR(20),
    duration     VARCHAR(20),
    listed_in    VARCHAR(300),
    description  TEXT
);

-- Load CSV (update path as needed):
-- LOAD DATA INFILE '/path/to/netflix_titles.csv'
-- INTO TABLE raw_netflix_titles
-- FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;


-- ─────────────────────────────────────────
-- 2. NORMALIZED DIMENSION TABLES
-- ─────────────────────────────────────────

DROP TABLE IF EXISTS content_genre;
DROP TABLE IF EXISTS content_country;
DROP TABLE IF EXISTS content;
DROP TABLE IF EXISTS genre;
DROP TABLE IF EXISTS country;

CREATE TABLE content (
    content_id     INT AUTO_INCREMENT PRIMARY KEY,
    show_id        VARCHAR(10) UNIQUE NOT NULL,
    type           ENUM('Movie','TV Show') NOT NULL,
    title          VARCHAR(300) NOT NULL,
    director       VARCHAR(500),
    release_year   YEAR,
    rating         VARCHAR(20),
    duration_raw   VARCHAR(20),
    duration_value INT,
    duration_unit  VARCHAR(20),
    date_added     DATE,
    description    TEXT,
    INDEX idx_type         (type),
    INDEX idx_release_year (release_year),
    INDEX idx_rating       (rating),
    INDEX idx_date_added   (date_added)
);

CREATE TABLE genre (
    genre_id   INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE country (
    country_id   INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE content_genre (
    content_id INT NOT NULL,
    genre_id   INT NOT NULL,
    PRIMARY KEY (content_id, genre_id),
    FOREIGN KEY (content_id) REFERENCES content(content_id),
    FOREIGN KEY (genre_id)   REFERENCES genre(genre_id),
    INDEX idx_cg_genre   (genre_id),
    INDEX idx_cg_content (content_id)
);

CREATE TABLE content_country (
    content_id INT NOT NULL,
    country_id INT NOT NULL,
    PRIMARY KEY (content_id, country_id),
    FOREIGN KEY (content_id) REFERENCES content(content_id),
    FOREIGN KEY (country_id) REFERENCES country(country_id),
    INDEX idx_cc_country (country_id),
    INDEX idx_cc_content (content_id)
);


-- ─────────────────────────────────────────
-- 3. PRE-AGGREGATED SUMMARY TABLES
-- ─────────────────────────────────────────

DROP TABLE IF EXISTS summary_genre_distribution;
CREATE TABLE summary_genre_distribution (
    genre_name  VARCHAR(100),
    total_count INT,
    movie_count INT,
    show_count  INT
);

DROP TABLE IF EXISTS summary_country_content;
CREATE TABLE summary_country_content (
    country_name VARCHAR(100),
    total_count  INT,
    movie_count  INT,
    show_count   INT
);

DROP TABLE IF EXISTS summary_yearly_additions;
CREATE TABLE summary_yearly_additions (
    release_year INT,
    total_added  INT,
    movies_added INT,
    shows_added  INT
);

DROP TABLE IF EXISTS summary_country_genre_matrix;
CREATE TABLE summary_country_genre_matrix (
    country_name VARCHAR(100),
    genre_name   VARCHAR(100),
    title_count  INT,
    PRIMARY KEY (country_name, genre_name)
);


-- ─────────────────────────────────────────
-- 4. DENORMALIZED FLAT VIEW (for Power BI)
-- ─────────────────────────────────────────

DROP VIEW IF EXISTS vw_netflix_flat;
CREATE VIEW vw_netflix_flat AS
SELECT
    c.content_id,
    c.show_id,
    c.type,
    c.title,
    c.director,
    c.release_year,
    c.rating,
    c.duration_value,
    c.duration_unit,
    c.date_added,
    YEAR(c.date_added)  AS year_added,
    MONTH(c.date_added) AS month_added,
    g.genre_name,
    co.country_name
FROM content c
LEFT JOIN content_genre  cg ON c.content_id = cg.content_id
LEFT JOIN genre           g ON cg.genre_id  = g.genre_id
LEFT JOIN content_country cc ON c.content_id = cc.content_id
LEFT JOIN country         co ON cc.country_id = co.country_id;
