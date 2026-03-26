CREATE TABLE IF NOT EXISTS `bot_merchant_stock_item` (
  `stock_profile` varchar(64) NOT NULL default '',
  `item_index` smallint(5) unsigned NOT NULL default '0',
  `item_id` int(10) unsigned NOT NULL default '0',
  `stock_amount` int(10) unsigned NOT NULL default '0',
  `sell_price` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`stock_profile`,`item_index`),
  KEY `item_id` (`item_id`)
) ENGINE=InnoDB;

DELETE FROM `bot_merchant_stock_item`
WHERE `stock_profile` IN ('alberta_curios');

INSERT INTO `bot_merchant_stock_item`
  (`stock_profile`, `item_index`, `item_id`, `stock_amount`, `sell_price`)
VALUES
  ('alberta_curios', 0, 909, 60, 0),
  ('alberta_curios', 1, 910, 30, 0),
  ('alberta_curios', 2, 911, 20, 0),
  ('alberta_curios', 3, 912, 10, 0)
ON DUPLICATE KEY UPDATE
  `item_id` = VALUES(`item_id`),
  `stock_amount` = VALUES(`stock_amount`),
  `sell_price` = VALUES(`sell_price`);
