CREATE TABLE IF NOT EXISTS `bot_controller_route_point` (
  `set_key` varchar(64) NOT NULL default '',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  `route_x` smallint(5) unsigned NOT NULL default '0',
  `route_y` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`set_key`,`point_index`)
) ENGINE=InnoDB;

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('patrol.prontera', 'HeadlessPronteraPatrolController', 'Prontera patrol', 'social', 'prontera', 0, 1, 1, 70, 1, 2400, 300, 900, 10000, 'park', 'day', 8, 22)
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
  `stop_policy` = VALUES(`stop_policy`),
  `routine_group` = VALUES(`routine_group`),
  `routine_start_hour` = VALUES(`routine_start_hour`),
  `routine_end_hour` = VALUES(`routine_end_hour`);

DELETE FROM `bot_controller_slot`
WHERE `controller_key` IN ('patrol.prontera');

INSERT INTO `bot_controller_slot`
  (`controller_key`, `slot_index`, `slot_label`, `pool_key`, `profile_key`, `role_key`, `map_name`, `spawn_x`, `spawn_y`, `loop_route`, `mode`, `pulse_profile`, `anchor_set_key`, `route_set_key`, `talk_set_key`, `emote_set_key`, `enabled`)
VALUES
  ('patrol.prontera', 0, 'Square Patrol', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 160, 186, 1, 'patrol', 'square_loiter_busy', '', 'patrol.prontera.loop', '', '', 1);

DELETE FROM `bot_controller_route_point`
WHERE `set_key` IN ('patrol.prontera.loop');

INSERT INTO `bot_controller_route_point`
  (`set_key`, `point_index`, `route_x`, `route_y`)
VALUES
  ('patrol.prontera.loop', 0, 160, 186),
  ('patrol.prontera.loop', 1, 163, 186),
  ('patrol.prontera.loop', 2, 163, 189),
  ('patrol.prontera.loop', 3, 160, 189);
