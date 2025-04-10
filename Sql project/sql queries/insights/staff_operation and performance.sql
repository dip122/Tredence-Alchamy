
-- Staff Contribution to Revenue

select s.staff_id , concat(s.first_name, ' ' , s.last_name) as staff_name ,
SUM(p.amount) as total_revenue
from staff s join payment p 
on s.staff_id = p.staff_id
group by s.staff_id
order by total_revenue desc;

-- Repeat Customers per Staff

SELECT 
    r.staff_id, 
    COUNT(DISTINCT r.customer_id) AS unique_customers,
    COUNT(r.rental_id) AS total_rentals
FROM rental r
GROUP BY r.staff_id
HAVING COUNT(rental_id) > 2;

-- Weekend vs. Weekday Performance of each staff

select s.staff_id, concat(s.first_name, ' ' , s.last_name) as staff_name,
	case when dayofweek(r.rental_date) in (1,7) then 'weekend'
    else 'weekday'
    end as day_type,
    count(r.rental_id) as rental_counts,
    SUM(p.amount) as total_revenue
from rental r join staff s on r.staff_id = s.staff_id
join payment p on p.rental_id = r.rental_id
group by s.staff_id , day_type;

-- Monthly Revenue Trends

select date_format(p.payment_date,"%Y-%m" ) as month,
SUM(p.amount) as total_revenue
from payment p 
group by month
order by month;

-- Rental Conversion Rate of films

select f.title , f.film_id , (count(r.rental_id)/count(i.inventory_id)) as conversion_rate
from inventory i left join rental r
on r.inventory_id = i.inventory_id
join film f on f.film_id = i.film_id
group by f.film_id
order by conversion_rate;





