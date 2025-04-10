use sakila;
show tables;

-- Determine which store has generated the highest total revenue and provide the breakdown of
-- revenue per staff member for that store.

select * from store;
select * from payment;
select * from staff;

with new_table as (
	select st.store_id , count(distinct p.staff_id) as count_staffs,
	SUM(p.amount) as total_revenue
	from store st join payment p
	on st.manager_staff_id = p.staff_id
	group by st.store_id 
	order by total_revenue desc
    limit 1
)
-- select * from new_table; 
select store_id , staff_id , total_revenue
from payment p join staff using(staff_id)
join new_table using(store_id)
group by store_id , staff_id;

-- List the top 5 rented films per store based on rental count. Show store ID, film title, and number of rentals.
select * from film;
select * from store;
with new_ranked_table as (
	select s.store_id , f.title,
	count(r.rental_id) as rental_count,
	rank() over(partition by s.store_id order by count(r.rental_id) desc) as ranked_rental_count
	from rental r join inventory i on r.inventory_id = i.inventory_id
	join film f on f.film_id = i.film_id
	join store s on s.store_id = i.store_id
	group by s.store_id , f.film_id
)
select store_id , title , rental_count
from new_ranked_table
where ranked_rental_count <= 5
order by store_id , rental_count desc
limit 5;

-- Calculate the number and percentage of inventory items per store that have never been rented.
select * from inventory;
select * from rental;
select * from store;


select i.store_id , count(i.inventory_id) as count_inventory_items,
SUM(case when r.rental_id is NULL then 1 else 0 end) as not_used,
ROUND(((SUM(case when r.rental_id is NULL then 1 else 0 end))/count(i.inventory_id))*100 , 2) as percentage_amount
from inventory i left join rental r
on i.inventory_id = r.inventory_id
group by i.store_id;

-- Find the film with the longest average rental duration per store and show the average in days

select * from inventory;
select * from rental;

select i.film_id ,i.store_id, f.title,
ROUND(avg(timestampdiff(second , r.rental_date , r.return_date))/86400 , 2) as average_duration_day
from rental r join inventory i
on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
where r.return_date is NOT NULL
group by i.store_id , i.film_id , f.title
order by average_duration_day desc 
limit 2;

-- query 2 (same question with above question )

WITH film_avg AS (
  SELECT 
    inv.store_id,
    f.film_id,
    f.title,
    AVG(DATEDIFF(r.return_date, r.rental_date)) AS avg_duration
  FROM rental r
  JOIN inventory inv ON r.inventory_id = inv.inventory_id
  JOIN film f ON inv.film_id = f.film_id
  GROUP BY inv.store_id, f.film_id, f.title
)
SELECT 
  store_id, 
  film_id, 
  title, 
  ROUND(avg_duration, 2) AS avg_duration_in_days
FROM (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY avg_duration DESC) AS rn
  FROM film_avg
) sub
WHERE rn = 1;

-- Identify the most common rental day of the week for each store.

with new_table as (
	select i.store_id,
	DAYNAME(r.rental_date)  as day_name, count(r.rental_id) as rental_count
	from rental r 
	join inventory i on r.inventory_id = i.inventory_id
	group by i.store_id , day_name
)
,ranked_table as (
	select store_id , day_name , rental_count ,
    rank() over(partition by store_id order by rental_count desc) as ranked_rental_count
    from new_table
)

select store_id , day_name , rental_count from ranked_table
where ranked_rental_count = 1;

-- Which store has the lowest average rentals per inventory item? Show store ID, total inventory, total 
-- rentals, and average rentals per item.

select i.store_id , count(distinct i.inventory_id) as total_inventory,
count(r.rental_id) as total_rentals ,
ROUND(count(r.rental_id)/count(distinct i.inventory_id) , 2 ) as avergae_rentals_per_items
from rental r 
join inventory i on i.inventory_id = r.inventory_id
group by i.store_id
order by avergae_rentals_per_items limit 1;

-- Find the average number of films available per category per store

select * from store;
select * from category;

with new_table as (
	select film_id , category_id , title , description , name
	from film join film_category using (film_id)
	join category using(category_id)
),
film_category_store as (
	select store_id , category_id ,
    count(distinct i.film_id) as film_count
    from inventory i 
	join new_table nt on i.film_id = nt.film_id
    group by store_id , category_id 
)
-- select * from film_category_store; 
select store_id  , ROUND(avg(film_count), 2) as average_films
from film_category_store
group by store_id;

select store_id , category_id, film_count
from film_category_store
order by film_count desc;



-- query 2 ( group by store_id and category_name also --> same question with the above question )

SELECT 
    i.store_id,
    c.name AS category,
    COUNT(DISTINCT i.film_id) AS films_per_category
FROM inventory i
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY i.store_id, c.name
ORDER BY i.store_id, films_per_category DESC;


-- List all stores with more than 50 films that haven’t been rented in the last 6 months

SELECT 
  s.store_id,
  COUNT(DISTINCT inv.film_id) AS distinct_films
FROM store s
JOIN inventory inv ON s.store_id = inv.store_id
LEFT JOIN rental r ON inv.inventory_id = r.inventory_id 
                   AND r.rental_date >= DATE_SUB('2006-02-14', INTERVAL 6 MONTH)
WHERE r.rental_id IS NULL
GROUP BY s.store_id
HAVING distinct_films  < 50;

-- Determine the monthly rental growth or decline (in percentage) for each store over the last 6 months.

with max_rental_date as (
	select max(rental_date) as max_date from rental
),
monthly_rentals as (
	select i.store_id, date_format(r.rental_date , "%Y-%m") as rental_month,
    count(r.rental_id) as rental_counts
    from rental r 
    left join inventory i on r.inventory_id = i.inventory_id
    where r.rental_date <= date_sub((select max(rental_date) from rental) , interval 6 month)
    group by i.store_id , rental_month
),
growth as (
	select store_id , rental_month , rental_counts,
	LAG(rental_counts) over(partition by store_id order by rental_counts) as prev_month_rental_count 
	from monthly_rentals
)
select store_id , rental_month , rental_counts, 
prev_month_rental_count , ROUND((((rental_counts - prev_month_rental_count)/prev_month_rental_count))*100 , 2) as percentage_growth
from growth
where prev_month_rental_count is not NULL;


-- Which store has the highest customer repeat rate (customers with 2+ rentals from the same store)

with count_rentals_per_customer as (
	select i.store_id  , 
    r.customer_id, 
    count(r.rental_id) as count_rentals
	from rental r left join
	inventory i on r.inventory_id = i.inventory_id
	group by i.store_id , r.customer_id
), -- store_id , customer_id and rental_count of each customer in each store
store_repeated_customers as (
	select store_id ,
    SUM(case when count_rentals>=2 then 1 else 0 end) as repeated_customer,
    count(customer_id) as total_customer,
    ROUND(((SUM(case when count_rentals>=2 then 1 else 0 end))/count(customer_id))*100 , 2) as repeated_rate_percentage
    from count_rentals_per_customer 
    group by store_id
)
select store_id , repeated_customer ,
total_customer , repeated_rate_percentage
from store_repeated_customers
order by repeated_rate_percentage desc 
limit 1;






