-- ============================================================
-- Netflix Content Analytics | 15+ Analytical SQL Queries
-- Description: Covers genre mix, release trends, content gaps,
--              regional patterns, ratings, and YoY analysis
-- ============================================================

USE netflix_analytics;


-- ═══════════════════════════════════════════
-- SECTION A: CONTENT OVERVIEW
-- ═══════════════════════════════════════════

-- ── Query 1: Total Catalog Size — Movies vs TV Shows
-- Purpose: High-level KPI split for dashboard cards
SELECT
    type,
    COUNT(*)                                        AS total_titles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_catalog
FROM content
GROUP BY type
ORDER BY total_titles DESC;
-- Insight: ~70% Movies, ~30% TV Shows on Netflix


-- ── Query 2: Year-Over-Year Content Additions
-- Purpose: Trend line chart — how aggressively Netflix grew
SELECT
    YEAR(date_added)                                AS year_added,
    COUNT(*)                                        AS total_added,
    SUM(CASE WHEN type = 'Movie'   THEN 1 ELSE 0 END) AS movies_added,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS shows_added
FROM content
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added)
ORDER BY year_added;
-- Insight: Explosive growth 2015–2019, plateau post-2020


-- ── Query 3: Monthly Content Addition Patterns
-- Purpose: Identify seasonal acquisition cycles
SELECT
    YEAR(date_added)  AS yr,
    MONTH(date_added) AS mo,
    MONTHNAME(date_added) AS month_name,
    COUNT(*)          AS titles_added
FROM content
WHERE date_added IS NOT NULL
GROUP BY yr, mo, month_name
ORDER BY yr, mo;
-- Insight: Q4 typically shows spikes aligned with holiday content strategy


-- ═══════════════════════════════════════════
-- SECTION B: GENRE ANALYSIS
-- ═══════════════════════════════════════════

-- ── Query 4: Top 15 Genres by Volume
-- Purpose: Genre mix bar chart
SELECT
    g.genre_name,
    COUNT(DISTINCT cg.content_id)                     AS title_count,
    ROUND(COUNT(DISTINCT cg.content_id) * 100.0
        / (SELECT COUNT(*) FROM content), 1)          AS pct_catalog
FROM genre g
JOIN content_genre cg ON g.genre_id = cg.genre_id
GROUP BY g.genre_name
ORDER BY title_count DESC
LIMIT 15;
-- Insight: International Movies, Dramas, Comedies dominate the catalog


-- ── Query 5: Genre Split — Movies vs TV Shows
-- Purpose: Understand content strategy per format
SELECT
    g.genre_name,
    COUNT(DISTINCT CASE WHEN c.type = 'Movie'   THEN c.content_id END) AS movies,
    COUNT(DISTINCT CASE WHEN c.type = 'TV Show' THEN c.content_id END) AS tv_shows,
    COUNT(DISTINCT c.content_id)                                        AS total
FROM genre g
JOIN content_genre cg ON g.genre_id    = cg.genre_id
JOIN content       c  ON cg.content_id = c.content_id
GROUP BY g.genre_name
HAVING total > 50
ORDER BY total DESC;


-- ── Query 6: Genre Growth Over Time (YoY using LAG)
-- Purpose: Identify rising vs declining genres
SELECT
    yr,
    genre_name,
    titles_added,
    LAG(titles_added) OVER (PARTITION BY genre_name ORDER BY yr) AS prev_year,
    titles_added
        - LAG(titles_added) OVER (PARTITION BY genre_name ORDER BY yr) AS yoy_change
FROM (
    SELECT
        YEAR(c.date_added)    AS yr,
        g.genre_name,
        COUNT(DISTINCT c.content_id) AS titles_added
    FROM content c
    JOIN content_genre cg ON c.content_id = cg.content_id
    JOIN genre          g ON cg.genre_id  = g.genre_id
    WHERE c.date_added IS NOT NULL
    GROUP BY yr, g.genre_name
) base
ORDER BY genre_name, yr;
-- Insight: International content grew fastest 2018–2021


-- ── Query 7: Multi-Genre Co-occurrence
-- Purpose: Which genres appear together most often
SELECT
    g1.genre_name AS genre_a,
    g2.genre_name AS genre_b,
    COUNT(*)      AS co_occurrences
FROM content_genre cg1
JOIN content_genre cg2 ON cg1.content_id = cg2.content_id
                      AND cg1.genre_id   < cg2.genre_id
JOIN genre g1 ON cg1.genre_id = g1.genre_id
JOIN genre g2 ON cg2.genre_id = g2.genre_id
GROUP BY g1.genre_name, g2.genre_name
ORDER BY co_occurrences DESC
LIMIT 20;
-- Insight: International TV + Dramas is the most common pair


