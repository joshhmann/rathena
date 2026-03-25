-- Refine seeded recurring bots into role/profile-backed pools for controller assignment.

UPDATE `bot_profile`
SET `role` = 'dock_regular'
WHERE `name` IN ('BotPc01', 'BotPc02');

UPDATE `bot_profile`
SET `role` = 'market_browser'
WHERE `name` IN ('BotPc03', 'BotPc05');

UPDATE `bot_profile`
SET `role` = 'harbor_wanderer'
WHERE `name` = 'BotPc04';

UPDATE `bot_profile`
SET `role` = 'square_regular'
WHERE `name` IN ('BotPc06', 'BotPc07');

UPDATE `bot_profile`
SET `role` = 'square_wanderer'
WHERE `name` IN ('BotPc08', 'BotPc09', 'BotPc10');

UPDATE `bot_profile`
SET `role` = 'party_candidate'
WHERE `bot_key` = 'quick_party_open';

UPDATE `bot_behavior_config`
SET `profile_key` = 'social.alberta.regular'
WHERE `bot_id` IN (SELECT `bot_id` FROM `bot_profile` WHERE `name` IN ('BotPc01', 'BotPc02'));

UPDATE `bot_behavior_config`
SET `profile_key` = 'social.alberta.browser'
WHERE `bot_id` IN (SELECT `bot_id` FROM `bot_profile` WHERE `name` IN ('BotPc03', 'BotPc05'));

UPDATE `bot_behavior_config`
SET `profile_key` = 'social.alberta.harbor'
WHERE `bot_id` IN (SELECT `bot_id` FROM `bot_profile` WHERE `name` = 'BotPc04');

UPDATE `bot_behavior_config`
SET `profile_key` = 'social.prontera.regular'
WHERE `bot_id` IN (SELECT `bot_id` FROM `bot_profile` WHERE `name` IN ('BotPc06', 'BotPc07'));

UPDATE `bot_behavior_config`
SET `profile_key` = 'social.prontera.wanderer'
WHERE `bot_id` IN (SELECT `bot_id` FROM `bot_profile` WHERE `name` IN ('BotPc08', 'BotPc09', 'BotPc10'));

UPDATE `bot_behavior_config`
SET `profile_key` = 'party.prontera.open'
WHERE `bot_id` IN (SELECT `bot_id` FROM `bot_profile` WHERE `bot_key` = 'quick_party_open');
