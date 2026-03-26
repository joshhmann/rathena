ALTER TABLE `bot_controller_policy`
	ADD COLUMN IF NOT EXISTS `fair_weight` smallint(5) unsigned NOT NULL default '1' AFTER `restart_cooldown_ms`,
	ADD COLUMN IF NOT EXISTS `demand_users_step` smallint(5) unsigned NOT NULL default '1' AFTER `fair_weight`,
	ADD COLUMN IF NOT EXISTS `demand_priority_step` smallint(5) unsigned NOT NULL default '0' AFTER `demand_users_step`,
	ADD COLUMN IF NOT EXISTS `demand_priority_cap` smallint(5) unsigned NOT NULL default '0' AFTER `demand_priority_step`;

CREATE TABLE IF NOT EXISTS `bot_controller_demand_map` (
	`controller_key` varchar(64) NOT NULL default '',
	`map_name` varchar(32) NOT NULL default '',
	`user_weight` smallint(5) unsigned NOT NULL default '1',
	`point_index` smallint(5) unsigned NOT NULL default '0',
	PRIMARY KEY (`controller_key`,`map_name`),
	KEY `controller_key` (`controller_key`),
	KEY `point_index` (`point_index`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_pulse_profile` (
	`profile_key` varchar(64) NOT NULL default '',
	`start_hour` tinyint(3) unsigned NOT NULL default '0',
	`end_hour` tinyint(3) unsigned NOT NULL default '0',
	`min_delay_s` smallint(5) unsigned NOT NULL default '35',
	`max_delay_s` smallint(5) unsigned NOT NULL default '60',
	`talk_weight` tinyint(3) unsigned NOT NULL default '60',
	PRIMARY KEY (`profile_key`)
) ENGINE=InnoDB;

DELETE FROM `bot_controller_demand_map`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta');

INSERT INTO `bot_controller_demand_map`
	(`controller_key`, `map_name`, `user_weight`, `point_index`)
VALUES
	('social.prontera', 'prontera', 3, 0),
	('social.prontera', 'prt_in', 1, 1),
	('social.prontera', 'prt_fild08', 1, 2),
	('patrol.prontera', 'prontera', 1, 0),
	('patrol.prontera', 'prt_fild08', 3, 1),
	('social.alberta', 'alberta', 3, 0),
	('social.alberta', 'izlude', 1, 1),
	('merchant.alberta', 'alberta', 3, 0),
	('merchant.alberta', 'izlude', 2, 1)
ON DUPLICATE KEY UPDATE
	`user_weight` = VALUES(`user_weight`),
	`point_index` = VALUES(`point_index`);

INSERT INTO `bot_pulse_profile`
	(`profile_key`, `start_hour`, `end_hour`, `min_delay_s`, `max_delay_s`, `talk_weight`)
VALUES
	('square_anchor_day', 7, 21, 40, 70, 70),
	('square_anchor_evening', 9, 22, 45, 80, 60),
	('square_loiter_busy', 8, 20, 30, 55, 55),
	('square_loiter_late', 10, 23, 35, 60, 50),
	('square_loiter_night', 11, 23, 30, 50, 45),
	('market_anchor_day', 8, 21, 40, 70, 65),
	('market_anchor_trade', 9, 22, 45, 75, 60),
	('market_loiter_browse', 8, 20, 30, 55, 55),
	('mh', 9, 22, 35, 60, 50),
	('ml', 10, 23, 35, 55, 45)
ON DUPLICATE KEY UPDATE
	`start_hour` = VALUES(`start_hour`),
	`end_hour` = VALUES(`end_hour`),
	`min_delay_s` = VALUES(`min_delay_s`),
	`max_delay_s` = VALUES(`max_delay_s`),
	`talk_weight` = VALUES(`talk_weight`);
