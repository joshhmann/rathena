CREATE TABLE IF NOT EXISTS `bot_guild_activity_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guild_name` varchar(64) NOT NULL default '',
  `activity_type` enum('member_join','notice_change') NOT NULL default 'member_join',
  `activity_units` int(10) unsigned NOT NULL default '1',
  `created_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`id`),
  KEY `guild_name` (`guild_name`),
  KEY `activity_type` (`activity_type`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_merchant_activity_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `bot_id` int(10) unsigned NOT NULL,
  `activity_type` enum('browse','sale') NOT NULL default 'browse',
  `activity_units` int(10) unsigned NOT NULL default '1',
  `created_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`id`),
  KEY `bot_id` (`bot_id`),
  KEY `activity_type` (`activity_type`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB;

ALTER TABLE `bot_controller_demand_signal`
  MODIFY `signal_type` enum('merchant_open_map','merchant_live_map','merchant_stock_map','merchant_browse_map','merchant_sale_map','merchant_browse_events_map','merchant_sale_units_map','guild_enabled_name','guild_roster_name','guild_live_name','guild_leader_name','guild_leader_live_name','guild_notice_name','guild_join_recent_name','guild_notice_recent_name','guild_join_events_name','guild_notice_events_name','guild_storage_name','guild_storage_log_name','guild_castle_name','guild_candidate_map') NOT NULL default 'merchant_open_map';

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('social.prontera', 11, 'guild_join_events_name', 'PBG150001', 1),
  ('social.prontera', 12, 'guild_notice_events_name', 'PBG150001', 1),
  ('patrol.prontera', 8, 'guild_join_events_name', 'PBG150001', 1),
  ('patrol.prontera', 9, 'guild_notice_events_name', 'PBG150001', 1),
  ('guild.watch.prontera', 5, 'guild_join_events_name', 'PBG150001', 1),
  ('guild.watch.prontera', 6, 'guild_notice_events_name', 'PBG150001', 1),
  ('guild.square.prontera', 5, 'guild_join_events_name', 'PBG150001', 1),
  ('guild.square.prontera', 6, 'guild_notice_events_name', 'PBG150001', 1),
  ('social.alberta', 3, 'merchant_browse_events_map', 'alberta', 1),
  ('merchant.alberta', 5, 'merchant_browse_events_map', 'alberta', 1),
  ('merchant.alberta', 6, 'merchant_sale_units_map', 'alberta', 1),
  ('market.flow.alberta', 4, 'merchant_browse_events_map', 'alberta', 1),
  ('market.flow.alberta', 5, 'merchant_sale_units_map', 'alberta', 1),
  ('market.spill.alberta', 5, 'merchant_browse_events_map', 'alberta', 1),
  ('market.spill.alberta', 6, 'merchant_sale_units_map', 'alberta', 1)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);
