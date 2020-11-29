1
/*города, в которых больше 1 аэропорта (не уникальные города)*/
SELECT city, COUNT(city) FROM airports
GROUP BY city HAVING COUNT(city) > 1

2
/*кол-во мест разных классов в боинге, без эконом-класса
aircraft_code 773 = Боинг 777-300*/
WITH specified_code AS (SELECT aircraft_code FROM aircrafts WHERE model = 'Боинг 777-300')
	SELECT fare_conditions, count(fare_conditions) FROM seats
	NATURAL JOIN specified_code GROUP BY fare_conditions HAVING fare_conditions != 'Economy'

3
/*100 самых дорогих перелетов (указаны названия аэропортов)*/
WITH to_from_airports_names AS
				(SELECT flight_id, A1.airport_name AS "detarture_name",  A2.airport_name AS "arrival_name"
				FROM flights, airports A1, airports A2 WHERE flights.departure_airport = A1.airport_code
														 AND flights.arrival_airport = A2.airport_code)
	SELECT DISTINCT detarture_name, arrival_name, amount
	FROM to_from_airports_names JOIN ticket_flights USING (flight_id)
	ORDER BY amount DESC, detarture_name LIMIT 100

4
/*максимальная и минимальная сумма брони по месяцам
формат: https://postgrespro.ru/docs/postgresql/9.5/functions-formatting*/
SELECT
TO_CHAR(book_date, 'yyyy') as "year", TO_CHAR(book_date, 'month') as "month",
ROUND( MIN(total_amount) ),
ROUND( MAX(total_amount), 4 )
FROM bookings GROUP BY "year", "month" ORDER BY "year", "month"


WITH
from_to_airports_names AS (SELECT flight_id, A1.airport_name AS "detarture_name",  A2.airport_name AS "arrival_name"
	FROM flights, airports A1, airports A2 WHERE flights.departure_airport = A1.airport_code
										   AND flights.arrival_airport = A2.airport_code),
departure_count(airport_name, sum_detarture) AS (SELECT detarture_name, count(*) AS sum_detarture
	FROM from_to_airports_names JOIN ticket_flights USING (flight_id) GROUP BY detarture_name),
arrival_count(airport_name, sum_arrival)   AS (SELECT arrival_name, count(*) AS sum_arrival
	FROM from_to_airports_names JOIN ticket_flights USING (flight_id) GROUP BY arrival_name)

SELECT airport_name, departure_count.sum_detarture + arrival_count.sum_arrival AS "total_fligfts"
	FROM departure_count JOIN arrival_count USING(airport_name);

SELECT departure_airport, arrival_airport, flight_id,
count(*) OVER(PARTITION BY departure_airport, arrival_airport ) AS "Duplicates" FROM flights;

SELECT departure_airport, arrival_airport, count(*) AS "Duplicates" FROM flights
GROUP BY departure_airport, arrival_airport;
