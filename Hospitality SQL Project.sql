-- Step1:Create a Database
CREATE DATABASE hotelmanagement_db;
USE hotelmanagement_db;

-- Step 2: Create a table 
-- 1. fact_bookings
CREATE TABLE fact_bookings (
    booking_id VARCHAR(50),          -- Text ID
    property_id INT,                 -- Number
    booking_date DATE,               -- Date
    check_in_date DATE,              -- Date
    checkout_date DATE,              -- Date
    no_guests INT,                   -- Number of guests
    room_category VARCHAR(10),      -- Room category like RT1
    booking_platform VARCHAR(50),   -- Booking source
    ratings_given int,            --  IF I WILL USE Float (you changed nulls to 0, so FLOAT is ok)
    booking_status VARCHAR(20),     -- Status text
    revenue_generated FLOAT,        -- Revenue
    revenue_realized FLOAT          -- Revenue
);

-- Show data from table
SELECT * FROM fact_bookings;

-- 2.fact_aggregated_bookings
CREATE TABLE fact_aggregated_bookings (
    property_id VARCHAR(50),
    check_in_date DATE,
    room_category VARCHAR(10),
    successful_bookings INT,
    capacity INT
);

-- Show data from table
SELECT * FROM fact_aggregated_bookings;

-- 3.dim_rooms
CREATE TABLE dim_rooms (
    room_id VARCHAR(10),
    room_class VARCHAR(50)
);
---- Show data from table
SELECT * FROM dim_rooms;

-- 4.dim_hotels
CREATE TABLE dim_hotels (
    property_id INT,
    property_name VARCHAR(100),
    category VARCHAR(50),
    city VARCHAR(50)
);
-- Show data from table
SELECT * FROM dim_hotels;

-- 5.dim_date: 
CREATE TABLE dim_date (
    date DATE,
    mmm_yy VARCHAR(10),
    week_no VARCHAR(10),
    day_type VARCHAR(10)
);
-- Show data from table
SELECT * FROM dim_date;

-- Question 1:Total Revenue
SELECT SUM(revenue_realized) AS total_revenue
FROM fact_bookings;

-- Question 2:Occupancy
SELECT 
  ROUND(SUM(successful_bookings) * 100.0 / NULLIF(SUM(capacity), 0), 2) AS occupancy_percentage
FROM fact_aggregated_bookings;

-- Question 3:Cancelation Rate
SELECT(COUNT(CASE WHEN BOOKING_STATUS = 'CANCELLED' THEN 1 END)*100.0)/COUNT(*)AS CANCELATION_RATE FROM FACT_BOOKINGS;

-- Question 4:Total Booking
select count(booking_id) as total_bookings from fact_bookings;

-- Question 5: Utilized Capacity
SELECT 
    SUM(successful_bookings) AS utilized_rooms,
    SUM(capacity) AS total_rooms,
    (SUM(successful_bookings)/SUM(capacity))*100 AS utilized_capacity_percentage
FROM fact_aggregated_bookings;

-- Question 6: (Weekly Revenue Trend)
SELECT 
    DATE_FORMAT(d.date, '%Y-%m') AS month,
    d.week_no AS week_number,
    SUM(fb.revenue_realized) AS total_revenue
FROM fact_bookings fb
JOIN dim_date d
    ON fb.check_in_date = d.date
WHERE fb.booking_status = 'Checked Out'
GROUP BY DATE_FORMAT(d.date, '%Y-%m'), d.week_no
ORDER BY DATE_FORMAT(d.date, '%Y-%m'), d.week_no;

-- show the exact column names from the table
SHOW COLUMNS FROM dim_date;

-- Question 7: Weekday & Weekend Revenue and Booking
SELECT d.day_type, 
       COUNT(f.booking_id) AS total_bookings, 
       SUM(f.revenue_generated) AS total_revenue
FROM fact_bookings f
JOIN dim_date d ON f.check_in_date = d.date
WHERE f.booking_status = 'Checked Out'
GROUP BY d.day_type;

-- Question 8: Revenue by State & Hotel
SELECT 
     h.property_name, 
     h.city, 
       SUM(f.revenue_generated) AS total_revenue
FROM fact_bookings f
JOIN dim_hotels h ON f.property_id = h.property_id
WHERE f.booking_status = 'Checked Out'
GROUP BY h.property_name, h.city
ORDER BY total_revenue DESC; 

-- Question 9: Class Wise Revenue
SELECT r.room_class, 
       SUM(f.revenue_generated) AS total_revenue
FROM fact_bookings f
JOIN dim_rooms r ON f.room_category = r.room_id
WHERE f.booking_status = 'Checked Out'
GROUP BY r.room_class;

-- Question 10: Checked out cancel No show
SELECT booking_status, COUNT(*) AS total_bookings
FROM fact_bookings
GROUP BY booking_status;

-- Question 11: Weekly trend Key trend (Revenue, Total booking, Occupancy)
SELECT d.week_no, 
       SUM(f.revenue_generated) AS total_revenue,
       COUNT(f.booking_id) AS total_bookings,
       ROUND(SUM(ab.successful_bookings)*100.0 / SUM(ab.capacity), 2) AS occupancy_rate
FROM fact_bookings f
JOIN dim_date d ON f.check_in_date = d.date
JOIN fact_aggregated_bookings ab ON f.property_id = ab.property_id AND f.check_in_date = ab.check_in_date
WHERE f.booking_status = 'Checked Out'
GROUP BY d.week_no
ORDER BY d.week_no;