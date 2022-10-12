
-- step 1: connect between detail and header
select h.SalesOrderID,
	   h.OrderDate,
	   h.CustomerID,
	   d.ProductID,
	   D.OrderQty,
	   d.UnitPrice,
	   d.UnitPriceDiscount,
	   d.LineTotal  
from sales.SalesOrderHeader AS h
     left join Sales.SalesOrderDetail as d
	 on h.SalesOrderID=d.SalesOrderID

	 -- to see the production product table
	 select  *
	 from Production.Product
	ORDER BY PRODUCTID ASC
	 --- 
	--- step 2- add to step 1 conection production product table
select h.SalesOrderID,
	   h.OrderDate,
	   h.CustomerID,
	   d.ProductID,
	   D.OrderQty,
	   d.UnitPrice,
	   d.UnitPriceDiscount,
	   d.LineTotal,
	   p.listprice,
	   p.standardcost
from sales.SalesOrderHeader AS h
     left join Sales.SalesOrderDetail as d
	 on h.SalesOrderID=d.SalesOrderID
	 left join Production.Product as p
	 on p.productID=d.productID
--- to see customer table
select *
from Sales.Customer
-- step 3 connect to customer table
select h.SalesOrderID,
	   h.OrderDate,
	   h.CustomerID,
	   d.ProductID,
	   D.OrderQty,
	   d.UnitPrice,
	   d.UnitPriceDiscount,
	   d.LineTotal,
	   p.listprice,
	   p.standardcost,
	   c.StoreID
from sales.SalesOrderHeader AS h
     left join Sales.SalesOrderDetail as d
	 on h.SalesOrderID=d.SalesOrderID
	 left join Production.Product as p
	 on p.productID=d.productID
	 left join Sales.Customer as c
	 on c.CustomerID=h.CustomerID

-- to see proudect sub catg Table
select*
from Production.ProductSubcategory

---step 4 t connect to ProductSubcategory table
select h.SalesOrderID,
	   h.OrderDate,
	   h.CustomerID,
	   d.ProductID,
	   SubCatg.ProductSubcategoryID,
	   SubCatg.ProductCategoryID,
	   D.OrderQty,
	   d.UnitPrice,
	   d.UnitPriceDiscount,
	   d.LineTotal,
	   p.listprice,
	   p.standardcost,
	   c.StoreID
from sales.SalesOrderHeader AS h
     left join Sales.SalesOrderDetail as d
	 on h.SalesOrderID=d.SalesOrderID
	 left join Production.Product as p
	 on p.productID=d.productID
	 left join Sales.Customer as c
	 on c.CustomerID=h.CustomerID 
	 left join Production.ProductSubcategory as SubCatg
	 on SubCatg.ProductSubcategoryID=p.ProductSubcategoryID
--- step 5 making panel
select h.SalesOrderID,
	   h.OrderDate,
	   h.CustomerID,
	   d.ProductID,
	   SubCatg.ProductSubcategoryID,
	   SubCatg.ProductCategoryID,
	   D.OrderQty,
	   d.UnitPrice,
	   d.UnitPriceDiscount,
	   d.LineTotal,
	   p.listprice,
	   p.standardcost,
	   c.StoreID
	   into PanelProject
from sales.SalesOrderHeader AS h
     left join Sales.SalesOrderDetail as d
	 on h.SalesOrderID=d.SalesOrderID
	 left join Production.Product as p
	 on p.productID=d.productID
	 left join Sales.Customer as c
	 on c.CustomerID=h.CustomerID 
	 left join Production.ProductSubcategory as SubCatg
	 on SubCatg.ProductSubcategoryID=p.ProductSubcategoryID
	-- check the panel 
	select *
	from PanelProject



							--------------------------testing data -----------------------------------


--1. test if there nulls in unite price -- there no unite price nulls
	select *
	from PanelProject
	where UnitPrice  is null

--2. test if unite price= 0 -- there no unite price= zero
	select *
	from PanelProject
	where UnitPrice= 0
