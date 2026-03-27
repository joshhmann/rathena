DELETE FROM `bot_controller_policy`
WHERE `controller_key` IN ('guild.square.prontera', 'market.spill.alberta');

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `min_active_ms`, `restart_cooldown_ms`, `fair_weight`, `demand_users_step`, `demand_priority_step`, `demand_priority_cap`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('guild.square.prontera', 'HeadlessPronteraGuildQuarterController', 'Prontera guild quarter', 'event', 'prontera', 1, 1, 1, 89, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23),
  ('market.spill.alberta', 'HeadlessAlbertaMarketSpillController', 'Alberta market spill', 'merchant', 'alberta', 1, 1, 1, 87, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23)
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
  ('guild.square.prontera', 0, 0, 0, '', 0),
  ('market.spill.alberta', 0, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE
  `controller_key` = VALUES(`controller_key`);

DELETE FROM `bot_controller_demand_map`
WHERE `controller_key` IN ('guild.square.prontera', 'market.spill.alberta');

INSERT INTO `bot_controller_demand_map`
  (`controller_key`, `map_name`, `user_weight`, `point_index`)
VALUES
  ('guild.square.prontera', 'prontera', 2, 0),
  ('guild.square.prontera', 'prt_in', 1, 1),
  ('market.spill.alberta', 'alberta', 2, 0),
  ('market.spill.alberta', 'izlude', 1, 1)
ON DUPLICATE KEY UPDATE
  `user_weight` = VALUES(`user_weight`),
  `point_index` = VALUES(`point_index`);

DELETE FROM `bot_controller_demand_signal`
WHERE `controller_key` IN ('guild.square.prontera', 'market.spill.alberta');

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('guild.square.prontera', 0, 'guild_roster_name', 'PBG150001', 1),
  ('guild.square.prontera', 1, 'guild_notice_name', 'PBG150001', 1),
  ('guild.square.prontera', 2, 'guild_notice_recent_name', 'PBG150001', 2),
  ('guild.square.prontera', 3, 'guild_storage_name', 'PBG150001', 1),
  ('guild.square.prontera', 4, 'guild_castle_name', 'PBG150001', 2),
  ('market.spill.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('market.spill.alberta', 1, 'merchant_live_map', 'alberta', 1),
  ('market.spill.alberta', 2, 'merchant_browse_map', 'alberta', 2),
  ('market.spill.alberta', 3, 'merchant_sale_map', 'alberta', 2),
  ('market.spill.alberta', 4, 'merchant_stock_map', 'alberta', 1)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);

DELETE FROM `bot_controller_slot`
WHERE `controller_key` IN ('guild.square.prontera', 'market.spill.alberta');

INSERT INTO `bot_controller_slot`
  (`controller_key`, `slot_index`, `slot_label`, `pool_key`, `profile_key`, `role_key`, `map_name`, `spawn_x`, `spawn_y`, `loop_route`, `mode`, `pulse_profile`, `anchor_set_key`, `route_set_key`, `talk_set_key`, `emote_set_key`, `enabled`)
VALUES
  ('guild.square.prontera', 0, 'Guild Quarter Steward', 'pool.social.prontera', 'social.prontera.regular', 'square_regular', 'prontera', 155, 180, 0, 'hold', 'square_anchor_evening', '', '', 'guild.square.prontera.a', 'guild.square.prontera.a', 1),
  ('guild.square.prontera', 1, 'Notice Courier', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 154, 179, 1, 'loiter', 'square_loiter_busy', 'guild.square.prontera.courier', '', 'guild.square.prontera.b', 'guild.square.prontera.b', 1),
  ('market.spill.alberta', 0, 'Market Barker', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 51, 241, 0, 'hold', 'market_anchor_trade', '', '', 'market.spill.alberta.a', 'market.spill.alberta.a', 1),
  ('market.spill.alberta', 1, 'Dock Runner', 'pool.social.alberta', 'social.alberta.browser', 'market_browser', 'alberta', 46, 245, 1, 'patrol', 'market_loiter_browse', '', 'market.spill.alberta.loop', 'market.spill.alberta.b', 'market.spill.alberta.b', 1)
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
WHERE `set_key` IN ('guild.square.prontera.courier');

INSERT INTO `bot_controller_anchor_point`
  (`set_key`, `point_index`, `anchor_x`, `anchor_y`)
VALUES
  ('guild.square.prontera.courier', 0, 154, 179),
  ('guild.square.prontera.courier', 1, 157, 181),
  ('guild.square.prontera.courier', 2, 152, 182),
  ('guild.square.prontera.courier', 3, 150, 179)
ON DUPLICATE KEY UPDATE
  `anchor_x` = VALUES(`anchor_x`),
  `anchor_y` = VALUES(`anchor_y`);

DELETE FROM `bot_controller_talk_line`
WHERE `set_key` IN ('guild.square.prontera.a', 'guild.square.prontera.b', 'market.spill.alberta.a', 'market.spill.alberta.b');

INSERT INTO `bot_controller_talk_line`
  (`set_key`, `line_index`, `line_text`)
VALUES
  ('guild.square.prontera.a', 0, 'The guild quarter stays busy whenever fresh notices go up.'),
  ('guild.square.prontera.a', 1, 'Runners keep crossing this block when storage requests pile up.'),
  ('guild.square.prontera.b', 0, 'I have another message for the guild office.'),
  ('guild.square.prontera.b', 1, 'Someone from the roster is always checking the board.'),
  ('market.spill.alberta.a', 0, 'The market is spilling out into the harbor lane again.'),
  ('market.spill.alberta.a', 1, 'More buyers show up whenever the stalls keep moving stock.'),
  ('market.spill.alberta.b', 0, 'I keep circling between the docks and the counters.'),
  ('market.spill.alberta.b', 1, 'Sales like this pull half the harbor into the market.');

DELETE FROM `bot_controller_emote_value`
WHERE `set_key` IN ('guild.square.prontera.a', 'guild.square.prontera.b', 'market.spill.alberta.a', 'market.spill.alberta.b');

INSERT INTO `bot_controller_emote_value`
  (`set_key`, `emote_index`, `emotion`)
VALUES
  ('guild.square.prontera.a', 0, 7),
  ('guild.square.prontera.a', 1, 9),
  ('guild.square.prontera.b', 0, 4),
  ('guild.square.prontera.b', 1, 1),
  ('market.spill.alberta.a', 0, 1),
  ('market.spill.alberta.a', 1, 9),
  ('market.spill.alberta.b', 0, 10),
  ('market.spill.alberta.b', 1, 4);

DELETE FROM `bot_controller_route_point`
WHERE `set_key` IN ('market.spill.alberta.loop');

INSERT INTO `bot_controller_route_point`
  (`set_key`, `point_index`, `route_x`, `route_y`)
VALUES
  ('market.spill.alberta.loop', 0, 46, 245),
  ('market.spill.alberta.loop', 1, 50, 244),
  ('market.spill.alberta.loop', 2, 53, 241),
  ('market.spill.alberta.loop', 3, 49, 239)
ON DUPLICATE KEY UPDATE
  `route_x` = VALUES(`route_x`),
  `route_y` = VALUES(`route_y`);
