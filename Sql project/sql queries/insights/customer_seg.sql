use sakila;

-- top revenue generating customer

select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
SUM(p.amount) as total_revenue
from payment p join customer c 
on p.customer_id = c.customer_id
group by c.customer_id
order by total_revenue desc;

-- Classify Customers into Payment & Activity Tiers

select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
count(r.rental_id) as rental_count,
SUM(p.amount) as total_revenue,
case when SUM(p.amount) > 150 then 'HIGH VALUE' 
	when SUM(p.amount) > 100 then 'LOW VALUE'
    else 'LOW VALUE'
end as payment_tire
from payment p join customer c
on p.customer_id = c.customer_id
join rental r on r.customer_id = c.customer_id
group by c.customer_id
order by total_revenue desc;

-- Churn and Retention

select c.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
MAX(r.rental_date) as last_rental_date
from customer c 
join rental r on c.customer_id = r.customer_id
group by c.customer_id
having last_rental_date < date_sub(curdate() , interval 6 month); -- indentify the customer who have not rented for last 6 months

-- Repeat Rental Behavior

select r.customer_id , concat(c.first_name , ' ' , c.last_name) as customer_name,
count(r.rental_id) as rental_count
from rental r join customer c on r.customer_id = c.customer_id
group by r.customer_id
order by rental_count desc;



