-- Часть 1

-- max через оконку 
select 
	first_name, last_name, salary, industry,
	first_value(concat(first_name, ' ', last_name)) over(partition by industry order by salary desc) as name_ighest_sal
from salary 

-- max через max() 
with sub_max_industry_salary as (
	select industry, max(salary) max_industry_salary
	from salary 
	group by industry
)
select 
	t.first_name, t.last_name, t.salary, t.industry, 
	concat(sal.first_name, ' ', sal.last_name) as name_ighest_sal
from
	(select first_name, last_name, salary, s.industry, max_industry_salary
	from salary s join sub_max_industry_salary sub on s.industry = sub.industry) t
	join salary sal
	on t.industry = sal.industry and t.max_industry_salary = sal.salary
order by industry, t.salary desc

-- min через оконку 
select 
	first_name, last_name, salary, industry,
	first_value(concat(first_name, ' ', last_name)) over(partition by industry order by salary asc) as name_lowest_sal
from salary 

-- min через min() 
with sub_min_industry_salary as (
	select industry, min(salary) min_industry_salary
	from salary 
	group by industry
)
select 
	t.first_name, t.last_name, t.salary, t.industry, 
	concat(sal.first_name, ' ', sal.last_name) as name_lowest_sal
from
	(select first_name, last_name, salary, s.industry, min_industry_salary
	from salary s join sub_min_industry_salary sub on s.industry = sub.industry) t
	join salary sal
	on t.industry = sal.industry and t.min_industry_salary = sal.salary
order by industry, t.salary desc

-- Часть 2 
-- 1 задача

select 
	distinct sh."SHOPNUMBER", sh."CITY", sh."ADDRESS",
	sum(s."QTY") over (partition by s."SHOPNUMBER") as SUM_QTY,
	sum(s."QTY" * g."PRICE") over (partition by s."SHOPNUMBER") as SUM_QTY_PRICE
from 
	sales s 
	left join goods g on s."ID_GOOD" = g."ID_GOOD" 
	left join shops sh on s."SHOPNUMBER" = sh."SHOPNUMBER"
where "DATE" = '02.01.2016' 
order by "SHOPNUMBER" 

-- Задача 2
/* Условие: 
 * Отберите за каждую дату долю от суммарных продаж (в рублях на дату). Расчеты проводите только по товарам направления ЧИСТОТА.
 * Столбцы в результирующей таблице:
 * DATE_, CITY, SUM_SALES_REL
 *  
 * Не понимаю зачем в результирующей таблице CITY если мы по нему не группировались, поэтому буду выводить без города
 */

select
	distinct s."DATE",
	sum(s."QTY" * g."PRICE") over (partition by s."DATE") * 1.0 / sum(s."QTY" * g."PRICE") over () as SUM_SALES_REL
from 
	sales s 
	left join goods g on s."ID_GOOD" = g."ID_GOOD" 
	left join shops sh on s."SHOPNUMBER" = sh."SHOPNUMBER"
where g."CATEGORY" = 'ЧИСТОТА' 

-- Конечно можно сделать долю каждого города в каждой дате от суммарных продаж, но кажется что этот вариант не подходит для нашей задачи:
select
	distinct s."DATE",
	sh."CITY",
	sum(s."QTY" * g."PRICE") over (partition by s."DATE", sh."CITY") * 1.0 / sum(s."QTY" * g."PRICE") over () as SUM_SALES_REL
from 
	sales s 
	left join goods g on s."ID_GOOD" = g."ID_GOOD" 
	left join shops sh on s."SHOPNUMBER" = sh."SHOPNUMBER"
where g."CATEGORY" = 'ЧИСТОТА' 

-- Задача 3
with ranks_goods as (
	select
		s."DATE", s."SHOPNUMBER", s."ID_GOOD", sum(s."QTY") as sum_qty,
		rank() over (partition by s."DATE", s."SHOPNUMBER" order by sum(s."QTY") desc)
	from 
		sales s 
		left join goods g on s."ID_GOOD" = g."ID_GOOD" 
		left join shops sh on s."SHOPNUMBER" = sh."SHOPNUMBER"
	group by s."DATE", s."SHOPNUMBER", s."ID_GOOD"
	order by s."DATE" asc, s."SHOPNUMBER" asc, sum_qty desc
)
select "DATE", "SHOPNUMBER", "ID_GOOD"
from ranks_goods
where rank <=3 
order by "DATE", "SHOPNUMBER", "ID_GOOD";

