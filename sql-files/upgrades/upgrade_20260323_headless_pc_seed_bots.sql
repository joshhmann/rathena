-- Dev-only seed identities for headless_pc provisioning smoke tests.
-- Current headless_pc bring-up still loads real char rows by char_id through
-- char-server, so these are provisioned as normal account+character pairs.

INSERT IGNORE INTO `login` (
  `account_id`, `userid`, `user_pass`, `sex`, `email`, `group_id`, `state`,
  `unban_time`, `expiration_time`, `logincount`, `last_ip`,
  `character_slots`, `pincode`, `pincode_change`, `vip_time`, `old_group`,
  `web_auth_token_enabled`
) VALUES
  (2000010, 'botpc01', 'botpc01', 'M', 'botpc01@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000011, 'botpc02', 'botpc02', 'F', 'botpc02@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000012, 'botpc03', 'botpc03', 'M', 'botpc03@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000013, 'botpc04', 'botpc04', 'F', 'botpc04@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000014, 'botpc05', 'botpc05', 'M', 'botpc05@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000015, 'botpc06', 'botpc06', 'F', 'botpc06@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000016, 'botpc07', 'botpc07', 'M', 'botpc07@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000017, 'botpc08', 'botpc08', 'F', 'botpc08@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000018, 'botpc09', 'botpc09', 'M', 'botpc09@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0),
  (2000019, 'botpc10', 'botpc10', 'F', 'botpc10@local.test', 0, 0, 0, 0, 0, '', 0, '', 0, 0, 0, 0);

INSERT IGNORE INTO `char` (
  `char_id`, `account_id`, `char_num`, `name`, `class`, `base_level`,
  `job_level`, `zeny`, `str`, `agi`, `vit`, `int`, `dex`, `luk`, `max_hp`,
  `hp`, `max_sp`, `sp`, `status_point`, `skill_point`, `hair`, `hair_color`,
  `clothes_color`, `last_map`, `last_x`, `last_y`, `save_map`, `save_x`,
  `save_y`, `online`, `sex`
) VALUES
  (150010, 2000010, 0, 'BotPc01', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 156, 191, 'prontera', 156, 191, 0, 'M'),
  (150011, 2000011, 0, 'BotPc02', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 157, 191, 'prontera', 157, 191, 0, 'F'),
  (150012, 2000012, 0, 'BotPc03', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 158, 191, 'prontera', 158, 191, 0, 'M'),
  (150013, 2000013, 0, 'BotPc04', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 159, 191, 'prontera', 159, 191, 0, 'F'),
  (150014, 2000014, 0, 'BotPc05', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 160, 191, 'prontera', 160, 191, 0, 'M'),
  (150015, 2000015, 0, 'BotPc06', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 161, 191, 'prontera', 161, 191, 0, 'F'),
  (150016, 2000016, 0, 'BotPc07', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 162, 191, 'prontera', 162, 191, 0, 'M'),
  (150017, 2000017, 0, 'BotPc08', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 163, 191, 'prontera', 163, 191, 0, 'F'),
  (150018, 2000018, 0, 'BotPc09', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 164, 191, 'prontera', 164, 191, 0, 'M'),
  (150019, 2000019, 0, 'BotPc10', 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 40, 40, 11, 11, 48, 0, 1, 0, 0, 'prontera', 165, 191, 'prontera', 165, 191, 0, 'F');
