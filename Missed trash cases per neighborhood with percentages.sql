--    ======================================
--    2025 311 MISSED TRASH REPORTS PROJECT
--    ======================================

-- View Tables (we will be using two tables for this project. One for 311 data, one for population data per neighborhood)

SELECT * FROM trash_raw;
SELECT * FROM boston_populations; 

--    ========================
--    311 REPORTS BY CASE TYPE
--    ========================

-- This counts how many 2025 311 reports in Boston. There were 267,187 reports

SELECT COUNT(*) FROM trash_raw; 

-- This counts how many distinct case_types show up in the 311 reports data. There are 162 different case types

SELECT COUNT(DISTINCT(case_types)) FROM trash_raw; 

-- This lists each case type, and how many of each one there were in 2025. The top 3 case types in 2025 were: Parking Enforcement, Requests for Street Cleaning, Improper Storage of Trash (Barrels)

SELECT 	case_types, COUNT(*) AS number_of_reports FROM trash_raw
  GROUP BY case_types
  ORDER BY number_of_reports DESC;

-- This counts how many Missed Trash cases there were in 2025. There were 9,970 Missed Trash cases in 2025

SELECT COUNT(*) FROM trash_raw
  WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'; 

-- This helps me find what percentage of all 2025 reports were Missed Trash reports: it was 3.7% of all reports

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

-- This breaks up all the Missed Trash cases into neighborhood case counts. Top three neighborhoods: Dorchester, Hyde Park, Roxbury

SELECT neighborhood, COUNT(*) AS missed_trash_cases FROM trash_raw
  WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
  GROUP BY neighborhood
  ORDER BY missed_trash_cases DESC; 

-- This takes the last query further, adding the total number of Missed Trash cases, and the percent at which each nieghborhood makes up of the total to the table

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

-- This is the last query, but only worrying about the top 10 nieghborhoods (The actual metric I use in my charts is the top 10 neighborhoods) 

WITH cases_per_neighborhood AS (
	SELECT 
		neighborhood, 
		COUNT(*) AS missed_per_neighborhood, 
		(SELECT COUNT(*) AS all_missed_trash_top10 FROM trash_raw
			WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
			AND neighborhood IN (
    			SELECT neighborhood FROM trash_raw
    				WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'
      				AND neighborhood IS NOT NULL
      				AND neighborhood <> ''
   				   GROUP BY neighborhood
   				   ORDER BY COUNT(*) DESC
    			  LIMIT 10)) AS all_missed_trash
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


