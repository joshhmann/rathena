DELETE FROM `bot_controller_policy`
WHERE `controller_key` IN ('guild.watch.prontera', 'market.flow.alberta');

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `min_active_ms`, `restart_cooldown_ms`, `fair_weight`, `demand_users_step`, `demand_priority_step`, `demand_priority_cap`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('guild.watch.prontera', 'HeadlessPronteraGuildWatchController', 'Prontera guild watch', 'event', 'prontera', 1, 1, 1, 92, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23),
  ('market.flow.alberta', 'HeadlessAlbertaTradeFlowController', 'Alberta trade flow', 'merchant', 'alberta', 1, 1, 1, 88, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23)
ON DUPLICATE KEY UPDATE
  `controller_npc` = VALUES(`controller_npc`),
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
  ('guild.watch.prontera', 0, 0, 0, '', 0),
  ('market.flow.alberta', 0, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE
  `controller_key` = VALUES(`controller_key`);

DELETE FROM `bot_controller_demand_map`
WHERE `controller_key` IN ('guild.watch.prontera', 'market.flow.alberta');

INSERT INTO `bot_controller_demand_map`
  (`controller_key`, `map_name`, `user_weight`, `point_index`)
VALUES
  ('guild.watch.prontera', 'prontera', 2, 0),
  ('guild.watch.prontera', 'prt_in', 1, 1),
  ('market.flow.alberta', 'alberta', 2, 0),
  ('market.flow.alberta', 'izlude', 1, 1)
ON DUPLICATE KEY UPDATE
  `user_weight` = VALUES(`user_weight`),
  `point_index` = VALUES(`point_index`);

DELETE FROM `bot_controller_demand_signal`
WHERE `controller_key` IN ('guild.watch.prontera', 'market.flow.alberta');

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('guild.watch.prontera', 0, 'guild_roster_name', 'PBG150001', 1),
  ('guild.watch.prontera', 1, 'guild_leader_live_name', 'PBG150001', 2),
  ('guild.watch.prontera', 2, 'guild_join_recent_name', 'PBG150001', 2),
  ('guild.watch.prontera', 3, 'guild_notice_recent_name', 'PBG150001', 1),
  ('guild.watch.prontera', 4, 'guild_storage_log_name', 'PBG150001', 1),
  ('market.flow.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('market.flow.alberta', 1, 'merchant_browse_map', 'alberta', 2),
  ('market.flow.alberta', 2, 'merchant_sale_map', 'alberta', 2),
  ('market.flow.alberta', 3, 'merchant_stock_map', 'alberta', 1)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);

DELETE FROM `bot_controller_slot`
WHERE `controller_key` IN ('guild.watch.prontera', 'market.flow.alberta');

INSERT INTO `bot_controller_slot`
  (`controller_key`, `slot_index`, `slot_label`, `pool_key`, `profile_key`, `role_key`, `map_name`, `spawn_x`, `spawn_y`, `loop_route`, `mode`, `pulse_profile`, `anchor_set_key`, `route_set_key`, `talk_set_key`, `emote_set_key`, `enabled`)
VALUES
  ('guild.watch.prontera', 0, 'Guild Watch Captain', 'pool.social.prontera', 'social.prontera.regular', 'square_regular', 'prontera', 149, 191, 0, 'hold', 'square_anchor_evening', '', '', 'guild.watch.prontera.a', 'guild.watch.prontera.a', 1),
  ('guild.watch.prontera', 1, 'Guild Watch Runner', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 150, 189, 1, 'loiter', 'square_loiter_busy', 'guild.watch.prontera.runner', '', 'guild.watch.prontera.b', 'guild.watch.prontera.b', 1),
  ('market.flow.alberta', 0, 'Trade Crier', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 49, 242, 0, 'hold', 'market_anchor_trade', '', '', 'market.flow.alberta.a', 'market.flow.alberta.a', 1),
  ('market.flow.alberta', 1, 'Supply Runner', 'pool.social.alberta', 'social.alberta.browser', 'market_browser', 'alberta', 45, 243, 1, 'patrol', 'market_loiter_browse', '', 'market.flow.alberta.loop', 'market.flow.alberta.b', 'market.flow.alberta.b', 1)
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

DELETE FROM `bot_controller_anchor_point`
WHERE `set_key` IN ('guild.watch.prontera.runner');

INSERT INTO `bot_controller_anchor_point`
  (`set_key`, `point_index`, `anchor_x`, `anchor_y`)
VALUES
  ('guild.watch.prontera.runner', 0, 150, 189),
  ('guild.watch.prontera.runner', 1, 152, 191),
  ('guild.watch.prontera.runner', 2, 147, 192),
  ('guild.watch.prontera.runner', 3, 145, 189)
ON DUPLICATE KEY UPDATE
  `anchor_x` = VALUES(`anchor_x`),
  `anchor_y` = VALUES(`anchor_y`);

DELETE FROM `bot_controller_talk_line`
WHERE `set_key` IN ('guild.watch.prontera.a', 'guild.watch.prontera.b', 'market.flow.alberta.a', 'market.flow.alberta.b');

INSERT INTO `bot_controller_talk_line`
  (`set_key`, `line_index`, `line_text`)
VALUES
  ('guild.watch.prontera.a', 0, 'Guild notices changed again this morning.'),
  ('guild.watch.prontera.a', 1, 'Warehouse traffic picks up when members gather.'),
  ('guild.watch.prontera.b', 0, 'I was sent to check the guild quarter.'),
  ('guild.watch.prontera.b', 1, 'Someone always needs a runner when notices go up.'),
  ('market.flow.alberta.a', 0, 'Harbor sellers are moving stock fast today.'),
  ('market.flow.alberta.a', 1, 'If the stalls stay busy, more runners will show.'),
  ('market.flow.alberta.b', 0, 'Another buyer just left the dock stalls.'),
  ('market.flow.alberta.b', 1, 'Trade lanes stay hot whenever sales keep flowing.')
ON DUPLICATE KEY UPDATE
  `line_text` = VALUES(`line_text`);

DELETE FROM `bot_controller_emote_value`
WHERE `set_key` IN ('guild.watch.prontera.a', 'guild.watch.prontera.b', 'market.flow.alberta.a', 'market.flow.alberta.b');

INSERT INTO `bot_controller_emote_value`
  (`set_key`, `emote_index`, `emotion`)
VALUES
  ('guild.watch.prontera.a', 0, 1),
  ('guild.watch.prontera.a', 1, 7),
  ('guild.watch.prontera.b', 0, 4),
  ('guild.watch.prontera.b', 1, 9),
  ('market.flow.alberta.a', 0, 1),
  ('market.flow.alberta.a', 1, 9),
  ('market.flow.alberta.b', 0, 10),
  ('market.flow.alberta.b', 1, 4)
ON DUPLICATE KEY UPDATE
  `emotion` = VALUES(`emotion`);

DELETE FROM `bot_controller_route_point`
WHERE `set_key` IN ('market.flow.alberta.loop');

INSERT INTO `bot_controller_route_point`
  (`set_key`, `point_index`, `route_x`, `route_y`)
VALUES
  ('market.flow.alberta.loop', 0, 45, 243),
  ('market.flow.alberta.loop', 1, 49, 244),
  ('market.flow.alberta.loop', 2, 52, 242),
  ('market.flow.alberta.loop', 3, 47, 240)
ON DUPLICATE KEY UPDATE
  `route_x` = VALUES(`route_x`),
  `route_y` = VALUES(`route_y`);
