-- Recent additions to add after db init (.gz)
-- mysql yaamp -p < file.sql

-- add shares for solo function

ALTER TABLE accounts ADD payment_period INT(10) NULL AFTER last_earning;
