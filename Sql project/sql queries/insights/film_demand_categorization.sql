

-- Categories Generating the Most Revenue

select c.name , SUM(p.amount) as total_revenue
from rental r join inventory i
on r.inventory_id = i.inventory_id
join payment p on p.rental_id = r.rental_id
join film f on f.film_id = i.film_id
join film_category fc on fc.film_id = f.film_id
join category c on c.category_id = fc.category_id
group by c.name
order by total_revenue desc
limit 10;

-- Rental Frequency by Language, Length, Rating
select f.language_id , l.name as language_name, f.rating , count(r.rental_id) as rental_count
from film f join language l 
on f.language_id = l.language_id
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
group by f.language_id , f.rating;

-- Films/Categories with No Rentals

select f.film_id , f.title , c.name as category
from film f 
join film_category fc on f.film_id = fc.film_id
join category c on c.category_id = fc.category_id
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id
where r.rental_id is NULL;

-- 