--3. test if the orderQtly null or =0
	select *
	from PanelProject
	where OrderQty  is null or OrderQty=0
--4. test if there standard cost is null or =0 or <0 on panel table-- we didnt find it
select *
from PanelProject
where StandardCost=0 or StandardCost is null or StandardCost <0
-----test if there standard cost is null or =0 or <0 on production product table 
select ProductID,
       StandardCost
from Production.Product
where  StandardCost=0 or StandardCost is null or StandardCost <0
group by ProductID, StandardCost
--- check how much like that-- almost 200 product without standardCost 
select count(ProductID) AS NumOfProductWithoutPrice 
from Production.Product
where  StandardCost=0 or StandardCost is null or StandardCost <0
-- how much we have diff  product in our panel table ---266
select  count( distinct ProductID) AS NumOfProduct
from PanelProject

---to see if there product without postive standard cost in sales detail table 
 select     count  ( distinct ProductID)
 from  Sales.SalesOrderDetail
 where ProductID  not in ( 
						select ProductID
						from Production.Product
						where  StandardCost=0 or StandardCost is null or StandardCost <0 )
---------
 select     ProductID
 from  Sales.SalesOrderDetail
 where ProductID   in ( 
						select ProductID
						from Production.Product
						where  StandardCost=0 or StandardCost is null or StandardCost <0 )

/*test if unite price is after or before the discount and if the discount is in % or not 
for that we choice one order and we check if the lineTotal in the table is equall
to the line table we will get if we assume differnt ones:
assume1 : the unite price already after discount- not pass
assume 2: the unite price before the discount and the discount in money ( for example 20 $)-not pass
assume3:the unite price before the discount and the discount in % ( for example 20 %)-not pass

assume 4: the unite price before the discount and the discount is decimal number ( for example 0.2)-can pass -close */

select SalesOrderID,
       sum(LineTotal)-sum (OrderQty*UnitPrice) as Assume1DiffResult,
	   sum(LineTotal)-sum (OrderQty*(UnitPrice-UnitPriceDiscount)) as Assume2DiffResult,
	   sum(LineTotal)- sum (OrderQty*(UnitPrice*((100-UnitPriceDiscount)/100))) as Assume3DiffResult,
	   sum(LineTotal)- sum (OrderQty*(UnitPrice*(1-UnitPriceDiscount))) as Assume4DiffResult
from Sales.SalesOrderDetail
where UnitPriceDiscount >0
group by SalesOrderID

-- the same test on the data panel that we made -- to see which what assume more right
--
select SalesOrderID,
       sum(LineTotal)-sum (OrderQty*UnitPrice) as Assume1DiffResult,
	   sum(LineTotal)-sum (OrderQty*(UnitPrice-UnitPriceDiscount)) as Assume2DiffResult,
	   sum(LineTotal)- sum (OrderQty*(UnitPrice*((100-UnitPriceDiscount)/100))) as Assume3DiffResult,
	   sum(LineTotal)- sum (OrderQty*(UnitPrice*(1-UnitPriceDiscount))) as Assume4DiffResult
from PanelProject
where UnitPriceDiscount >0
group by SalesOrderID

/* assume 4 pass as the most close one -the unite price before the discount and the discount is decimal numbe*/


------------------------------------CATG QUERY ----------------

/* calculation income, cost and profit per line on our panel BY CATG*/
 
 select *,
      OrderQty*(UnitPrice*(1-UnitPriceDiscount)) as LineIncome, 
	  OrderQty*StandardCost as LineCost,
	  (OrderQty*(UnitPrice*(1-UnitPriceDiscount))) -( OrderQty*StandardCost) as Lineprofit
	  into PanelProject2
 from PanelProject
 /* calculation over the years the  income, cost and profit per line on our panel
 by group by years, months and quarter */

  select year(OrderDate) as [Year],
         month(OrderDate) as [Month],
		 DATEPART(quarter,OrderDate) as [Quarter],
          sum(LineIncome) as Income,
		  sum(LineCost) as Cost ,
		  sum(Lineprofit) as Proft
 from PanelProject2
 group by year(OrderDate),
         month(OrderDate),
		 DATEPART(quarter,OrderDate)
