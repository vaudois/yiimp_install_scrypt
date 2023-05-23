-- Recent additions to add after db init (.gz)
-- mysql yaamp -p < file.sql

-- don't forget to restart memcached service to refresh the db structure

ALTER TABLE `coins` ADD `tags` VARCHAR(50) NULL AFTER `watch`;
ALTER TABLE `coins` ADD `test_coin` VARCHAR(50) NULL AFTER `auxpow`;
ALTER TABLE `coins` ADD `usemweb` VARCHAR(50) NULL AFTER `usesegwit`;
ALTER TABLE `coins` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1300;
