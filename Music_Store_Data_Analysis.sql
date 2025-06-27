/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

select first_name, last_name, title, levels
from employee
order by levels desc
limit 1

/* Q2: Which countries have the most Invoices? */

select billing_country, count(invoice_id) as total_invoice
from invoice
group by billing_country
order by total_invoice desc

/* Q3: What are top 3 values of total invoice? */

select total
from invoice
order by total desc
limit 3

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city, billing_country,round(sum(total)::numeric,2) as total_invoice
from invoice
group by 1,2
order by total_invoice desc
limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select c.first_name, c.last_name, round(sum(i.total)::numeric,2) as total_spent
from customer as c
join invoice as i
on c.customer_id = i.customer_id
group by 1,2
order by 3 desc
limit 1

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select c.email, c.first_name, c.last_name
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
where track_id in (
		select t.track_id 
		from track as t
		join genre as g
		on t.genre_id = g.genre_id
		where g.name = 'Rock'
		)
group by 1,2,3
order by 1

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select a.artist_id, a.name, count(a.artist_id) as total_track
from artist as a
join album as al on a.artist_id = al.artist_id
join track as t on al.album_id = t.album_id
join genre as g on t.genre_id = g.genre_id
where g.name = 'Rock'
group by 1,2
order by 3 desc
limit 10

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name, milliseconds
from track
where milliseconds > (
		select avg(milliseconds)
		from track
)
order by milliseconds desc

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

with bsa as(
		select a.artist_id, a.name, sum(il.unit_price*il.quantity) as total_sales
		from invoice_line as il
		join track as t on il.track_id = t.track_id
		join album as al on t.album_id = al.album_id
		join artist as a on al.artist_id = a.artist_id
		group by 1
		order by 3 desc
		limit 1
)
select c.first_name, c.last_name, bsa.name, sum(il.unit_price*il.quantity) as total_spent
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
join track as t on  il.track_id = t.track_id
join album as al on t.album_id = al.album_id
join bsa on al.artist_id = bsa.artist_id
group by 1,2,3
order by 4 desc

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

with cte as(
	select i.billing_country, g.name, count(il.quantity) as total_purchases,
			row_number() over(partition by i.billing_country order by count(il.quantity) desc) as ranking
	from invoice as i
	join invoice_line as il on i.invoice_id = il.invoice_id
	join track as t on il.track_id = t.track_id
	join genre as g on t.genre_id = g.genre_id
	group by 1,2
	order by 3 desc
)
select *
from cte
where ranking <= 1
order by billing_country

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

--Method 1: using CTE
with cte as(
	select c.first_name, c.last_name, i.billing_country, sum(total) as total_spent,
		row_number() over(partition by i.billing_country order by sum(i.total) desc) as ranking
	from customer as c
	join invoice as i on c.customer_id = i.customer_id
	group by 1,2,3
	order by 3
)
select *
from cte
where ranking <=1

--Method 2: using recursive CTE

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,round(SUM(total)::numeric,2) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 1,5 DESC),

	max_spending AS(
		SELECT billing_country,round(MAX(total_spending)::numeric,2) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;