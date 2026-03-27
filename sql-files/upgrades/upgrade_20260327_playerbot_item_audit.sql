ALTER TABLE `bot_shared_memory`
  ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_item_audit` (
  `id` bigint(20) unsigned NOT NULL auto_increment,
  `ts` int(10) unsigned NOT NULL default '0',
  `bot_id` int(10) unsigned NOT NULL default '0',
  `char_id` int(10) unsigned NOT NULL default '0',
  `account_id` int(10) unsigned NOT NULL default '0',
  `action` enum('inventory_add','inventory_remove','equip','unequip','storage_deposit','storage_withdraw') NOT NULL default 'inventory_add',
  `item_id` int(10) unsigned NOT NULL default '0',
  `amount` int(10) unsigned NOT NULL default '0',
  `location` enum('inventory','equipped','storage') NOT NULL default 'inventory',
  `result` enum('ok','denied','invalid','missing','overflow','failed') NOT NULL default 'ok',
  `detail` varchar(191) NOT NULL default '',
  PRIMARY KEY (`id`),
  KEY `ts` (`ts`),
  KEY `bot_id` (`bot_id`),
  KEY `char_id` (`char_id`),
  KEY `account_id` (`account_id`),
  KEY `action` (`action`),
  KEY `item_id` (`item_id`)
) ENGINE=InnoDB;
