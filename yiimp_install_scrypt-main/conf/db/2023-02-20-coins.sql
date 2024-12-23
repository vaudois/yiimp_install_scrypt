-- Recent additions to add after db init (.gz)
-- mysql yaamp -p < file.sql

-- don't forget to restart memcached service to refresh the db structure
ALTER TABLE `coins` ADD `tags` VARCHAR(50) NULL AFTER `watch`;