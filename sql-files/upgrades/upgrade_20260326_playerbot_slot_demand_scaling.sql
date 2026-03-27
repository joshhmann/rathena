ALTER TABLE `bot_controller_slot`
  ADD COLUMN IF NOT EXISTS `min_demand_users` int(10) unsigned NOT NULL default '0' AFTER `emote_set_key`;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 0
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta', 'guild.watch.prontera', 'guild.square.prontera', 'market.flow.alberta', 'market.spill.alberta');

UPDATE `bot_controller_slot`
SET `min_demand_users` = 2
WHERE `controller_key` = 'social.prontera' AND `slot_index` = 2;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 4
WHERE `controller_key` = 'social.prontera' AND `slot_index` = 3;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 6
WHERE `controller_key` = 'social.prontera' AND `slot_index` = 4;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 3
WHERE `controller_key` = 'patrol.prontera' AND `slot_index` = 0;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 1
WHERE `controller_key` = 'social.alberta' AND `slot_index` = 1;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 3
WHERE `controller_key` = 'social.alberta' AND `slot_index` = 2;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 2
WHERE `controller_key` = 'merchant.alberta' AND `slot_index` = 0;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 1
WHERE `controller_key` = 'guild.watch.prontera' AND `slot_index` = 0;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 4
WHERE `controller_key` = 'guild.watch.prontera' AND `slot_index` = 1;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 2
WHERE `controller_key` = 'guild.square.prontera' AND `slot_index` = 0;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 5
WHERE `controller_key` = 'guild.square.prontera' AND `slot_index` = 1;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 2
WHERE `controller_key` = 'market.flow.alberta' AND `slot_index` = 0;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 5
WHERE `controller_key` = 'market.flow.alberta' AND `slot_index` = 1;

UPDATE `bot_controller_slot`
SET `min_demand_users` = 6
WHERE `controller_key` = 'market.spill.alberta' AND `slot_index` = 0;
