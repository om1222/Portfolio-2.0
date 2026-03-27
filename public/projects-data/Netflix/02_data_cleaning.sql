-- ============================================================
-- Netflix Content Analytics | Data Cleaning & Normalization
-- Description: Cleans raw CSV data and populates the
--              normalized schema tables
-- ============================================================

USE netflix_analytics;

-- ─────────────────────────────────────────
-- STEP 1: Inspect Raw Data Issues
-- ─────────────────────────────────────────

-- Check total rows
SELECT COUNT(*) AS total_raw_rows FROM raw_netflix_titles;

-- Identify NULL / empty fields
SELECT
    SUM(CASE WHEN NULLIF(TRIM(director), '') IS NULL THEN 1 ELSE 0 END)   AS null_directors,
    SUM(CASE WHEN NULLIF(TRIM(cast), '')     IS NULL THEN 1 ELSE 0 END)   AS null_cast,
    SUM(CASE WHEN NULLIF(TRIM(country), '')  IS NULL THEN 1 ELSE 0 END)   AS null_country,
    SUM(CASE WHEN NULLIF(TRIM(date_added),'') IS NULL THEN 1 ELSE 0 END)  AS null_date_added,
    SUM(CASE WHEN NULLIF(TRIM(rating), '')   IS NULL THEN 1 ELSE 0 END)   AS null_rating,
    SUM(CASE WHEN NULLIF(TRIM(duration), '') IS NULL THEN 1 ELSE 0 END)   AS null_duration
FROM raw_netflix_titles;

-- Spot inconsistent country values
SELECT country, COUNT(*) AS cnt
FROM raw_netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY cnt DESC
LIMIT 30;

-- Multi-value genre examples
SELECT listed_in
FROM raw_netflix_titles
WHERE listed_in LIKE '%,%'
LIMIT 10;

-- Multi-value country examples
SELECT country
FROM raw_netflix_titles
WHERE country LIKE '%,%'
LIMIT 10;


-- ─────────────────────────────────────────
-- STEP 2: Standardize Country Names
-- ─────────────────────────────────────────

-- Create a mapping table for inconsistent country labels
DROP TABLE IF EXISTS country_mapping;
CREATE TABLE country_mapping (
    raw_name        VARCHAR(200),
    standard_name   VARCHAR(100)
);

INSERT INTO country_mapping (raw_name, standard_name) VALUES
('United States',          'United States'),
('USA',                    'United States'),
('U.S.A.',                 'United States'),
('US',                     'United States'),
('United Kingdom',         'United Kingdom'),
('UK',                     'United Kingdom'),
('U.K.',                   'United Kingdom'),
('South Korea',            'South Korea'),
('Korea',                  'South Korea'),
('West Germany',           'Germany'),
('East Germany',           'Germany'),
('Soviet Union',           'Russia'),
('Hong Kong',              'China'),
('Taiwan',                 'China');


-- ─────────────────────────────────────────
-- STEP 3: Populate content table
-- ─────────────────────────────────────────

INSERT INTO content (
    show_id, type, title, director,
    release_year, rating, duration_raw,
    duration_value, duration_unit, date_added, description
)
SELECT
    TRIM(show_id)                                              AS show_id,

    -- Standardize type
    CASE
        WHEN UPPER(TRIM(type)) = 'MOVIE'   THEN 'Movie'
        WHEN UPPER(TRIM(type)) = 'TV SHOW' THEN 'TV Show'
        ELSE TRIM(type)
    END                                                        AS type,

    TRIM(title)                                                AS title,

    -- Null-safe director
    NULLIF(TRIM(director), '')                                 AS director,

    release_year,

    -- Standardize rating
    NULLIF(TRIM(rating), '')                                   AS rating,

    NULLIF(TRIM(duration), '')                                 AS duration_raw,

    -- Extract numeric duration value
    CAST(SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED)  AS duration_value,

    -- Extract duration unit (min / Season)
    TRIM(SUBSTRING_INDEX(TRIM(duration), ' ', -1))             AS duration_unit,

    -- Parse date_added to DATE
    CASE
        WHEN NULLIF(TRIM(date_added), '') IS NOT NULL
        THEN STR_TO_DATE(TRIM(date_added), '%M %d, %Y')
        ELSE NULL
    END                                                        AS date_added,

    NULLIF(TRIM(description), '')                              AS description

FROM raw_netflix_titles
WHERE NULLIF(TRIM(show_id), '') IS NOT NULL;


-- ─────────────────────────────────────────
-- STEP 4: Populate genre & content_genre tables
-- ─────────────────────────────────────────

-- Extract individual genres from comma-separated listed_in
-- Using a numbers helper to split up to 5 genres per title
DROP TABLE IF EXISTS helper_numbers;
CREATE TABLE helper_numbers (n INT PRIMARY KEY);
INSERT INTO helper_numbers VALUES (1),(2),(3),(4),(5),(6),(7),(8);

INSERT IGNORE INTO genre (genre_name)
SELECT DISTINCT
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.listed_in, ',', n.n), ',', -1)) AS genre_name
FROM raw_netflix_titles r
JOIN helper_numbers n
    ON n.n <= 1 + LENGTH(r.listed_in) - LENGTH(REPLACE(r.listed_in, ',', ''))