-- ═══════════════════════════════════════════
-- SECTION C: REGIONAL / COUNTRY ANALYSIS
-- ═══════════════════════════════════════════

-- ── Query 8: Top 20 Content-Producing Countries
-- Purpose: World map bubble chart
SELECT
    co.country_name,
    COUNT(DISTINCT cc.content_id)                          AS total_titles,
    SUM(CASE WHEN c.type = 'Movie'   THEN 1 ELSE 0 END)   AS movies,
    SUM(CASE WHEN c.type = 'TV Show' THEN 1 ELSE 0 END)   AS tv_shows
FROM country      co
JOIN content_country cc ON co.country_id  = cc.country_id
JOIN content          c ON cc.content_id  = c.content_id
GROUP BY co.country_name
ORDER BY total_titles DESC
LIMIT 20;
-- Insight: US, India, UK are the top 3 producing nations


-- ── Query 9: Content Gaps — Countries with Low Catalog Presence
-- Purpose: Identify expansion opportunities
SELECT
    co.country_name,
    COUNT(DISTINCT cc.content_id) AS total_titles
FROM country      co
JOIN content_country cc ON co.country_id = cc.country_id
GROUP BY co.country_name
HAVING total_titles < 10
ORDER BY total_titles ASC;
-- Insight: Many African & Central Asian countries have <5 titles each


-- ── Query 10: Genre Preferences by Country (Top Genre per Country)
-- Purpose: What content type should Netflix push per region
SELECT
    country_name,
    genre_name,
    title_count
FROM (
    SELECT
        co.country_name,
        g.genre_name,
        COUNT(DISTINCT c.content_id) AS title_count,
        RANK() OVER (
            PARTITION BY co.country_name
            ORDER BY COUNT(DISTINCT c.content_id) DESC
        ) AS rnk
    FROM country       co
    JOIN content_country cc ON co.country_id  = cc.country_id
    JOIN content          c ON cc.content_id  = c.content_id
    JOIN content_genre   cg ON c.content_id   = cg.content_id
    JOIN genre            g ON cg.genre_id    = g.genre_id
    GROUP BY co.country_name, g.genre_name
) ranked
WHERE rnk = 1
ORDER BY title_count DESC
LIMIT 30;


-- ── Query 11: Countries with No TV Show Representation
-- Purpose: Where to introduce TV content to expand engagement
SELECT
    co.country_name,
    COUNT(DISTINCT cc.content_id) AS movie_count
FROM country       co
JOIN content_country cc ON co.country_id = cc.country_id
JOIN content          c ON cc.content_id = c.content_id
WHERE c.type = 'Movie'
  AND NOT EXISTS (
      SELECT 1
      FROM content_country cc2
      JOIN content c2 ON cc2.content_id = c2.content_id
      WHERE cc2.country_id = co.country_id
        AND c2.type = 'TV Show'
  )
GROUP BY co.country_name
ORDER BY movie_count DESC;


-- ═══════════════════════════════════════════
-- SECTION D: RATINGS & DURATION
-- ═══════════════════════════════════════════

-- ── Query 12: Ratings Distribution
-- Purpose: Audience maturity breakdown
SELECT
    rating,
    COUNT(*)                                               AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)    AS pct
FROM content
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY total DESC;
-- Insight: TV-MA (mature) is #1 — Netflix skews adult audience


-- ── Query 13: Average Movie Duration Over the Years
-- Purpose: Has Netflix content gotten longer or shorter?
SELECT
    release_year,
    ROUND(AVG(duration_value), 0) AS avg_duration_mins,
    MIN(duration_value)            AS shortest,
    MAX(duration_value)            AS longest
FROM content
WHERE type = 'Movie'
  AND duration_unit = 'min'
  AND duration_value IS NOT NULL
GROUP BY release_year
ORDER BY release_year;


-- ── Query 14: TV Show Season Count Distribution
-- Purpose: Are most shows short-run or long-running?
SELECT
    duration_value  AS seasons,
    COUNT(*)        AS show_count
FROM content
WHERE type = 'TV Show'
  AND duration_unit LIKE '%Season%'
GROUP BY duration_value
ORDER BY seasons;
-- Insight: The vast majority of Netflix shows have only 1 season


-- ═══════════════════════════════════════════
-- SECTION E: DIRECTOR & CAST INSIGHTS
-- ═══════════════════════════════════════════

-- ── Query 15: Most Prolific Directors on Netflix
-- Purpose: Who has the highest content volume?
SELECT
    director,
    COUNT(*)                                          AS total_titles,
    GROUP_CONCAT(DISTINCT type ORDER BY type)         AS content_types,
    MIN(release_year)                                 AS first_title,
    MAX(release_year)                                 AS latest_title
