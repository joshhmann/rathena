ALTER TABLE `bot_controller_policy`
  ADD COLUMN IF NOT EXISTS `fair_weight` smallint(5) unsigned NOT NULL default '1' AFTER `restart_cooldown_ms`,
  ADD COLUMN IF NOT EXISTS `demand_users_step` smallint(5) unsigned NOT NULL default '1' AFTER `fair_weight`,
  ADD COLUMN IF NOT EXISTS `demand_priority_step` smallint(5) unsigned NOT NULL default '0' AFTER `demand_users_step`,
  ADD COLUMN IF NOT EXISTS `demand_priority_cap` smallint(5) unsigned NOT NULL default '0' AFTER `demand_priority_step`;

CREATE TABLE IF NOT EXISTS `bot_controller_runtime` (
  `controller_key` varchar(64) NOT NULL default '',
  `last_started_at` int(10) unsigned NOT NULL default '0',
  `last_stopped_at` int(10) unsigned NOT NULL default '0',
  `last_selected_at` int(10) unsigned NOT NULL default '0',
  `last_decision` varchar(191) NOT NULL default '',
  `last_tick_at` int(10) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`controller_key`)
) ENGINE=InnoDB;

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `min_active_ms`, `restart_cooldown_ms`, `fair_weight`, `demand_users_step`, `demand_priority_step`, `demand_priority_cap`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('social.prontera', 'HeadlessPronteraSocialController', 'Prontera social', 'social', 'prontera', 1, 1, 1, 90, 5, 2200, 400, 1500, 12000, 45000, 15000, 3, 2, 2, 8, 'park', 'day', 7, 23),
  ('patrol.prontera', 'HeadlessPronteraPatrolController', 'Prontera patrol', 'social', 'prontera', 0, 1, 1, 70, 1, 2400, 300, 900, 10000, 30000, 15000, 1, 3, 1, 4, 'park', 'day', 8, 22),
  ('social.alberta', 'HeadlessAlbertaSocialController', 'Alberta social', 'social', 'alberta', 1, 1, 1, 80, 5, 2400, 500, 1800, 15000, 60000, 20000, 3, 2, 2, 8, 'park', 'night', 0, 6),
  ('merchant.alberta', 'HeadlessAlbertaMerchantController', 'Alberta merchants', 'merchant', 'alberta', 1, 1, 1, 85, 1, 2600, 600, 1600, 18000, 90000, 30000, 2, 4, 1, 3, 'park', 'day', 8, 22)
ON DUPLICATE KEY UPDATE
  `controller_label` = VALUES(`controller_label`),
  `controller_type` = VALUES(`controller_type`),
  `map_name` = VALUES(`map_name`),
  `scheduler_enabled` = VALUES(`scheduler_enabled`),
  `controller_enabled` = VALUES(`controller_enabled`),
  `gate_users` = VALUES(`gate_users`),
  `priority` = VALUES(`priority`),
  `actor_weight` = VALUES(`actor_weight`),
  `tick_ms` = VALUES(`tick_ms`),
  `start_min_ms` = VALUES(`start_min_ms`),
  `start_max_ms` = VALUES(`start_max_ms`),
  `grace_ms` = VALUES(`grace_ms`),
  `min_active_ms` = VALUES(`min_active_ms`),
  `restart_cooldown_ms` = VALUES(`restart_cooldown_ms`),
  `fair_weight` = VALUES(`fair_weight`),
  `demand_users_step` = VALUES(`demand_users_step`),
  `demand_priority_step` = VALUES(`demand_priority_step`),
  `demand_priority_cap` = VALUES(`demand_priority_cap`),
  `stop_policy` = VALUES(`stop_policy`),
  `routine_group` = VALUES(`routine_group`),
  `routine_start_hour` = VALUES(`routine_start_hour`),
  `routine_end_hour` = VALUES(`routine_end_hour`);

INSERT INTO `bot_controller_runtime`
  (`controller_key`, `last_started_at`, `last_stopped_at`, `last_selected_at`, `last_decision`, `last_tick_at`)
VALUES
  ('social.prontera', 0, 0, 0, '', 0),
  ('patrol.prontera', 0, 0, 0, '', 0),
  ('social.alberta', 0, 0, 0, '', 0),
  ('merchant.alberta', 0, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE
  `controller_key` = VALUES(`controller_key`);
