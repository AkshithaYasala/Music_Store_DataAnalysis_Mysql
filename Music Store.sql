CREATE DATABASE MUSICSTORE;
USE MUSICSTORE;
CREATE TABLE genre(
genre_id INT PRIMARY KEY,
name varchar(120)
);

SELECT * FROM genre LIMIT 3;

CREATE TABLE media_type(
media_type_id INT PRIMARY KEY,
name varchar(120)
);

CREATE TABLE employee(
employee_id INT PRIMARY KEY,
last_name varchar(20),
first_name varchar(20),
title varchar(60),
reports_to int,
levels varchar(5),
birthdate DATE,
hire_date DATE,
address varchar(300),
city varchar(100),
state varchar(100),
country varchar(30),
postal_code varchar(20),
phone varchar(30),
fax varchar(30),
email varchar(50)
);


CREATE TABLE customer(
customer_id INT PRIMARY KEY,
first_name varchar(50),
last_name varchar(50),
company varchar(100),
address varchar(150),
city varchar(40),
state varchar(10),
country varchar(30),
postal_code varchar(100),
phone varchar(30),
fax varchar(30),
email varchar(50),
support_rep_id int 
);

ALTER TABLE customer ADD CONSTRAINT FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id);

CREATE TABLE artist(
artist_id int PRIMARY KEY,
name varchar(100)
);
SELECT * FROM artist;

CREATE TABLE album(
album_id INT PRIMARY KEY,
title varchar(160),
artist_id INT,
FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
);

SELECT * FROM album LIMIT 5;

CREATE TABLE track(
track_id INT PRIMARY KEY,
name varchar(120),
album_id INT,
media_type_id INT,
genre_id INT,
composer varchar(220),
milliseconds int,
bytes int,
unit_price DECIMAL(10,2),
FOREIGN KEY (album_id) REFERENCES album(album_id),
FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id),
FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);

SELECT * FROM track;

ALTER TABLE track MODIFY name VARCHAR(255);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE  'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/track.csv'
INTO TABLE  track
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price);

SELECT * FROM track LIMIT 5;

CREATE TABLE invoice(
invoice_id INT PRIMARY KEY,
customer_id INT,
invoice_date DATE,
billing_address varchar(300),
billing_city varchar(100),
billing_state varchar(100),
billing_country varchar(100),
billing_postal_code varchar(20),
total DECIMAL(10,2),
FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

SELECT * FROM invoice LIMIT 5;

CREATE TABLE invoice_line(
invoice_line_id INT PRIMARY KEY,
invoice_id INT,
track_id INT,
unit_price DECIMAL(10,2),
quantity int,
FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id),
FOREIGN KEY (track_id) REFERENCES track(track_id)
);


CREATE TABLE playlist(
playlist_id INT PRIMARY KEY,
name varchar(100)
);

CREATE TABLE playlist_track(
playlist_id INT,
track_id INT,
PRIMARY KEY (playlist_id,track_id),
FOREIGN KEY (playlist_id) REFERENCES playlist(playlist_id),
FOREIGN KEY(track_id) REFERENCES track(track_id)
);

-- Queries
-- 1. Who is the senior most employee based on job title?  

SELECT employee_id,
CONCAT(first_name,' ' ,last_name) as employee_name,
title,levels 
FROM employee 
ORDER BY levels DESC
LIMIT 1;

-- 2. Which countries have the most Invoices? 

SELECT billing_country,
COUNT(invoice_id) as total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices desc;

-- 3. What are the top 3 values of total invoice? 

SELECT DISTINCT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4. Which city has the best customers? - We would like to throw a promotional Music Festival in 
-- the city we made the most money. Write a query that returns one city that has the highest sum of 
-- invoice totals. Return both the city name & sum of all invoice totals 

SELECT billing_city,sum(total) as invoice_totals
FROM invoice
GROUP BY billing_city
ORDER BY invoice_totals DESC
LIMIT 1;



-- 5. Who is the best customer? - The customer who has spent the most money will be declared 
-- the best customer. Write a query that returns the person who has spent the most money 

SELECT c.customer_id,CONCAT(c.first_name, ' ', c.last_name) AS customer_name,ROUND(SUM(i.total), 2) AS total_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;


-- 6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A

SELECT c.first_name,c.last_name,c.email,g.name as genre 
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line i1
ON i.invoice_id = i1.invoice_id
JOIN track t
ON i1.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = "Rock"
GROUP  BY c.customer_id,g.genre_id
ORDER BY email ASC;
desc customer;
desc invoice;

-- 7. Let's invite the artists who have written the most rock music in our dataset. Write a query that 
-- returns the Artist name and total track count of the top 10 rock bands 

WITH  rock_artist as (
SELECT ar.name as artist_name,
COUNT(track_id) AS total_track
FROM artist ar
JOIN album al
ON ar.artist_id = al.artist_id
JOIN track t
ON al.album_id = t.album_id
JOIN genre g
 ON t.genre_id = g.genre_id
 WHERE g.name = "Rock"
 GROUP BY ar.artist_id,ar.name
)
SELECT * FROM rock_artist
ORDER BY total_track DESC
LIMIT 10;

-- 8. Return all the track names that have a song length longer than the average song length.- 
-- Return the Name and Milliseconds for each track. Order by the song length, with the longest 
-- songs listed first 

SELECT name,milliseconds 
FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- 9. Find how much amount is spent by each customer on artists? Write a query to return 
-- customer name, artist name and total spent 

SELECT CONCAT(c.first_name,' ',c.last_name) as customer_name, ar.name as artist_name,SUM(i1.unit_price * i1.quantity) as total_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line i1
ON i.invoice_id = i1.invoice_id
JOIN track t
ON i1.track_id = t.track_id
JOIN album al
ON t.album_id = al.album_id
JOIN artist ar
ON al.artist_id = ar.artist_id
GROUP BY 
c.customer_id,c.first_name,c.last_name,ar.artist_id,ar.name
ORDER BY total_spent DESC;

-- 10. We want to find out the most popular music Genre for each country. We determine the most 
-- popular genre as the genre with the highest amount of purchases. Write a query that returns 
-- each country along with the top Genre. For countries where the maximum number of purchases 
-- is shared, return all Genres 

WITH genre_purchases AS(
SELECT i.billing_country as country,
g.name as genre,
COUNT(i1.invoice_line_id) AS total_purchases
FROM invoice i
JOIN invoice_line i1
ON i.invoice_id = i1.invoice_id
JOIN track  t
ON i1.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
GROUP BY i.billing_country,g.name
),
ranked_genres AS (
SELECT country,
genre,
total_purchases,
DENSE_RANK() OVER (
PARTITION BY country
ORDER BY total_purchases DESC) AS genre_rank
FROM genre_purchases
)
SELECT country,genre,total_purchases
FROM ranked_genres
WHERE genre_rank = 1
ORDER BY country;

-- 11. Write a query that determines the customer that has spent the most on music for each 
-- country. Write a query that returns the country along with the top customer and how much they 
-- spent. For countries where the top amount spent is shared, provide all customers who spent this 
-- amount
WITH customer_spending AS (
SELECT
i.billing_country AS country,
c.customer_id,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
ROUND(SUM(i.total), 2) AS total_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY
i.billing_country,c.customer_id,c.first_name,c.last_name
),
ranked_customers AS (
SELECT country, customer_name,total_spent,
DENSE_RANK() OVER (PARTITION BY country
ORDER BY total_spent DESC) AS spending_rank
FROM customer_spending
)
SELECT country,customer_name,total_spent
FROM ranked_customers
WHERE spending_rank = 1
ORDER BY country;

 