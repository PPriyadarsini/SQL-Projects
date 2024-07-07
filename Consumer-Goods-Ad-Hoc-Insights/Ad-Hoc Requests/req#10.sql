
-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division, product_code, product, total_sold_quantity, rank_order

with cte as (
	select
		p.division, 
		p.product_code, 
		concat(p.product, ' - ', p.variant) as product,
		sum(s.sold_quantity) as total_sold_quantity,
		row_number() over (partition by p.division order by sum(s.sold_quantity) desc) as rank_order
	from dim_product p
	join fact_sales_monthly s
	on s.product_code = p.product_code
	where s.fiscal_year = 2021
    group by p.division, p.product_code, p.product
)

select 
	division, 
	product_code, 
	product,
	total_sold_quantity,
	rank_order
from cte
where rank_order <= 3
	