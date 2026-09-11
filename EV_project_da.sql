create database ev_charging_db;
use ev_charging_db;
CREATE TABLE charging_sessions (
    Session_ID VARCHAR(20) PRIMARY KEY,
    Date DATE,
    Start_Time TIME,
    End_Time TIME,
    Station_ID VARCHAR(10),
    Customer_ID VARCHAR(10),
    EV_Model VARCHAR(50),
    Charger_Type VARCHAR(20),
    Energy_Consumed_kWh DECIMAL(10,2),
    Charging_Duration_Min INT,
    Revenue DECIMAL(10,2),
    Payment_Method VARCHAR(30),
    Session_Status VARCHAR(20)
);
CREATE TABLE stations (
    Station_ID VARCHAR(10) PRIMARY KEY,
    Station_Name VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Location_Type VARCHAR(30),
    Charger_Count INT,
    Station_Status VARCHAR(20)
);
CREATE TABLE customers (
    Customer_ID VARCHAR(10) PRIMARY KEY,
    Customer_Type VARCHAR(30),
    Gender VARCHAR(20),
    Age_Group VARCHAR(20),
    Membership VARCHAR(20),
    Registration_Date DATE
);
SELECT COUNT(*) AS total_sessions
FROM charging_sessions;
select count(*) as total_stations 
from stations;
select count(*) as total_customers
from customers;
#**Checking duplicate Session IDs
SELECT Session_ID, COUNT(*) AS count
FROM charging_sessions
GROUP BY Session_ID
HAVING COUNT(*) > 1;
#Check missing EV models
SELECT COUNT(*) AS missing_ev_models
FROM charging_sessions
WHERE EV_Model IS NULL;
#checking missing payment methods
select count(*) as missing_payments_method
from  charging_sessions
where Payment_Method is null;
#cheking negative energy
SELECT *
FROM charging_sessions
WHERE Energy_Consumed_kWh < 0;
#Total revenue
select
sum(Revenue) as total_revenue
from charging_sessions
where session_Status='completed';
##Total charging sessions
SELECT 
    COUNT(*) AS Total_Sessions
FROM charging_sessions;
##Total completed sessions
SELECT 
    COUNT(*) AS Completed_Sessions
FROM charging_sessions
WHERE Session_Status = 'Completed';
##Toatal failed sessions
SELECT 
    COUNT(*) AS Failed_Sessions
FROM charging_sessions
WHERE Session_Status = 'Failed';
##Total Energy consumed
SELECT 
    SUM(Energy_Consumed_kWh) AS Total_Energy
FROM charging_sessions
WHERE Session_Status = 'Completed';
##Average charging Duration
SELECT 
    AVG(Charging_Duration_Min) AS Avg_Charging_Duration
FROM charging_sessions
WHERE Session_Status = 'Completed';
## Average revenue per session
SELECT 
    AVG(Revenue) AS Avg_Revenue_Per_Session
FROM charging_sessions
WHERE Session_Status = 'Completed';
##VALIDATING USING JOINS
## REVENUE by city
SELECT 
    s.City,
    SUM(c.Revenue) AS Total_Revenue
FROM charging_sessions c
JOIN stations s
    ON c.Station_ID = s.Station_ID
WHERE c.Session_Status = 'Completed'
GROUP BY s.City
ORDER BY Total_Revenue DESC;
## REVENUE BY STATION
select 
   s.Station_Name,
   s.city,
   sum(c.Revenue) AS Total_revenue
from Charging_Sessions c
join Stations s
    ON c.Station_ID = s.Station_ID
WHERE c.Session_Status = 'Completed'
GROUP BY s.Station_Name, s.City
ORDER BY Total_Revenue DESC;
## Sessions by EV model
SELECT 
    EV_Model,
    COUNT(*) AS Total_Sessions
FROM charging_sessions
WHERE Session_Status = 'Completed'
GROUP BY EV_Model
ORDER BY Total_Sessions DESC;
## Top 10 stations
SELECT
    s.Station_ID,
    s.Station_Name,
    s.City,
    SUM(c.Revenue) AS Total_Revenue
