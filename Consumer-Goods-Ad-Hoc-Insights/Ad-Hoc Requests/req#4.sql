
-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference

with cte1 as (
	select 
		dp.segment,
        count(distinct fsm.product_code) as product_count_2020
    from fact_sales_monthly fsm
    join dim_product dp
    on dp.product_code = fsm.product_code
    where fiscal_year = '2020'
    group by dp.segment
),

cte2 as (
	select 
		dp.segment,
        count(distinct fsm.product_code) as product_count_2021
    from fact_sales_monthly fsm
    join dim_product dp
    on dp.product_code = fsm.product_code
    where fiscal_year = '2021'	
    group by dp.segment
)

select 
	cte1.segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) as difference
from cte1
join cte2
on cte1.segment = cte2.segment
order by difference desc;

