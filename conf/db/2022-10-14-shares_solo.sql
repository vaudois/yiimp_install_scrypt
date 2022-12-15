-- Recent additions to add after db init (.gz)
-- mysql yaamp -p < file.sql

 -- add shares for solo function

ALTER TABLE `shares` ADD `solo` TINYINT(1) NULL DEFAULT NULL AFTER `algo`;

