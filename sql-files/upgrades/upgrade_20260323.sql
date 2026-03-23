CREATE TABLE IF NOT EXISTS `headless_pc_lifecycle` (
  `char_id` int(10) unsigned NOT NULL,
  `spawn_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `remove_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `reconcile_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `walk_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `reconcile_result` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`char_id`)
) ENGINE=MyISAM;

ALTER TABLE `headless_pc_lifecycle`
  ADD COLUMN IF NOT EXISTS `walk_ack_seq` int(10) unsigned NOT NULL DEFAULT '0' AFTER `reconcile_ack_seq`;
