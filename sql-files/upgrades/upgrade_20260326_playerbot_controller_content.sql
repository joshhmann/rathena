CREATE TABLE IF NOT EXISTS `bot_controller_anchor_point` (
  `set_key` varchar(64) NOT NULL default '',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  `anchor_x` smallint(5) unsigned NOT NULL default '0',
  `anchor_y` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`set_key`,`point_index`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_controller_talk_line` (
  `set_key` varchar(64) NOT NULL default '',
  `line_index` smallint(5) unsigned NOT NULL default '0',
  `line_text` varchar(191) NOT NULL default '',
  PRIMARY KEY (`set_key`,`line_index`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `bot_controller_emote_value` (
  `set_key` varchar(64) NOT NULL default '',
  `emote_index` smallint(5) unsigned NOT NULL default '0',
  `emotion` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`set_key`,`emote_index`)
) ENGINE=InnoDB;

DELETE FROM `bot_controller_anchor_point`
WHERE `set_key` IN (
  'social.prontera.wanderer.a', 'social.prontera.wanderer.b', 'social.prontera.wanderer.c',
  'social.alberta.browser.a', 'social.alberta.harbor.a', 'social.alberta.browser.b'
);

INSERT INTO `bot_controller_anchor_point`
  (`set_key`, `point_index`, `anchor_x`, `anchor_y`)
VALUES
  ('social.prontera.wanderer.a', 0, 145, 184),
  ('social.prontera.wanderer.a', 1, 148, 187),
  ('social.prontera.wanderer.a', 2, 152, 184),
  ('social.prontera.wanderer.a', 3, 149, 182),
  ('social.prontera.wanderer.b', 0, 153, 188),
  ('social.prontera.wanderer.b', 1, 150, 190),
  ('social.prontera.wanderer.b', 2, 146, 189),
  ('social.prontera.wanderer.c', 0, 147, 190),
  ('social.prontera.wanderer.c', 1, 151, 189),
  ('social.prontera.wanderer.c', 2, 154, 186),
  ('social.alberta.browser.a', 0, 44, 243),
  ('social.alberta.browser.a', 1, 47, 246),
  ('social.alberta.browser.a', 2, 51, 244),
  ('social.alberta.browser.a', 3, 49, 241),
  ('social.alberta.harbor.a', 0, 45, 247),
  ('social.alberta.harbor.a', 1, 48, 242),
  ('social.alberta.harbor.a', 2, 52, 245),
  ('social.alberta.browser.b', 0, 43, 241),
  ('social.alberta.browser.b', 1, 46, 244),
  ('social.alberta.browser.b', 2, 50, 242);

DELETE FROM `bot_controller_talk_line`
WHERE `set_key` IN (
  'social.prontera.regular.a', 'social.prontera.regular.b',
  'social.prontera.wanderer.a', 'social.prontera.wanderer.b', 'social.prontera.wanderer.c',
  'social.alberta.regular.a', 'social.alberta.regular.b',
  'social.alberta.browser.a', 'social.alberta.harbor.a', 'social.alberta.browser.b',
  'merchant.alberta.stall.a'
);

INSERT INTO `bot_controller_talk_line`
  (`set_key`, `line_index`, `line_text`)
VALUES
  ('social.prontera.regular.a', 0, 'The south gate traffic never really stops.'),
  ('social.prontera.regular.a', 1, 'Keep moving and mind the square.'),
  ('social.prontera.regular.b', 0, 'Supplies from Alberta came in before noon.'),
  ('social.prontera.regular.b', 1, 'Shops are busy again today.'),
  ('social.prontera.wanderer.a', 0, 'I was told the Kafra queue clears by dusk.'),
  ('social.prontera.wanderer.a', 1, 'Prontera feels fuller every week.'),
  ('social.prontera.wanderer.b', 0, 'I only meant to pass through the square.'),
  ('social.prontera.wanderer.b', 1, 'Someone said the west gate road is crowded.'),
  ('social.prontera.wanderer.c', 0, 'I should decide whether I''m staying the night.'),
  ('social.prontera.wanderer.c', 1, 'The square''s louder than I expected.'),
  ('social.alberta.regular.a', 0, 'Fresh crates off the dock.'),
  ('social.alberta.regular.a', 1, 'Keep the lane clear for cargo.'),
  ('social.alberta.regular.b', 0, 'Dock orders are posted for the afternoon shift.'),
  ('social.alberta.regular.b', 1, 'Sea stock is moving fast today.'),
  ('social.alberta.browser.a', 0, 'Plenty of sellers out today.'),
  ('social.alberta.browser.a', 1, 'I heard another shipment came in.'),
  ('social.alberta.harbor.a', 0, 'No wonder Alberta stays busy.'),
  ('social.alberta.harbor.a', 1, 'The harbor never really rests.'),
  ('social.alberta.browser.b', 0, 'I''m looking for a fair price on fish.'),
  ('social.alberta.browser.b', 1, 'Someone said the curio stall moved again.'),
  ('merchant.alberta.stall.a', 0, 'Curios from the harbor and beyond.'),
  ('merchant.alberta.stall.a', 1, 'Take a look before the tide shifts again.');

DELETE FROM `bot_controller_emote_value`
WHERE `set_key` IN (
  'social.prontera.regular.a', 'social.prontera.regular.b',
  'social.prontera.wanderer.a', 'social.prontera.wanderer.b', 'social.prontera.wanderer.c',
  'social.alberta.regular.a', 'social.alberta.regular.b',
  'social.alberta.browser.a', 'social.alberta.harbor.a', 'social.alberta.browser.b',
  'merchant.alberta.stall.a'
);

INSERT INTO `bot_controller_emote_value`
  (`set_key`, `emote_index`, `emotion`)
VALUES
  ('social.prontera.regular.a', 0, 7),
  ('social.prontera.regular.a', 1, 1),
  ('social.prontera.regular.b', 0, 9),
  ('social.prontera.regular.b', 1, 4),
  ('social.prontera.wanderer.a', 0, 10),
  ('social.prontera.wanderer.a', 1, 11),
  ('social.prontera.wanderer.b', 0, 4),
  ('social.prontera.wanderer.b', 1, 9),
  ('social.prontera.wanderer.c', 0, 1),
  ('social.prontera.wanderer.c', 1, 18),
  ('social.alberta.regular.a', 0, 1),
  ('social.alberta.regular.a', 1, 7),
  ('social.alberta.regular.b', 0, 9),
  ('social.alberta.regular.b', 1, 4),
  ('social.alberta.browser.a', 0, 10),
  ('social.alberta.browser.a', 1, 4),
  ('social.alberta.harbor.a', 0, 1),
  ('social.alberta.harbor.a', 1, 9),
  ('social.alberta.browser.b', 0, 11),
  ('social.alberta.browser.b', 1, 18),
  ('merchant.alberta.stall.a', 0, 9),
  ('merchant.alberta.stall.a', 1, 7);
