-- ===================================================
-- Northwind E-commerce Data Analysis
-- ===================================================
-- Categorical Analysis
-- ===================================================
--1.Revenue by Product Category
select c.categoryid ,
		c.categoryname ,
		ROUND(
				SUM((od."Quantity" * od."UnitPrice") *(1-od."Discount"))::numeric, 2
			) as revenue
	from "NorthWind"."order_details" od 
	inner JOIN "NorthWind"."products" p
	on od."ProductID"  = p."ProductID"
	inner join "NorthWind"."Categories" c 
	on p."CategoryID" =c.categoryid 
	group by c.categoryid ,
		c.categoryname;

--2.Find the top 5 categories by revenue.
select * from 
(
select t2.categoryid as category_id ,
		SUM(t3."Quantity" * t3."UnitPrice") as revenue
	from (select p."ProductID", p."CategoryID" from "NorthWind".products p) as t1
	inner join (select c."categoryid" from "NorthWind"."Categories" c ) as t2
	on t1."CategoryID"=t2."categoryid"
	inner join (select od."ProductID" ,od."Quantity",od."UnitPrice"  from "NorthWind".order_details od) as t3
	on t1."ProductID"=t3."ProductID"
	group by t2.categoryid
	order by revenue desc
	limit 5) a 
inner join "NorthWind"."Categories" c on a.category_id = c.categoryid ;

-- ===================================================
-- Customer Analysis
-- ===================================================
--3.Calculate the average order value for each customer.
select c."CustomerID" ,
		c."ContactName",
		SUM(od."UnitPrice" *od."Quantity" ) as total_sales,
		COUNT(distinct o."OrderID"),
		SUM(od."UnitPrice" *od."Quantity" )/COUNT(distinct o."OrderID") as AOV
		
	from  "NorthWind".order_details od 
	inner join "NorthWind".orders o 
	on o."OrderID" =od."OrderID" 
	inner join "NorthWind".customers c
	on c."CustomerID" =o."CustomerID" 
	group by c."CustomerID",c."ContactName"
	order by c."CustomerID";

--4.Top 10 High-Value Customers
select c."CustomerID" ,
		c."ContactName" ,
		ROUND(
				SUM((od."Quantity" * od."UnitPrice") *(1-od."Discount"))::numeric, 2
			) as value
	from "NorthWind".order_details od 
	inner join "NorthWind".orders o
	on od."OrderID" = o."OrderID" 
	inner join "NorthWind".customers c 
	on o."CustomerID" =c."CustomerID" 
	group by c."CustomerID" ,
		c."ContactName"
	order by value desc 
	limit 10;

--5.Find customers who have placed more than 10 orders.
select c."CustomerID" ,
		c."ContactName" ,
		COUNT(distinct o."OrderID" ) as order_count
	from "NorthWind".customers c 
	inner join "NorthWind".orders o 
	on c."CustomerID" = o."CustomerID" 
	group by c."CustomerID" ,c."ContactName" 
	having COUNT(distinct o."OrderID" )>10;

--6.Find customers who have not placed any orders in the last 6 months of available data.
select c."CustomerID",
		(select MAX(TO_DATE(o."OrderDate" ,'YYYY-MM-DD')) from "NorthWind".orders o) - MAX(TO_DATE(o."OrderDate",'YYYY-mm-dd')) as order_gap
  from "NorthWind".customers c 
  inner join "NorthWind".orders o 
  on c."CustomerID" =o."CustomerID" 
  group by c."CustomerID"
  having (select MAX(TO_DATE(o."OrderDate" ,'YYYY-MM-DD')) from "NorthWind".orders o) - MAX(TO_DATE(o."OrderDate",'YYYY-mm-dd')) >= 180 ;

