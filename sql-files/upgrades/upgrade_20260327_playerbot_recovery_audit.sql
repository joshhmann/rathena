CREATE TABLE IF NOT EXISTS `bot_recovery_audit` (
  `id` bigint(20) unsigned NOT NULL auto_increment,
  `ts` int(10) unsigned NOT NULL default '0',
  `bot_id` int(10) unsigned NOT NULL default '0',
  `char_id` int(10) unsigned NOT NULL default '0',
  `account_id` int(10) unsigned NOT NULL default '0',
  `authority` varchar(32) NOT NULL default '',
  `scope` varchar(32) NOT NULL default '',
  `action` varchar(32) NOT NULL default '',
  `state_before` varchar(191) NOT NULL default '',
  `state_after` varchar(191) NOT NULL default '',
  `result` varchar(16) NOT NULL default '',
  `detail` varchar(191) NOT NULL default '',
  PRIMARY KEY (`id`),
  KEY `ts` (`ts`),
  KEY `bot_id` (`bot_id`),
  KEY `char_id` (`char_id`),
  KEY `account_id` (`account_id`)
) ENGINE=InnoDB;
