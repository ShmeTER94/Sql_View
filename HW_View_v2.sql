--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".
--Seq Scan on film f  (cost=0.00..77.50 rows=538 width=78) (actual time=0.025..0.615 rows=538 loops=1)
--explain analyze  
select
	film_id,
	title,
	special_features
from
	film f
where
	'Behind the Scenes' = any (special_features) 



--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.
--Seq Scan on film f  (cost=0.00..67.50 rows=538 width=78) (actual time=0.044..0.867 rows=538 loops=1)
--explain analyze
select
	film_id,
	title,
	special_features
from
	film f
where
	special_features && array['Behind the Scenes']


--Subquery Scan on tmp  (cost=0.00..17572.50 rows=5000 width=82) (actual time=0.038..1.855 rows=538 loops=1)
--explain analyze
select
	*
from
	(
	select
		film_id,
		title,
		special_features ,
		generate_subscripts(special_features,
		1) as s
	from
		film f) as tmp
where
	special_features[s] = 'Behind the Scenes'




--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
--Sort  (cost=683.97..685.47 rows=599 width=10) (actual time=24.036..24.101 rows=599 loops=1)
--explain analyze	
with tmp as (
select
	film_id,
	title,
	special_features
from
	film f
where
	'Behind the Scenes' = any (special_features) 
)
select
	r.customer_id,
	count(*)
from
	rental r
join inventory i on
	r.inventory_id = i.inventory_id
where
	i.film_id in (
	select
		film_id
	from
		tmp)
group by
	r.customer_id
order by
	r.customer_id 



--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.
--Sort  (cost=683.97..685.47 rows=599 width=10) (actual time=19.274..19.339 rows=599 loops=1)
--explain analyze
select
	r.customer_id,
	count(*)
from
	rental r
join inventory i on
	r.inventory_id = i.inventory_id
where
	i.film_id in (
	select
		film_id
	from
		(
		select
			film_id,
			title,
			special_features
		from
			film f
		where
			'Behind the Scenes' = any (special_features)) as tmp)
group by
	r.customer_id
order by
	r.customer_id 



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления
create materialized view
practic_view
as
select
	r.customer_id,
	count(*)
from
	rental r
join inventory i on
	r.inventory_id = i.inventory_id
where
	i.film_id in (
	select
		film_id
	from
		(
		select
			film_id,
			title,
			special_features
		from
			film f
		where
			'Behind the Scenes' = any (special_features)) as tmp)
group by
	r.customer_id
order by
	r.customer_id 
	with data 

	
	
refresh materialized view
practic_view 



--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.


Ответ
1.При использовании special_features && array['Behind the Scenes'] затрачивается меньше ресурсов
2.При использовании CTE и подзапросов затрачивается одинаковое количество ресурсов (Cost = 683.97..685.47)




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.
select
	tmp.staff_id, f.title 
from
	(
	select
		inventory_id,
		staff_id ,
		rental_date ,
		row_number() over (partition by staff_id
	order by
		rental_date) as rnb
	from
		rental r) as tmp
join inventory i on
	tmp.inventory_id = i.inventory_id
	join film f on i.film_id = f.film_id 
where
	tmp.rnb = 1
		

--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
with cte as (
select
	*,
	max(cnt_rent) over (partition by store_id) as max_rent,
	min(cnt_rent) over (partition by store_id) as min_rent 
from
	(
	select
		rental_date::date,
		store_id,
		amount,
		count(*) over (partition by s.store_id,
		r.rental_date::date) as cnt_rent,
		sum(amount) over (partition by s.store_id,
		r.rental_date::date) as sum_rent
	from
		rental r
	join staff s on
		r.staff_id = s.staff_id
	join payment p on
		p.rental_id = r.rental_id)as ctein1)
	select
	distinct rental_date, cnt_rent, sum_rent
from
	cte
	where cnt_rent = max_rent
	union all
	select distinct rental_date, cnt_rent, sum_rent from cte 
	where cnt_rent = min_rent
	
