# Upgrade for playerbot reservation ledger.

CREATE TABLE IF NOT EXISTS `bot_reservation` (
  `reservation_id` bigint(20) unsigned NOT NULL auto_increment,
  `type` enum('anchor','dialog_target','social_target','merchant_spot','party_role') NOT NULL default 'anchor',
  `resource_key` varchar(96) NOT NULL default '',
  `holder_bot_id` int(10) unsigned NOT NULL default '0',
  `holder_controller_id` varchar(64) NOT NULL default '',
  `lock_mode` enum('lease','hard_lock') NOT NULL default 'lease',
  `lease_until` int(10) unsigned NOT NULL default '0',
  `epoch` int(10) unsigned NOT NULL default '0',
  `priority` smallint(5) unsigned NOT NULL default '0',
  `reason` varchar(64) NOT NULL default '',
  `created_at` int(10) unsigned NOT NULL default '0',
  `updated_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`reservation_id`),
  UNIQUE KEY `type_resource` (`type`,`resource_key`),
  KEY `holder_bot_id` (`holder_bot_id`),
  KEY `holder_controller_id` (`holder_controller_id`),
  KEY `lease_until` (`lease_until`)
) ENGINE=InnoDB;
