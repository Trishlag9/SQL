--1)Number of businesses in each category

SELECT * FROM tbl_yelp_businesses LIMIT 10
SELECT * FROM tbl_yelp_reviews LIMIT 10

WITH cte as (SELECT business_id,trim(A.value) as category
FROM tbl_yelp_businesses
,lateral split_to_table(categories,',') A 
)
SELECT category,COUNT(*) as no_of_business
FROM cte
GROUP BY 1
ORDER BY 2 DESC

--2)Find top 10 users who have reviewed the most businesses in the 'Restaurants' category
SELECT r.user_id,count(distinct r.business_id)
from tbl_yelp_reviews r
inner join tbl_yelp_businesses b on r.business_id=b.business_id
where b.categories ilike '%restaurants%'
group by 1
order by 2 desc
limit 10

--3)Find most popular categories of businesses (based on number of reviews)
with cte as (
    select business_id, trim(A.value) as category
    from tbl_yelp_businesses
    ,lateral split_to_table(categories, ',') A
)
select category, count(*) as no_of_reviews
from cte
inner join tbl_yelp_reviews r on cte.business_id = r.business_id
group by category

--4)Find top 3 most recent reviews or each business
SELECT *
FROM
(SELECT *,ROW_NUMBER() OVER (PARTITION BY business_id ORDER BY review_date DESC) as rn
FROM tbl_yelp_reviews) A
WHERE rn<=3

SELECT * FROM tbl_yelp_reviews LIMIT 10
WITH cte AS (
  SELECT r.*, b.name,
         ROW_NUMBER() OVER (PARTITION BY r.business_id ORDER BY review_date DESC) AS rn
  FROM tbl_yelp_reviews r
  INNER JOIN tbl_yelp_businesses b ON r.business_id = b.business_id
)
SELECT * FROM cte
WHERE rn <= 3;

--5)Find the month with highest number of reviews
SELECT * FROM tbl_yelp_businesses LIMIT 10
SELECT * FROM tbl_yelp_reviews LIMIT 10

SELECT month(review_date) as review_month,COUNT(*) as number_of_reviews
FROM tbl_yelp_reviews
GROUP BY month(review_date) 
ORDER BY 2 DESC


--6)Find the percentage of 5 star reviews for each business
SELECT 
  b.business_id,
  b.name,
  COUNT(*) AS total_reviews,sum(case when r.review_stars=5 then 1 else 0 end) as star5_reviews,star5_reviews/total_reviews as percent_5_star
FROM tbl_yelp_reviews r
JOIN tbl_yelp_businesses b ON r.business_id = b.business_id
GROUP BY 1, 2;

--7)Find the top 5 most reviewed businesses in each city
With cte as (SELECT b.city,b.business_id,b.name,COUNT(*) as total_reviews
from tbl_yelp_reviews r
JOIN tbl_yelp_businesses b ON r.business_id = b.business_id
GROUP BY 1,2,3
)
SELECT * FROM
(SELECT *,ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_reviews desc ) as rn
FROM cte) S
WHERE rn<=5