order by [Year], [Month], [Quarter]


-------------------------------------------------DIFFERENT CATEGORIES--------------------
 /* after we validate our data, we would like to group the data of the panel per customer,seller and product. */
select  year(orderdate) as YearOfOrder,
	    sum(LineTotal) as SumOfYearlyIncome,
		sum(linecost) as YearlyCost,
		sum(lineprofit) as YearlyProfit
from PanelProject2
group by  year(orderdate)
order by  SumOfYearlyIncome , year(OrderDate) asc
--1. show the data by quarter:
select  year(orderdate) as YearOfIncome,
		DATEPART(quarter,OrderDate) as  quarterOf,
	    sum(LineTotal) as Income,
		sum(linecost) as Cost,
		sum(lineprofit) as Profit,
		rank() over(partition by year(orderdate) order by sum(lineprofit) desc) as Ranking
from PanelProject2
group by  DATEPART(quarter,OrderDate), year(orderdate)
order by  YearOfIncome asc, DATEPART(quarter,OrderDate) asc
--2.show the data by months: 
select  year(orderdate) as YearOfIncome,
		month(OrderDate) as  MonthOfIncome,
	    sum(LineTotal) as Income,
		sum(linecost) as Cost,
		sum(lineprofit) as Profit,
		rank() over(partition by year(orderdate) order by sum(lineprofit) desc) as Ranking
from PanelProject2
group by  month(OrderDate), year(orderdate)
order by  YearOfIncome asc, month(OrderDate) asc
--3.show the data by the day of the week:
declare @pYearOfOrder int = 2014
select  datename(weekday,OrderDate) as  dayOfWeekis,
	    sum(LineTotal) as Income,
		sum(linecost) as Cost,
		sum(lineprofit) as Profit
from PanelProject2
where year(orderdate) = @pYearOfOrder
group by   datename(weekday,OrderDate)
order by   dayOfWeekis asc
--4. show the data by discount per item of all times:
select  year(x.orderdate) as YearOfOrder,
	         x.ProductID,
		     p.[Name],
sum(UnitPrice* UnitPriceDiscount *OrderQty)/ sum (OrderQty) as avg_discountPerItem,
sum(x.linecost) as YearlyCost,
		sum(x.lineprofit) as YearlyIncome,
		rank() over(partition by x.productid order by sum(x.lineprofit) desc) as Ranking
from PanelProject2 as x
left join Production.Product as p
on p.ProductID = x.ProductID
group by  year(x.orderdate),x.ProductID,p.[Name]
order by   year(x.OrderDate) asc
--check March & April 2021 specificly:
select  year(x.orderdate) as YearOfOrder,
	         x.ProductID,
		     p.[Name],
sum(UnitPrice* UnitPriceDiscount *OrderQty)/ sum (OrderQty) as avg_discountPerItem,
sum(x.linecost) as YearlyCost,
		sum(x.lineprofit) as YearlyIncome,
		rank() over(partition by x.productid order by sum(x.lineprofit) desc) as Ranking
from PanelProject2 as x
left join Production.Product as p
on p.ProductID = x.ProductID
where year(x.orderdate) = 2012 and month(x.orderdate) between 3 and 4
group by  year(x.orderdate),x.ProductID,p.[Name]
order by   year(x.OrderDate) asc
--5. show the data by storeid per year:?????????????????
select  year(orderdate) as YearOfOrder,
		month(orderdate) as MonthOfOrder,
	    StoreID,
		sum(orderqty) as AmountOfProducts,
		sum(unitpricediscount) DiscountPerProduct,
		sum(linecost) as YearlyCost,
		sum(lineprofit) as YearlyIncome,
		rank() over(partition by productid order by sum(lineprofit) desc) as Ranking
