-- Persistent bot identity schema for playerbot provisioning.
-- This slice defines the stable identity, link, appearance, and runtime state
-- tables used by the recurring bot lane.

CREATE TABLE IF NOT EXISTS `bot_profile` (
  `bot_id` int(10) unsigned NOT NULL auto_increment,
  `bot_key` varchar(64) NOT NULL default '',
  `name` varchar(30) NOT NULL default '',
  `status` enum('draft','active','disabled','retired') NOT NULL default 'draft',
  `role` varchar(32) NOT NULL default '',
  `home_map` varchar(32) NOT NULL default '',
  `routine_pool` varchar(64) NOT NULL default '',
  `timezone_policy` varchar(64) NOT NULL default '',
  `personality_tag` varchar(64) NOT NULL default '',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  UNIQUE KEY `bot_key` (`bot_key`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_identity_link` (
  `bot_id` int(10) unsigned NOT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `char_id` int(10) unsigned DEFAULT NULL,
  `link_status` enum('pending','linked','retired') NOT NULL default 'pending',
  `linked_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  UNIQUE KEY `account_id` (`account_id`),
  UNIQUE KEY `char_id` (`char_id`),
  KEY `link_status` (`link_status`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_appearance` (
  `bot_id` int(10) unsigned NOT NULL,
  `job_id` smallint(5) unsigned NOT NULL default '0',
  `sex` enum('F','M') NOT NULL default 'M',
  `hair_style` tinyint(4) unsigned NOT NULL default '0',
  `hair_color` smallint(5) unsigned NOT NULL default '0',
  `cloth_color` smallint(5) unsigned NOT NULL default '0',
  `weapon_view` smallint(6) unsigned NOT NULL default '0',
  `shield_view` smallint(6) unsigned NOT NULL default '0',
  `head_top` smallint(6) unsigned NOT NULL default '0',
  `head_mid` smallint(6) unsigned NOT NULL default '0',
  `head_bottom` smallint(6) unsigned NOT NULL default '0',
  `robe` smallint(6) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_runtime_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `current_map` varchar(32) NOT NULL default '',
  `current_x` smallint(5) unsigned NOT NULL default '0',
  `current_y` smallint(5) unsigned NOT NULL default '0',
  `current_state` enum('idle','walking','resting','merchanting','event','party','offline') NOT NULL default 'offline',
  `park_state` enum('active','grace','parked') NOT NULL default 'parked',
  `spawned_gid` int(10) unsigned DEFAULT NULL,
  `despawn_grace_until` datetime DEFAULT NULL,
  `last_spawned_at` datetime DEFAULT NULL,
  `last_despawned_at` datetime DEFAULT NULL,
  `last_parked_at` datetime DEFAULT NULL,
  `last_route_key` varchar(64) NOT NULL default '',
  `last_seen_tick` bigint(20) NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `current_map` (`current_map`),
  KEY `park_state` (`park_state`)
) ENGINE=InnoDB;
