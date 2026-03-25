-- Add behavior config for persistent playerbots and backfill the current
-- seeded Alberta/Prontera social identities into the SQL-backed pool model.

CREATE TABLE IF NOT EXISTS `bot_behavior_config` (
  `bot_id` int(10) unsigned NOT NULL,
  `profile_key` varchar(64) NOT NULL default '',
  `pool_key` varchar(64) NOT NULL default '',
  `controller_tag` varchar(64) NOT NULL default '',
  `interaction_policy` enum('ambient_only','clickable','party_candidate','merchant_candidate') NOT NULL default 'ambient_only',
  `party_policy` enum('never','selective','open') NOT NULL default 'never',
  `presence_policy` enum('always_on','demand_gated','schedule_gated','hybrid') NOT NULL default 'demand_gated',
  `routine_group` varchar(64) NOT NULL default '',
  `routine_start_hour` tinyint(3) unsigned NOT NULL default '0',
  `routine_end_hour` tinyint(3) unsigned NOT NULL default '0',
  `pulse_profile` varchar(64) NOT NULL default '',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `pool_key` (`pool_key`),
  KEY `profile_key` (`profile_key`),
  KEY `routine_group` (`routine_group`)
) ENGINE=InnoDB;

INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc01', 'BotPc01', 'active', 'social_regular', 'alberta', 'pool.social.alberta', 'night', 'social.alberta'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150010);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc02', 'BotPc02', 'active', 'social_regular', 'alberta', 'pool.social.alberta', 'night', 'social.alberta'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150011);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc03', 'BotPc03', 'active', 'social_regular', 'alberta', 'pool.social.alberta', 'night', 'social.alberta'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150012);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc04', 'BotPc04', 'active', 'social_regular', 'alberta', 'pool.social.alberta', 'night', 'social.alberta'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150013);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc05', 'BotPc05', 'active', 'social_regular', 'alberta', 'pool.social.alberta', 'night', 'social.alberta'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150014);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc06', 'BotPc06', 'active', 'social_regular', 'prontera', 'pool.social.prontera', 'day', 'social.prontera'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150015);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc07', 'BotPc07', 'active', 'social_regular', 'prontera', 'pool.social.prontera', 'day', 'social.prontera'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150016);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc08', 'BotPc08', 'active', 'social_regular', 'prontera', 'pool.social.prontera', 'day', 'social.prontera'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150017);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc09', 'BotPc09', 'active', 'social_regular', 'prontera', 'pool.social.prontera', 'day', 'social.prontera'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150018);
INSERT IGNORE INTO `bot_profile` (`bot_key`, `name`, `status`, `role`, `home_map`, `routine_pool`, `timezone_policy`, `personality_tag`)
SELECT 'botpc10', 'BotPc10', 'active', 'social_regular', 'prontera', 'pool.social.prontera', 'day', 'social.prontera'
FROM DUAL WHERE EXISTS (SELECT 1 FROM `char` WHERE `char_id` = 150019);

INSERT IGNORE INTO `bot_identity_link` (`bot_id`, `account_id`, `char_id`, `link_status`, `linked_at`)
SELECT p.`bot_id`, c.`account_id`, c.`char_id`, 'linked', NOW()
FROM `bot_profile` p
JOIN `char` c ON c.`name` = p.`name`
WHERE p.`bot_key` IN ('botpc01','botpc02','botpc03','botpc04','botpc05','botpc06','botpc07','botpc08','botpc09','botpc10');

INSERT IGNORE INTO `bot_appearance` (`bot_id`, `job_id`, `sex`, `hair_style`, `hair_color`, `cloth_color`, `weapon_view`, `shield_view`, `head_top`, `head_mid`, `head_bottom`, `robe`)
SELECT p.`bot_id`, c.`class`, c.`sex`, c.`hair`, c.`hair_color`, c.`clothes_color`, c.`weapon`, c.`shield`, c.`head_top`, c.`head_mid`, c.`head_bottom`, c.`robe`
FROM `bot_profile` p
JOIN `char` c ON c.`name` = p.`name`
WHERE p.`bot_key` IN ('botpc01','botpc02','botpc03','botpc04','botpc05','botpc06','botpc07','botpc08','botpc09','botpc10');

INSERT IGNORE INTO `bot_runtime_state` (`bot_id`, `current_map`, `current_x`, `current_y`, `current_state`, `park_state`, `spawned_gid`, `despawn_grace_until`, `last_spawned_at`, `last_despawned_at`, `last_parked_at`, `last_route_key`, `last_seen_tick`)
SELECT p.`bot_id`, c.`save_map`, c.`save_x`, c.`save_y`, 'offline', 'parked', NULL, NULL, NULL, NULL, NOW(), '', 0
FROM `bot_profile` p
JOIN `char` c ON c.`name` = p.`name`
WHERE p.`bot_key` IN ('botpc01','botpc02','botpc03','botpc04','botpc05','botpc06','botpc07','botpc08','botpc09','botpc10');

INSERT IGNORE INTO `bot_behavior_config` (`bot_id`, `profile_key`, `pool_key`, `controller_tag`, `interaction_policy`, `party_policy`, `presence_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`, `pulse_profile`)
SELECT p.`bot_id`, 'social.alberta', 'pool.social.alberta', '', 'ambient_only', 'never', 'demand_gated', 'night', 0, 6, 'market_anchor_day'
FROM `bot_profile` p
WHERE p.`bot_key` IN ('botpc01','botpc02','botpc03','botpc04','botpc05');

INSERT IGNORE INTO `bot_behavior_config` (`bot_id`, `profile_key`, `pool_key`, `controller_tag`, `interaction_policy`, `party_policy`, `presence_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`, `pulse_profile`)
SELECT p.`bot_id`, 'social.prontera', 'pool.social.prontera', '', 'ambient_only', 'never', 'demand_gated', 'day', 7, 23, 'square_anchor_day'
FROM `bot_profile` p
WHERE p.`bot_key` IN ('botpc06','botpc07','botpc08','botpc09','botpc10');