select "CustomerID", lastest_order_date, max_order_date, 
EXTRACT(months FROM AGE(lastest_order_date, max_order_date)) AS years_diff
from
(
select c."CustomerID", MAX(TO_DATE(o."OrderDate" ,'YYYY-MM-DD')) lastest_order_date,
		(select MAX(TO_DATE(o."OrderDate" ,'YYYY-MM-DD')) from orders o) max_order_date
		
  from customers c 
  inner join orders o 
  on c."CustomerID" =o."CustomerID" 
  group by c."CustomerID"
  )
  where EXTRACT(months FROM AGE(lastest_order_date, max_order_date))<=-6;
  
 --7.Find customers whose total spending is above the average customer spending
with customer_spending as 
	(
		select c."CustomerID" ,
				SUM(od."Quantity" *od."UnitPrice" ) as total_spend
			from customers c 
			inner join orders o
			on c."CustomerID" =o."CustomerID" 
			inner join order_details od 
			on o."OrderID" =od."OrderID" 
			group by c."CustomerID" 
	)
select * 
	from customer_spending 
	where total_spend > 
	(select SUM(od."Quantity" * od."UnitPrice" )/COUNT(distinct o."CustomerID") 
		FROM orders o inner join order_details od on o."OrderID"=od."OrderID"); 
 
 --8.Calculate each customer's lifetime value (CLV).
select c."CustomerID" ,
		SUM(od."Quantity" *od."UnitPrice" ) as CLV
	from customers c 
	left outer join orders o 
	on c."CustomerID" = o."CustomerID"
	left outer join order_details od 
	on o."OrderID" =od."OrderID" 
	group by c."CustomerID" ;
 
 --9.Customer who didnot place order
select c."CustomerID" from customers c where c."CustomerID" not IN (select distinct o."CustomerID" from orders o);

--10.Find customers who purchased products from more than 3 different categories.
select c."CustomerID" ,
		COUNT(distinct p."CategoryID" ) as categorical_count
	from customers c
	inner join orders o 
	on c."CustomerID" = o."CustomerID" 
	inner join order_details od  
	on od."OrderID" =o."OrderID" 
	join products p 
	on p."ProductID" = od."ProductID"
	group by c."CustomerID" 
	having COUNT(distinct p."CategoryID" ) >3;

--11.Identify repeat customers who ordered in multiple years.
select c."CustomerID" ,
		count(distinct extract(year from TO_DATE(o."OrderDate",'YYYY-mm-dd'))) as year_count
	from customers c 
	inner join orders o 
	on c."CustomerID" =o."CustomerID" 
	group by c."CustomerID"
	having count(distinct extract(year from TO_DATE(o."OrderDate",'YYYY-mm-dd'))) > 1;

--12.Find customers responsible for the top 80% of revenue (Pareto Analysis).

with customer_revenue as 
(
select c."CustomerID" ,
		SUM(od."Quantity" *od."UnitPrice" ) as revenue
	from customers c 
	inner join orders o 
	on c."CustomerID" =o."CustomerID" 
	inner join order_details od
	on o."OrderID" =od."OrderID"
	group by c."CustomerID"
)
,
total_revenue as
(
select SUM(od."UnitPrice" * od."Quantity" ) as total
	from order_details od 
)
,
individual_contribution as 
(
select *,
	   SUM(cr.revenue*100/tr.total ) oVER(order by cr.revenue DESC) as individual_contribution
	from customer_revenue cr
	cross join total_revenue tr
)
select *
	from individual_contribution ic
	where ic.individual_contribution <=80
;

-- ===================================================
-- Product Analysis
-- ===================================================
--13.Find products that have never been ordered
select p."ProductID" ,p."ProductName" 
	from products p 
	where p."ProductID" not in 
	(select distinct od."ProductID" from order_details od );

--14.Find the top-selling products(10) based on quantity sold.
select p."ProductID" , 
		p."ProductName" ,
		p."CategoryID",
		SUM(od."Quantity") as quantity_sold
	from "NorthWind".products p inner join "NorthWind".order_details od 
	on p."ProductID" =od."ProductID" 
	group by p."ProductID",p."ProductName",p."CategoryID"  
	order by quantity_sold desc
	limit 10;

