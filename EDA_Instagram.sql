--Create a database to store your data using CRETAE DATABASE name_of_database
--Impression means total numeber of time the post has been displayed on user's screen, same user can have multiple impressions too
USE MyDatabase

SELECT TOP 5 * FROM Instagram

--Summary statistics
SELECT COUNT(*) AS total_posts,
AVG(Impressions) as Avg_Impressions,
MAX(Likes) as maximum_Likes,
MIN(Likes) as minimum_Likes
FROM Instagram

--Missing Data

SELECT COUNT(*) as Total_rows,
SUM(CASE WHEN Data_comment IS NULL THEN 1 ELSE 0 END) AS Missing_data_comment,
SUM(CASE WHEN Plays IS NULL THEN 1 ELSE 0 END) AS Missing_Plays
FROM Instagram

--Dropping column "data comment' since all rows are nulls
ALTER TABLE Instagram
DROP COLUMN Data_comment

SELECT * FROM Instagram

--Analysing disbtribution
SELECT Post_type,COUNT(*) AS Frequency
FROM Instagram
GROUP BY Post_type

--Engagement metrics
SELECT TOP 5 Post_ID,
Likes * 1.0/Impressions * 100 as Likes_per_Impression,
Saves * 1.0/Impressions * 100 as Saves_per_Impression
FROM Instagram

--Trends over time
SELECT * FROM Instagram
SELECT CAST(Publish_time as DATE) AS Extracted_Date,
SUM(Impressions) as Total_Impressions,
SUM(Likes) as Total_Likes
FROM Instagram
GROUP BY CAST(Publish_time as DATE)
ORDER BY Extracted_Date ASC

--Detetecting Outliers- 19 rows
SELECT * FROM instagram
WHERE Impressions>
(SELECT AVG(Impressions) + 2 * STDEV(Impressions) FROM Instagram)
OR Impressions <
(SELECT AVG(Impressions) - 2 * STDEV(Impressions) FROM Instagram)