from PanelProject2
group by  year(orderdate),month(orderdate),StoreID
order by   year(OrderDate) asc, month(orderdate)asc
-- 6. productsSubs?????????????????????
select   year(orderdate) YearOfOrder,
		 month(orderdate)MonthOfOrder,
		x.ProductCategoryID,
		s.[Name],
		sum(x.orderqty) as AmountOfProducts,
		sum(x.linecost) as YearlyCost,
		sum(x.lineprofit) as YearlyIncome
from PanelProject2 as x
left join Production.ProductSubcategory as s
on x.ProductCategoryID = s.ProductSubcategoryID
group by   year(orderdate),month(orderdate),x.ProductCategoryID, s.[Name]
order by  YearOfOrder asc, MonthOfOrder asc 




			-----------------------------Profit and loss analysis NEDAA---------------------------------


/* to see how the products was profit or not to the company 
by seeing every year how each product give sum profit , avg profit to unite , 
sum qty of sells, and avg cost for unite , avg discount and more */
  select year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProft,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost 
 from PanelProject2
 group by year(OrderDate),
         ProductID
order by [Year], ProductID
/*now let see on each year what the most 10 product that have the highest profit percent from total 
profit of that year */

--------------------------------------2011------------------------------------------ 
  select top 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2011)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2011
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit desc

  -- cheack query of percent 
  select top 10  sum(PercentOfYearlyProfit )
  from(  select year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2011)*100 as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2011
 group by year(OrderDate), ProductID
)  as m
---to check if there products that make negative profit and take top 10 
  select   top 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2011)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2011 
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit  asc


--------------------------------------2012------------------------------------------ 
  select  TOP 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2012)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2012
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit desc

  -- cheack query of percent 
  select sum(PercentOfYearlyProfit )
  from(  select year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2012) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2012
 group by year(OrderDate), ProductID
)  as d
---to check if there products that make negative profit and take top 10 
 select   top 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2012)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2012
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit  asc

--------------------------------------2013------------------------------------------ 
  select TOP 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2013)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2013
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit desc

  -- cheack query of percent 
  select sum(PercentOfYearlyProfit )
  from(  select year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2013) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2013
 group by year(OrderDate), ProductID
)  as d
---to check if there products that make negative profit and take top 10 
 select   top 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2013)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2013
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit  asc	
    --------------------------------------2014------------------------------------------ 
  select TOP 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2014)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2014
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit desc

  -- cheack query of percent 
  select sum(PercentOfYearlyProfit )
  from(  select year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProft,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2014) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2014
 group by year(OrderDate), ProductID
)  as d


---to check if there products that make negative profit and take top 10 
 select   top 10 year(OrderDate) as [Year],
          ProductID,
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost,
		  (sum(Lineprofit)/ (select sum(Lineprofit) from PanelProject2 where year(OrderDate)= 2014)) as PercentOfYearlyProfit
 from PanelProject2
 where year(OrderDate)= 2014
 group by year(OrderDate), ProductID
  order by PercentOfYearlyProfit  asc	
  
---------------------------CHEECK ALL YEARS  PROFIT LOSES ACTING----------- 
-- WITHOUT LOOKING INTO PRODUCT DIFF WE WANT TO SEE HOW THE COMPANY EFFICIENCY TO INCREASE PROFIT 
-- BY LOOKING HOW EFFICIENCY  IT GET WITH PROFIT LOSES
 select    year(OrderDate) as [Year],
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost
 from PanelProject2
 where Lineprofit<=0
 group by year(OrderDate)
  order by year(OrderDate)  asc

  -- WITHOUT LOOKING INTO PRODUCT DIFF WE WANT TO SEE HOW THE COMPANY EFFICIENCY TO INCREASE PROFIT 
