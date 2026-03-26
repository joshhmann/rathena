CREATE TABLE IF NOT EXISTS `bot_controller_policy` (
  `controller_key` varchar(64) NOT NULL default '',
  `controller_npc` varchar(64) NOT NULL default '',
  `controller_label` varchar(64) NOT NULL default '',
  `controller_type` enum('social','merchant','party','event') NOT NULL default 'social',
  `map_name` varchar(32) NOT NULL default '',
  `scheduler_enabled` tinyint(1) unsigned NOT NULL default '1',
  `controller_enabled` tinyint(1) unsigned NOT NULL default '1',
  `gate_users` smallint(5) unsigned NOT NULL default '0',
  `priority` smallint(5) unsigned NOT NULL default '0',
  `actor_weight` smallint(5) unsigned NOT NULL default '1',
  `tick_ms` int(10) unsigned NOT NULL default '2000',
  `start_min_ms` int(10) unsigned NOT NULL default '0',
  `start_max_ms` int(10) unsigned NOT NULL default '0',
  `grace_ms` int(10) unsigned NOT NULL default '0',
  `stop_policy` enum('release','park') NOT NULL default 'release',
  `routine_group` varchar(64) NOT NULL default '',
  `routine_start_hour` tinyint(3) unsigned NOT NULL default '0',
  `routine_end_hour` tinyint(3) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`controller_key`),
  UNIQUE KEY `controller_npc` (`controller_npc`),
  KEY `map_name` (`map_name`),
  KEY `scheduler_enabled` (`scheduler_enabled`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_controller_slot` (
  `slot_id` int(10) unsigned NOT NULL auto_increment,
  `controller_key` varchar(64) NOT NULL default '',
  `slot_index` smallint(5) unsigned NOT NULL default '0',
  `slot_label` varchar(64) NOT NULL default '',
  `pool_key` varchar(64) NOT NULL default '',
  `profile_key` varchar(64) NOT NULL default '',
  `role_key` varchar(64) NOT NULL default '',
  `map_name` varchar(32) NOT NULL default '',
  `spawn_x` smallint(5) unsigned NOT NULL default '0',
  `spawn_y` smallint(5) unsigned NOT NULL default '0',
  `loop_route` tinyint(1) unsigned NOT NULL default '0',
  `mode` enum('hold','loiter','patrol') NOT NULL default 'hold',
  `pulse_profile` varchar(64) NOT NULL default '',
  `anchor_set_key` varchar(64) NOT NULL default '',
  `route_set_key` varchar(64) NOT NULL default '',
  `talk_set_key` varchar(64) NOT NULL default '',
  `emote_set_key` varchar(64) NOT NULL default '',
  `enabled` tinyint(1) unsigned NOT NULL default '1',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`slot_id`),
  UNIQUE KEY `controller_key` (`controller_key`,`slot_index`),
  KEY `pool_key` (`pool_key`),
  KEY `profile_key` (`profile_key`),
  KEY `role_key` (`role_key`)
) ENGINE=InnoDB;

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('social.prontera', 'HeadlessPronteraSocialController', 'Prontera social', 'social', 'prontera', 1, 1, 1, 90, 5, 2200, 400, 1500, 12000, 'park', 'day', 7, 23),
  ('social.alberta', 'HeadlessAlbertaSocialController', 'Alberta social', 'social', 'alberta', 1, 1, 1, 80, 5, 2400, 500, 1800, 15000, 'park', 'night', 0, 6),
  ('merchant.alberta', 'HeadlessAlbertaMerchantController', 'Alberta merchants', 'merchant', 'alberta', 1, 1, 1, 85, 1, 2600, 600, 1600, 18000, 'park', 'day', 8, 22)
ON DUPLICATE KEY UPDATE
  `controller_label` = VALUES(`controller_label`),
  `controller_type` = VALUES(`controller_type`),
  `map_name` = VALUES(`map_name`),
  `scheduler_enabled` = VALUES(`scheduler_enabled`),
  `controller_enabled` = VALUES(`controller_enabled`),
  `gate_users` = VALUES(`gate_users`),
  `priority` = VALUES(`priority`),
  `actor_weight` = VALUES(`actor_weight`),
  `tick_ms` = VALUES(`tick_ms`),
  `start_min_ms` = VALUES(`start_min_ms`),
  `start_max_ms` = VALUES(`start_max_ms`),
  `grace_ms` = VALUES(`grace_ms`),
  `stop_policy` = VALUES(`stop_policy`),
  `routine_group` = VALUES(`routine_group`),
  `routine_start_hour` = VALUES(`routine_start_hour`),
  `routine_end_hour` = VALUES(`routine_end_hour`);

DELETE FROM `bot_controller_slot`
WHERE `controller_key` IN ('social.prontera', 'social.alberta', 'merchant.alberta');

INSERT INTO `bot_controller_slot`
  (`controller_key`, `slot_index`, `slot_label`, `pool_key`, `profile_key`, `role_key`, `map_name`, `spawn_x`, `spawn_y`, `loop_route`, `mode`, `pulse_profile`, `anchor_set_key`, `route_set_key`, `talk_set_key`, `emote_set_key`, `enabled`)
VALUES
  ('social.prontera', 0, 'Square Regular A', 'pool.social.prontera', 'social.prontera.regular', 'square_regular', 'prontera', 146, 188, 0, 'hold', 'square_anchor_day', '', '', 'social.prontera.regular.a', 'social.prontera.regular.a', 1),
  ('social.prontera', 1, 'Square Regular B', 'pool.social.prontera', 'social.prontera.regular', 'square_regular', 'prontera', 151, 186, 0, 'hold', 'square_anchor_evening', '', '', 'social.prontera.regular.b', 'social.prontera.regular.b', 1),
  ('social.prontera', 2, 'Square Wanderer A', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 145, 184, 1, 'loiter', 'square_loiter_busy', 'social.prontera.wanderer.a', '', 'social.prontera.wanderer.a', 'social.prontera.wanderer.a', 1),
  ('social.prontera', 3, 'Square Wanderer B', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 153, 188, 1, 'loiter', 'square_loiter_late', 'social.prontera.wanderer.b', '', 'social.prontera.wanderer.b', 'social.prontera.wanderer.b', 1),
  ('social.prontera', 4, 'Square Wanderer C', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 147, 190, 1, 'loiter', 'square_loiter_night', 'social.prontera.wanderer.c', '', 'social.prontera.wanderer.c', 'social.prontera.wanderer.c', 1),
  ('social.alberta', 0, 'Dock Regular A', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 47, 245, 0, 'hold', 'market_anchor_day', '', '', 'social.alberta.regular.a', 'social.alberta.regular.a', 1),
  ('social.alberta', 1, 'Dock Regular B', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 50, 244, 0, 'hold', 'market_anchor_trade', '', '', 'social.alberta.regular.b', 'social.alberta.regular.b', 1),
  ('social.alberta', 2, 'Market Browser A', 'pool.social.alberta', 'social.alberta.browser', 'market_browser', 'alberta', 44, 243, 1, 'loiter', 'market_loiter_browse', 'social.alberta.browser.a', '', 'social.alberta.browser.a', 'social.alberta.browser.a', 1),
  ('social.alberta', 3, 'Harbor Wanderer', 'pool.social.alberta', 'social.alberta.harbor', 'harbor_wanderer', 'alberta', 45, 247, 1, 'loiter', 'mh', 'social.alberta.harbor.a', '', 'social.alberta.harbor.a', 'social.alberta.harbor.a', 1),
  ('social.alberta', 4, 'Market Browser B', 'pool.social.alberta', 'social.alberta.browser', 'market_browser', 'alberta', 43, 241, 1, 'loiter', 'ml', 'social.alberta.browser.b', '', 'social.alberta.browser.b', 'social.alberta.browser.b', 1),
  ('merchant.alberta', 0, 'Harbor Curios', 'pool.merchant.alberta', 'merchant.alberta', 'stall_merchant', 'alberta', 52, 242, 0, 'hold', 'market_anchor_trade', '', '', 'merchant.alberta.stall.a', 'merchant.alberta.stall.a', 1);
