
-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code, customer, average_discount_percentage

set sql_mode = ' ';

select
	dc.customer,
	dc.customer_code,
    round(avg(pre_invoice_discount_pct),4) as average_discount_percentage
from fact_pre_invoice_deductions pnv
join dim_customer dc
on dc.customer_code = pnv.customer_code
where fiscal_year = '2021' and market = 'India'
group by dc.customer_code
order by average_discount_percentage desc
limit 5;