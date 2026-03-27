CREATE TABLE IF NOT EXISTS `bot_guild_runtime` (
  `guild_name` varchar(64) NOT NULL default '',
  `last_member_join_at` int(10) unsigned NOT NULL default '0',
  `last_notice_at` int(10) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`guild_name`),
  KEY `last_member_join_at` (`last_member_join_at`),
  KEY `last_notice_at` (`last_notice_at`)
) ENGINE=InnoDB;

ALTER TABLE `bot_controller_demand_signal`
  MODIFY `signal_type` enum('merchant_open_map','merchant_live_map','merchant_stock_map','merchant_browse_map','merchant_sale_map','guild_enabled_name','guild_roster_name','guild_live_name','guild_leader_name','guild_leader_live_name','guild_notice_name','guild_join_recent_name','guild_notice_recent_name','guild_storage_name','guild_storage_log_name','guild_castle_name','guild_candidate_map') NOT NULL default 'merchant_open_map';

DELETE FROM `bot_controller_demand_signal`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera');

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('social.prontera', 0, 'guild_candidate_map', 'prontera', 2),
  ('social.prontera', 1, 'guild_roster_name', 'PBG150001', 1),
  ('social.prontera', 2, 'guild_live_name', 'PBG150001', 2),
  ('social.prontera', 3, 'guild_leader_name', 'PBG150001', 1),
  ('social.prontera', 4, 'guild_leader_live_name', 'PBG150001', 2),
  ('social.prontera', 5, 'guild_notice_name', 'PBG150001', 1),
  ('social.prontera', 6, 'guild_join_recent_name', 'PBG150001', 2),
  ('social.prontera', 7, 'guild_notice_recent_name', 'PBG150001', 1),
  ('social.prontera', 8, 'guild_storage_name', 'PBG150001', 1),
  ('social.prontera', 9, 'guild_storage_log_name', 'PBG150001', 1),
  ('social.prontera', 10, 'guild_castle_name', 'PBG150001', 2),
  ('patrol.prontera', 0, 'guild_candidate_map', 'prontera', 1),
  ('patrol.prontera', 1, 'guild_roster_name', 'PBG150001', 1),
  ('patrol.prontera', 2, 'guild_leader_live_name', 'PBG150001', 1),
  ('patrol.prontera', 3, 'guild_notice_name', 'PBG150001', 1),
  ('patrol.prontera', 4, 'guild_join_recent_name', 'PBG150001', 1),
  ('patrol.prontera', 5, 'guild_notice_recent_name', 'PBG150001', 1),
  ('patrol.prontera', 6, 'guild_storage_name', 'PBG150001', 1),
  ('patrol.prontera', 7, 'guild_castle_name', 'PBG150001', 2)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);
