CREATE TABLE IF NOT EXISTS `bot_progression_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `build_tag` varchar(64) NOT NULL default '',
  `progression_profile` varchar(64) NOT NULL default '',
  `base_level` smallint(5) unsigned NOT NULL default '1',
  `job_level` smallint(5) unsigned NOT NULL default '1',
  `equipment_profile` varchar(64) NOT NULL default '',
  `daily_activity_budget` smallint(5) unsigned NOT NULL default '0',
  `last_progression_tick` int(10) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `progression_profile` (`progression_profile`),
  KEY `last_progression_tick` (`last_progression_tick`)
) ENGINE=InnoDB;

INSERT IGNORE INTO `bot_progression_state`
(`bot_id`, `build_tag`, `progression_profile`, `base_level`, `job_level`, `equipment_profile`, `daily_activity_budget`, `last_progression_tick`)
SELECT p.`bot_id`,
       'starter',
       'starter',
       GREATEST(1, c.`base_level`),
       GREATEST(1, c.`job_level`),
       'starter',
       1,
       UNIX_TIMESTAMP()
FROM `bot_profile` p
JOIN `bot_identity_link` l ON l.`bot_id` = p.`bot_id`
JOIN `char` c ON c.`char_id` = l.`char_id`;