--15.Find the top-selling product in each category
with categorical_rank as 
(
	select 	p."CategoryID",
		p."ProductID",
		p."ProductName" ,
		SUM(od."Quantity" *od."UnitPrice" ) as revenue,
		DENSE_RANK() OVER(partition by p."CategoryID" order by SUM(od."Quantity" *od."UnitPrice" ) DESC) as rnk
	from products p
	inner join order_details od  
	on p."ProductID" = od."ProductID"
	group by p."CategoryID" ,p."ProductID",p."ProductName"
)
select cr."CategoryID" ,
		cr."ProductID" ,
		cr."ProductName" ,
		cr.revenue 
	from categorical_rank as cr
	where cr.rnk =1;

--16.Find products whose sales revenue is below the average revenue of their category.
with categorical_average as
(
	select c.categoryid ,
			AVG(od."UnitPrice" *od."Quantity" ) as avg
	from "Categories" c 
	inner join products p
	on c."categoryid" = p."CategoryID" 
	inner join order_details od 
	on od."ProductID" =p."ProductID"
	group by c.categoryid 
	
)
,
product_revenue as
(
	select p."ProductID" ,
		p."ProductName" ,
		p."CategoryID",
		SUM(od."UnitPrice" * od."Quantity" ) as revenue
	from products p 
	inner join order_details od 
	on p."ProductID" = od."ProductID" 
	inner join categorical_average as ca
	on ca."categoryid" = p."CategoryID" 
	group by p."ProductID" , p."ProductName" ,p."CategoryID"
)
select pr."ProductID",
		pr."ProductName",
		pr."revenue"
	from categorical_average ca
	inner join product_revenue pr
	on ca."categoryid" = pr."CategoryID"
	where pr.revenue < ca.avg
;
	
--17.Rank products within each category based on revenue
select  p."CategoryID",
		p."ProductID" ,
		p."ProductName" ,
		SUM(od."UnitPrice" * od."Quantity") as revenue,
		DENSE_RANK() OVER(partition by p."CategoryID" order by SUM(od."UnitPrice" * od."Quantity") DESC) as rnk
	from products p 
	left outer join order_details od 
	on p."ProductID" =od."ProductID" 
	group by p."CategoryID",
		p."ProductID" ,
		p."ProductName";

