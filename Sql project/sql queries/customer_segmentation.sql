-- (GROUP 3 )

use sakila;

show tables;

select * from customer;
select * from address;
select * from city;
select *  from country;

select * from payment;

-- Identify the top 10 customers who have paid the highest total rental fees across all stores. Include
-- their customer ID, full name, email, and total payment amount.

select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
c.email as customer_email , SUM(p.amount) as total_payment_amount
from customer c join payment p on
c.customer_id = p.customer_id
group by c.customer_id , customer_name , customer_email
order by total_payment_amount;

-- Group customers into three payment tiers — Low (< 100), Medium (100–200), and High (> 200) —
-- based on their total payments. Count how many customers fall into each tier.

select * from payment;

with new_table as (
	select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
	c.email as customer_email , SUM(p.amount) as total_payment_amount
	from customer c join payment p on
	c.customer_id = p.customer_id
	group by c.customer_id , customer_name , customer_email
)

select 
	SUM(case when total_payment_amount > 50 and total_payment_amount<100 then 1 else 0 end) AS LOW,
	SUM(case when total_payment_amount > 100 and total_payment_amount < 200 then 1 else 0 end ) AS mediums,
	SUM(case when total_payment_amount > 200 then 1 else 0 end) AS high 
from new_table;

-- Calculate the average number of rentals made per customer who joined in each month of the last year

select * from rental;

with new_table as (
	select r.customer_id , date_format(r.rental_date , "%Y-%m") as month_rental,
		count(r.rental_id) as count_rental
		from rental r 
		group by month_rental , r.customer_id
)

select month_rental , count(distinct customer_id) as customer_count,
ROUND(avg(count_rental) ,2 ) as avg_rental_per_customer
from new_table 
group by month_rental
order by month_rental;

-- Identify customers who rented more than 10 times in the past 3 months and calculate the average
-- payment amount for this group.



SELECT
    r.customer_id,
    COUNT(r.rental_id) AS rental_count,
    AVG(p.amount) AS avg_payment
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
WHERE r.rental_date >= DATE_SUB('2006-03-01', INTERVAL 3 MONTH)
GROUP BY r.customer_id
HAVING rental_count > 10;



-- determine the city with the highest average payment per customer, considering only customers
-- with at least 5 rental

select * from customer;
select * from rental;
select * from payment;
select * from city;
select * from address;

select c.customer_id , SUM(p.amount) as payment_amount , a.address_id , a.city_id , ct.city
from customer c right join rental r on c.customer_id = r.customer_id
join payment p on c.customer_id = p.customer_id
join address a on c.address_id = a.address_id
join city ct on ct.city_id = a.city_id
group by c.customer_id , ct.city 
having count(c.customer_id) >= 5;

-- Calculate the number of active vs. inactive customers, where active customers are defined as those
-- who rented at least once in the last 6 month

-- query 1 ( correct)
with max_date_cte as (
	select max(rental_date) as max_date from rental
)
,new_table as (
	select distinct customer_id 
	from rental r , max_date_cte
	where rental_date >= DATE_SUB(max_date_cte.max_date, interval 6 month)
)

select SUM(case when r.customer_id is NOT NULL then 1 else 0 end) as active_customers,
SUM(case when r.customer_id is NULL then 1 else 0 end) as incative_customers
from customer c left join new_table r on c.customer_id = r.customer_id;


-- Find the percentage of customers who returned to rent again within 30 days of their first rental.

select * from rental;
with first_rental as (
	select c.customer_id , 
	min(r.rental_date) as first_rental_date
	from customer c join rental r on c.customer_id = r.customer_id
    group by c.customer_id
),
new_customers as (
	select fr.customer_id
    from first_rental fr join rental r on
    fr.customer_id = r.customer_id 
    where fr.first_rental_date < r.rental_date
    and r.rental_date <= DATE_ADD(fr.first_rental_date, interval 30 day)
    group by fr.customer_id
)

select count(nc.customer_id) as required_customer,
(select count(distinct customer_id) from customer) as total_customers,
(count(nc.customer_id)/(select count(distinct customer_id) from customer))*100 as percentage_return
from new_customers nc;

-- List the top 5 cities with the most customers who have not rented anything in the last 12 months.

select ct.city_id , ct.city as city_name,
SUM(case when r.customer_id is null then 1 else 0 end) as inactive_customer from customer c
join address a on c.address_id = a.address_id
join city ct on ct.city_id = a.city_id
left join rental r on c.customer_id = r.customer_id
and r.rental_date >= date_sub(curdate() , interval 12 month)
group by ct.city_id
order by inactive_customer desc limit 5;

-- Identify customers who rented the same film more than once and calculate how many such repeat
-- rentals exist per customer.

select * from customer;
select * from rental;

with new_customers as (
	select r.customer_id , i.film_id , count(r.rental_id) as rental_counts
	from rental r right join inventory i using(inventory_id)
	where r.customer_id is not NULL
	group by r.customer_id , i.film_id
	having  count(*) > 1
)

select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name, rental_counts
from new_customers nc left join customer c on nc.customer_id = c.customer_id
order by rental_counts desc;


 -- Find the average time gap (in days) between successive rentals for each customer and rank the top 10 with the shortest average gap

with rental_gaps as (
	select customer_id , rental_date,
	LAG(rental_date) over(partition by customer_id order by rental_date) as prev_rental_date
	from rental
),
gap_calculation as (
	select customer_id , 
	rental_date , prev_rental_date , 
	abs(datediff(rental_date,prev_rental_date)) as rental_gap
	from rental_gaps
    where prev_rental_date is not NULL
),
avg_gap as (
	select customer_id , ROUND(avg(rental_gap), 2) as average_gaps
	from gap_calculation
    group by customer_id 
    order by average_gaps desc
    limit 10
)

select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
c.email , c.address_id , average_gaps
from customer c right join avg_gap a on c.customer_id = a.customer_id
order by average_gaps ;

with rental_gaps as (
	select customer_id , rental_date,
	LAG(rental_date) over(partition by customer_id order by rental_date) as prev_rental_date
	from rental
)
select * from rental_gaps;

WITH rental_dates AS (
    SELECT 
        customer_id,
        rental_date,
        LEAD(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date) AS next_rental
    FROM rental
),
gaps AS (
    SELECT 
        customer_id,
        DATEDIFF(next_rental, rental_date) AS gap_days
    FROM rental_dates
    WHERE next_rental IS NOT NULL
)
SELECT 
    customer_id,
    ROUND(AVG(gap_days), 2) AS avg_gap_days
FROM gaps
GROUP BY customer_id
ORDER BY avg_gap_days ASC
LIMIT 10;







