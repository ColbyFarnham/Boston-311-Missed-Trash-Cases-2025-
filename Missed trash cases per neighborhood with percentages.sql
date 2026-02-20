--    **************************************
--    2025 311 MISSED TRASH REPRORTS PROJECT
--    **************************************

-- View Tables (we will be using two tables for this project. One for 311 data, one for population data per neighborhood)

SELECT * FROM trah_raw;
SELECT * FROM boston_populations; 

--    *************************
--    311 Reports by Case Types
--    *************************

-- This counts how many 2025 311 reports in Boston. There were 267,187 reports

SELECT COUNT(*) FROM trash_raw; 

-- This counts how many distinct case_types show up in the 311 reports data. There are 162 different case types.

SELECT COUNT(DISTINCT(case_types)) FROM trash_raw; 

-- This lists each case type, and how many of each one there were in 2025. The top 3 case types in 2025 were: Parking Enforcement, Requests for Street Cleaning, Improper Storage of Trash (Barrels). 

SELECT 	case_types,
  COUNT(*) AS number_of_reports FROM trash_raw
  GROUP BY case_types
  ORDER BY number_of_reports DESC;

-- This gets us the specific case types we are interesting in: Missed Trash Reports. We use case types rather than case title because there are many different missed trash case titles, but only one missed trash case type 
SELECT open_dt, case_types, nieghborhood FROM trash_raw
WHERE case_types = 'Missed Trash/Recycling/Yard Waste/Bulk Item'; 
