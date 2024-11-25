-- Часть 1

-- Задание 1
select o.customer_id, c.name
from orders_new o left join customers_new c on o.customer_id = c.customer_id
where 
	to_timestamp(shipment_date, 'YYYY-MM-DD HH24:MI:SS') - to_timestamp(order_date, 'YYYY-MM-DD HH24:MI:SS') = 
	(select max(to_timestamp(shipment_date, 'YYYY-MM-DD HH24:MI:SS') - to_timestamp(order_date, 'YYYY-MM-DD HH24:MI:SS'))
	from orders_new );

-- Задание 2
with total_orders_t as (
	select customer_id, count(order_id) as total_orders
	from orders_new
	group by customer_id
)
select 
	o.customer_id, c.name, 
	avg(to_timestamp(shipment_date, 'YYYY-MM-DD HH24:MI:SS') - to_timestamp(order_date, 'YYYY-MM-DD HH24:MI:SS')) as avg_delivery_time,
	sum(o.order_ammount) as total_orders_sum
from orders_new o left join customers_new c on o.customer_id = c.customer_id
group by o.customer_id, c.name
having count(o.order_id) = (select max(total_orders) from total_orders_t)
order by total_orders_sum desc;


-- Задание 3
-- Так как у каждого заказа есть дата доставки, предположу что все заказы с cancel означают, что покупатель отказался от них после доставки

select 
	name, 
	count(*) filter (where order_status = 'Cancel') as total_canceled_orders,
	count(*) filter (where (to_timestamp(shipment_date, 'YYYY-MM-DD HH24:MI:SS') - to_timestamp(order_date, 'YYYY-MM-DD HH24:MI:SS'))
	> '5 days'::interval) as total_delayed_orders, 
	sum(order_ammount) as total_orders_sum
from orders_new o join customers_new c on o.customer_id = c.customer_id 
where 
	(to_timestamp(shipment_date, 'YYYY-MM-DD HH24:MI:SS') - to_timestamp(order_date, 'YYYY-MM-DD HH24:MI:SS')) > '5 days'::interval 
	or order_status = 'Cancel'
group by o.customer_id, name
order by total_orders_sum desc;

-- Часть 2 

with total_category_sum as (
	select 
		p.product_category,
		sum(o.order_ammount) as total_sum
	from orders o left join products p on o.product_id = p.product_id
	group by p.product_category
),
product_name_sum as (
	select
		p.product_category, 
		p.product_name, 
		sum(o.order_ammount) total_categ_sum
	from orders o left join products p on o.product_id = p.product_id
	group by p.product_category, p.product_name
	order by p.product_category
),
max_product_name as (
	select product_name_sum.product_category, product_name, max_total_categ_sum
	from
		(select product_category, max(total_categ_sum) as max_total_categ_sum
		from product_name_sum
		group by product_category
		order by product_category) max_total_categ_sum_t 
		join product_name_sum on total_categ_sum = max_total_categ_sum and max_total_categ_sum_t.product_category = product_name_sum.product_category
)
select 
	total_category_sum.product_category, 
	total_category_sum.total_sum as category_total_sum, 
	t.product_category as category_max_total_sum,
	max_product_name.product_name as product_name_max_sum
from 
	total_category_sum  
	cross join (select product_category
		from total_category_sum
		where total_sum = (select max(total_sum) from total_category_sum)) t
	inner join max_product_name 
	on total_category_sum.product_category = max_product_name.product_category
	