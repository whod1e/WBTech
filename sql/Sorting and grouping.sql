--Часть 1

-- Задача 1
-- по числу полных лет
select city, age, count(id) as count_users
from users
group by city, age
order by count_users desc;

-- по категориям: от 0 до 20 (категория young), от 21 до 49 (категория adult), от 50 и выше (категория old)
select city, age_category, count(id) as count_users
from
    (select *,
        case
            when age between 0 and 20 then 'young'
            when age between 21 and 49 then 'adult'
            else 'old'
        end as age_category
    from users) as users_with_age_category
group by city, age_category
order by count_users desc;

-- Задача 2

select category, round(avg(price), 2) as avg_price
from products
where category in (select category 
					from products 
					where lower(name) like '%home%' or lower(name) like '%hair%')
group by category;

-- Часть 2
-- Задача 1
/* Мы можем заметить что у пользователей имеются повторы категорий, но с разными датами регистрации
 * Будем считать их за уникальные категории */
select *
from sellers s 
where seller_id = 52

/* В условии сказано "rich" это кто продает более одной категории товаров и чья суммарная выручка превышает 50 000
 * а "poor" продают более одной категории, но чья суммарная выручка менее 50 000
 * но остаются те которые продают меньше 1 категории, их я буду отмечать "nn" и не буду выводить в запросе 
 */
select *	
from	
	(select
		seller_id,
		count(distinct category) as total_categ,
		avg(rating) as avg_rating,
		sum(revenue) as total_revenue,
		case 
			when count(*) > 1 and sum(revenue) > 50000 then 'rich'
			when count(*) > 1 and sum(revenue) <= 50000 then 'poor'
			else 'nn'
		end as seller_type
	from sellers
	where category != 'Bedding' 
	group by seller_id) t
where seller_type != 'nn'
order by seller_id

-- Задача 2
-- За дату регистрации продавца будем брать минимальную date_reg

with poor_salers as (
	select seller_id 
	from
		(select
			seller_id,
			case 
				when count(*) > 1 and sum(revenue) > 50000 then 'rich'
				when count(*) > 1 and sum(revenue) <= 50000 then 'poor'
				else 'nn'
			end as seller_type
		from sellers
		where category != 'Bedding' 
		group by seller_id)
	where seller_type = 'poor'
)
select 
	seller_id, 
	(current_date - min(to_date(date_reg, 'DD/MM/YYYY'))) / 30 as month_from_registration,
	(select max(delivery_days) - min(delivery_days) from sellers) max_delivery_difference
from sellers 
where seller_id in (select * from poor_salers) and category != 'Bedding'
group by seller_id 
order by seller_id 

-- Задача 3
/*
 * Если за дату регистрации брать первую среди всех регистраций продавца (seller_id), 
 * то получается, что продавцов удовлетворяющих условию нет.
 */
select seller_id, string_agg(category, ' - ')
from sellers 
group by seller_id 
having 
	count(*) = 2
	and sum(revenue) > 75000
	and date_part('year', min(to_date(date_reg, 'DD/MM/YYYY'))) = 2022 


/* 
 * Тогда можно интерпретировать иначе: продавцы, которые зарегистрировали какую-то из категорий в 2022 году
 * будут подходить по условию регистрации.
 */
	
select seller_id, string_agg(category, ' - ')
from sellers
where 
	seller_id in (select seller_id
	from sellers s 
	where date_part('year', to_date(date_reg, 'DD/MM/YYYY')) = 2022) 
group by seller_id 
having 
	count(*) = 2
	and sum(revenue) > 75000
	
-- Конечно можно сказать что продавец это seller_id + category, но тогда у каждого продавца будет всего лишь одна категория,
-- что точно не подходит нашему заданию