-- Задача 4
/*
 * У нас 01.01.2016 первая дата для всех магазинов. Бывает такого, что нет даты 02.01.2016 а есть сразу 03.01.2016
 * Я понимаю это так что в этот день не было продаж (так как не было записей в sales), поэтому для 03.01.2016 мы должны вернуть
 * значение предыдущей даты как 0, а не за 01.01.2016(если бы мы использовали просто lag()). Поэтому добавлю case где обработаю этот случай
 */ 

with t as (
	select s."DATE", sh."SHOPNUMBER", g."CATEGORY", sum(s."QTY" * g."PRICE") as total_sales
	from 
		sales s 
		left join goods g on s."ID_GOOD" = g."ID_GOOD" 
		left join shops sh on s."SHOPNUMBER" = sh."SHOPNUMBER"
	where sh."CITY" = 'СПб'
	group by s."DATE", sh."SHOPNUMBER", g."CATEGORY"
	order by sh."SHOPNUMBER", g."CATEGORY", s."DATE"
)
select 
	"DATE", "SHOPNUMBER", "CATEGORY", 
	case 
		when to_date("DATE", 'DD.MM.YYYY') - (lag(to_date("DATE", 'DD.MM.YYYY')) over (partition by "SHOPNUMBER", "CATEGORY" order by "DATE")) > 1
		then 0
		else lag(total_sales) over (partition by "SHOPNUMBER", "CATEGORY" order by "DATE")
	end as "PREV_SALES"
from t

-- Часть 2

drop table if exists query;

create table query (
    searchid serial primary key,   -- уникальный идентификатор запроса
    year int not null,             -- год
    month int not null,            -- месяц
    day int not null,              -- день
    userid int not null,           -- id пользователя
    ts bigint not null,            -- время запроса в формате unix
    devicetype varchar(50) not null,  -- тип устройства (например, 'mobile', 'desktop')
    deviceid varchar(100) not null,   -- id устройства
    query varchar(255) not null    -- поисковый запрос
);

insert into query (year, month, day, userid, ts, devicetype, deviceid, query)
values
(2024, 11, 17, 1, 1694870400, 'iphone', 'dev001', 'к'),
(2024, 11, 17, 1, 1694870430, 'iphone', 'dev001', 'ку'),
(2024, 11, 17, 1, 1694870520, 'iphone', 'dev001', 'куп'),
(2024, 11, 17, 1, 1694870545, 'iphone', 'dev001', 'купить'),
(2024, 11, 17, 1, 1694870640, 'iphone', 'dev001', 'купить кур'),
(2024, 11, 17, 1, 1694870740, 'iphone', 'dev001', 'купить куртку'),
(2024, 11, 17, 2, 1694870760, 'desktop', 'dev002', 'смартфон'),
(2024, 11, 17, 2, 1694870920, 'desktop', 'dev002', 'смартфоны'),
(2024, 11, 17, 2, 1694870960, 'desktop', 'dev002', 'купить смартфон'),
(2024, 11, 17, 2, 1694871000, 'desktop', 'dev002', 'купить смартфон дешево'),
(2024, 11, 17, 2, 1694871100, 'desktop', 'dev003', 'айфон 16'),
(2024, 11, 17, 3, 1694871000, 'ipad', 'dev003', 'ноутбук'),
(2024, 11, 17, 3, 1694871060, 'ipad', 'dev003', 'ноутбуки'),
(2024, 11, 17, 3, 1694871140, 'ipad', 'dev003', 'купить ноутбук'),
(2024, 11, 17, 3, 1694871180, 'ipad', 'dev003', 'купить ноутбук для работы'),
(2024, 11, 17, 4, 1694871240, 'android', 'dev004', 'игрушки'),
(2024, 11, 17, 4, 1694871300, 'android', 'dev004', 'детские игрушки'),
(2024, 11, 17, 4, 1694871520, 'android', 'dev004', 'купить детские игрушки'),
(2024, 11, 17, 4, 1694871540, 'android', 'dev004', 'купить игрушки недорого'),
(2024, 11, 17, 4, 1694871840, 'android', 'dev004', 'купить безопасные детские игрушки недорого'),
(2024, 11, 17, 5, 1694871540, 'desktop', 'dev003', 'dota 2');

select *
from
	(select *,
		case
			when count(*) over (partition by userid) = 1 then 1
			when lead(ts) over (partition by userid order by ts) - ts > 180 then 1
			when lead(ts) over (partition by userid order by ts) - ts > 60 
			and length(LEAD(query) OVER (PARTITION BY userid ORDER BY ts)) < length(query) then 2
			else 0
		end is_final
	from query) t
where 
	day = 17 and month = 11 and year = 2024 
	and devicetype = 'android'
	and is_final in (1,2);