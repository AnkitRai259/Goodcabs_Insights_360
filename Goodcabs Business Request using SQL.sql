-- total trips

SELECT 
     count(trip_id) as total_trips
FROM 
	 fact_trips;
     
-- Average fare per km

SELECT 
	ROUND(AVG(fare_amount/nullif(distance_travelled_km,0)),2) as average_fare_per_km
FROM 
	 fact_trips
WHERE 
	distance_travelled_km>0;

-- Average fare per trip

SELECT 
    ROUND((SUM(fare_amount)/ count(distinct trip_id)),2) as average_fare_per_trip
FROM 
	fact_trips
WHERE 
     fare_amount is not null ;
     
-- percentage contribution of each city to total trips 

WITH cte AS  
(SELECT  
       COUNT(DISTINCT  trip_id) AS  total_trips 
FROM 
       fact_trips)
SELECT  
	 city_name, ROUND(COUNT(DISTINCT trip_id)*100 /(SELECT  total_trips FROM  cte),2) AS  percentage_contributions
FROM 
	 fact_trips ft JOIN  dim_city dc ON ft.city_id = dc.city_id
GROUP BY 
	city_name 
ORDER BY 
	percentage_contributions DESC ;

-- Monthly actual and target total trips 
with cte as (SELECT 
     monthname(mtt.month) as months, sum(mtt.total_target_trips) as target_trips
FROM
	monthly_target_trips mtt
GROUP BY 
      months),
cte2 as ( Select monthname(date) months , count(distinct trip_id) as actual_trip 
         from fact_trips
         Group by months)
Select cte.months , actual_trip, target_trips  , case 
                                             when target_trips> actual_trip then 'Below Target'
                                             else 'Above Target'
                                             end as performance_status , 
                                             ROUND((actual_trip-target_trips)*100/target_trips,2) as perf_difference
from cte join cte2 on cte.months=cte2.months
Group by cte.months , actual_trip , target_trips ;
                                              
-- City level  Repeat passenger trip frequency count 
-- frequency count
Select city_name , 
SUM(case when trip_count = "2-Trips" then repeat_passenger_count else 0 end ) as 2_trips,
SUM(case when trip_count = "3-Trips" then repeat_passenger_count else 0 end ) as 3_trips,
SUM(case when trip_count = "4-Trips" then repeat_passenger_count else 0 end ) as 4_trips,
SUM(case when trip_count = "5-Trips" then repeat_passenger_count else 0 end ) as 5_trips,
SUM(case when trip_count = "6-Trips" then repeat_passenger_count else 0 end ) as 6_trips,
SUM(case when trip_count = "7-Trips" then repeat_passenger_count else 0 end ) as 7_trips,
SUM(case when trip_count = "8-Trips" then repeat_passenger_count else 0 end ) as 8_trips,
SUM(case when trip_count = "9-Trips" then repeat_passenger_count else 0 end ) as 9_trips,
SUM(case when trip_count = "10-Trips" then repeat_passenger_count else 0 end ) as 10_trips
From dim_repeat_trip_distribution drtd join dim_city dc on drtd.city_id=dc.city_id
group by city_name ;

-- frequency or % 
Select city_name , 
round(SUM(case when trip_count = "2-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2) as 2_trips,
round(SUM(case when trip_count = "3-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2) as 3_trips,
round(SUM(case when trip_count = "4-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2)as 4_trips,
round(SUM(case when trip_count = "5-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2)as 5_trips,
round(SUM(case when trip_count = "6-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2) as 6_trips,
round(SUM(case when trip_count = "7-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2)as 7_trips,
round(SUM(case when trip_count = "8-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2)as 8_trips,
round(SUM(case when trip_count = "9-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2)as 9_trips,
round(SUM(case when trip_count = "10-Trips" then repeat_passenger_count else 0 end )*100/sum(repeat_passenger_count),2)as 10_trips
From dim_repeat_trip_distribution drtd join dim_city dc on drtd.city_id=dc.city_id
group by city_name ;









-- Identify cities with top 3 and bottom 3 
SELECT city_name, sum(new_passengers) AS total_new_passengers ,
                  sum(total_passengers) AS total_passenger, 
				 (sum(new_passengers)*100/sum(total_passengers)) AS new_passenger_percent, 
                  RANK() OVER  (ORDER BY sum(new_passengers)DESC ) AS rnk , 
                  CASE
				      WHEN RANK() OVER (ORDER BY sum(new_passengers) DESC)<=3 THEN 'Top 3'
					  WHEN RANK() OVER (ORDER BY sum(new_passengers) ASC )<=3 THEN'Bottom 3'
					  ELSE 'other' END AS city_category
FROM dim_city dc JOIN fact_passenger_summary fps ON dc.city_id=fps.city_id
GROUP BY city_name 
ORDER BY total_new_passengers DESC;



-- Identify month with highest revenue for each city 
with monthly_revenue as (Select city_name,
sum(case when monthname(date)='January' then fare_amount else 0 end) as January, 
sum(case when monthname(date)='February' then fare_amount else 0 end) as February, 
sum(case when monthname(date)='March' then fare_amount else 0 end) as March, 
sum(case when monthname(date)='April' then fare_amount else 0 end) as April, 
sum(case when monthname(date)='May' then fare_amount else 0 end) as May, 
sum(case when monthname(date)='June' then fare_amount else 0 end) as June
from fact_trips join dim_city on fact_trips.city_id= dim_city.city_id
group by city_name),
greatest_revenue as ( select city_name , GREATEST(January,February, March,April, May, June)as max_revenue
from monthly_revenue ),
 revenue as (SELECT 
    m.city_name, CASE 
                     WHEN January = max_revenue THEN 'January'
                     WHEN February = max_revenue THEN 'February'
                     WHEN March = max_revenue THEN 'March'
                     WHEN April = max_revenue THEN 'April'
				     WHEN May = max_revenue THEN 'May'
                     WHEN June = max_revenue THEN 'June'
                     END AS highest_revenue_month,
    max_revenue
FROM monthly_revenue m JOIN greatest_revenue maxr ON m.city_name = maxr.city_name)
Select city_name, max_revenue ,highest_revenue_month, ROUND(max_revenue* 100/(select sum(fare_amount) from fact_trips),2) as percentage_contribution
from revenue ;





-- Repeat passenger rate analysis for each month and city
Select city_name,
round(sum(case when monthname(month)='January' then repeat_passengers else 0 end)*100 /sum(total_passengers),2)  as January, 
round(sum(case when monthname(month)='February' then repeat_passengers else 0 end)*100 /sum(total_passengers),2) as February, 
round(sum(case when monthname(month)='March' then repeat_passengers else 0 end)*100 /sum(total_passengers),2) as March, 
round(sum(case when monthname(month)='April' then repeat_passengers else 0 end)*100 /sum(total_passengers),2) as April, 
round(sum(case when monthname(month)='May' then repeat_passengers else 0 end)*100 /sum(total_passengers),2) as May, 
round(sum(case when monthname(month)='June' then repeat_passengers else 0 end)*100 /sum(total_passengers),2) as June
from fact_passenger_summary fps join dim_city on fps.city_id= dim_city.city_id
group by city_name;

-- Repeat passenger rate over the cities across all months of the year
SELECT city_name , ROUND(sum(repeat_passengers)*100/sum(total_passengers),2) AS repeat_passenger_rate
FROM fact_passenger_summary fps JOIN dim_city ON fps.city_id= dim_city.city_id
GROUP BY city_name;








