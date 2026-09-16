-- ===================================================
-- Northwind E-commerce Data Analysis
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

--2.Top 10 High-Value Customers
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

--3.Monthly Sales Trends:
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