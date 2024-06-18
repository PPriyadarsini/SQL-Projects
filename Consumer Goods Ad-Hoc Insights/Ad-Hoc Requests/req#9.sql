
-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel, gross_sales_mln, percentage

with cte as (
	select 
		c.channel,
		round((sum(p.gross_price * s.sold_quantity))/1000000,2) as gross_sales_mln
	from dim_customer c
	join fact_sales_monthly s
	on s.customer_code = c.customer_code
	join fact_gross_price p
	on 
		p.product_code = s.product_code and
		p.fiscal_year = s.fiscal_year
	where s.fiscal_year = 2021
	group by c.channel
)
    
select 
	channel,
    gross_sales_mln,
    concat(round((gross_sales_mln * 100)/(select sum(gross_sales_mln) from cte),2), ' %') as percentage
from cte
order by gross_sales_mln desc
