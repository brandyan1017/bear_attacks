/*
Created by: Brandy Nolan
Created on: September 22, 2024
Description: This Kaggle dataset shows every recorded killing by a black, brown, or polar bear from 1900-present day in North America.
*/

-- DATA CLEANING

-- Replaced non-breaking spaces with an empty string.
UPDATE dbo.bear
SET gender = LTRIM(RTRIM(REPLACE(gender, CHAR(160), '')));

-- Updated null values with the mode gender (male) in gender column to male
UPDATE dbo.bear
SET gender = 'male' 
WHERE GENDER is null

-- Replaced null age values with the average age from the dataset.
-- Based on research, no date of birth is available for these individuals, but it is confirmed they were not children at the time.
UPDATE dbo.bear
SET age = 36 -- avg age
WHERE age is null

-- Rounded up ages less than 1 to the age of 1
UPDATE dbo.bear
SET age = 1
WHERE age < 1


-- EXPLORATORY DATA ANAYLSIS

-- Victim Demographics

-- What is the gender and age distribution of the victims?
SELECT 
	gender,
	ROUND(AVG(age),0) avg_age,
	COUNT(*) gender_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS gender_percentage
FROM 
	dbo.bear
GROUP BY 
	gender
ORDER BY 3 DESC;


-- Bear species

-- What is the distribution of attacks by bear species (e.g., brown bear, black bear, polar bear)?
--- Brown bears in the wild have the highest number of attacks (72).
SELECT
	Type_of_bear,
	type,
	COUNT(*) type_count
FROM 
	dbo.bear
GROUP BY 
	Type_of_bear, 
	Type
ORDER BY 3 DESC;

-- Are certain species more likely to attack in certain areas?
--- High incidence areas are Alaska, Montana, and British Columbia.
WITH location_cte AS (
SELECT 
	Type_of_bear,
	Type,
    Location,
    CASE 
        WHEN LEN(Location) > 0 AND CHARINDEX(',', Location) > 0 THEN 
            LEFT(Location, CHARINDEX(',', Location) - 1)
        ELSE 
            NULL
    END AS city,
    CASE 
        WHEN LEN(Location) > 0 AND CHARINDEX(',', Location) > 0 THEN 
            SUBSTRING(Location, CHARINDEX(',', Location) + 1, LEN(Location) - CHARINDEX(',', Location))
        ELSE 
            NULL
    END AS state
FROM bear
)
SELECT
	state,
	Type_of_bear,
	COUNT(*) count
FROM 
	location_cte
GROUP BY
	state,
	Type_of_bear
ORDER BY 3 DESC;


--- General Trends

--How many bear attacks occurred over time (yearly/monthly trends)?
--- Sparse events early on and there's an increase that starts in the 1960s.  However there's a steady rise in the late 20th Centery adn Early 21st Century.
WITH yearly_cte AS (
SELECT
	Year,
	COUNT(*) count
FROM 
	dbo.bear
GROUP BY
	Year
)
SELECT
	Year,
	AVG(count) OVER (ORDER BY Year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS rolling_avg_5_years
FROM yearly_cte;


-- Low Activity in Early and Late Months (Winter Months)
--- Significant Increase Starting in Spring (April–June)
--- Peak Activity During Summer and Early Fall (July–October)
--- Decline in Late Fall and Early Winter (November)
SELECT
	Month,
	COUNT(*)
FROM 
	dbo.bear
GROUP BY
	Month
ORDER BY 
    CASE Month
        WHEN 'Jan' THEN 1
        WHEN 'Feb' THEN 2
        WHEN 'Mar' THEN 3
        WHEN 'Apr' THEN 4
        WHEN 'May' THEN 5
        WHEN 'Jun' THEN 6
        WHEN 'Jul' THEN 7
        WHEN 'Aug' THEN 8
        WHEN 'Sep' THEN 9
        WHEN 'Oct' THEN 10
        WHEN 'Nov' THEN 11
        WHEN 'Dec' THEN 12
    END;

-- Were the victims engaged in specific activities during the attack (e.g., hiking, camping, hunting)?
--- The most attacked groups are neither hunters nor hikers.
SELECT
	Hunter,
	Hikers,
	COUNT(Hunter) hunter_count,
	COUNT(Hikers) hikers_count

FROM 
	dbo.bear
GROUP BY
	Hunter,
	Hikers;

-- Distribution of attacks resulting in multiple fatalities.
--- Higher incidence fo single fatalities.
SELECT
	CASE 
		WHEN Only_one_killed = 0 THEN 'No'
		ELSE 'Yes'
	END as single_fatality,
	COUNT(*) count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS single_fatality_percentage
FROM 
	dbo.bear
GROUP BY 
	Only_one_killed
