CREATE TABLE IF NOT EXISTS `bot_controller_demand_signal` (
  `controller_key` varchar(64) NOT NULL default '',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  `signal_type` enum('merchant_open_map','merchant_live_map','guild_enabled_name','guild_candidate_map') NOT NULL default 'merchant_open_map',
  `signal_key` varchar(64) NOT NULL default '',
  `signal_weight` smallint(5) unsigned NOT NULL default '1',
  PRIMARY KEY (`controller_key`,`point_index`),
  KEY `signal_type` (`signal_type`),
  KEY `signal_key` (`signal_key`)
) ENGINE=InnoDB;

DELETE FROM `bot_controller_demand_signal`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta');

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('social.prontera', 0, 'guild_candidate_map', 'prontera', 2),
  ('patrol.prontera', 0, 'guild_candidate_map', 'prontera', 1),
  ('social.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('merchant.alberta', 0, 'merchant_open_map', 'alberta', 3),
  ('merchant.alberta', 1, 'merchant_live_map', 'alberta', 2)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);
