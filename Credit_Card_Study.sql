
USE MyDatabase
--Different card types (4-Silver, Signature,Gold,Platinum)
SELECT DISTINCT card_type
FROM cc_trans

--Range of the transaction (04/10/2013-26/05/2015)
SELECT min(transaction_date),max(transaction_date)
FROM cc_trans

--1)Top 5 cities with highest spends and their percentage contribution of total credit card spends 
With city_wise_spend as (
SELECT city,SUM(amount) as total_spend
FROM cc_trans
GROUP BY city
),
total_spend as (
SELECT SUM(cast(amount as bigint)) as total_amount 
FROM cc_trans)
SELECT TOP 5 city_wise_spend.* ,ROUND((total_spend * 1.0/total_amount * 100),2) as percent_contribution
FROM city_wise_spend INNER JOIN total_spend on 1=1
ORDER BY total_spend DESC

--2)Highest spend month and amount spent in that month for each card type

WITH card_wise_status as (SELECT card_type,DATEPART(year,transaction_date) as yr_of_transaction,DATEPART(month,transaction_date) as  month_of_transaction,
sum(amount) as total_spend
FROM cc_trans
GROUP BY card_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date)
--ORDER BY MONTH(transaction_date)
)
SELECT * FROM
(SELECT *,RANK() OVER (PARTITION BY(card_type) ORDER BY total_spend DESC) as rn FROM card_wise_status) a
WHERE rn=1

--3)the transaction details(all columns from the table) for each card type when it reaches a cumulative of 1000000 total
--spends (We should have 4 rows in the o/p one for each card type)
With cte as (SELECT *,
SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date,transaction_id ASC) as total_spend
FROM cc_trans)
SELECT * FROM (SELECT *,RANK() OVER (PARTITION BY card_type ORDER BY total_spend) AS rn 
FROM cte
WHERE total_spend >= 1000000) a WHERE rn=1

--4)City which had lowest percentage spend for gold card type (Gold vs total gold ratio)

SELECT * FROM cc_trans
With gold_total as (SELECT city,card_type,SUM(amount) as gold_spend
FROM cc_trans
--WHERE card_type='Gold'
GROUP BY city,card_type),
one_all_gold_amount as(
SELECT card_type,SUM(amount) as total_gold_amount
FROM cc_trans
WHERE card_type='Gold'
GROUP BY card_type)
SELECT TOP 1 G.city,G.gold_spend * 1.0/OAG.total_gold_amount  *100 as percentage_of_gold_spend
FROM gold_total G JOIN one_all_gold_amount OAG
ON G.card_type=OAG.card_type
ORDER BY percentage_of_gold_spend

--5)print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

SELECT * FROM cc_trans
WITH cte as (SELECT city,exp_type,SUM(amount) as total_amount
FROM cc_trans
GROUP BY city,exp_type)
SELECT city,MAX(CASE WHEN rn_asc = 1 THEN exp_type end ) as lowest_exp_type,MIN(CASE WHEN rn_desc=1 THEN exp_type end) as highest_exp_type
FROM 
(SELECT *,rank() over (partition by city ORDER BY total_amount asc) as rn_asc,
rank() over (partition by city ORDER BY total_amount DESC) as rn_desc
FROM cte) A
GROUP BY city

--6)percentage contribution of spends by females for each expense type
SELECT exp_type,sum(case when gender='F' then amount else 0 end)* 1.0 /sum(amount) as percentage_of_female_contribution
from cc_trans
GROUP BY exp_type
ORDER BY percentage_of_female_contribution desc

--7)which card and expense type combination saw highest month over month growth in Jan-2014
WITH cte as (SELECT card_type,exp_type,DATEPART(year,transaction_date) as yt,DATEPART(month,transaction_date) as mt,sum(amount) as total_spend
FROM cc_trans
GROUP BY card_type,exp_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date))
SELECT TOP 1 *,(total_spend - prev_month_spend) as mom_growth
FROM (
SELECT cte.*,LAG(total_spend,1) OVER (PARTITION BY card_type,exp_type ORDER BY yt,mt) as prev_month_spend
FROM cte) A
WHERE prev_month_spend IS NOT NULL and yt=2014 and mt=1
ORDER BY mom_growth DESC
FROM cc_trans

--8)During weekends,which city has highest total spend to total no of transactions ratio 

SELECT * FROM cc_trans
SELECT top 1 city,sum(amount) * 1.0 /COUNT(1) as ratio
FROM cc_trans
WHERE datepart(weekday,transaction_date) in (1,7)
GROUP BY city
ORDER BY ratio DESC

--9)which city took least number of days to reach its 500th transaction after the first transaction in that city

WITH cte as (SELECT * ,ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date,transaction_id) as rn
FROM cc_trans)
SELECT top 1 city,DATEDIFF(day,MIN(transaction_date),MAX(transaction_date)) 
FROM cte
WHERE rn=500 or rn=1
GROUP BY city
HAVING count(*) = 2
ORDER BY DATEDIFF(day,MIN(transaction_date),MAX(transaction_date))
