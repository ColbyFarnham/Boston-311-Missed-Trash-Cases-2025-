--With allows me to select my old query as a part of this query
WITH per_neighborhood AS (

--My original table that puts together populations and 311 cases
  SELECT
    t.neighborhood,
    COUNT(*) AS missed_cases_2025,
    p.total_population AS town_population
  FROM trash_raw t
  LEFT JOIN boston_populations p
    ON t.neighborhood = p.neighborhood
  WHERE t.case_types ~* '\mMissed Trash\M'
  GROUP BY
    t.neighborhood,
    p.total_population
),

  -- The section adds what percentage of total population a specific town is
with_totals AS (
  SELECT
    *,
    SUM(town_population) OVER () AS total_population_all
  FROM per_neighborhood
),

  --This is the end of the WITH function that created a table for us to work with. 
percentages AS (
  SELECT
    neighborhood,
    town_population,
    total_population_all,
   
      -- 1) percent of total population
    ROUND(100.0 * town_population / NULLIF(total_population_all, 0), 4) AS pct_of_total_population,
  
    missed_cases_2025,

      -- 2) missed pickups per town population (rate within neighborhood)
    ROUND(1000.0 * missed_cases_2025 / NULLIF(town_population, 0), 6) AS missed_per_1000_people,

      -- 3) missed pickups per total population (share of entire city's population)
    ROUND(100.0 * missed_cases_2025 / NULLIF(total_population_all, 0), 10) AS missed_per_total_population
 
FROM with_totals
)

--The Final SELECT where I cleanly select everything that I've worked on
SELECT
  neighborhood,
  town_population,
  total_population_all,
  pct_of_total_population,
  missed_cases_2025,
  missed_per_1000_people,
  missed_per_total_population
FROM percentages
  ORDER BY missed_per_1000_people DESC;