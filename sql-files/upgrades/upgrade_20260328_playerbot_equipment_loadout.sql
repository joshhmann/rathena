CREATE TABLE IF NOT EXISTS `bot_equipment_loadout` (
  `bot_id` int(10) unsigned NOT NULL,
  `equip_location` int(10) unsigned NOT NULL default '0',
  `item_id` int(10) unsigned NOT NULL default '0',
  `required` tinyint(1) unsigned NOT NULL default '1',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`,`equip_location`),
  KEY `item_id` (`item_id`),
  KEY `required` (`required`)
) ENGINE=InnoDB;
