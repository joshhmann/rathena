CREATE TABLE IF NOT EXISTS `bot_merchant_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `merchant_policy` varchar(64) NOT NULL default '',
  `shop_name` varchar(64) NOT NULL default '',
  `market_map` varchar(32) NOT NULL default '',
  `market_x` smallint(5) unsigned NOT NULL default '0',
  `market_y` smallint(5) unsigned NOT NULL default '0',
  `opening_start_hour` tinyint(3) unsigned NOT NULL default '0',
  `opening_end_hour` tinyint(3) unsigned NOT NULL default '0',
  `stock_profile` varchar(64) NOT NULL default '',
  `price_profile` varchar(64) NOT NULL default '',
  `stall_style` enum('anchored','roaming','popup') NOT NULL default 'anchored',
  `open_state` enum('closed','scheduled','open') NOT NULL default 'scheduled',
  `enabled` tinyint(1) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `market_map` (`market_map`),
  KEY `open_state` (`open_state`),
  KEY `enabled` (`enabled`)
) ENGINE=InnoDB;

INSERT INTO `bot_merchant_state`
  (`bot_id`, `merchant_policy`, `shop_name`, `market_map`, `market_x`, `market_y`, `opening_start_hour`, `opening_end_hour`, `stock_profile`, `price_profile`, `stall_style`, `open_state`, `enabled`)
SELECT
  p.`bot_id`,
  '',
  '',
  p.`home_map`,
  0,
  0,
  0,
  0,
  '',
  '',
  'anchored',
  'closed',
  0
FROM `bot_profile` p
LEFT JOIN `bot_merchant_state` m ON m.`bot_id` = p.`bot_id`
WHERE m.`bot_id` IS NULL;
