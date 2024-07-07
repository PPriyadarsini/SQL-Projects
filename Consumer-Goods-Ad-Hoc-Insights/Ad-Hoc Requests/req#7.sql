
-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month, Year, Gross sales Amount

set sql_mode = ' ';

select 
	date_format(s.date, '%b') as month,
    s.fiscal_year as year,
    concat(round(sum(gp.gross_price * s.sold_quantity)/1000000,2), ' M') as gross_sales_amount
from fact_gross_price gp
join fact_sales_monthly s
on 
	gp.product_code = s.product_code and
    gp.fiscal_year = s.fiscal_year
join dim_customer dc
on dc.customer_code = s.customer_code
where customer = 'Atliq Exclusive'
group by month, year;