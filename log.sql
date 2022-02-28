-- Keep a log of any SQL queries you execute as you solve the mystery.

-- Objectives: Find the thief, the accomplice, and the city the thief escaped to

-- Check for the structure of the tables
.schema

-- Take a look at the description from crime_scene_reports
SELECT description FROM crime_scene_reports
WHERE year = 2021 AND month = 7 AND day = 28 AND street = 'Humphrey Street';

-- New info: Theft of the CS50 duck took place at 10:15am at the Humphrey Street bakery. Interviews were conducted today with three witnesses who were present at the time – each of their interview transcripts mentions the bakery.

-- Check the interviews
SELECT * FROM interviews
WHERE year = 2021 AND month = 7 AND day = 28;

-- New info: | 161 | Ruth    | 2021 | 7     | 28  | Sometime within ten minutes of the theft, I saw the thief get into a car in the bakery parking lot and drive away. If you have security footage from the bakery parking lot, you might want to look for cars that left the parking lot in that time frame.
-- New info: | 162 | Eugene  | 2021 | 7     | 28  | I don't know the thief's name, but it was someone I recognized. Earlier this morning, before I arrived at Emma's bakery, I was walking by the ATM on Leggett Street and saw the thief there withdrawing some money.
-- New info: | 163 | Raymond | 2021 | 7     | 28  | As the thief was leaving the bakery, they called someone who talked to them for less than a minute. In the call, I heard the thief say that they were planning to take the earliest flight out of Fiftyville tomorrow. The thief then asked the person on the other end of the phone to purchase the flight ticket. |
-- New info: | 193 | Emma    | 2021 | 7     | 28  | I'm the bakery owner, and someone came in, suspiciously whispering into a phone for about half an hour. They never bought anything.

-- Take a look at bakery_security_log
SELECT * FROM bakery_security_logs
WHERE year = 2021 AND month = 7 AND day = 28;

-- Found that there are several cars leaving the bakery within 10 minutes of the theft
-- Those car's owner are:
SELECT * FROM people
WHERE license_plate IN (
  SELECT license_plate FROM bakery_security_logs
  WHERE year = 2021 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 25
);

-- Suspects: Vanessa, Barry, Iman, Sofia, Luca, Diana, Kelsey, Bruce

-- Let's see if anyone above boarded a flight
SELECT * FROM passengers
WHERE passport_number IN (
  SELECT passport_number FROM people
  WHERE license_plate IN (
    SELECT license_plate FROM bakery_security_logs
    WHERE year = 2021 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 25
  )
);

-- Let's see which of those flights are on 7/29 with airport_id from fiftyville

-- First let's check for the ID of fiftyville
SELECT * FROM airports;
-- | 8  | CSF          | Fiftyville Regional Airport             | Fiftyville    |

-- Back to the query
SELECT * FROM flights
WHERE id IN (
  SELECT flight_id FROM passengers
  WHERE passport_number IN (
    SELECT passport_number FROM people
    WHERE license_plate IN (
      SELECT license_plate FROM bakery_security_logs
      WHERE year = 2021 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 25
    )
  )
) AND origin_airport_id = 8 AND year = 2021 AND month = 7 AND day = 29;

-- Two results: 2021/7/29 8:20 -> flight_id = 36, 2021/7/29 16:00 -> flight_id = 18
-- From the interviews we know that the thief plan to leave on the earliest flight

-- Let's check the detail of the passengers who took flight_id = 36
SELECT * FROM passengers
WHERE flight_id = 36;

-- Let's narrow it down using the list of suspects above
SELECT * FROM passengers
WHERE flight_id = 36 AND passport_number IN (
  SELECT passport_number FROM people
  WHERE license_plate IN (
    SELECT license_plate FROM bakery_security_logs
    WHERE year = 2021 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 25
  )
);

-- 4 people
SELECT * FROM people WHERE passport_number IN (
  SELECT passport_number FROM passengers
  WHERE flight_id = 36 AND passport_number IN (
    SELECT passport_number FROM people
    WHERE license_plate IN (
      SELECT license_plate FROM bakery_security_logs
      WHERE year = 2021 AND month = 7 AND day = 28 AND hour = 10 AND minute >= 15 AND minute <= 25
    )
  )
);

-- Suspects: Sofia, Luca, Kelsey, Bruce

-- Let's check the phone calls next
SELECT * FROM phone_calls
WHERE caller IN (
  SELECT phone_number FROM people
  WHERE name IN ('Sofia', 'Luca', 'Kelsey', 'Bruce')
);

-- Did any of them make a phone call on 7/28?
SELECT * FROM phone_calls
WHERE caller IN (
  SELECT phone_number FROM people
  WHERE name IN ('Sofia', 'Luca', 'Kelsey', 'Bruce')
) AND year = 2021 AND month = 7 AND day = 28;

-- The suspect is narrowed down to 3 people
SELECT name FROM people
WHERE phone_number IN (
  SELECT caller FROM phone_calls
  WHERE caller IN (
    SELECT phone_number FROM people
    WHERE name IN (
      'Sofia', 'Luca', 'Kelsey', 'Bruce')
    ) AND year = 2021 AND month = 7 AND day = 28
);

-- Suspects: Sofia, Kelsey, Bruce

-- From interview with the bakery owner, we know that there's someone suspicious who talk on their phone for around 30 minutes and that one is:
-- | 224 | (499) 555-9472 | (892) 555-8872 | 2021 | 7     | 28  | 36       |
SELECT name FROM people WHERE phone_number = '(499) 555-9472';

-- Kelsey (The number 1 suspect for now)

-- Let's check if any of the suspects withdrew money at Leggett Street
SELECT account_number FROM atm_transactions WHERE atm_location = 'Leggett Street' AND year = 2021 AND month = 7 AND day = 28 AND transaction_type = 'withdraw';

SELECT name FROM people
JOIN bank_accounts ON bank_accounts.person_id = people.id
WHERE account_number IN (
  SELECT account_number FROM atm_transactions
  WHERE atm_location = 'Leggett Street' AND year = 2021 AND month = 7 AND day = 28 AND transaction_type = 'withdraw'
);

-- Seems like it's actually Bruce since Kelsey didn't use the atm on 7/28

SELECT * FROM people WHERE name = 'Bruce';

-- Let's double check if Bruce really is the thief
-- Bakery security logs
SELECT * FROM bakery_security_logs WHERE license_plate = (SELECT license_plate FROM people WHERE name = 'Bruce');
-- Bruce enter the at 8:23 and exit at 10:18

-- Calls
SELECT * FROM phone_calls WHERE caller = (SELECT phone_number FROM people WHERE name = 'Bruce');
-- Bruce did make a call for 45 minutes, the owner might be bad with estimating times

-- Flights
SELECT * FROM flights
JOIN passengers ON passengers.flight_id = flights.id
WHERE passengers.passport_number = (SELECT passport_number FROM people WHERE name = 'Bruce');
-- Only 1 result: 7/28 8:20 flight with id = 36, seat=4A, origin_airport_id = 8, destination_airport_id = 4

-- The destination is:
SELECT * FROM airports WHERE id = 4;

-- | 4  | LGA          | LaGuardia Airport | New York City |

-- Now let's look for his accomplice

-- So Bruce talked for 45 minutes on 7/28 with this number  (375) 555-8161
SELECT * FROM people WHERE phone_number = '(375) 555-8161';

-- Accomplice : Robin
