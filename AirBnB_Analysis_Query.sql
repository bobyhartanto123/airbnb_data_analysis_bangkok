--This is an Exploratory Data Analysis Project that analyze airbnb  listings and reviews from the airbnb properties
--in Bangkok


--Data cleaning phase

BEGIN TRANSACTION
--To make sure all prices are in integer format
	update listings$ set price = cast(price as int) from listings$
--Remove the dollar sign from price
	update listings$ set price = REPLACE(price,'$','') from listings$

COMMIT

--Removing the time from datetime because all the time in the dataset shows 00:00:00:00
alter table listings$ add first_review_converted Date;
alter table listings$ add host_since_converted Date;
alter table listings$ add calendar_last_scraped_converted Date;
alter table listings$ add last_review_converted Date;

update listings$ set first_review_converted = cast(first_review as date)
update listings$ set last_review_converted = cast (last_review as date)
update listings$ set host_since_converted = cast(host_since as date)
update listings$ set calendar_last_scraped_converted = cast(calendar_last_scraped as date)



--Drop previous columns that contains 00:00:00
BEGIN TRANSACTION
	ALTER TABLE listings$ drop column first_review;
	alter table listings$ drop column last_review;
	alter table listings$ drop column host_since;
	alter table listings$ drop column calendar_last_scraped;

commit;


SELECT * FROM listings$ where calendar_updated is not null

--Drop calendar_updated because it only contains null value
select neighbourhood_group_cleansed from listings$ where neighbourhood_group_cleansed is not null;


BEGIN TRANSACTION
	ALTER TABLE listings$ drop column calendar_updated
commit;

alter table listings$ drop column neighbourhood_group_cleansed


--Replace "null" in host location with Bangkok,Thailand
update listings$ set host_location = COALESCE(host_location,'Bangkok,Thailand');



--DATA ANALYSIS PHASE

--1.Find the top ten earners of airbnb in 3 months
select TOP 10
host_name as Host_Name,
name,
property_type,
amenities,
--airbnb data didn't exacly shows how many nights customers spend on their propery(for security reason),
--so I assumed that the revenue come from 90 days minus the availability in 90 days multiply by price
SUM(price * (90-availability_90)) as revenue_in_3_month
from listings$ group by host_name,name,property_type,amenities order by revenue_in_3_month desc

--2 Identify cheapest and the most expensive airbnb property
select min(price),max(price) from listings$ where price != 0.0;

--3.List top ten name of the hosts that have the most listings in AirBnb in Bangkok
select host_name,count(*) from listings$ group by host_name order by count(*) desc  

--4.List top ten airbnb property that have the best location review in Bangkok
select top 10 
name,
neighbourhood_cleansed, 
avg(review_scores_location) as Average_Location_Rating
from listings$ group by name,neighbourhood_cleansed order by avg(review_scores_location) desc

--cleaning review data table
update reviews$ set date = cast(date as date) 
alter table reviews$ add review_date_cleaned Date
update reviews$ set review_date_cleaned = cast(date as date)




--Joining listing table and review table to get insights on customer satisfactions and how frequent customers booked the particular
=--hotels


--1.List how frequently the property of the owners getting booked by customers
with listing_review_join as (select 
list.id,
list.name,
list.host_id,
list.host_name,
review.reviewer_id,
review.reviewer_name,
review.review_date_cleaned,
review.comments
from listings$ list inner join reviews$ review
on
list.id = review.listing_id)
select 
listing_review_join.host_name,
listing_review_join.name,
count(*) as booking_frequency
from listing_review_join group by listing_review_join.host_name,listing_review_join.name
order by host_name 

--2.List the most unsafe airbnb in Thailand according to users reviews
select 
list.host_id,
list.host_url,
list.host_name,
count(*) as dangerous_reviews
from listings$ list inner join reviews$ review
on
list.id = review.listing_id where review.comments like '%unsafe%'
group by list.host_id,list.host_url,list.host_name order by count(*) desc

--3.List the dirtiest airbnb in Thailand according to users reviews
select 
list.host_id,
list.host_url,
list.host_name,
count(*) as dirty_reviews
from listings$ list inner join reviews$ review
on
list.id = review.listing_id where review.comments like '%dirty%'
group by list.host_id,list.host_url,list.host_name order by count(*) desc


--4.List what types of property that travelers most likely want to booked in Thailand
with property_type_booking as (select
rev.id as transaction_id,
rev.listing_id as listing_id,
rev.reviewer_name as customer_name,
list.property_type
from
reviews$ rev inner join listings$ list
on
rev.listing_id = list.id)

select
property_type_booking.property_type,
count(*) as qty_of_property_type_booked
from property_type_booking group by property_type_booking.property_type order by count(*) desc

















