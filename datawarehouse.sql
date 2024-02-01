create table dimDate (
	date_key int primary key,
	date date not null,
	year smallint not null,
	quarter smallint not null,
	month smallint not null,
	week smallint not null,
	day smallint not null,
	is_weekend bool
);

insert into dimDate (date_key, date, year, quarter, month, week, day, is_weekend)
select distinct to_char(payment_date, 'yyyymmdd')::int as date_key,
	   date(payment_date) as date, 
	   extract(year from payment_date) as year,
	   extract(quarter from payment_date) as quarter,
	   extract(month from payment_date) as month,
	   extract(week from payment_date) as week,
	   extract(day from payment_date) as day,
	   (case when extract(isodow from payment_date) in (6, 7) then true else false end) as is_weekend
from payment;

create table dimCustomer (
	customer_key serial primary key,
	customer_id int not null,
	firstname varchar(20) not null,
	lastname varchar(20) not null,
	email varchar(50),
	phone char(20),
	address varchar(50) not null,
	address2 varchar(50),
	district varchar(20) not null,
	city varchar(50),
	country varchar(50) not null,
	postal_code varchar(10) not null,
	active bool not null,
	create_date timestamp not null,
	start_date date not null,
	end_date date not null
); 

insert into dimCustomer (customer_key, customer_id, firstname, lastname, email, phone, address, address2, district, city, country, postal_code, active, create_date, start_date, end_date)
select c.customer_id as customer_key,
	   c.customer_id,
	   c.first_name,
	   c.last_name,
	   c.email,
	   a.phone,
	   a.address,
	   a.address2,
	   a.district,
	   ci.city,
	   co.country,
	   a.postal_code,
	   c.activebool as active,
	   c.create_date,
	   now() as start_date,
	   now() as end_date
from customer c
join address a
on c.address_id = a.address_id
join city ci
on a.city_id = ci.city_id
join country co
on ci.country_id = co.country_id;

create table dimMovie (
	movie_key serial primary key,
	film_id int not null,
	title varchar(50) not null,
	description text not null,
	release_year smallint not null,
	language varchar(20) not null,
	rental_duration smallint not null,
	length smallint not null,
	rating varchar(5),
	special_features text
);

insert into dimMovie (movie_key, film_id, title, description, release_year, language, rental_duration, length, rating, special_features)
select 
	f.film_id as movie_key,
	f.film_id,
	f.title,
	f.description,
	f.release_year,
	l.name,
	f.rental_duration,
	f.length,
	f.rating,
	f.special_features
from film f
join language l
on f.language_id = l.language_id;

create table dimStore (
	store_key serial primary key,
	store_id int not null,
	address varchar(50) not null,
	address2 varchar(50),
	district varchar(20) not null,
	city varchar(50),
	country varchar(50) not null,
	postal_code varchar(10) not null,
	manager_firstname varchar(20) not null,
	manager_lastname varchar(20) not null,
	start_date date,
	end_date date
);

insert into dimStore (store_key, store_id, address, address2, district, city, country, postal_code, manager_firstname, manager_lastname, start_date, end_date)
select sto.store_id as store_key,
	   sto.store_id,
	   a.address,
	   a.address2,
	   a.district,
	   ci.city,
	   co.country,
	   a.postal_code,
	   stf.first_name,
	   stf.last_name,
	   now() as start_date,
	   now() as end_date	   
from store sto
join staff stf
on sto.manager_staff_id = stf.staff_id
join address a
on sto.address_id = a.address_id
join city ci
on a.city_id = ci.city_id
join country co
on ci.country_id = co.country_id;

create table factSales (
	sales_key serial primary key,
	date_key int references dimDate (date_key),
	customer_key int references dimCustomer (customer_key),
	movie_key int references dimMovie (movie_key),
	store_key int references dimStore (store_key),
	sales_amount numeric(5, 2)
	
);

insert into factSales (date_key, customer_key, movie_key, store_key, sales_amount)
select to_char(p.payment_date, 'yyyymmdd')::int as date_key,
	   p.customer_id as customer_key,
	   i.film_id as movie_key,
	   i.store_id as store_key,
	   p.amount as sales_amount  
from payment p
join rental r
on p.rental_id = r.rental_id
join inventory i
on r.inventory_id = i.inventory_id;

-- Query using the star-schema
select dimDate.year, dimMovie.title, dimCustomer.city, sum(factSales.sales_amount) as revenue
from factSales
join dimDate 
on factSales.date_key = dimDate.date_key
join dimCustomer
on factSales.customer_key = dimCustomer.customer_key
join dimMovie
on factSales.movie_key = dimMovie.movie_key
join dimStore
on factSales.store_key = dimStore.store_key
group by dimDate.year, dimMovie.title, dimCustomer.city
order by revenue desc

