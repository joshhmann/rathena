# Upgrade for playerbot shared world/social memory.

CREATE TABLE IF NOT EXISTS `bot_shared_memory` (
  `memory_id` bigint(20) unsigned NOT NULL auto_increment,
  `memory_scope` enum('map','social','guild','merchant','controller','resource') NOT NULL default 'map',
  `memory_key` varchar(96) NOT NULL default '',
  `int_value` int(11) NOT NULL default '0',
  `text_value` varchar(191) NOT NULL default '',
  `source_tag` varchar(64) NOT NULL default '',
  `expires_at` int(10) unsigned NOT NULL default '0',
  `updated_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`memory_id`),
  UNIQUE KEY `scope_key` (`memory_scope`,`memory_key`),
  KEY `expires_at` (`expires_at`),
  KEY `source_tag` (`source_tag`)
) ENGINE=InnoDB;
