UPDATE `bot_profile`
SET
  `role` = 'market_runner',
  `routine_pool` = 'pool.trade.alberta',
  `personality_tag` = 'market.alberta.runner'
WHERE `bot_key` IN ('botpc03', 'botpc05');

UPDATE `bot_behavior_config`
SET
  `pool_key` = 'pool.trade.alberta',
  `profile_key` = 'market.alberta.runner',
  `controller_tag` = 'market.alberta.runner',
  `interaction_policy` = 'ambient_only',
  `presence_policy` = 'demand_gated',
  `routine_group` = 'day',
  `routine_start_hour` = 8,
  `routine_end_hour` = 22,
  `pulse_profile` = 'market_loiter_browse'
WHERE `bot_id` IN (
  SELECT `bot_id` FROM `bot_profile` WHERE `bot_key` IN ('botpc03', 'botpc05')
);

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `min_active_ms`, `restart_cooldown_ms`, `fair_weight`, `demand_users_step`, `demand_priority_step`, `demand_priority_cap`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('social.alberta', 'HeadlessAlbertaSocialController', 'Alberta social', 'social', 'alberta', 1, 1, 1, 80, 3, 2400, 500, 1800, 15000, 60000, 20000, 3, 2, 2, 8, 'park', 'night', 0, 6),
  ('market.spill.alberta', 'HeadlessAlbertaMarketSpillController', 'Alberta market spill', 'merchant', 'alberta', 1, 1, 1, 87, 1, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23)
ON DUPLICATE KEY UPDATE
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

DELETE FROM `bot_controller_slot`
WHERE `controller_key` IN ('social.alberta', 'guild.watch.prontera', 'guild.square.prontera', 'market.flow.alberta', 'market.spill.alberta');

INSERT INTO `bot_controller_slot`
  (`controller_key`, `slot_index`, `slot_label`, `pool_key`, `profile_key`, `role_key`, `map_name`, `spawn_x`, `spawn_y`, `loop_route`, `mode`, `pulse_profile`, `anchor_set_key`, `route_set_key`, `talk_set_key`, `emote_set_key`, `enabled`)
VALUES
  ('social.alberta', 0, 'Dock Regular A', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 47, 245, 0, 'hold', 'market_anchor_day', '', '', 'social.alberta.regular.a', 'social.alberta.regular.a', 1),
  ('social.alberta', 1, 'Dock Regular B', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 50, 244, 0, 'hold', 'market_anchor_trade', '', '', 'social.alberta.regular.b', 'social.alberta.regular.b', 1),
  ('social.alberta', 2, 'Harbor Wanderer', 'pool.social.alberta', 'social.alberta.harbor', 'harbor_wanderer', 'alberta', 45, 247, 1, 'loiter', 'mh', 'social.alberta.harbor.a', '', 'social.alberta.harbor.a', 'social.alberta.harbor.a', 1),
  ('guild.watch.prontera', 0, 'Guild Watch Captain', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 149, 191, 0, 'hold', 'square_anchor_evening', '', '', 'guild.watch.prontera.a', 'guild.watch.prontera.a', 1),
  ('guild.watch.prontera', 1, 'Guild Watch Runner', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 150, 189, 1, 'loiter', 'square_loiter_busy', 'guild.watch.prontera.runner', '', 'guild.watch.prontera.b', 'guild.watch.prontera.b', 1),
  ('guild.square.prontera', 0, 'Guild Quarter Steward', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 155, 180, 0, 'hold', 'square_anchor_evening', '', '', 'guild.square.prontera.a', 'guild.square.prontera.a', 1),
  ('guild.square.prontera', 1, 'Notice Courier', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 154, 179, 1, 'loiter', 'square_loiter_busy', 'guild.square.prontera.courier', '', 'guild.square.prontera.b', 'guild.square.prontera.b', 1),
  ('market.flow.alberta', 0, 'Trade Crier', 'pool.trade.alberta', 'market.alberta.runner', 'market_runner', 'alberta', 49, 242, 0, 'hold', 'market_anchor_trade', '', '', 'market.flow.alberta.a', 'market.flow.alberta.a', 1),
  ('market.flow.alberta', 1, 'Supply Runner', 'pool.trade.alberta', 'market.alberta.runner', 'market_runner', 'alberta', 45, 243, 1, 'patrol', 'market_loiter_browse', '', 'market.flow.alberta.loop', 'market.flow.alberta.b', 'market.flow.alberta.b', 1),
  ('market.spill.alberta', 0, 'Market Barker', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 51, 241, 0, 'hold', 'market_anchor_trade', '', '', 'market.spill.alberta.a', 'market.spill.alberta.a', 1)
ON DUPLICATE KEY UPDATE
  `slot_label` = VALUES(`slot_label`),
  `pool_key` = VALUES(`pool_key`),
  `profile_key` = VALUES(`profile_key`),
  `role_key` = VALUES(`role_key`),
  `map_name` = VALUES(`map_name`),
  `spawn_x` = VALUES(`spawn_x`),
  `spawn_y` = VALUES(`spawn_y`),
  `loop_route` = VALUES(`loop_route`),
  `mode` = VALUES(`mode`),
  `pulse_profile` = VALUES(`pulse_profile`),
  `anchor_set_key` = VALUES(`anchor_set_key`),
  `route_set_key` = VALUES(`route_set_key`),
  `talk_set_key` = VALUES(`talk_set_key`),
  `emote_set_key` = VALUES(`emote_set_key`),
  `enabled` = VALUES(`enabled`);
