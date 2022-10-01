-- Recent additions to add after db init (.gz)
-- mysql yaamp -p < file.sql

-- Additional fields for additions by cryptopool.builders

ALTER TABLE `coins` ADD `link_twitter` varchar(1024) DEFAULT NULL AFTER `link_explorer`;
ALTER TABLE `coins` ADD `link_facebook` varchar(1024) DEFAULT NULL AFTER `link_twitter`;
ALTER TABLE `coins` ADD `donation_address` varchar(1024) DEFAULT NULL AFTER `link_facebook`;
ALTER TABLE `coins` ADD `link_discord` varchar(1024) DEFAULT NULL AFTER `link_twitter`;
ALTER TABLE `coins` ADD `usefaucet` tinyint(1) UNSIGNED NOT NULL DEFAULT '0' AFTER `donation_address`;
ALTER TABLE `coins` ADD `dedicatedport` int(11) DEFAULT NULL AFTER `rpcport`;