-- BY LOOKING HOW EFFICIENCY  IT GET WITH POSTIVE  PROFIT 

 select    year(OrderDate) as [Year],
		  sum (OrderQty) as SumYearlyQty,
          sum(LineIncome) as SumIncome,
		  sum(LineCost) as SumCost ,
		  sum(Lineprofit) as SumProfit,
		  sum(UnitPrice*OrderQty)/sum(OrderQty) as AvgPriceBeforeDiscount,
		  sum (UnitPrice*UnitPriceDiscount*OrderQty)/sum(OrderQty) as Avgdiscount,
		   sum (LineIncome)/sum(OrderQty) as AvgIncome,
		  sum (Lineprofit)/sum(OrderQty) as AvgProfit,
		  sum (StandardCost*OrderQty)/sum(OrderQty) as AvgCost
 from PanelProject2
 where Lineprofit>=0
 group by year(OrderDate)
  order by year(OrderDate)  asc



  			-----------------------------Profit and loss analysis -ROEY ---------------------------------


---roey's analysis on why 2012: why Marcxh & April 2012 were the worst on profit? and why there was a pick of profit on July-August 2013? 
--1. lets have a look on the top 5 ProductID per Profit in each month:
declare @pYearOfOrder int = 2012
select x.*
from (select  year(d.orderdate) as YearOfOrder,
		month(d.orderdate) as MonthOfOrder,
		      d.ProductID,
			  p.Name,
		sum(d.orderqty) as AmountOrdered,
		sum(d.lineprofit) as ProfitPerProduct,
		avg(d.unitprice) as UnitPrice,
		rank() over ( partition by month(d.orderdate) order by sum(d.lineprofit) )  as MonthyProfit
from dbo.PanelProject2 as d
left join Production.Product as p
on p.ProductID = d.ProductID
where year(d.orderdate) = @pYearOfOrder
group by year(d.orderdate), month(orderdate), d.ProductID, p.Name
) as x
where x.MonthyProfit < 5
order by YearOfOrder, MonthOfOrder asc 

--find correlation between Mountian 100 Amount of Orders and the total Profit :
--didn't find any coorelation...
select year(d.orderdate) as YearOf,
	   month(d.orderdate) as MonthOf,
       sum(d.orderqty) As OrderQTY
from dbo.PanelProject2 as d
left join Production.Product as p
on p.ProductID = d.ProductID 
where p.[name] like 'Road-650 Red%'
group by year(d.orderdate),
	   month(d.orderdate)
order by year(d.orderdate),
	   month(d.orderdate) asc
 --look for a product category that the quantity sold changed:
 --didn't find any coorelation...
 select year(p.orderdate) as YearOf,
	   month(p.orderdate) as MonthOf, 
	   case
	   when  c.[Name] = 'Components' then sum(p.orderqty) else '-' end as Components,
	    case
	   when  c.[Name] = 'Clothing' then sum(p.orderqty)   else '-' end as Clothing,
	    case 
	   when  c.[Name] = 'Bikes' then sum(p.orderqty) else '-' end as Bikes,  
	    case
		when c.[Name] = 'Accessories' then sum(p.orderqty) else  '-' end as Accessories
 from Production.ProductCategory as c
 join PanelProject2 as p
 on p.ProductCategoryID = c.ProductCategoryID
 group by year(p.orderdate), month(p.orderdate),c.[Name]
order by year(p.orderdate),
	   month(p.orderdate) asc
	--Next, Lets see If theres was coorelation bewtwen most profitable customerid and change in the profit 
 declare @pYearOfOrder int = 2012
select d.*
from (select  year(d.orderdate) as YearOfOrder,
		month(d.orderdate) as MonthOfOrder,
		      d.CustomerID,
			  p.Name,
		sum(d.orderqty) as AmountOrdered,
		sum(d.lineprofit) as ProfitPerProduct,
		avg(d.unitprice) as UnitPrice,
		rank() over ( partition by month(d.orderdate) order by sum(d.lineprofit) )  as MonthyProfit
from dbo.PanelProject2 as d
left join Production.Product as p
on p.ProductID = d.ProductID
where year(d.orderdate) = @pYearOfOrder
group by year(d.orderdate), month(orderdate), d.ProductID, p.Name
) as x
where x.MonthyProfit < 5
order by YearOfOrder, MonthOfOrder asc 