WHERE NULLIF(TRIM(r.listed_in), '') IS NOT NULL;

INSERT IGNORE INTO content_genre (content_id, genre_id)
SELECT DISTINCT
    c.content_id,
    g.genre_id
FROM raw_netflix_titles r
JOIN helper_numbers n
    ON n.n <= 1 + LENGTH(r.listed_in) - LENGTH(REPLACE(r.listed_in, ',', ''))
JOIN content c ON c.show_id = TRIM(r.show_id)
JOIN genre g
    ON g.genre_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.listed_in, ',', n.n), ',', -1))
WHERE NULLIF(TRIM(r.listed_in), '') IS NOT NULL;


-- ─────────────────────────────────────────
-- STEP 5: Populate country & content_country tables
-- ─────────────────────────────────────────

INSERT IGNORE INTO country (country_name)
SELECT DISTINCT
    COALESCE(
        m.standard_name,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.country, ',', n.n), ',', -1))
    ) AS country_name
FROM raw_netflix_titles r
JOIN helper_numbers n
    ON n.n <= 1 + LENGTH(r.country) - LENGTH(REPLACE(r.country, ',', ''))
LEFT JOIN country_mapping m
    ON TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.country, ',', n.n), ',', -1)) = m.raw_name
WHERE NULLIF(TRIM(r.country), '') IS NOT NULL;

INSERT IGNORE INTO content_country (content_id, country_id)
SELECT DISTINCT
    c.content_id,
    co.country_id
FROM raw_netflix_titles r
JOIN helper_numbers n
    ON n.n <= 1 + LENGTH(r.country) - LENGTH(REPLACE(r.country, ',', ''))
JOIN content c ON c.show_id = TRIM(r.show_id)
JOIN country co
    ON co.country_name = COALESCE(
        (SELECT m.standard_name FROM country_mapping m
         WHERE m.raw_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.country, ',', n.n), ',', -1))),
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.country, ',', n.n), ',', -1))
    )
WHERE NULLIF(TRIM(r.country), '') IS NOT NULL;


-- ─────────────────────────────────────────
-- STEP 6: Populate Pre-Aggregated Summary Tables
-- ─────────────────────────────────────────

-- Genre distribution summary
INSERT INTO summary_genre_distribution (genre_name, total_count, movie_count, show_count)
SELECT
    g.genre_name,
    COUNT(DISTINCT cg.content_id)                                             AS total_count,
    COUNT(DISTINCT CASE WHEN c.type = 'Movie'   THEN cg.content_id END)      AS movie_count,
    COUNT(DISTINCT CASE WHEN c.type = 'TV Show' THEN cg.content_id END)      AS show_count
FROM genre g
JOIN content_genre cg ON g.genre_id   = cg.genre_id
JOIN content       c  ON cg.content_id = c.content_id
GROUP BY g.genre_name;

-- Country content summary
INSERT INTO summary_country_content (country_name, total_count, movie_count, show_count)
SELECT
    co.country_name,
    COUNT(DISTINCT cc.content_id)                                             AS total_count,
    COUNT(DISTINCT CASE WHEN c.type = 'Movie'   THEN cc.content_id END)      AS movie_count,
    COUNT(DISTINCT CASE WHEN c.type = 'TV Show' THEN cc.content_id END)      AS show_count
FROM country co
JOIN content_country cc ON co.country_id = cc.country_id
JOIN content          c ON cc.content_id  = c.content_id
GROUP BY co.country_name;

-- Yearly additions summary
INSERT INTO summary_yearly_additions (release_year, total_added, movies_added, shows_added)
SELECT
    release_year,
    COUNT(*)                                                   AS total_added,
    SUM(CASE WHEN type = 'Movie'   THEN 1 ELSE 0 END)         AS movies_added,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END)         AS shows_added
FROM content
WHERE release_year IS NOT NULL
GROUP BY release_year;

-- Country × Genre matrix
INSERT INTO summary_country_genre_matrix (country_name, genre_name, title_count)
SELECT
    co.country_name,
    g.genre_name,
    COUNT(DISTINCT c.content_id) AS title_count
FROM content c
JOIN content_genre  cg ON c.content_id  = cg.content_id
JOIN genre          g  ON cg.genre_id   = g.genre_id
JOIN content_country cc ON c.content_id = cc.content_id
JOIN country        co  ON cc.country_id = co.country_id
GROUP BY co.country_name, g.genre_name;

-- Verify row counts
SELECT 'content'                    AS tbl, COUNT(*) AS rows FROM content
UNION ALL
SELECT 'genre',                              COUNT(*) FROM genre
UNION ALL
SELECT 'country',                            COUNT(*) FROM country
UNION ALL
SELECT 'content_genre',                      COUNT(*) FROM content_genre
UNION ALL
SELECT 'content_country',                    COUNT(*) FROM content_country
UNION ALL
SELECT 'summary_genre_distribution',         COUNT(*) FROM summary_genre_distribution
UNION ALL
SELECT 'summary_country_content',            COUNT(*) FROM summary_country_content
UNION ALL
SELECT 'summary_country_genre_matrix',       COUNT(*) FROM summary_country_genre_matrix;