--18.Find products that generated revenue in every year available in the dataset.
with yearly_product_revenue as
(
	select od."ProductID" ,
		EXTRACT(year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as year,
		SUM(od."Quantity" *od."UnitPrice" )
	from order_details od 
	inner join orders o
	on od."OrderID" =o."OrderID" 
	group by od."ProductID",year
	order by od."ProductID",year
)
select ypr."ProductID",
		p."ProductName",
		COUNT(ypr."ProductID") as no_of_years
	from yearly_product_revenue as ypr
	inner join products p
	on ypr."ProductID" =p."ProductID"
	group by ypr."ProductID",p."ProductName" 
	having COUNT(ypr."ProductID") = (select COUNT(distinct extract (year from TO_DATE(o."OrderDate",'YYYY-mm-dd'))) from orders o)
;

--19.Find products with declining sales compared to the previous year.
with yearly_revenue as
(
select  EXTRACT(year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as year,
		p."ProductID" ,
		p."ProductName" ,
		SUM(od."Quantity" * od."UnitPrice" ) as revenue
	from orders o
	inner join order_details od 
	on o."OrderID" = od."OrderID" 
	inner join products p
	on p."ProductID" = od."ProductID" 
	group by year,p."ProductID" ,
		p."ProductName"
),
compared_table as
(
select yr."ProductID" ,
		yr."ProductName" ,
		yr."year" ,
		yr.revenue ,
		LAG(yr."revenue") OVER(partition by yr."ProductID",yr."ProductName" order by yr."year" ASC) as prev_revenue
		from yearly_revenue as yr
)
select distinct "ProductID" ,
		"ProductName" 
	from compared_table 
where revenue < prev_revenue;

-- ===================================================
-- Employee Analysis
-- ===================================================
--20.Calculate total revenue generated by each employee.
select e."EmployeeID" , 
		CONCAt( e."FirstName",' ', e."LastName") as full_name,
		SUM(od."Quantity"* od."UnitPrice") as revenue
	from employees e 
	inner join orders o
	on e."EmployeeID" =o."EmployeeID" 
	inner join order_details od
	on od."OrderID" = o."OrderID" 
	group by e."EmployeeID" , 
		CONCAt( e."FirstName",' ', e."LastName");


--21.Find the employee who handled the most orders.
select e."EmployeeID" ,
		e."FirstName" ||' '||e."LastName" as full_name,
		COUNT(distinct o."OrderID") as order_count
	from employees e 
	inner join orders o
	on e."EmployeeID" =o."EmployeeID"
	group by e."EmployeeID" ,
		e."FirstName" ||' '||e."LastName"
order by order_count desc
limit 1;

--22.Rank employees by revenue using a window function.

with employee_revenue as 
(
select e."EmployeeID" ,
		e."FirstName" ||' '||e."LastName" as full_name,
		COUNT(distinct o."OrderID") as order_count
	from employees e 
	inner join orders o
	on e."EmployeeID" =o."EmployeeID"
	group by e."EmployeeID" ,
		e."FirstName" ||' '||e."LastName"
)
select er."EmployeeID",
		er.full_name,
		RANK() OVER(order by er.order_count DESC) as rnk
	from employee_revenue as er;

--23.Find the average order value handled by each employee.
select e."EmployeeID" ,
		e."FirstName"||' '||e."LastName" as full_name,
		SUM(od."UnitPrice" *od."Quantity" )/COUNT(distinct od."OrderID" ) as average_order_value
	from employees e 
	inner join orders o
	on e."EmployeeID" = o."EmployeeID" 
	inner join order_details od
	on o."OrderID" = od."OrderID" 
	group by e."EmployeeID" ,
		e."FirstName"||' '||e."LastName";

-- ===================================================
-- Orders Analysis
-- ===================================================
--24.Find the highest revenue-generating order.
select od."OrderID" ,
		SUM(od."UnitPrice" *od."Quantity" ) as revenue
	from "NorthWind".order_details od 
	group by od."OrderID" 
	order by revenue desc;

--25.Find orders whose total value is greater than the average order value.
with order_value as 
(
	select o."OrderID" ,
		SUM(od."Quantity" *od."UnitPrice" ) as order_value
	from orders o 
	inner join order_details od 
	on o."OrderID" = od."OrderID" 
	group by o."OrderID" 
)
select * from order_value as ov 
		where ov.order_value > (select SUM(od."UnitPrice" *od."Quantity" )/COUNT(distinct od."OrderID" ) from order_details od); 

with order_value as 
(
	select o."OrderID" ,
		SUM(od."Quantity" *od."UnitPrice" ) as order_value
	from orders o 
	inner join order_details od 
	on o."OrderID" = od."OrderID" 
	group by o."OrderID" 
),
average_value as 
(
	select SUM(od."UnitPrice" *od."Quantity" )/COUNT(distinct od."OrderID" ) as avg_value from order_details od
)
select ov."OrderID" , ov.order_value 
from order_value ov
cross join average_value av
where ov.order_value > av.avg_value ;

--26.Find the top 3 highest-value orders for every year.
with ranked as 
(
select EXTRAct(year from to_date(o."OrderDate",'YYYY-mm-dd')) as year,
		o."OrderID",
		SUM(od."UnitPrice"*od."Quantity") as revenue,
		DENSE_RANK() OVER(partition by EXTRAct(year from to_date(o."OrderDate",'YYYY-mm-dd')) order by SUM(od."UnitPrice"*od."Quantity") DESC) as drnk
	from orders o 
	inner join order_details od 
	on o."OrderID" =od."OrderID" 
	group by year, o."OrderID"
)
select * from ranked where drnk<=3;

-- ===================================================
-- Business Performance Analysis
-- ===================================================
--27..Monthly Sales Trends:
select EXTRACT(year from TO_DATE(o."OrderDate" ,'YYYY-MM-DD')) as year,
		EXTRACT(month from TO_DATE(o."OrderDate" ,'YYYY-MM-DD')) as month,
		ROUND(
				SUM((od."Quantity" * od."UnitPrice") *(1-od."Discount"))::numeric, 2
			) as Sales
	from "NorthWind".order_details od
	inner join "NorthWind".orders o
	on od."OrderID" = o."OrderID" 
	group by year,month
	order by year,month;

--28.Calculate the running total of monthly sales revenue using window functions
with monthly_grouped as
(
select EXTRACT(year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as year,
		TO_cHar(To_Date(o."OrderDate",'YYYY-mm-dd'),'MM') as month,
		SUM(od."UnitPrice"*od."Quantity") as revenue
	from orders o
	inner join order_details od
	on o."OrderID" =od."OrderID" 
	group by year,month
)
select year,
		month,
		SUM(revenue) OVER(partition by year order by month ) as running_total_revenue
	from monthly_grouped;


--29.Find the percentage contribution of each category to total sales.
with each_category as
(
select p."CategoryID" ,
		SUM(od."Quantity"*od."UnitPrice" ) as categorical_revenue
		from order_details od
	inner join products p 
	on p."ProductID" = od."ProductID" 
	group by p."CategoryID"
),
total_sales as
(
select SUM(od."UnitPrice"*od."Quantity") as total_sales from order_details od
)
select ec."CategoryID",
		ec."categorical_revenue",
		ec."categorical_revenue" *100/ts."total_sales"
	from each_category ec
	cross join total_sales ts
;

--30.Identify the month with the highest sales for each year.
with orderly_revenue as 
(
select EXTRACT(year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as year,
		EXTRACT(month from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as month,
		SUM(od."UnitPrice"*od."Quantity") as revenue
	from orders o 
	inner join order_details od 
	on o."OrderID" =od."OrderID" 
	group by year,month
)
,
ranked as
(
select year,
		month,
		revenue,
		DENSE_RANK() OVER(partition by year order by revenue DESC) as drnk
		from orderly_revenue
)
select year,
		month,
		revenue
	from ranked
	where drnk=1
;

--31.Calculate month-over-month sales growth.
with monthly_revenue as 
(
select extract (year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as year,
	extract (month from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as month,
	SUM(od."UnitPrice"*od."Quantity") as monthly_revenue
	from orders o
	inner join order_details od 
	on o."OrderID" =od."OrderID" 
	group by year,month
)
select year,
month,
monthly_revenue,
LAG(monthly_revenue) OVER(order by year,month ASC) as prev_month_revenue,
monthly_revenue-LAG(monthly_revenue) OVER(order by year,month ASC) as monthly_growth
from monthly_revenue
;

--32.Show the year-over-year sales growth.
with year_sales as 
(
select EXTRACT(year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) as year,
		SUM(od."Quantity"*od."UnitPrice") as sales,
		LAG(SUM(od."Quantity"*od."UnitPrice")) OVER(order by EXTRACT(year from TO_DATE(o."OrderDate",'YYYY-mm-dd')) ASC) as prev_year_sales
	from "NorthWind".orders o 
	inner join "NorthWind".order_details od 
	on o."OrderID" =od."OrderID" 
	group by year
)
select year,
		sales,
	     ((sales-prev_year_sales)/prev_year_sales)*100.0 as growth_percentage
 		from year_sales;
