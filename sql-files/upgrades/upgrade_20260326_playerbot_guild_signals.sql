ALTER TABLE `bot_controller_demand_signal`
  MODIFY `signal_type` enum('merchant_open_map','merchant_live_map','merchant_stock_map','merchant_browse_map','merchant_sale_map','guild_enabled_name','guild_roster_name','guild_live_name','guild_candidate_map')
  NOT NULL default 'merchant_open_map';

DELETE FROM `bot_controller_demand_signal`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta');

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('social.prontera', 0, 'guild_candidate_map', 'prontera', 2),
  ('social.prontera', 1, 'guild_roster_name', 'PBG150001', 1),
  ('social.prontera', 2, 'guild_live_name', 'PBG150001', 2),
  ('patrol.prontera', 0, 'guild_candidate_map', 'prontera', 1),
  ('patrol.prontera', 1, 'guild_roster_name', 'PBG150001', 1),
  ('social.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('social.alberta', 1, 'merchant_stock_map', 'alberta', 1),
  ('social.alberta', 2, 'merchant_browse_map', 'alberta', 1),
  ('merchant.alberta', 0, 'merchant_open_map', 'alberta', 3),
  ('merchant.alberta', 1, 'merchant_live_map', 'alberta', 2),
  ('merchant.alberta', 2, 'merchant_stock_map', 'alberta', 1),
  ('merchant.alberta', 3, 'merchant_browse_map', 'alberta', 1),
  ('merchant.alberta', 4, 'merchant_sale_map', 'alberta', 2)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);