FROM content
WHERE director IS NOT NULL
GROUP BY director
HAVING total_titles > 2
ORDER BY total_titles DESC
LIMIT 20;
-- Insight: Rajiv Chilaka (Indian animation) tops the director leaderboard


-- ── Query 16: Director Genre Specialization
-- Purpose: Which genres do top directors focus on?
SELECT
    c.director,
    g.genre_name,
    COUNT(DISTINCT c.content_id) AS title_count
FROM content c
JOIN content_genre cg ON c.content_id = cg.content_id
JOIN genre         g  ON cg.genre_id  = g.genre_id
WHERE c.director IS NOT NULL
GROUP BY c.director, g.genre_name
HAVING title_count >= 3
ORDER BY title_count DESC
LIMIT 30;


-- ═══════════════════════════════════════════
-- SECTION F: ADVANCED / PRODUCT ANALYTICS
-- ═══════════════════════════════════════════

-- ── Query 17: Content Freshness — Age of Catalog at Time of Addition
-- Purpose: Was Netflix acquiring new or old content?
SELECT
    YEAR(date_added)                                   AS year_added,
    ROUND(AVG(YEAR(date_added) - release_year), 1)    AS avg_catalog_age_yrs,
    SUM(CASE WHEN YEAR(date_added) = release_year
             THEN 1 ELSE 0 END)                        AS same_year_releases,
    COUNT(*)                                           AS total_added
FROM content
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added)
ORDER BY year_added;
-- Insight: Netflix increasingly adds day-and-date releases post 2017


-- ── Query 18: Content Gap Score by Country (Gap = Many Movies, Few Shows)
-- Purpose: Surface countries ripe for TV Show investment
SELECT
    co.country_name,
    SUM(CASE WHEN c.type = 'Movie'   THEN 1 ELSE 0 END) AS movies,
    SUM(CASE WHEN c.type = 'TV Show' THEN 1 ELSE 0 END) AS tv_shows,
    ROUND(
        SUM(CASE WHEN c.type = 'Movie'   THEN 1 ELSE 0 END)
      / NULLIF(SUM(CASE WHEN c.type = 'TV Show' THEN 1 ELSE 0 END), 0),
    1)                                                   AS movie_to_show_ratio
FROM country       co
JOIN content_country cc ON co.country_id  = cc.country_id
JOIN content          c ON cc.content_id  = c.content_id
GROUP BY co.country_name
HAVING movies > 10
ORDER BY movie_to_show_ratio DESC
LIMIT 20;
-- Insight: India has 6:1 movie-to-show ratio — massive TV Show gap


-- ── Query 19: LEAD/LAG — Sequential Genre Trend Analysis
-- Purpose: Which genres are accelerating vs stalling?
SELECT
    genre_name,
    yr,
    titles_added,
    LAG(titles_added,  1) OVER (PARTITION BY genre_name ORDER BY yr) AS yr_minus_1,
    LEAD(titles_added, 1) OVER (PARTITION BY genre_name ORDER BY yr) AS yr_plus_1,
    ROUND(
        (titles_added - LAG(titles_added,1) OVER (PARTITION BY genre_name ORDER BY yr))
      / NULLIF(LAG(titles_added,1) OVER (PARTITION BY genre_name ORDER BY yr), 0) * 100,
    1) AS yoy_growth_pct
FROM (
    SELECT
        g.genre_name,
        YEAR(c.date_added)           AS yr,
        COUNT(DISTINCT c.content_id) AS titles_added
    FROM content c
    JOIN content_genre cg ON c.content_id = cg.content_id
    JOIN genre          g ON cg.genre_id  = g.genre_id
    WHERE c.date_added IS NOT NULL
    GROUP BY g.genre_name, YEAR(c.date_added)
) base
ORDER BY genre_name, yr;


-- ── Query 20: Content Strategy Summary — Key KPIs
-- Purpose: Single-row summary for executive dashboard
SELECT
    COUNT(*)                                                      AS total_titles,
    SUM(CASE WHEN type = 'Movie'   THEN 1 ELSE 0 END)            AS total_movies,
    SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END)            AS total_shows,
    ROUND(AVG(CASE WHEN type='Movie' THEN duration_value END), 0) AS avg_movie_mins,
    ROUND(AVG(CASE WHEN type='TV Show' THEN duration_value END),0) AS avg_show_seasons,
    COUNT(DISTINCT
        (SELECT country_id FROM content_country
         WHERE content_id = content.content_id LIMIT 1))         AS countries_represented,
    MIN(release_year)                                             AS oldest_title_yr,
    MAX(release_year)                                             AS newest_title_yr
FROM content;
