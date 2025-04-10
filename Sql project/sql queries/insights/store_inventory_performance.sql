
-- Store-Level Performance ( inventory & rental freq )

select i.store_id , count(distinct i.inventory_id) as inventory_count,
count(r.rental_id) as rental_count,
SUM(p.amount) as total_revenue
from inventory i left join rental r on r.inventory_id = i.inventory_id
left join payment p on r.rental_id = p.rental_id
group by i.store_id;

-- Underutilized Inventory

select * from inventory;

select i.inventory_id , i.store_id, i.film_id, count(r.rental_id) as rental_counts
from inventory i
left join rental r on i.inventory_id = r.inventory_id
group by i.inventory_id
having rental_counts = 0;

-- Best-Performing Films by Store and Category

select i.store_id , c.name as category , f.title,
count(r.rental_id) as rental_count
from rental r join inventory i
on r.inventory_id = i.inventory_id
join film f on f.film_id = i.film_id
join film_category fc on fc.film_id = f.film_id
join category c on fc.category_id = c.category_id
group by i.store_id , c.name , f.film_id -- as we want to know the best performing films
order by rental_count desc
limit 10;