FROM charging_sessions c
JOIN stations s
    ON c.Station_ID = s.Station_ID
WHERE c.Session_Status = 'Completed'
GROUP BY
    s.Station_ID,
    s.Station_Name,
    s.City
ORDER BY Total_Revenue DESC
LIMIT 10;
##which ev model charges more times
SELECT
    EV_Model,
    COUNT(*) AS Total_Sessions
FROM charging_sessions
WHERE Session_Status = 'Completed'
GROUP BY EV_Model
ORDER BY Total_Sessions DESC;
# Membership vs Non membership
SELECT
    cu.Membership,
    COUNT(*) AS Total_Sessions
FROM charging_sessions cs
JOIN customers cu
    ON cs.Customer_ID = cu.Customer_ID
WHERE cs.Session_Status = 'Completed'
GROUP BY cu.Membership
ORDER BY Total_Sessions DESC;
##Customer Type with Highest Usage
SELECT
    cu.Customer_Type,
    COUNT(*) AS Total_Sessions
FROM charging_sessions cs
JOIN customers cu
    ON cs.Customer_ID = cu.Customer_ID
WHERE cs.Session_Status = 'Completed'
GROUP BY cu.Customer_Type
ORDER BY Total_Sessions DESC;
##Monthly Revenue Trend
SELECT
    YEAR(Date) AS Year,
    MONTH(Date) AS Month_Number,
    MONTHNAME(Date) AS Month,
    SUM(Revenue) AS Total_Revenue
FROM charging_sessions
WHERE Session_Status = 'Completed'
GROUP BY
    YEAR(Date),
    MONTH(Date),
    MONTHNAME(Date)
ORDER BY
    Year,
    Month_Number;
##Failed Sessions by Station
SELECT
    s.Station_ID,
    s.Station_Name,
    s.City,
    COUNT(*) AS Failed_Sessions
FROM charging_sessions cs
JOIN stations s
    ON cs.Station_ID = s.Station_ID
WHERE cs.Session_Status = 'Failed'
GROUP BY
    s.Station_ID,
    s.Station_Name,
    s.City
ORDER BY Failed_Sessions DESC;
##Calculate Revenue Growth %
WITH MonthlyRevenue AS (
    SELECT
        YEAR(Date) AS Year,
        MONTH(Date) AS Month_Number,
        DATE_FORMAT(Date, '%Y-%m') AS Month,
        SUM(Revenue) AS Total_Revenue
    FROM charging_sessions
    WHERE Session_Status = 'Completed'
    GROUP BY
        YEAR(Date),
        MONTH(Date),
        DATE_FORMAT(Date, '%Y-%m')
),
RevenueWithPrevious AS (
    SELECT
        Month,
        Year,
        Month_Number,
        Total_Revenue,
        LAG(Total_Revenue) OVER (
            ORDER BY Year, Month_Number
        ) AS Previous_Month_Revenue
    FROM MonthlyRevenue
)
SELECT
    Month,
    Total_Revenue,
    Previous_Month_Revenue,
    ROUND(
        ((Total_Revenue - Previous_Month_Revenue)
        / Previous_Month_Revenue) * 100,
        2
    ) AS MoM_Growth_Percentage
FROM RevenueWithPrevious
ORDER BY Year, Month_Number;
##Station Utilization
WITH StationUsage AS (
    SELECT
        s.Station_ID,
        s.Station_Name,
        s.City,
        s.Charger_Count,
        COUNT(cs.Session_ID) AS Total_Sessions
    FROM stations s
    LEFT JOIN charging_sessions cs
        ON s.Station_ID = cs.Station_ID
        AND cs.Session_Status = 'Completed'
    GROUP BY
        s.Station_ID,
        s.Station_Name,
        s.City,
        s.Charger_Count
)
SELECT
    Station_ID,
    Station_Name,
    City,
    Charger_Count,
    Total_Sessions,
    ROUND(
        Total_Sessions / NULLIF(Charger_Count, 0),
        2
    ) AS Sessions_Per_Charger
FROM StationUsage
ORDER BY Sessions_Per_Charger DESC;