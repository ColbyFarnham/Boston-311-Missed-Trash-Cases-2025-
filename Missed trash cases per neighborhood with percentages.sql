--    ======================================
--    2025 311 MISSED TRASH REPORTS PROJECT
--    ======================================

--    View Tables (we will be using two tables for this project. One for 311 data, one for population data per neighborhood) --

SELECT * FROM trash_raw;
SELECT * FROM boston_populations; 

--    ========================
--    311 REPORTS BY CASE TYPE
--    ========================

--    Count number of 311 reports --

SELECT COUNT(*) FROM trash_raw; 

--    Countn distinct case_types in the 311 reports --

SELECT COUNT(DISTINCT(case_types)) FROM trash_raw; 

--    Counts each case type-

SELECT 	case_types, COUNT(*) AS number_of_reports FROM trash_raw
  GROUP BY case_types
  ORDER BY number_of_reports DESC;

-- Counts Missed Trash cases --

SELECT COUNT(*) FROM trash_raw
  WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'; 

--    Percentage of Missed Trash reports --

WITH trash_per_total AS 
  (
  SELECT
    (SELECT COUNT(*) FROM trash_raw
     	WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item') AS missed_trash_cases,
    (SELECT COUNT(*) FROM trash_raw) AS total_reports 
  )
SELECT missed_trash_cases, total_reports, (missed_trash_cases::numeric / total_reports) * 100 AS missed_trash_percent FROM trash_per_total;

--    ============================
--    MISSED TRASH BY NEIGHBORHOOD
--    ============================

--    Missed Trash cases by  neighborhood. Top three - Hyde Park, Roxbury --

SELECT neighborhood, COUNT(*) AS missed_trash_cases FROM trash_raw
  WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
  GROUP BY neighborhood
  ORDER BY missed_trash_cases DESC; 

--    Adding the total number of Missed Trash cases, and the percent at which each nieghborhood makes up of the total to the table --

WITH cases_per_neighborhood AS 
  (
	SELECT 
		neighborhood, 
		COUNT(*) AS missed_per_neighborhood, 
		(SELECT COUNT(*) FROM trash_raw 
			WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item') AS all_missed_trash
FROM trash_raw
	WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
	GROUP BY neighborhood
	ORDER BY missed_per_neighborhood DESC
  )
SELECT 
	neighborhood, 
	missed_per_neighborhood, 
	all_missed_trash,
	((missed_per_neighborhood::numeric / all_missed_trash) * 100) AS percent_of_all
FROM cases_per_neighborhood; 

--    =====================
--    TOP 10 NEIGHBORHOODS
--    =====================

WITH cases_per_neighborhood AS (
	SELECT 
		neighborhood, 
		COUNT(*) AS missed_per_neighborhood, 
		(SELECT COUNT(*) AS all_missed_trash_top10 FROM trash_raw
			WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
			AND neighborhood IN (
    			SELECT neighborhood FROM trash_raw
    				WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
   				    GROUP BY neighborhood
   				    ORDER BY COUNT(*) DESC
    			    LIMIT 10)) AS all_missed_trash_top10
	FROM trash_raw
		WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
		GROUP BY neighborhood
		ORDER BY missed_per_neighborhood DESC
	)
SELECT 
	neighborhood, 
	missed_per_neighborhood, 
	all_missed_trash_top10,
	((missed_per_neighborhood::numeric / all_missed_trash_top10) * 100) AS percent_of_top_10
FROM cases_per_neighborhood;

--    =============================
--    NEIGHBORHOODS AND POPULATIONS
--    =============================

--    Joining populations on the 311 neighborhood column --

SELECT
  t.neighborhood ,
  p.total_population AS population,
  COUNT(*) AS missed_trash_cases
FROM trash_raw t
LEFT JOIN boston_populations p
  ON t.neighborhood = p.neighborhood
  WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
GROUP BY
  t.neighborhood,
  p.total_population
ORDER BY
  population DESC;

--    neighborhood, town_population, missed_cases_2025, pct_of_total_cases, missed_per_1000_people --

WITH per_neighborhood AS (
  SELECT
    t.neighborhood,
    COUNT(*) AS missed_cases_2025,
    p.total_population AS town_population
  FROM trash_raw t
  LEFT JOIN boston_populations p
    ON t.neighborhood = p.neighborhood
  WHERE t.case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
  GROUP BY
    t.neighborhood,
    p.total_population
),
with_totals AS (
  SELECT
    *,
    SUM(town_population) OVER () AS total_population_all
  FROM per_neighborhood
),
percentages AS (
  SELECT
    neighborhood,
    town_population,
    total_population_all,
    ROUND(100.0 * town_population / NULLIF(total_population_all, 0), 2) AS pct_of_total_population,
    missed_cases_2025,
    ROUND(1000.0 * missed_cases_2025 / NULLIF(town_population, 0), 2) AS missed_per_1000_people,
    ROUND(100.0 * missed_cases_2025 / NULLIF(SUM(missed_cases_2025) OVER (), 0), 4) AS pct_of_total_cases
FROM with_totals
)
SELECT
  neighborhood,
  town_population,
  missed_cases_2025,
  pct_of_total_cases,
  missed_per_1000_people
FROM percentages
  ORDER BY missed_per_1000_people DESC;
