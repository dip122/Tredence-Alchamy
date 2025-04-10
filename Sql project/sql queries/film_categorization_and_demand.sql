

-- Identify the top 5 film categories with the highest total revenue. Show category name and revenue

select ct.name as category_name , SUM(p.amount) as total_revenue from payment p
join rental r on p.rental_id = r.rental_id
left join inventory i on i.inventory_id = r.inventory_id
left join film f on i.film_id= f.film_id
left join film_category fct on f.film_id = fct.film_id
left join category ct on fct.category_id = ct.category_id
group by ct.name
order by total_revenue desc
limit 5;

-- For each film rating (G, PG, PG-13, R, NC-17), calculate the average rental frequency and average
-- rental duration.

select f.rating,
count(r.rental_id) as rental_frequency,
avg(timestampdiff(HOUR , r.rental_date , r.return_date)) as average_rental_duration_hour
from film f 
left join inventory i on f.film_id = i.film_id
left join rental r on r.inventory_id = i.inventory_id
where r.return_date is not NULL
group by f.rating
order by average_rental_duration_hour desc;

-- query 2 for above question

WITH film_stats AS (
  SELECT 
    f.film_id,
    f.rating,
    COUNT(r.rental_id) AS rental_count,
    AVG(DATEDIFF(r.return_date, r.rental_date)) AS avg_duration
  FROM film f
  LEFT JOIN inventory inv ON f.film_id = inv.film_id
  LEFT JOIN rental r ON inv.inventory_id = r.inventory_id
  GROUP BY f.film_id, f.rating
)
SELECT 
  rating,
  ROUND(AVG(rental_count), 2) AS avg_rental_frequency,
  ROUND(AVG(avg_duration), 2) AS avg_rental_duration
FROM film_stats
GROUP BY rating;



-- Find the 10 most frequently rented films in the past year. Include film title, rental count, and total revenue

select f.film_id , f.title , count(r.rental_id) as rental_counts,
SUM(p.amount) as total_revenue
from rental r 
left join inventory i on r.inventory_id = i.inventory_id
left join film f on i.film_id = f.film_id
left join payment p on p.rental_id = r.rental_id
group by f.film_id 
order by total_revenue desc
limit 10;

-- Which actors appear in the highest number of top 50 rented films?

with film_rental_count as (
	select f.film_id , f.description,  count(r.rental_id) as rental_counts from rental r 
	left join inventory i on r.inventory_id = i.inventory_id
	left join film f on f.film_id = i.film_id
	group by f.film_id
	order by rental_counts desc
	limit 50
)
select actor_id ,
concat(first_name , ' ' , last_name) as actor_name,
count(*) as apprence_count
from film_rental_count frt left join film_actor using(film_id)
left join actor using(actor_id)
group by actor_id , actor_name
order by apprence_count desc;

-- Determine the rental conversion rate per film — number of rentals divided by number of inventory
-- copies available. List top and bottom 5 films.

with film_statistics as (
	select f.film_id , f.title ,
    count(distinct i.inventory_id) as count_inventory,
    count(r.rental_id) as count_rentals ,
    count(r.rental_id)/count(distinct i.inventory_id) as conversion_rate
    from inventory i left join rental r 
    on i.inventory_id = r.inventory_id 
    join film f on f.film_id = i.film_id
    group by f.film_id , f.title
)

(select * from film_statistics 
order by conversion_rate desc limit 5)
union
(select * from film_statistics 
order by conversion_rate limit 5);

-- List all films that have never been rented, along with their category and language.

SELECT f.title, c.name AS category, l.name AS language
FROM film f
JOIN language l ON f.language_id = l.language_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL
GROUP BY f.film_id, f.title, c.name, l.name;

-- Which film categories have the highest average revenue per rental transaction?

select c.name as category , count(r.rental_id) as rental_count,
SUM(p.amount) as total_revenue,
SUM(p.amount)/count(r.rental_id) as average_revenue_per_rental_transactions
from rental r
left join inventory i on r.inventory_id = i.inventory_id
join payment p on p.rental_id = r.rental_id
join film f on f.film_id = i.film_id
join film_category fc on fc.film_id = f.film_id
join category c on c.category_id = fc.category_id 
group by c.name
order by average_revenue_per_rental_transactions desc;

-- Find films that were rented more than 5 times in a single day — list film title, date, and number of rentals.

select f.film_id , f.title ,  
DATE(r.rental_date) as rental_day,
count(r.rental_id) as rental_count
from rental r left join inventory i
on r.inventory_id  = i.inventory_id
join film f on f.film_id = i.film_id 
group by f.film_id, rental_day 
having rental_count > 5
order by rental_count desc;

-- What percentage of rentals were of films longer than 120 minutes?

select 
Round((SUM(case when f.length > 120 then 1 else 0 end)/count(*))*100 , 2) as percentage_rental_films_longer_then_20
from rental r 
join inventory i on r.inventory_id = i.inventory_id
join film f on f.film_id = i.film_id;

-- Determine the correlation between film rental rate and actual rental count. Group films into rental
-- rate buckets and compute rental averages.

select * from film;

with new_rental_cal as (
	select f.film_id , f.rental_rate , count(r.rental_id) as rental_count
	from rental r 
	left join inventory i on r.inventory_id = i.inventory_id
	left join film f on f.film_id = i.film_id
	group by f.film_id,f.rental_rate
), 
rate_filter as (
	select rental_rate , rental_count,
    case 
		when rental_rate < 1.99 then '0-1.98'
        when rental_rate < 2.99 then '1.99-2.98'
        when rental_rate < 3.99 then '2.99-3.99'
		else '3.99+'
        end as rate_bucket
	from new_rental_cal
)

select rate_bucket, count(*) as count_films,
ROUND(avg(rental_count) , 2) as average_rentals_per_film
from rate_filter
group by rate_bucket
order by average_rentals_per_film desc;





