CREATE TABLE IF NOT EXISTS `headless_pc_runtime` (
  `char_id` int(10) unsigned NOT NULL,
  `map_name` varchar(32) NOT NULL,
  `x` smallint(5) unsigned NOT NULL,
  `y` smallint(5) unsigned NOT NULL,
  `state` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`char_id`)
) ENGINE=MyISAM;
