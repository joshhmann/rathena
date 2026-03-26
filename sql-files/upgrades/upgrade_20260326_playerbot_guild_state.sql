CREATE TABLE IF NOT EXISTS `bot_guild_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `guild_policy` varchar(64) NOT NULL default '',
  `guild_name` varchar(64) NOT NULL default '',
  `guild_position` varchar(64) NOT NULL default '',
  `invite_policy` enum('never','selective','open') NOT NULL default 'never',
  `guild_member_state` enum('unguilded','candidate','member','officer','leader') NOT NULL default 'unguilded',
  `enabled` tinyint(1) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `guild_name` (`guild_name`),
  KEY `invite_policy` (`invite_policy`),
  KEY `guild_member_state` (`guild_member_state`),
  KEY `enabled` (`enabled`)
) ENGINE=InnoDB;

INSERT INTO `bot_guild_state`
  (`bot_id`, `guild_policy`, `guild_name`, `guild_position`, `invite_policy`, `guild_member_state`, `enabled`)
SELECT
  p.`bot_id`,
  '',
  '',
  '',
  'never',
  'unguilded',
  0
FROM `bot_profile` p
LEFT JOIN `bot_guild_state` g ON g.`bot_id` = p.`bot_id`
WHERE g.`bot_id` IS NULL;
