--
-- Table structure for table `acc_reg_num`
--

CREATE TABLE IF NOT EXISTS `acc_reg_num` (
  `account_id` int(11) unsigned NOT NULL default '0',
  `key` varchar(32) binary NOT NULL default '',
  `index` int(11) unsigned NOT NULL default '0',
  `value` bigint(11) NOT NULL default '0',
  PRIMARY KEY (`account_id`,`key`,`index`),
  KEY `account_id` (`account_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `acc_reg_str`
--

CREATE TABLE IF NOT EXISTS `acc_reg_str` (
  `account_id` int(11) unsigned NOT NULL default '0',
  `key` varchar(32) binary NOT NULL default '',
  `index` int(11) unsigned NOT NULL default '0',
  `value` varchar(254) NOT NULL default '0',
  PRIMARY KEY (`account_id`,`key`,`index`),
  KEY `account_id` (`account_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `achievement`
--

CREATE TABLE IF NOT EXISTS `achievement` (
  `char_id` int(11) unsigned NOT NULL default '0',
  `id` bigint(11) unsigned NOT NULL,
  `count1` int unsigned NOT NULL default '0',
  `count2` int unsigned NOT NULL default '0',
  `count3` int unsigned NOT NULL default '0',
  `count4` int unsigned NOT NULL default '0',
  `count5` int unsigned NOT NULL default '0',
  `count6` int unsigned NOT NULL default '0',
  `count7` int unsigned NOT NULL default '0',
  `count8` int unsigned NOT NULL default '0',
  `count9` int unsigned NOT NULL default '0',
  `count10` int unsigned NOT NULL default '0',
  `completed` datetime,
  `rewarded` datetime,
  PRIMARY KEY (`char_id`,`id`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `auction`
--

CREATE TABLE IF NOT EXISTS `auction` (
  `auction_id` bigint(20) unsigned NOT NULL auto_increment,
  `seller_id` int(11) unsigned NOT NULL default '0',
  `seller_name` varchar(30) NOT NULL default '',
  `buyer_id` int(11) unsigned NOT NULL default '0',
  `buyer_name` varchar(30) NOT NULL default '',
  `price` int(11) unsigned NOT NULL default '0',
  `buynow` int(11) unsigned NOT NULL default '0',
  `hours` smallint(6) NOT NULL default '0',
  `timestamp` int(11) unsigned NOT NULL default '0',
  `nameid` int(10) unsigned NOT NULL default '0',
  `item_name` varchar(50) NOT NULL default '',
  `type` smallint(6) NOT NULL default '0',
  `refine` tinyint(3) unsigned NOT NULL default '0',
  `attribute` tinyint(4) unsigned NOT NULL default '0',
  `card0` int(10) unsigned NOT NULL default '0',
  `card1` int(10) unsigned NOT NULL default '0',
  `card2` int(10) unsigned NOT NULL default '0',
  `card3` int(10) unsigned NOT NULL default '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL default '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
  PRIMARY KEY  (`auction_id`)
) ENGINE=MyISAM;

--
-- Table `barter` for barter shop persistency
--

CREATE TABLE IF NOT EXISTS `barter` (
  `name` varchar(50) NOT NULL DEFAULT '',
  `index` SMALLINT(5) UNSIGNED NOT NULL,
  `amount` SMALLINT(5) UNSIGNED NOT NULL,
  PRIMARY KEY  (`name`,`index`)
) ENGINE=MyISAM;

--
-- Table structure for `db_roulette`
--

CREATE TABLE IF NOT EXISTS `db_roulette` (
  `index` int(11) NOT NULL default '0',
  `level` smallint(5) unsigned NOT NULL,
  `item_id` int(10) unsigned NOT NULL,
  `amount` smallint(5) unsigned NOT NULL DEFAULT '1',
  `flag` smallint(5) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`index`)
) ENGINE=MyISAM;

--
-- Table structure for table `bonus_script`
--

CREATE TABLE IF NOT EXISTS `bonus_script` (
  `char_id` INT(11) UNSIGNED NOT NULL,
  `script` TEXT NOT NULL,
  `tick` BIGINT(20) NOT NULL DEFAULT '0',
  `flag` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `type` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `icon` SMALLINT(3) NOT NULL DEFAULT '-1',
  KEY `char_id` (`char_id`)
) ENGINE=InnoDB;

--
-- Table structure for table `buyingstore_items`
--

CREATE TABLE IF NOT EXISTS `buyingstore_items` (
  `buyingstore_id` int(10) unsigned NOT NULL,
  `index` smallint(5) unsigned NOT NULL,
  `item_id` int(10) unsigned NOT NULL,
  `amount` smallint(5) unsigned NOT NULL,
  `price` int(10) unsigned NOT NULL,
  PRIMARY KEY (`buyingstore_id`, `index`)
) ENGINE=MyISAM;

--
-- Table structure for table `buyingstores`
--

CREATE TABLE IF NOT EXISTS `buyingstores` (
  `id` int(10) unsigned NOT NULL,
  `account_id` int(11) unsigned NOT NULL,
  `char_id` int(10) unsigned NOT NULL,
  `sex` enum('F','M') NOT NULL DEFAULT 'M',
  `map` varchar(20) NOT NULL,
  `x` smallint(5) unsigned NOT NULL,
  `y` smallint(5) unsigned NOT NULL,
  `title` varchar(80) NOT NULL,
  `limit` int(10) unsigned NOT NULL,
  `body_direction` CHAR( 1 ) NOT NULL DEFAULT '4',
  `head_direction` CHAR( 1 ) NOT NULL DEFAULT '0',
  `sit` CHAR( 1 ) NOT NULL DEFAULT '1',
  `autotrade` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM;

--
-- Table structure for table `cart_inventory`
--

CREATE TABLE IF NOT EXISTS `cart_inventory` (
  `id` int(11) NOT NULL auto_increment,
  `char_id` int(11) unsigned NOT NULL default '0',
  `nameid` int(10) unsigned NOT NULL default '0',
  `amount` int(11) NOT NULL default '0',
  `equip` int(11) unsigned NOT NULL default '0',
  `identify` smallint(6) NOT NULL default '0',
  `refine` tinyint(3) unsigned NOT NULL default '0',
  `attribute` tinyint(4) NOT NULL default '0',
  `card0` int(10) unsigned NOT NULL default '0',
  `card1` int(10) unsigned NOT NULL default '0',
  `card2` int(10) unsigned NOT NULL default '0',
  `card3` int(10) unsigned NOT NULL default '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `expire_time` int(11) unsigned NOT NULL default '0',
  `bound` tinyint(3) unsigned NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL default '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `char`
--

CREATE TABLE IF NOT EXISTS `char` (
  `char_id` int(11) unsigned NOT NULL auto_increment,
  `account_id` int(11) unsigned NOT NULL default '0',
  `char_num` tinyint(1) NOT NULL default '0',
  `name` varchar(30) NOT NULL DEFAULT '',
  `class` smallint(6) unsigned NOT NULL default '0',
  `base_level` smallint(6) unsigned NOT NULL default '1',
  `job_level` smallint(6) unsigned NOT NULL default '1',
  `base_exp` bigint(20) unsigned NOT NULL default '0',
  `job_exp` bigint(20) unsigned NOT NULL default '0',
  `zeny` int(11) unsigned NOT NULL default '0',
  `str` smallint(4) unsigned NOT NULL default '0',
  `agi` smallint(4) unsigned NOT NULL default '0',
  `vit` smallint(4) unsigned NOT NULL default '0',
  `int` smallint(4) unsigned NOT NULL default '0',
  `dex` smallint(4) unsigned NOT NULL default '0',
  `luk` smallint(4) unsigned NOT NULL default '0',
  `pow` smallint(4) unsigned NOT NULL default '0',
  `sta` smallint(4) unsigned NOT NULL default '0',
  `wis` smallint(4) unsigned NOT NULL default '0',
  `spl` smallint(4) unsigned NOT NULL default '0',
  `con` smallint(4) unsigned NOT NULL default '0',
  `crt` smallint(4) unsigned NOT NULL default '0',
  `max_hp` int(11) unsigned NOT NULL default '0',
  `hp` int(11) unsigned NOT NULL default '0',
  `max_sp` int(11) unsigned NOT NULL default '0',
  `sp` int(11) unsigned NOT NULL default '0',
  `max_ap` int(11) unsigned NOT NULL default '0',
  `ap` int(11) unsigned NOT NULL default '0',
  `status_point` int(11) unsigned NOT NULL default '0',
  `skill_point` int(11) unsigned NOT NULL default '0',
  `trait_point` int(11) unsigned NOT NULL default '0',
  `option` int(11) NOT NULL default '0',
  `karma` tinyint(3) NOT NULL default '0',
  `manner` smallint(6) NOT NULL default '0',
  `party_id` int(11) unsigned NOT NULL default '0',
  `guild_id` int(11) unsigned NOT NULL default '0',
  `pet_id` int(11) unsigned NOT NULL default '0',
  `homun_id` int(11) unsigned NOT NULL default '0',
  `elemental_id` int(11) unsigned NOT NULL default '0',
  `hair` tinyint(4) unsigned NOT NULL default '0',
  `hair_color` smallint(5) unsigned NOT NULL default '0',
  `clothes_color` smallint(5) unsigned NOT NULL default '0',
  `body` smallint(5) unsigned NOT NULL default '0',
  `weapon` smallint(6) unsigned NOT NULL default '0',
  `shield` smallint(6) unsigned NOT NULL default '0',
  `head_top` smallint(6) unsigned NOT NULL default '0',
  `head_mid` smallint(6) unsigned NOT NULL default '0',
  `head_bottom` smallint(6) unsigned NOT NULL default '0',
  `robe` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `last_map` varchar(11) NOT NULL default '',
  `last_x` smallint(4) unsigned NOT NULL default '53',
  `last_y` smallint(4) unsigned NOT NULL default '111',
  `last_instanceid` int(11) unsigned NOT NULL default '0',
  `save_map` varchar(11) NOT NULL default '',
  `save_x` smallint(4) unsigned NOT NULL default '53',
  `save_y` smallint(4) unsigned NOT NULL default '111',
  `partner_id` int(11) unsigned NOT NULL default '0',
  `online` tinyint(2) NOT NULL default '0',
  `father` int(11) unsigned NOT NULL default '0',
  `mother` int(11) unsigned NOT NULL default '0',
  `child` int(11) unsigned NOT NULL default '0',
  `fame` int(11) unsigned NOT NULL default '0',
  `rename` SMALLINT(3) unsigned NOT NULL default '0',
  `delete_date` INT(11) UNSIGNED NOT NULL DEFAULT '0',
  `moves` int(11) unsigned NOT NULL DEFAULT '0',
  `unban_time` int(11) unsigned NOT NULL default '0',
  `font` tinyint(3) unsigned NOT NULL default '0',
  `uniqueitem_counter` int(11) unsigned NOT NULL default '0',
  `sex` ENUM('M','F') NOT NULL,
  `hotkey_rowshift` tinyint(3) unsigned NOT NULL default '0',
  `hotkey_rowshift2` tinyint(3) unsigned NOT NULL default '0',
  `clan_id` int(11) unsigned NOT NULL default '0',
  `last_login` datetime DEFAULT NULL,
  `title_id` INT(11) unsigned NOT NULL default '0',
  `show_equip` tinyint(3) unsigned NOT NULL default '0',
  `inventory_slots` smallint(6) NOT NULL default '100',
  `body_direction` tinyint(1) unsigned NOT NULL default '0',
  `disable_call` tinyint(3) unsigned NOT NULL default '0',
  `disable_partyinvite` tinyint(1) unsigned NOT NULL default '0',
  `disable_showcostumes` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`char_id`),
  UNIQUE KEY `name_key` (`name`),
  KEY `account_id` (`account_id`),
  KEY `party_id` (`party_id`),
  KEY `guild_id` (`guild_id`),
  KEY `online` (`online`)
) ENGINE=MyISAM AUTO_INCREMENT=150000; 

--
-- Table structure for table `char_reg_num`
--

CREATE TABLE IF NOT EXISTS `char_reg_num` (
  `char_id` int(11) unsigned NOT NULL default '0',
  `key` varchar(32) binary NOT NULL default '',
  `index` int(11) unsigned NOT NULL default '0',
  `value` bigint(11) NOT NULL default '0',
  PRIMARY KEY (`char_id`,`key`,`index`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `char_reg_str`
--

CREATE TABLE IF NOT EXISTS `char_reg_str` (
  `char_id` int(11) unsigned NOT NULL default '0',
  `key` varchar(32) binary NOT NULL default '',
  `index` int(11) unsigned NOT NULL default '0',
  `value` varchar(254) NOT NULL default '0',
  PRIMARY KEY (`char_id`,`key`,`index`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `charlog`
--

CREATE TABLE IF NOT EXISTS `charlog` (
  `id` bigint(20) unsigned NOT NULL auto_increment,
  `time` datetime NOT NULL,
  `char_msg` varchar(255) NOT NULL default 'char select',
  `account_id` int(11) unsigned NOT NULL default '0',
  `char_num` tinyint(4) NOT NULL default '0',
  `name` varchar(23) NOT NULL default '',
  `str` int(11) unsigned NOT NULL default '0',
  `agi` int(11) unsigned NOT NULL default '0',
  `vit` int(11) unsigned NOT NULL default '0',
  `int` int(11) unsigned NOT NULL default '0',
  `dex` int(11) unsigned NOT NULL default '0',
  `luk` int(11) unsigned NOT NULL default '0',
  `hair` tinyint(4) NOT NULL default '0',
  `hair_color` int(11) NOT NULL default '0',
  PRIMARY KEY (`id`),
  KEY `account_id` (`account_id`)
) ENGINE=MyISAM; 

--
-- Table structure for table `clan`
--

CREATE TABLE IF NOT EXISTS `clan` (
  `clan_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(24) NOT NULL DEFAULT '',
  `master` varchar(24) NOT NULL DEFAULT '',
  `mapname` varchar(24) NOT NULL DEFAULT '',
  `max_member` smallint(6) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`clan_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5;

-- ----------------------------
-- Records of clan
-- ----------------------------

INSERT INTO `clan` VALUES ('1', 'Swordman Clan', 'Raffam Oranpere', 'prontera', '500');
INSERT INTO `clan` VALUES ('2', 'Arcwand Clan', 'Devon Aire', 'geffen', '500');
INSERT INTO `clan` VALUES ('3', 'Golden Mace Clan', 'Berman Aire', 'prontera', '500');
INSERT INTO `clan` VALUES ('4', 'Crossbow Clan', 'Shaam Rumi', 'payon', '500');

--
-- Table structure for `clan_alliance`
--

CREATE TABLE IF NOT EXISTS `clan_alliance` (
  `clan_id` int(11) unsigned NOT NULL DEFAULT '0',
  `opposition` int(11) unsigned NOT NULL DEFAULT '0',
  `alliance_id` int(11) unsigned NOT NULL DEFAULT '0',
  `name` varchar(24) NOT NULL DEFAULT '',
  PRIMARY KEY (`clan_id`,`alliance_id`),
  KEY `alliance_id` (`alliance_id`)
) ENGINE=MyISAM;

-- ----------------------------
-- Records of clan_alliance
-- ----------------------------

INSERT INTO `clan_alliance` VALUES ('1', '0', '3', 'Golden Mace Clan');
INSERT INTO `clan_alliance` VALUES ('2', '0', '3', 'Golden Mace Clan');
INSERT INTO `clan_alliance` VALUES ('2', '1', '4', 'Crossbow Clan');
INSERT INTO `clan_alliance` VALUES ('3', '0', '1', 'Swordman Clan');
INSERT INTO `clan_alliance` VALUES ('3', '0', '2', 'Arcwand Clan');
INSERT INTO `clan_alliance` VALUES ('3', '0', '4', 'Crossbow Clan');
INSERT INTO `clan_alliance` VALUES ('4', '0', '3', 'Golden Mace Clan');
INSERT INTO `clan_alliance` VALUES ('4', '1', '2', 'Arcwand Clan');

--
-- Table structure for table `elemental`
--

CREATE TABLE IF NOT EXISTS `elemental` (
  `ele_id` int(11) unsigned NOT NULL auto_increment,
  `char_id` int(11) unsigned NOT NULL,
  `class` mediumint(9) unsigned NOT NULL default '0',
  `mode` int(11) unsigned NOT NULL default '1',
  `hp` int(11) unsigned NOT NULL default '0',
  `sp` int(11) unsigned NOT NULL default '0',
  `max_hp` int(11) unsigned NOT NULL default '0',
  `max_sp` int(11) unsigned NOT NULL default '0',
  `atk1` MEDIUMINT(6) unsigned NOT NULL default '0',
  `atk2` MEDIUMINT(6) unsigned NOT NULL default '0',
  `matk` MEDIUMINT(6) unsigned NOT NULL default '0',
  `aspd` smallint(4) unsigned NOT NULL default '0',
  `def` smallint(4) unsigned NOT NULL default '0',
  `mdef` smallint(4) unsigned NOT NULL default '0',
  `flee` smallint(4) unsigned NOT NULL default '0',
  `hit` smallint(4) unsigned NOT NULL default '0',
  `life_time` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`ele_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `friends`
--

CREATE TABLE IF NOT EXISTS `friends` (
  `char_id` int(11) unsigned NOT NULL default '0',
  `friend_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY (`char_id`, `friend_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `global_acc_reg_num`
--

CREATE TABLE IF NOT EXISTS `global_acc_reg_num` (
  `account_id` int(11) unsigned NOT NULL default '0',
  `key` varchar(32) binary NOT NULL default '',
  `index` int(11) unsigned NOT NULL default '0',
  `value` bigint(11) NOT NULL default '0',
  PRIMARY KEY (`account_id`,`key`,`index`),
  KEY `account_id` (`account_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `global_acc_reg_str`
--

CREATE TABLE IF NOT EXISTS `global_acc_reg_str` (
  `account_id` int(11) unsigned NOT NULL default '0',
  `key` varchar(32) binary NOT NULL default '',
  `index` int(11) unsigned NOT NULL default '0',
  `value` varchar(254) NOT NULL default '0',
  PRIMARY KEY (`account_id`,`key`,`index`),
  KEY `account_id` (`account_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild`
--

CREATE TABLE IF NOT EXISTS `guild` (
  `guild_id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(24) NOT NULL default '',
  `char_id` int(11) unsigned NOT NULL default '0',
  `master` varchar(24) NOT NULL default '',
  `guild_lv` tinyint(6) unsigned NOT NULL default '0',
  `connect_member` tinyint(6) unsigned NOT NULL default '0',
  `max_member` tinyint(6) unsigned NOT NULL default '0',
  `average_lv` smallint(6) unsigned NOT NULL default '1',
  `exp` bigint(20) unsigned NOT NULL default '0',
  `next_exp` bigint(20) unsigned NOT NULL default '0',
  `skill_point` tinyint(11) unsigned NOT NULL default '0',
  `mes1` varchar(60) NOT NULL default '',
  `mes2` varchar(120) NOT NULL default '',
  `emblem_len` int(11) unsigned NOT NULL default '0',
  `emblem_id` int(11) unsigned NOT NULL default '0',
  `emblem_data` blob,
  `last_master_change` datetime,
  PRIMARY KEY  (`guild_id`,`char_id`),
  UNIQUE KEY `guild_id` (`guild_id`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_alliance`
--

CREATE TABLE IF NOT EXISTS `guild_alliance` (
  `guild_id` int(11) unsigned NOT NULL default '0',
  `opposition` int(11) unsigned NOT NULL default '0',
  `alliance_id` int(11) unsigned NOT NULL default '0',
  `name` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`guild_id`,`alliance_id`),
  KEY `alliance_id` (`alliance_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_castle`
--

CREATE TABLE IF NOT EXISTS `guild_castle` (
  `castle_id` int(11) unsigned NOT NULL default '0',
  `guild_id` int(11) unsigned NOT NULL default '0',
  `economy` int(11) unsigned NOT NULL default '0',
  `defense` int(11) unsigned NOT NULL default '0',
  `triggerE` int(11) unsigned NOT NULL default '0',
  `triggerD` int(11) unsigned NOT NULL default '0',
  `nextTime` int(11) unsigned NOT NULL default '0',
  `payTime` int(11) unsigned NOT NULL default '0',
  `createTime` int(11) unsigned NOT NULL default '0',
  `visibleC` int(11) unsigned NOT NULL default '0',
  `visibleG0` int(11) unsigned NOT NULL default '0',
  `visibleG1` int(11) unsigned NOT NULL default '0',
  `visibleG2` int(11) unsigned NOT NULL default '0',
  `visibleG3` int(11) unsigned NOT NULL default '0',
  `visibleG4` int(11) unsigned NOT NULL default '0',
  `visibleG5` int(11) unsigned NOT NULL default '0',
  `visibleG6` int(11) unsigned NOT NULL default '0',
  `visibleG7` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`castle_id`),
  KEY `guild_id` (`guild_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_expulsion`
--

CREATE TABLE IF NOT EXISTS `guild_expulsion` (
  `guild_id` int(11) unsigned NOT NULL default '0',
  `account_id` int(11) unsigned NOT NULL default '0',
  `name` varchar(24) NOT NULL default '',
  `mes` varchar(40) NOT NULL default '',
  `char_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`guild_id`,`name`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_member`
--

CREATE TABLE IF NOT EXISTS `guild_member` (
  `guild_id` int(11) unsigned NOT NULL default '0',
  `char_id` int(11) unsigned NOT NULL default '0',
  `exp` bigint(20) unsigned NOT NULL default '0',
  `position` tinyint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`guild_id`,`char_id`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_position`
--

CREATE TABLE IF NOT EXISTS `guild_position` (
  `guild_id` int(9) unsigned NOT NULL default '0',
  `position` tinyint(6) unsigned NOT NULL default '0',
  `name` varchar(24) NOT NULL default '',
  `mode` smallint(11) unsigned NOT NULL default '0',
  `exp_mode` tinyint(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`guild_id`,`position`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_skill`
--

CREATE TABLE IF NOT EXISTS `guild_skill` (
  `guild_id` int(11) unsigned NOT NULL default '0',
  `id` smallint(11) unsigned NOT NULL default '0',
  `lv` tinyint(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`guild_id`,`id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_storage`
--

CREATE TABLE IF NOT EXISTS `guild_storage` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guild_id` int(11) unsigned NOT NULL default '0',
  `nameid` int(10) unsigned NOT NULL default '0',
  `amount` int(11) unsigned NOT NULL default '0',
  `equip` int(11) unsigned NOT NULL default '0',
  `identify` smallint(6) unsigned NOT NULL default '0',
  `refine` tinyint(3) unsigned NOT NULL default '0',
  `attribute` tinyint(4) unsigned NOT NULL default '0',
  `card0` int(10) unsigned NOT NULL default '0',
  `card1` int(10) unsigned NOT NULL default '0',
  `card2` int(10) unsigned NOT NULL default '0',
  `card3` int(10) unsigned NOT NULL default '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `expire_time` int(11) unsigned NOT NULL default '0',
  `bound` tinyint(3) unsigned NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL default '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `guild_id` (`guild_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `guild_storage_log`
--

CREATE TABLE IF NOT EXISTS `guild_storage_log` (
  `id` int(11) NOT NULL auto_increment,
  `guild_id` int(11) unsigned NOT NULL default '0',
  `time` datetime NOT NULL,
  `char_id` int(11) NOT NULL default '0',
  `name` varchar(24) NOT NULL default '',
  `nameid` int(10) unsigned NOT NULL default '0',
  `amount` int(11) NOT NULL default '1',
  `identify` smallint(6) NOT NULL default '0',
  `refine` tinyint(3) unsigned NOT NULL default '0',
  `attribute` tinyint(4) unsigned NOT NULL default '0',
  `card0` int(10) unsigned NOT NULL default '0',
  `card1` int(10) unsigned NOT NULL default '0',
  `card2` int(10) unsigned NOT NULL default '0',
  `card3` int(10) unsigned NOT NULL default '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `expire_time` int(11) unsigned NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL default '0',
  `bound` tinyint(1) unsigned NOT NULL default '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  INDEX (`guild_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1;

--
-- Table structure for table `homunculus`
--

CREATE TABLE IF NOT EXISTS `homunculus` (
  `homun_id` int(11) NOT NULL auto_increment,
  `char_id` int(11) unsigned NOT NULL,
  `class` mediumint(9) unsigned NOT NULL default '0',
  `prev_class` mediumint(9) NOT NULL default '0',
  `name` varchar(24) NOT NULL default '',
  `level` smallint(4) NOT NULL default '0',
  `exp` bigint(20) unsigned NOT NULL default '0',
  `intimacy` int(12) NOT NULL default '0',
  `hunger` smallint(4) NOT NULL default '0',
  `str` smallint(4) unsigned NOT NULL default '0',
  `agi` smallint(4) unsigned NOT NULL default '0',
  `vit` smallint(4) unsigned NOT NULL default '0',
  `int` smallint(4) unsigned NOT NULL default '0',
  `dex` smallint(4) unsigned NOT NULL default '0',
  `luk` smallint(4) unsigned NOT NULL default '0',
  `hp` int(11) unsigned NOT NULL default '0',
  `max_hp` int(11) unsigned NOT NULL default '0',
  `sp` int(11) unsigned NOT NULL default '0',
  `max_sp` int(11) unsigned NOT NULL default '0',
  `skill_point` smallint(4) unsigned NOT NULL default '0',
  `alive` tinyint(2) NOT NULL default '1',
  `rename_flag` tinyint(2) NOT NULL default '0',
  `vaporize` tinyint(2) NOT NULL default '0',
  `autofeed` tinyint(2) NOT NULL default '0',
  PRIMARY KEY  (`homun_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `hotkey`
--

CREATE TABLE IF NOT EXISTS `hotkey` (
  `char_id` INT(11) unsigned NOT NULL,
  `hotkey` TINYINT(2) unsigned NOT NULL,
  `type` TINYINT(1) unsigned NOT NULL default '0',
  `itemskill_id` INT(11) unsigned NOT NULL default '0',
  `skill_lvl` TINYINT(4) unsigned NOT NULL default '0',
  PRIMARY KEY (`char_id`,`hotkey`)
) ENGINE=MyISAM;

-- 
-- Table structure for table `interlog`
--

CREATE TABLE IF NOT EXISTS `interlog` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `time` datetime NOT NULL,
  `log` varchar(255) NOT NULL default '',
  PRIMARY KEY (`id`),
  INDEX `time` (`time`)
) ENGINE=MyISAM;

--
-- Table structure for table `inventory`
--

CREATE TABLE IF NOT EXISTS `inventory` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `char_id` int(11) unsigned NOT NULL default '0',
  `nameid` int(10) unsigned NOT NULL default '0',
  `amount` int(11) unsigned NOT NULL default '0',
  `equip` int(11) unsigned NOT NULL default '0',
  `identify` smallint(6) NOT NULL default '0',
  `refine` tinyint(3) unsigned NOT NULL default '0',
  `attribute` tinyint(4) unsigned NOT NULL default '0',
  `card0` int(10) unsigned NOT NULL default '0',
  `card1` int(10) unsigned NOT NULL default '0',
  `card2` int(10) unsigned NOT NULL default '0',
  `card3` int(10) unsigned NOT NULL default '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `expire_time` int(11) unsigned NOT NULL default '0',
  `favorite` tinyint(3) unsigned NOT NULL default '0',
  `bound` tinyint(3) unsigned NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL default '0',
  `equip_switch` int(11) unsigned NOT NULL default '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `ipbanlist`
--

CREATE TABLE IF NOT EXISTS `ipbanlist` (
  `list` varchar(15) NOT NULL default '',
  `btime` datetime NOT NULL,
  `rtime` datetime NOT NULL,
  `reason` varchar(255) NOT NULL default '',
  PRIMARY KEY (`list`, `btime`)
) ENGINE=MyISAM;

--
-- Table structure for table `login`
--

CREATE TABLE IF NOT EXISTS `login` (
  `account_id` int(11) unsigned NOT NULL auto_increment,
  `userid` varchar(23) NOT NULL default '',
  `user_pass` varchar(32) NOT NULL default '',
  `sex` enum('M','F','S') NOT NULL default 'M',
  `email` varchar(39) NOT NULL default '',
  `group_id` tinyint(3) NOT NULL default '0',
  `state` int(11) unsigned NOT NULL default '0',
  `unban_time` int(11) unsigned NOT NULL default '0',
  `expiration_time` int(11) unsigned NOT NULL default '0',
  `logincount` mediumint(9) unsigned NOT NULL default '0',
  `lastlogin` datetime,
  `last_ip` varchar(100) NOT NULL default '',
  `birthdate` DATE,
  `character_slots` tinyint(3) unsigned NOT NULL default '0',
  `pincode` varchar(4) NOT NULL DEFAULT '',
  `pincode_change` int(11) unsigned NOT NULL DEFAULT '0',
  `vip_time` int(11) unsigned NOT NULL default '0',
  `old_group` tinyint(3) NOT NULL default '0',
  `web_auth_token` varchar(17) null,
  `web_auth_token_enabled` tinyint(2) NOT NULL default '0',
  PRIMARY KEY  (`account_id`),
  KEY `name` (`userid`),
  UNIQUE KEY `web_auth_token_key` (`web_auth_token`)
) ENGINE=MyISAM AUTO_INCREMENT=2000000; 

-- added standard accounts for servers, VERY INSECURE!!!
-- inserted into the table called login which is above

INSERT INTO `login` (`account_id`, `userid`, `user_pass`, `sex`, `email`) VALUES ('1', 's1', 'p1', 'S','athena@athena.com');

--
-- Table structure for table `mail`
--

CREATE TABLE IF NOT EXISTS `mail` (
  `id` bigint(20) unsigned NOT NULL auto_increment,
  `send_name` varchar(30) NOT NULL default '',
  `send_id` int(11) unsigned NOT NULL default '0',
  `dest_name` varchar(30) NOT NULL default '',
  `dest_id` int(11) unsigned NOT NULL default '0',
  `title` varchar(45) NOT NULL default '',
  `message` varchar(500) NOT NULL default '',
  `time` int(11) unsigned NOT NULL default '0',
  `status` tinyint(2) NOT NULL default '0',
  `zeny` int(11) unsigned NOT NULL default '0',
  `type` smallint(5) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB;

-- ----------------------------
-- Table structure for `mail_attachments`
-- ----------------------------

CREATE TABLE IF NOT EXISTS `mail_attachments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `index` smallint(5) unsigned NOT NULL DEFAULT '0',
  `nameid` int(10) unsigned NOT NULL DEFAULT '0',
  `amount` int(11) unsigned NOT NULL DEFAULT '0',
  `refine` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `attribute` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `identify` smallint(6) NOT NULL DEFAULT '0',
  `card0` int(10) unsigned NOT NULL DEFAULT '0',
  `card1` int(10) unsigned NOT NULL DEFAULT '0',
  `card2` int(10) unsigned NOT NULL DEFAULT '0',
  `card3` int(10) unsigned NOT NULL DEFAULT '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL DEFAULT '0',
  `bound` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
    PRIMARY KEY (`id`,`index`),
    FOREIGN KEY (`id`)
        REFERENCES `mail`(`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

--
-- Table structure for table `mapreg`
--

CREATE TABLE IF NOT EXISTS `mapreg` (
  `varname` varchar(32) binary NOT NULL,
  `index` int(11) unsigned NOT NULL default '0',
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`varname`,`index`)
) ENGINE=MyISAM;

--
-- Table `market` for market shop persistency
--

CREATE TABLE IF NOT EXISTS `market` (
  `name` varchar(50) NOT NULL DEFAULT '',
  `nameid` int(10) UNSIGNED NOT NULL,
  `price` INT(11) UNSIGNED NOT NULL,
  `amount` INT(11) NOT NULL,
  `flag` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY  (`name`,`nameid`)
) ENGINE = MyISAM;

--
-- Table structure for table `memo`
--

CREATE TABLE IF NOT EXISTS `memo` (
  `memo_id` int(11) unsigned NOT NULL auto_increment,
  `char_id` int(11) unsigned NOT NULL default '0',
  `map` varchar(11) NOT NULL default '',
  `x` smallint(4) unsigned NOT NULL default '0',
  `y` smallint(4) unsigned NOT NULL default '0',
  PRIMARY KEY  (`memo_id`),
  KEY `char_id` (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `mercenary`
--

CREATE TABLE IF NOT EXISTS `mercenary` (
  `mer_id` int(11) unsigned NOT NULL auto_increment,
  `char_id` int(11) unsigned NOT NULL,
  `class` mediumint(9) unsigned NOT NULL default '0',
  `hp` int(11) unsigned NOT NULL default '0',
  `sp` int(11) unsigned NOT NULL default '0',
  `kill_counter` int(11) NOT NULL,
  `life_time` bigint(20) NOT NULL default '0',
  PRIMARY KEY  (`mer_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `mercenary_owner`
--

CREATE TABLE IF NOT EXISTS `mercenary_owner` (
  `char_id` int(11) unsigned NOT NULL,
  `merc_id` int(11) unsigned NOT NULL default '0',
  `arch_calls` int(11) NOT NULL default '0',
  `arch_faith` int(11) NOT NULL default '0',
  `spear_calls` int(11) NOT NULL default '0',
  `spear_faith` int(11) NOT NULL default '0',
  `sword_calls` int(11) NOT NULL default '0',
  `sword_faith` int(11) NOT NULL default '0',
  PRIMARY KEY  (`char_id`)
) ENGINE=MyISAM;

-- ----------------------------
-- Table structure for `sales`
-- ----------------------------

CREATE TABLE IF NOT EXISTS `sales` (
  `nameid` int(10) unsigned NOT NULL,
  `start` datetime NOT NULL,
  `end` datetime NOT NULL,
  `amount` int(11) NOT NULL,
  PRIMARY KEY (`nameid`)
) ENGINE=MyISAM;

--
-- Table structure for table `sc_data`
--

CREATE TABLE IF NOT EXISTS `sc_data` (
  `account_id` int(11) unsigned NOT NULL,
  `char_id` int(11) unsigned NOT NULL,
  `type` smallint(11) unsigned NOT NULL,
  `tick` bigint(20) NOT NULL,
  `val1` int(11) NOT NULL default '0',
  `val2` int(11) NOT NULL default '0',
  `val3` int(11) NOT NULL default '0',
  `val4` int(11) NOT NULL default '0',
  PRIMARY KEY (`char_id`, `type`)
) ENGINE=MyISAM;

--
-- Table structure for table `skillcooldown`
--

CREATE TABLE IF NOT EXISTS `skillcooldown` (
  `account_id` int(11) unsigned NOT NULL,
  `char_id` int(11) unsigned NOT NULL,
  `skill` smallint(11) unsigned NOT NULL DEFAULT '0',
  `tick` bigint(20) NOT NULL,
  PRIMARY KEY (`char_id`, `skill`)
) ENGINE=MyISAM;

--
-- Table structure for table `party`
--

CREATE TABLE IF NOT EXISTS `party` (
  `party_id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(24) NOT NULL default '',
  `exp` tinyint(11) unsigned NOT NULL default '0',
  `item` tinyint(11) unsigned NOT NULL default '0',
  `leader_id` int(11) unsigned NOT NULL default '0',
  `leader_char` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`party_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `party_bookings`
--

CREATE TABLE IF NOT EXISTS `party_bookings` (
  `world_name` varchar(32) NOT NULL,
  `account_id` int(11) unsigned NOT NULL,
  `char_id` int(11) unsigned NOT NULL,
  `char_name` varchar(23) NOT NULL,
  `purpose` smallint(5) unsigned NOT NULL DEFAULT '0',
  `assist` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `damagedealer` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `healer` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `tanker` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `minimum_level` smallint(5) unsigned NOT NULL,
  `maximum_level` smallint(5) unsigned NOT NULL,
  `comment` varchar(255) NOT NULL DEFAULT '',
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`world_name`, `account_id`, `char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `pet`
--

CREATE TABLE IF NOT EXISTS `pet` (
  `pet_id` int(11) unsigned NOT NULL auto_increment,
  `class` mediumint(9) unsigned NOT NULL default '0',
  `name` varchar(24) NOT NULL default '',
  `account_id` int(11) unsigned NOT NULL default '0',
  `char_id` int(11) unsigned NOT NULL default '0',
  `level` smallint(4) unsigned NOT NULL default '0',
  `egg_id` int(10) unsigned NOT NULL default '0',
  `equip` int(10) unsigned NOT NULL default '0',
  `intimate` smallint(9) unsigned NOT NULL default '0',
  `hungry` smallint(9) unsigned NOT NULL default '0',
  `rename_flag` tinyint(4) unsigned NOT NULL default '0',
  `incubate` int(11) unsigned NOT NULL default '0',
  `autofeed` tinyint(2) NOT NULL default '0',
  PRIMARY KEY  (`pet_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `quest`
--

CREATE TABLE IF NOT EXISTS `quest` (
  `char_id` int(11) unsigned NOT NULL default '0',
  `quest_id` int(10) unsigned NOT NULL,
  `state` enum('0','1','2') NOT NULL default '0',
  `time` int(11) unsigned NOT NULL default '0',
  `count1` mediumint(8) unsigned NOT NULL default '0',
  `count2` mediumint(8) unsigned NOT NULL default '0',
  `count3` mediumint(8) unsigned NOT NULL default '0',
  PRIMARY KEY  (`char_id`,`quest_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `skill`
--

CREATE TABLE IF NOT EXISTS `skill` (
  `char_id` int(11) unsigned NOT NULL default '0',
  `id` smallint(11) unsigned NOT NULL default '0',
  `lv` tinyint(4) unsigned NOT NULL default '0',
  `flag` TINYINT(1) UNSIGNED NOT NULL default 0,
  PRIMARY KEY  (`char_id`,`id`)
) ENGINE=MyISAM;

--
-- Table structure for table `skill_homunculus`
--

CREATE TABLE IF NOT EXISTS `skill_homunculus` (
  `homun_id` int(11) NOT NULL,
  `id` int(11) NOT NULL,
  `lv` smallint(6) NOT NULL,
  PRIMARY KEY  (`homun_id`,`id`)
) ENGINE=MyISAM;

--
-- Table structure for table `skillcooldown_homunculus`
--

CREATE TABLE IF NOT EXISTS `skillcooldown_homunculus` (
  `homun_id` int(11) NOT NULL,
  `skill` smallint(11) unsigned NOT NULL DEFAULT '0',
  `tick` bigint(20) NOT NULL,
  PRIMARY KEY (`homun_id`,`skill`)
) ENGINE=MyISAM;

--
-- Table structure for table `skillcooldown_mercenary`
--

CREATE TABLE IF NOT EXISTS `skillcooldown_mercenary` (
  `mer_id` int(11) unsigned NOT NULL,
  `skill` smallint(11) unsigned NOT NULL DEFAULT '0',
  `tick` bigint(20) NOT NULL,
  PRIMARY KEY (`mer_id`,`skill`)
) ENGINE=MyISAM;

--
-- Table structure for table `storage`
--

CREATE TABLE IF NOT EXISTS `storage` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `account_id` int(11) unsigned NOT NULL default '0',
  `nameid` int(10) unsigned NOT NULL default '0',
  `amount` smallint(11) unsigned NOT NULL default '0',
  `equip` int(11) unsigned NOT NULL default '0',
  `identify` smallint(6) unsigned NOT NULL default '0',
  `refine` tinyint(3) unsigned NOT NULL default '0',
  `attribute` tinyint(4) unsigned NOT NULL default '0',
  `card0` int(10) unsigned NOT NULL default '0',
  `card1` int(10) unsigned NOT NULL default '0',
  `card2` int(10) unsigned NOT NULL default '0',
  `card3` int(10) unsigned NOT NULL default '0',
  `option_id0` smallint(5) NOT NULL default '0',
  `option_val0` smallint(5) NOT NULL default '0',
  `option_parm0` tinyint(3) NOT NULL default '0',
  `option_id1` smallint(5) NOT NULL default '0',
  `option_val1` smallint(5) NOT NULL default '0',
  `option_parm1` tinyint(3) NOT NULL default '0',
  `option_id2` smallint(5) NOT NULL default '0',
  `option_val2` smallint(5) NOT NULL default '0',
  `option_parm2` tinyint(3) NOT NULL default '0',
  `option_id3` smallint(5) NOT NULL default '0',
  `option_val3` smallint(5) NOT NULL default '0',
  `option_parm3` tinyint(3) NOT NULL default '0',
  `option_id4` smallint(5) NOT NULL default '0',
  `option_val4` smallint(5) NOT NULL default '0',
  `option_parm4` tinyint(3) NOT NULL default '0',
  `expire_time` int(11) unsigned NOT NULL default '0',
  `bound` tinyint(3) unsigned NOT NULL default '0',
  `unique_id` bigint(20) unsigned NOT NULL default '0',
  `enchantgrade` tinyint unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `account_id` (`account_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `vending_items`
--

CREATE TABLE IF NOT EXISTS `vending_items` (
  `vending_id` int(10) unsigned NOT NULL,
  `index` smallint(5) unsigned NOT NULL,
  `cartinventory_id` int(10) unsigned NOT NULL,
  `amount` smallint(5) unsigned NOT NULL,
  `price` int(10) unsigned NOT NULL,
  PRIMARY KEY (`vending_id`, `index`)
) ENGINE=MyISAM;

--
-- Table structure for table `vendings`
--

CREATE TABLE IF NOT EXISTS `vendings` (
  `id` int(10) unsigned NOT NULL,
  `account_id` int(11) unsigned NOT NULL,
  `char_id` int(10) unsigned NOT NULL,
  `sex` enum('F','M') NOT NULL DEFAULT 'M',
  `map` varchar(20) NOT NULL,
  `x` smallint(5) unsigned NOT NULL,
  `y` smallint(5) unsigned NOT NULL,
  `title` varchar(80) NOT NULL,
  `body_direction` CHAR( 1 ) NOT NULL DEFAULT '4',
  `head_direction` CHAR( 1 ) NOT NULL DEFAULT '0',
  `sit` CHAR( 1 ) NOT NULL DEFAULT '1',
  `autotrade` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM;

--
-- Table structure for table `headless_pc_runtime`
--

CREATE TABLE IF NOT EXISTS `headless_pc_runtime` (
  `char_id` int(10) unsigned NOT NULL,
  `map_name` varchar(32) NOT NULL,
  `x` smallint(5) unsigned NOT NULL,
  `y` smallint(5) unsigned NOT NULL,
  `state` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `headless_pc_lifecycle`
--

CREATE TABLE IF NOT EXISTS `headless_pc_lifecycle` (
  `char_id` int(10) unsigned NOT NULL,
  `spawn_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `remove_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `reconcile_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `walk_ack_seq` int(10) unsigned NOT NULL DEFAULT '0',
  `reconcile_result` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`char_id`)
) ENGINE=MyISAM;

--
-- Table structure for table `bot_profile`
--

CREATE TABLE IF NOT EXISTS `bot_profile` (
  `bot_id` int(10) unsigned NOT NULL auto_increment,
  `bot_key` varchar(64) NOT NULL default '',
  `name` varchar(30) NOT NULL default '',
  `status` enum('draft','active','disabled','retired') NOT NULL default 'draft',
  `role` varchar(32) NOT NULL default '',
  `home_map` varchar(32) NOT NULL default '',
  `routine_pool` varchar(64) NOT NULL default '',
  `timezone_policy` varchar(64) NOT NULL default '',
  `personality_tag` varchar(64) NOT NULL default '',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  UNIQUE KEY `bot_key` (`bot_key`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_identity_link`
--

CREATE TABLE IF NOT EXISTS `bot_identity_link` (
  `bot_id` int(10) unsigned NOT NULL,
  `account_id` int(11) unsigned DEFAULT NULL,
  `char_id` int(10) unsigned DEFAULT NULL,
  `link_status` enum('pending','linked','retired') NOT NULL default 'pending',
  `linked_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  UNIQUE KEY `account_id` (`account_id`),
  UNIQUE KEY `char_id` (`char_id`),
  KEY `link_status` (`link_status`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_appearance`
--

CREATE TABLE IF NOT EXISTS `bot_appearance` (
  `bot_id` int(10) unsigned NOT NULL,
  `job_id` smallint(5) unsigned NOT NULL default '0',
  `sex` enum('F','M') NOT NULL default 'M',
  `hair_style` tinyint(4) unsigned NOT NULL default '0',
  `hair_color` smallint(5) unsigned NOT NULL default '0',
  `cloth_color` smallint(5) unsigned NOT NULL default '0',
  `weapon_view` smallint(6) unsigned NOT NULL default '0',
  `shield_view` smallint(6) unsigned NOT NULL default '0',
  `head_top` smallint(6) unsigned NOT NULL default '0',
  `head_mid` smallint(6) unsigned NOT NULL default '0',
  `head_bottom` smallint(6) unsigned NOT NULL default '0',
  `robe` smallint(6) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_runtime_state`
--

CREATE TABLE IF NOT EXISTS `bot_runtime_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `current_map` varchar(32) NOT NULL default '',
  `current_x` smallint(5) unsigned NOT NULL default '0',
  `current_y` smallint(5) unsigned NOT NULL default '0',
  `current_state` enum('idle','walking','resting','merchanting','event','party','offline') NOT NULL default 'offline',
  `park_state` enum('active','grace','parked') NOT NULL default 'parked',
  `spawned_gid` int(10) unsigned DEFAULT NULL,
  `despawn_grace_until` datetime DEFAULT NULL,
  `last_spawned_at` datetime DEFAULT NULL,
  `last_despawned_at` datetime DEFAULT NULL,
  `last_parked_at` datetime DEFAULT NULL,
  `last_route_key` varchar(64) NOT NULL default '',
  `last_seen_tick` bigint(20) NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `current_map` (`current_map`),
  KEY `park_state` (`park_state`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_behavior_config`
--

CREATE TABLE IF NOT EXISTS `bot_behavior_config` (
  `bot_id` int(10) unsigned NOT NULL,
  `profile_key` varchar(64) NOT NULL default '',
  `pool_key` varchar(64) NOT NULL default '',
  `controller_tag` varchar(64) NOT NULL default '',
  `interaction_policy` enum('ambient_only','clickable','party_candidate','merchant_candidate') NOT NULL default 'ambient_only',
  `party_policy` enum('never','selective','open') NOT NULL default 'never',
  `presence_policy` enum('always_on','demand_gated','schedule_gated','hybrid') NOT NULL default 'demand_gated',
  `routine_group` varchar(64) NOT NULL default '',
  `routine_start_hour` tinyint(3) unsigned NOT NULL default '0',
  `routine_end_hour` tinyint(3) unsigned NOT NULL default '0',
  `pulse_profile` varchar(64) NOT NULL default '',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `pool_key` (`pool_key`),
  KEY `profile_key` (`profile_key`),
  KEY `routine_group` (`routine_group`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_policy`
--

CREATE TABLE IF NOT EXISTS `bot_controller_policy` (
  `controller_key` varchar(64) NOT NULL default '',
  `controller_npc` varchar(64) NOT NULL default '',
  `controller_label` varchar(64) NOT NULL default '',
  `controller_type` enum('social','merchant','party','event') NOT NULL default 'social',
  `map_name` varchar(32) NOT NULL default '',
  `scheduler_enabled` tinyint(1) unsigned NOT NULL default '1',
  `controller_enabled` tinyint(1) unsigned NOT NULL default '1',
  `gate_users` smallint(5) unsigned NOT NULL default '0',
  `priority` smallint(5) unsigned NOT NULL default '0',
  `actor_weight` smallint(5) unsigned NOT NULL default '1',
  `tick_ms` int(10) unsigned NOT NULL default '2000',
  `start_min_ms` int(10) unsigned NOT NULL default '0',
  `start_max_ms` int(10) unsigned NOT NULL default '0',
  `grace_ms` int(10) unsigned NOT NULL default '0',
  `min_active_ms` int(10) unsigned NOT NULL default '0',
  `restart_cooldown_ms` int(10) unsigned NOT NULL default '0',
  `fair_weight` smallint(5) unsigned NOT NULL default '1',
  `demand_users_step` smallint(5) unsigned NOT NULL default '1',
  `demand_priority_step` smallint(5) unsigned NOT NULL default '0',
  `demand_priority_cap` smallint(5) unsigned NOT NULL default '0',
  `stop_policy` enum('release','park') NOT NULL default 'release',
  `routine_group` varchar(64) NOT NULL default '',
  `routine_start_hour` tinyint(3) unsigned NOT NULL default '0',
  `routine_end_hour` tinyint(3) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`controller_key`),
  UNIQUE KEY `controller_npc` (`controller_npc`),
  KEY `map_name` (`map_name`),
  KEY `scheduler_enabled` (`scheduler_enabled`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_demand_map`
--

CREATE TABLE IF NOT EXISTS `bot_controller_demand_map` (
  `controller_key` varchar(64) NOT NULL default '',
  `map_name` varchar(32) NOT NULL default '',
  `user_weight` smallint(5) unsigned NOT NULL default '1',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`controller_key`,`map_name`),
  KEY `controller_key` (`controller_key`),
  KEY `point_index` (`point_index`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_demand_signal`
--

CREATE TABLE IF NOT EXISTS `bot_controller_demand_signal` (
  `controller_key` varchar(64) NOT NULL default '',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  `signal_type` enum('merchant_open_map','merchant_live_map','merchant_stock_map','merchant_browse_map','merchant_sale_map','merchant_browse_events_map','merchant_sale_units_map','guild_enabled_name','guild_roster_name','guild_live_name','guild_leader_name','guild_leader_live_name','guild_notice_name','guild_join_recent_name','guild_notice_recent_name','guild_join_events_name','guild_notice_events_name','guild_storage_name','guild_storage_log_name','guild_castle_name','guild_candidate_map') NOT NULL default 'merchant_open_map',
  `signal_key` varchar(64) NOT NULL default '',
  `signal_weight` smallint(5) unsigned NOT NULL default '1',
  PRIMARY KEY (`controller_key`,`point_index`),
  KEY `signal_type` (`signal_type`),
  KEY `signal_key` (`signal_key`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_runtime`
--

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

--
-- Table structure for table `bot_controller_slot`
--

CREATE TABLE IF NOT EXISTS `bot_controller_slot` (
  `slot_id` int(10) unsigned NOT NULL auto_increment,
  `controller_key` varchar(64) NOT NULL default '',
  `slot_index` smallint(5) unsigned NOT NULL default '0',
  `slot_label` varchar(64) NOT NULL default '',
  `pool_key` varchar(64) NOT NULL default '',
  `profile_key` varchar(64) NOT NULL default '',
  `role_key` varchar(64) NOT NULL default '',
  `map_name` varchar(32) NOT NULL default '',
  `spawn_x` smallint(5) unsigned NOT NULL default '0',
  `spawn_y` smallint(5) unsigned NOT NULL default '0',
  `loop_route` tinyint(1) unsigned NOT NULL default '0',
  `mode` enum('hold','loiter','patrol') NOT NULL default 'hold',
  `pulse_profile` varchar(64) NOT NULL default '',
  `anchor_set_key` varchar(64) NOT NULL default '',
  `route_set_key` varchar(64) NOT NULL default '',
  `talk_set_key` varchar(64) NOT NULL default '',
  `emote_set_key` varchar(64) NOT NULL default '',
  `min_demand_users` int(10) unsigned NOT NULL default '0',
  `enabled` tinyint(1) unsigned NOT NULL default '1',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`slot_id`),
  UNIQUE KEY `controller_key` (`controller_key`,`slot_index`),
  KEY `pool_key` (`pool_key`),
  KEY `profile_key` (`profile_key`),
  KEY `role_key` (`role_key`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_anchor_point`
--

CREATE TABLE IF NOT EXISTS `bot_controller_anchor_point` (
  `set_key` varchar(64) NOT NULL default '',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  `anchor_x` smallint(5) unsigned NOT NULL default '0',
  `anchor_y` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`set_key`,`point_index`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_talk_line`
--

CREATE TABLE IF NOT EXISTS `bot_controller_talk_line` (
  `set_key` varchar(64) NOT NULL default '',
  `line_index` smallint(5) unsigned NOT NULL default '0',
  `line_text` varchar(191) NOT NULL default '',
  PRIMARY KEY (`set_key`,`line_index`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_emote_value`
--

CREATE TABLE IF NOT EXISTS `bot_controller_emote_value` (
  `set_key` varchar(64) NOT NULL default '',
  `emote_index` smallint(5) unsigned NOT NULL default '0',
  `emotion` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`set_key`,`emote_index`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_controller_route_point`
--

CREATE TABLE IF NOT EXISTS `bot_controller_route_point` (
  `set_key` varchar(64) NOT NULL default '',
  `point_index` smallint(5) unsigned NOT NULL default '0',
  `route_x` smallint(5) unsigned NOT NULL default '0',
  `route_y` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY (`set_key`,`point_index`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_pulse_profile`
--

CREATE TABLE IF NOT EXISTS `bot_pulse_profile` (
  `profile_key` varchar(64) NOT NULL default '',
  `start_hour` tinyint(3) unsigned NOT NULL default '0',
  `end_hour` tinyint(3) unsigned NOT NULL default '0',
  `min_delay_s` smallint(5) unsigned NOT NULL default '35',
  `max_delay_s` smallint(5) unsigned NOT NULL default '60',
  `talk_weight` tinyint(3) unsigned NOT NULL default '60',
  PRIMARY KEY (`profile_key`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_merchant_state`
--

CREATE TABLE IF NOT EXISTS `bot_merchant_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `merchant_policy` varchar(64) NOT NULL default '',
  `shop_name` varchar(64) NOT NULL default '',
  `market_map` varchar(32) NOT NULL default '',
  `market_x` smallint(5) unsigned NOT NULL default '0',
  `market_y` smallint(5) unsigned NOT NULL default '0',
  `opening_start_hour` tinyint(3) unsigned NOT NULL default '0',
  `opening_end_hour` tinyint(3) unsigned NOT NULL default '0',
  `stock_profile` varchar(64) NOT NULL default '',
  `price_profile` varchar(64) NOT NULL default '',
  `stall_style` enum('anchored','roaming','popup') NOT NULL default 'anchored',
  `open_state` enum('closed','scheduled','open') NOT NULL default 'scheduled',
  `enabled` tinyint(1) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `market_map` (`market_map`),
  KEY `open_state` (`open_state`),
  KEY `enabled` (`enabled`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_guild_state`
--

CREATE TABLE IF NOT EXISTS `bot_guild_state` (
  `bot_id` int(10) unsigned NOT NULL,
  `guild_policy` varchar(64) NOT NULL default '',
  `guild_name` varchar(64) NOT NULL default '',
  `guild_position` varchar(64) NOT NULL default '',
  `invite_policy` enum('never','selective','open') NOT NULL default 'never',
  `guild_member_state` enum('unguilded','candidate','member','officer','leader') NOT NULL default 'unguilded',
  `enabled` tinyint(1) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`bot_id`),
  KEY `guild_name` (`guild_name`),
  KEY `invite_policy` (`invite_policy`),
  KEY `guild_member_state` (`guild_member_state`),
  KEY `enabled` (`enabled`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_guild_runtime`
--

CREATE TABLE IF NOT EXISTS `bot_guild_runtime` (
  `guild_name` varchar(64) NOT NULL default '',
  `last_member_join_at` int(10) unsigned NOT NULL default '0',
  `last_notice_at` int(10) unsigned NOT NULL default '0',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`guild_name`),
  KEY `last_member_join_at` (`last_member_join_at`),
  KEY `last_notice_at` (`last_notice_at`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_guild_activity_log`
--

CREATE TABLE IF NOT EXISTS `bot_guild_activity_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guild_name` varchar(64) NOT NULL default '',
  `activity_type` enum('member_join','notice_change') NOT NULL default 'member_join',
  `activity_units` int(10) unsigned NOT NULL default '1',
  `created_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`id`),
  KEY `guild_name` (`guild_name`),
  KEY `activity_type` (`activity_type`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_merchant_stock_item`
--

CREATE TABLE IF NOT EXISTS `bot_merchant_stock_item` (
  `stock_profile` varchar(64) NOT NULL default '',
  `item_index` smallint(5) unsigned NOT NULL default '0',
  `item_id` int(10) unsigned NOT NULL default '0',
  `stock_amount` int(10) unsigned NOT NULL default '0',
  `sell_price` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`stock_profile`,`item_index`),
  KEY `item_id` (`item_id`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_merchant_runtime`
--

CREATE TABLE IF NOT EXISTS `bot_merchant_runtime` (
  `bot_id` int(10) unsigned NOT NULL,
  `last_browse_at` int(10) unsigned NOT NULL default '0',
  `last_sale_at` int(10) unsigned NOT NULL default '0',
  `total_browse_count` int(10) unsigned NOT NULL default '0',
  `total_sale_count` int(10) unsigned NOT NULL default '0',
  `total_items_sold` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`bot_id`),
  KEY `last_browse_at` (`last_browse_at`),
  KEY `last_sale_at` (`last_sale_at`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_merchant_activity_log`
--

CREATE TABLE IF NOT EXISTS `bot_merchant_activity_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `bot_id` int(10) unsigned NOT NULL,
  `activity_type` enum('browse','sale') NOT NULL default 'browse',
  `activity_units` int(10) unsigned NOT NULL default '1',
  `created_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`id`),
  KEY `bot_id` (`bot_id`),
  KEY `activity_type` (`activity_type`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_reservation`
--

CREATE TABLE IF NOT EXISTS `bot_reservation` (
  `reservation_id` bigint(20) unsigned NOT NULL auto_increment,
  `type` enum('anchor','dialog_target','social_target','merchant_spot','party_role') NOT NULL default 'anchor',
  `resource_key` varchar(96) NOT NULL default '',
  `holder_bot_id` int(10) unsigned NOT NULL default '0',
  `holder_controller_id` varchar(64) NOT NULL default '',
  `lock_mode` enum('lease','hard_lock') NOT NULL default 'lease',
  `lease_until` int(10) unsigned NOT NULL default '0',
  `epoch` int(10) unsigned NOT NULL default '0',
  `priority` smallint(5) unsigned NOT NULL default '0',
  `reason` varchar(64) NOT NULL default '',
  `created_at` int(10) unsigned NOT NULL default '0',
  `updated_at` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY (`reservation_id`),
  UNIQUE KEY `type_resource` (`type`,`resource_key`),
  KEY `holder_bot_id` (`holder_bot_id`),
  KEY `holder_controller_id` (`holder_controller_id`),
  KEY `lease_until` (`lease_until`)
) ENGINE=InnoDB;

--
-- Table structure for table `bot_trace_event`
--

CREATE TABLE IF NOT EXISTS `bot_trace_event` (
  `id` bigint(20) unsigned NOT NULL auto_increment,
  `ts` int(10) unsigned NOT NULL default '0',
  `trace_id` varchar(64) NOT NULL default '',
  `bot_id` int(10) unsigned DEFAULT NULL,
  `char_id` int(10) unsigned DEFAULT NULL,
  `account_id` int(10) unsigned DEFAULT NULL,
  `map_id` int(10) unsigned NOT NULL default '0',
  `map_name` varchar(32) NOT NULL default '',
  `x` smallint(5) unsigned NOT NULL default '0',
  `y` smallint(5) unsigned NOT NULL default '0',
  `controller_id` varchar(64) NOT NULL default '',
  `controller_kind` varchar(32) NOT NULL default '',
  `owner_token` varchar(64) NOT NULL default '',
  `phase` enum('controller','scheduler','move','interaction','reservation','reconcile') NOT NULL default 'controller',
  `action` enum('controller.assigned','controller.released','scheduler.spawned','scheduler.parked','move.started','move.completed','move.failed','interaction.requested','interaction.completed','interaction.failed','reservation.acquired','reservation.denied','reservation.released','reconcile.started','reconcile.fixed','reconcile.failed') NOT NULL default 'controller.assigned',
  `target_type` varchar(32) NOT NULL default '',
  `target_id` varchar(64) NOT NULL default '',
  `reason_code` enum('none','operator.start','operator.stop','scheduler.select','scheduler.topup','scheduler.steady','scheduler.not_selected','demand.social','demand.guild','demand.merchant','cooldown','cap.actor','cap.map','claim.lost','path.blocked','target.invalid','script.busy','map.changed','restart.recovery','controller.gate','users.gate','no.demanded_slots','park.policy','pool.available','pool.denied','reconcile.scan','reconcile.sync','interaction.shop','interaction.guild','interaction.party') NOT NULL default 'none',
  `inputs` text DEFAULT NULL,
  `signals` text DEFAULT NULL,
  `reservation_refs` text DEFAULT NULL,
  `result` enum('ok','noop','retry','fallback','aborted','denied','timeout','desynced','fatal') NOT NULL default 'ok',
  `duration_ms` int(10) unsigned NOT NULL default '0',
  `fallback` varchar(64) NOT NULL default '',
  `error_code` varchar(64) NOT NULL default '',
  `error_detail` varchar(191) NOT NULL default '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `trace_id` (`trace_id`),
  KEY `ts` (`ts`),
  KEY `bot_id` (`bot_id`),
  KEY `char_id` (`char_id`),
  KEY `account_id` (`account_id`),
  KEY `map_name` (`map_name`),
  KEY `controller_id` (`controller_id`),
  KEY `action` (`action`),
  KEY `result` (`result`)
) ENGINE=InnoDB;

INSERT INTO `bot_controller_policy`
  (`controller_key`, `controller_npc`, `controller_label`, `controller_type`, `map_name`, `scheduler_enabled`, `controller_enabled`, `gate_users`, `priority`, `actor_weight`, `tick_ms`, `start_min_ms`, `start_max_ms`, `grace_ms`, `min_active_ms`, `restart_cooldown_ms`, `fair_weight`, `demand_users_step`, `demand_priority_step`, `demand_priority_cap`, `stop_policy`, `routine_group`, `routine_start_hour`, `routine_end_hour`)
VALUES
  ('social.prontera', 'HeadlessPronteraSocialController', 'Prontera social', 'social', 'prontera', 1, 1, 1, 90, 5, 2200, 400, 1500, 12000, 45000, 15000, 3, 2, 2, 8, 'park', 'day', 7, 23),
  ('patrol.prontera', 'HeadlessPronteraPatrolController', 'Prontera patrol', 'social', 'prontera', 0, 1, 1, 70, 1, 2400, 300, 900, 10000, 30000, 15000, 1, 3, 1, 4, 'park', 'day', 8, 22),
  ('social.alberta', 'HeadlessAlbertaSocialController', 'Alberta social', 'social', 'alberta', 1, 1, 1, 80, 3, 2400, 500, 1800, 15000, 60000, 20000, 3, 2, 2, 8, 'park', 'night', 0, 6),
  ('merchant.alberta', 'HeadlessAlbertaMerchantController', 'Alberta merchants', 'merchant', 'alberta', 1, 1, 1, 85, 1, 2600, 600, 1600, 18000, 90000, 30000, 2, 4, 1, 3, 'park', 'day', 8, 22),
  ('guild.watch.prontera', 'HeadlessPronteraGuildWatchController', 'Prontera guild watch', 'event', 'prontera', 1, 1, 1, 92, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23),
  ('guild.square.prontera', 'HeadlessPronteraGuildQuarterController', 'Prontera guild quarter', 'event', 'prontera', 1, 1, 1, 89, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23),
  ('market.flow.alberta', 'HeadlessAlbertaTradeFlowController', 'Alberta trade flow', 'merchant', 'alberta', 1, 1, 1, 88, 2, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23),
  ('market.spill.alberta', 'HeadlessAlbertaMarketSpillController', 'Alberta market spill', 'merchant', 'alberta', 1, 1, 1, 87, 1, 2400, 400, 1200, 15000, 60000, 20000, 2, 2, 2, 8, 'park', 'day', 8, 23)
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
  ('merchant.alberta', 0, 0, 0, '', 0),
  ('guild.watch.prontera', 0, 0, 0, '', 0),
  ('guild.square.prontera', 0, 0, 0, '', 0),
  ('market.flow.alberta', 0, 0, 0, '', 0),
  ('market.spill.alberta', 0, 0, 0, '', 0)
ON DUPLICATE KEY UPDATE
  `controller_key` = VALUES(`controller_key`);

DELETE FROM `bot_controller_demand_map`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta', 'guild.watch.prontera', 'guild.square.prontera', 'market.flow.alberta', 'market.spill.alberta');

INSERT INTO `bot_controller_demand_map`
  (`controller_key`, `map_name`, `user_weight`, `point_index`)
VALUES
  ('social.prontera', 'prontera', 3, 0),
  ('social.prontera', 'prt_in', 1, 1),
  ('social.prontera', 'prt_fild08', 1, 2),
  ('patrol.prontera', 'prontera', 1, 0),
  ('patrol.prontera', 'prt_fild08', 3, 1),
  ('social.alberta', 'alberta', 3, 0),
  ('social.alberta', 'izlude', 1, 1),
  ('merchant.alberta', 'alberta', 3, 0),
  ('merchant.alberta', 'izlude', 2, 1),
  ('guild.watch.prontera', 'prontera', 2, 0),
  ('guild.watch.prontera', 'prt_in', 1, 1),
  ('guild.square.prontera', 'prontera', 2, 0),
  ('guild.square.prontera', 'prt_in', 1, 1),
  ('market.flow.alberta', 'alberta', 2, 0),
  ('market.flow.alberta', 'izlude', 1, 1),
  ('market.spill.alberta', 'alberta', 2, 0),
  ('market.spill.alberta', 'izlude', 1, 1)
ON DUPLICATE KEY UPDATE
  `user_weight` = VALUES(`user_weight`),
  `point_index` = VALUES(`point_index`);

DELETE FROM `bot_controller_demand_signal`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta', 'guild.watch.prontera', 'guild.square.prontera', 'market.flow.alberta', 'market.spill.alberta');

INSERT INTO `bot_controller_demand_signal`
  (`controller_key`, `point_index`, `signal_type`, `signal_key`, `signal_weight`)
VALUES
  ('social.prontera', 0, 'guild_candidate_map', 'prontera', 2),
  ('social.prontera', 1, 'guild_roster_name', 'PBG150001', 1),
  ('social.prontera', 2, 'guild_live_name', 'PBG150001', 2),
  ('social.prontera', 3, 'guild_leader_name', 'PBG150001', 1),
  ('social.prontera', 4, 'guild_leader_live_name', 'PBG150001', 2),
  ('social.prontera', 5, 'guild_notice_name', 'PBG150001', 1),
  ('social.prontera', 6, 'guild_join_recent_name', 'PBG150001', 2),
  ('social.prontera', 7, 'guild_notice_recent_name', 'PBG150001', 1),
  ('social.prontera', 8, 'guild_storage_name', 'PBG150001', 1),
  ('social.prontera', 9, 'guild_storage_log_name', 'PBG150001', 1),
  ('social.prontera', 10, 'guild_castle_name', 'PBG150001', 2),
  ('patrol.prontera', 0, 'guild_candidate_map', 'prontera', 1),
  ('patrol.prontera', 1, 'guild_roster_name', 'PBG150001', 1),
  ('patrol.prontera', 2, 'guild_leader_live_name', 'PBG150001', 1),
  ('patrol.prontera', 3, 'guild_notice_name', 'PBG150001', 1),
  ('patrol.prontera', 4, 'guild_join_recent_name', 'PBG150001', 1),
  ('patrol.prontera', 5, 'guild_notice_recent_name', 'PBG150001', 1),
  ('patrol.prontera', 6, 'guild_storage_name', 'PBG150001', 1),
  ('patrol.prontera', 7, 'guild_castle_name', 'PBG150001', 2),
  ('guild.watch.prontera', 0, 'guild_roster_name', 'PBG150001', 1),
  ('guild.watch.prontera', 1, 'guild_leader_live_name', 'PBG150001', 2),
  ('guild.watch.prontera', 2, 'guild_join_recent_name', 'PBG150001', 2),
  ('guild.watch.prontera', 3, 'guild_notice_recent_name', 'PBG150001', 1),
  ('guild.watch.prontera', 4, 'guild_storage_log_name', 'PBG150001', 1),
  ('guild.square.prontera', 0, 'guild_roster_name', 'PBG150001', 1),
  ('guild.square.prontera', 1, 'guild_notice_name', 'PBG150001', 1),
  ('guild.square.prontera', 2, 'guild_notice_recent_name', 'PBG150001', 2),
  ('guild.square.prontera', 3, 'guild_storage_name', 'PBG150001', 1),
  ('guild.square.prontera', 4, 'guild_castle_name', 'PBG150001', 2),
  ('social.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('social.alberta', 1, 'merchant_stock_map', 'alberta', 1),
  ('social.alberta', 2, 'merchant_browse_map', 'alberta', 1),
  ('social.alberta', 3, 'merchant_browse_events_map', 'alberta', 1),
  ('merchant.alberta', 0, 'merchant_open_map', 'alberta', 3),
  ('merchant.alberta', 1, 'merchant_live_map', 'alberta', 2),
  ('merchant.alberta', 2, 'merchant_stock_map', 'alberta', 1),
  ('merchant.alberta', 3, 'merchant_browse_map', 'alberta', 1),
  ('merchant.alberta', 4, 'merchant_sale_map', 'alberta', 2),
  ('merchant.alberta', 5, 'merchant_browse_events_map', 'alberta', 1),
  ('merchant.alberta', 6, 'merchant_sale_units_map', 'alberta', 1),
  ('market.flow.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('market.flow.alberta', 1, 'merchant_browse_map', 'alberta', 2),
  ('market.flow.alberta', 2, 'merchant_sale_map', 'alberta', 2),
  ('market.flow.alberta', 3, 'merchant_stock_map', 'alberta', 1),
  ('market.flow.alberta', 4, 'merchant_browse_events_map', 'alberta', 1),
  ('market.flow.alberta', 5, 'merchant_sale_units_map', 'alberta', 1),
  ('market.spill.alberta', 0, 'merchant_open_map', 'alberta', 1),
  ('market.spill.alberta', 1, 'merchant_live_map', 'alberta', 1),
  ('market.spill.alberta', 2, 'merchant_browse_map', 'alberta', 2),
  ('market.spill.alberta', 3, 'merchant_sale_map', 'alberta', 2),
  ('market.spill.alberta', 4, 'merchant_stock_map', 'alberta', 1),
  ('market.spill.alberta', 5, 'merchant_browse_events_map', 'alberta', 1),
  ('market.spill.alberta', 6, 'merchant_sale_units_map', 'alberta', 1),
  ('social.prontera', 11, 'guild_join_events_name', 'PBG150001', 1),
  ('social.prontera', 12, 'guild_notice_events_name', 'PBG150001', 1),
  ('patrol.prontera', 8, 'guild_join_events_name', 'PBG150001', 1),
  ('patrol.prontera', 9, 'guild_notice_events_name', 'PBG150001', 1),
  ('guild.watch.prontera', 5, 'guild_join_events_name', 'PBG150001', 1),
  ('guild.watch.prontera', 6, 'guild_notice_events_name', 'PBG150001', 1),
  ('guild.square.prontera', 5, 'guild_join_events_name', 'PBG150001', 1),
  ('guild.square.prontera', 6, 'guild_notice_events_name', 'PBG150001', 1)
ON DUPLICATE KEY UPDATE
  `signal_type` = VALUES(`signal_type`),
  `signal_key` = VALUES(`signal_key`),
  `signal_weight` = VALUES(`signal_weight`);

DELETE FROM `bot_controller_slot`
WHERE `controller_key` IN ('social.prontera', 'patrol.prontera', 'social.alberta', 'merchant.alberta', 'guild.watch.prontera', 'guild.square.prontera', 'market.flow.alberta', 'market.spill.alberta');

INSERT INTO `bot_controller_slot`
  (`controller_key`, `slot_index`, `slot_label`, `pool_key`, `profile_key`, `role_key`, `map_name`, `spawn_x`, `spawn_y`, `loop_route`, `mode`, `pulse_profile`, `anchor_set_key`, `route_set_key`, `talk_set_key`, `emote_set_key`, `min_demand_users`, `enabled`)
VALUES
  ('social.prontera', 0, 'Square Regular A', 'pool.social.prontera', 'social.prontera.regular', 'square_regular', 'prontera', 146, 188, 0, 'hold', 'square_anchor_day', '', '', 'social.prontera.regular.a', 'social.prontera.regular.a', 0, 1),
  ('social.prontera', 1, 'Square Regular B', 'pool.social.prontera', 'social.prontera.regular', 'square_regular', 'prontera', 151, 186, 0, 'hold', 'square_anchor_evening', '', '', 'social.prontera.regular.b', 'social.prontera.regular.b', 0, 1),
  ('social.prontera', 2, 'Square Wanderer A', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 145, 184, 1, 'loiter', 'square_loiter_busy', 'social.prontera.wanderer.a', '', 'social.prontera.wanderer.a', 'social.prontera.wanderer.a', 2, 1),
  ('social.prontera', 3, 'Square Wanderer B', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 153, 188, 1, 'loiter', 'square_loiter_late', 'social.prontera.wanderer.b', '', 'social.prontera.wanderer.b', 'social.prontera.wanderer.b', 4, 1),
  ('social.prontera', 4, 'Square Wanderer C', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 147, 190, 1, 'loiter', 'square_loiter_night', 'social.prontera.wanderer.c', '', 'social.prontera.wanderer.c', 'social.prontera.wanderer.c', 6, 1),
  ('patrol.prontera', 0, 'Square Patrol', 'pool.social.prontera', 'social.prontera.wanderer', 'square_wanderer', 'prontera', 160, 186, 1, 'patrol', 'square_loiter_busy', '', 'patrol.prontera.loop', '', '', 3, 1),
  ('social.alberta', 0, 'Dock Regular A', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 47, 245, 0, 'hold', 'market_anchor_day', '', '', 'social.alberta.regular.a', 'social.alberta.regular.a', 0, 1),
  ('social.alberta', 1, 'Dock Regular B', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 50, 244, 0, 'hold', 'market_anchor_trade', '', '', 'social.alberta.regular.b', 'social.alberta.regular.b', 1, 1),
  ('social.alberta', 2, 'Harbor Wanderer', 'pool.social.alberta', 'social.alberta.harbor', 'harbor_wanderer', 'alberta', 45, 247, 1, 'loiter', 'mh', 'social.alberta.harbor.a', '', 'social.alberta.harbor.a', 'social.alberta.harbor.a', 3, 1),
  ('merchant.alberta', 0, 'Harbor Curios', 'pool.merchant.alberta', 'merchant.alberta', 'stall_merchant', 'alberta', 52, 242, 0, 'hold', 'market_anchor_trade', '', '', 'merchant.alberta.stall.a', 'merchant.alberta.stall.a', 2, 1),
  ('guild.watch.prontera', 0, 'Guild Watch Captain', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 149, 191, 0, 'hold', 'square_anchor_evening', '', '', 'guild.watch.prontera.a', 'guild.watch.prontera.a', 1, 1),
  ('guild.watch.prontera', 1, 'Guild Watch Runner', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 150, 189, 1, 'loiter', 'square_loiter_busy', 'guild.watch.prontera.runner', '', 'guild.watch.prontera.b', 'guild.watch.prontera.b', 4, 1),
  ('guild.square.prontera', 0, 'Guild Quarter Steward', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 155, 180, 0, 'hold', 'square_anchor_evening', '', '', 'guild.square.prontera.a', 'guild.square.prontera.a', 2, 1),
  ('guild.square.prontera', 1, 'Notice Courier', 'pool.guild.prontera', 'guild.prontera', 'guild_member', 'prontera', 154, 179, 1, 'loiter', 'square_loiter_busy', 'guild.square.prontera.courier', '', 'guild.square.prontera.b', 'guild.square.prontera.b', 5, 1),
  ('market.flow.alberta', 0, 'Trade Crier', 'pool.trade.alberta', 'market.alberta.runner', 'market_runner', 'alberta', 49, 242, 0, 'hold', 'market_anchor_trade', '', '', 'market.flow.alberta.a', 'market.flow.alberta.a', 2, 1),
  ('market.flow.alberta', 1, 'Supply Runner', 'pool.trade.alberta', 'market.alberta.runner', 'market_runner', 'alberta', 45, 243, 1, 'patrol', 'market_loiter_browse', '', 'market.flow.alberta.loop', 'market.flow.alberta.b', 'market.flow.alberta.b', 5, 1),
  ('market.spill.alberta', 0, 'Market Barker', 'pool.social.alberta', 'social.alberta.regular', 'dock_regular', 'alberta', 51, 241, 0, 'hold', 'market_anchor_trade', '', '', 'market.spill.alberta.a', 'market.spill.alberta.a', 6, 1);

DELETE FROM `bot_controller_anchor_point`
WHERE `set_key` IN (
  'social.prontera.wanderer.a', 'social.prontera.wanderer.b', 'social.prontera.wanderer.c',
  'social.alberta.browser.a', 'social.alberta.harbor.a', 'social.alberta.browser.b',
  'guild.watch.prontera.runner', 'guild.square.prontera.courier'
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
  ('social.alberta.browser.b', 2, 50, 242),
  ('guild.watch.prontera.runner', 0, 150, 189),
  ('guild.watch.prontera.runner', 1, 152, 191),
  ('guild.watch.prontera.runner', 2, 147, 192),
  ('guild.watch.prontera.runner', 3, 145, 189),
  ('guild.square.prontera.courier', 0, 154, 179),
  ('guild.square.prontera.courier', 1, 157, 181),
  ('guild.square.prontera.courier', 2, 152, 182),
  ('guild.square.prontera.courier', 3, 150, 179);

DELETE FROM `bot_controller_talk_line`
WHERE `set_key` IN (
  'social.prontera.regular.a', 'social.prontera.regular.b',
  'social.prontera.wanderer.a', 'social.prontera.wanderer.b', 'social.prontera.wanderer.c',
  'social.alberta.regular.a', 'social.alberta.regular.b',
  'social.alberta.browser.a', 'social.alberta.harbor.a', 'social.alberta.browser.b',
  'merchant.alberta.stall.a', 'guild.watch.prontera.a', 'guild.watch.prontera.b',
  'guild.square.prontera.a', 'guild.square.prontera.b',
  'market.flow.alberta.a', 'market.flow.alberta.b',
  'market.spill.alberta.a', 'market.spill.alberta.b'
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
  ('merchant.alberta.stall.a', 1, 'Take a look before the tide shifts again.'),
  ('guild.watch.prontera.a', 0, 'Guild notices changed again this morning.'),
  ('guild.watch.prontera.a', 1, 'Warehouse traffic picks up when members gather.'),
  ('guild.watch.prontera.b', 0, 'I was sent to check the guild quarter.'),
  ('guild.watch.prontera.b', 1, 'Someone always needs a runner when notices go up.'),
  ('guild.square.prontera.a', 0, 'The guild quarter stays busy whenever fresh notices go up.'),
  ('guild.square.prontera.a', 1, 'Runners keep crossing this block when storage requests pile up.'),
  ('guild.square.prontera.b', 0, 'I have another message for the guild office.'),
  ('guild.square.prontera.b', 1, 'Someone from the roster is always checking the board.'),
  ('market.flow.alberta.a', 0, 'Harbor sellers are moving stock fast today.'),
  ('market.flow.alberta.a', 1, 'If the stalls stay busy, more runners will show.'),
  ('market.flow.alberta.b', 0, 'Another buyer just left the dock stalls.'),
  ('market.flow.alberta.b', 1, 'Trade lanes stay hot whenever sales keep flowing.'),
  ('market.spill.alberta.a', 0, 'The market is spilling out into the harbor lane again.'),
  ('market.spill.alberta.a', 1, 'More buyers show up whenever the stalls keep moving stock.'),
  ('market.spill.alberta.b', 0, 'I keep circling between the docks and the counters.'),
  ('market.spill.alberta.b', 1, 'Sales like this pull half the harbor into the market.');

DELETE FROM `bot_controller_emote_value`
WHERE `set_key` IN (
  'social.prontera.regular.a', 'social.prontera.regular.b',
  'social.prontera.wanderer.a', 'social.prontera.wanderer.b', 'social.prontera.wanderer.c',
  'social.alberta.regular.a', 'social.alberta.regular.b',
  'social.alberta.browser.a', 'social.alberta.harbor.a', 'social.alberta.browser.b',
  'merchant.alberta.stall.a', 'guild.watch.prontera.a', 'guild.watch.prontera.b',
  'guild.square.prontera.a', 'guild.square.prontera.b',
  'market.flow.alberta.a', 'market.flow.alberta.b',
  'market.spill.alberta.a', 'market.spill.alberta.b'
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
  ('merchant.alberta.stall.a', 1, 7),
  ('guild.watch.prontera.a', 0, 1),
  ('guild.watch.prontera.a', 1, 7),
  ('guild.watch.prontera.b', 0, 4),
  ('guild.watch.prontera.b', 1, 9),
  ('guild.square.prontera.a', 0, 7),
  ('guild.square.prontera.a', 1, 9),
  ('guild.square.prontera.b', 0, 4),
  ('guild.square.prontera.b', 1, 1),
  ('market.flow.alberta.a', 0, 1),
  ('market.flow.alberta.a', 1, 9),
  ('market.flow.alberta.b', 0, 10),
  ('market.flow.alberta.b', 1, 4),
  ('market.spill.alberta.a', 0, 1),
  ('market.spill.alberta.a', 1, 9),
  ('market.spill.alberta.b', 0, 10),
  ('market.spill.alberta.b', 1, 4);

DELETE FROM `bot_controller_route_point`
WHERE `set_key` IN ('patrol.prontera.loop', 'market.flow.alberta.loop', 'market.spill.alberta.loop');

INSERT INTO `bot_controller_route_point`
  (`set_key`, `point_index`, `route_x`, `route_y`)
VALUES
  ('patrol.prontera.loop', 0, 160, 186),
  ('patrol.prontera.loop', 1, 163, 186),
  ('patrol.prontera.loop', 2, 163, 189),
  ('patrol.prontera.loop', 3, 160, 189),
  ('market.flow.alberta.loop', 0, 45, 243),
  ('market.flow.alberta.loop', 1, 49, 244),
  ('market.flow.alberta.loop', 2, 52, 242),
  ('market.flow.alberta.loop', 3, 47, 240),
  ('market.spill.alberta.loop', 0, 46, 245),
  ('market.spill.alberta.loop', 1, 50, 244),
  ('market.spill.alberta.loop', 2, 53, 241),
  ('market.spill.alberta.loop', 3, 49, 239);

INSERT INTO `bot_pulse_profile`
  (`profile_key`, `start_hour`, `end_hour`, `min_delay_s`, `max_delay_s`, `talk_weight`)
VALUES
  ('square_anchor_day', 7, 21, 40, 70, 70),
  ('square_anchor_evening', 9, 22, 45, 80, 60),
  ('square_loiter_busy', 8, 20, 30, 55, 55),
  ('square_loiter_late', 10, 23, 35, 60, 50),
  ('square_loiter_night', 11, 23, 30, 50, 45),
  ('market_anchor_day', 8, 21, 40, 70, 65),
  ('market_anchor_trade', 9, 22, 45, 75, 60),
  ('market_loiter_browse', 8, 20, 30, 55, 55),
  ('mh', 9, 22, 35, 60, 50),
  ('ml', 10, 23, 35, 55, 45)
ON DUPLICATE KEY UPDATE
  `start_hour` = VALUES(`start_hour`),
  `end_hour` = VALUES(`end_hour`),
  `min_delay_s` = VALUES(`min_delay_s`),
  `max_delay_s` = VALUES(`max_delay_s`),
  `talk_weight` = VALUES(`talk_weight`);

DELETE FROM `bot_merchant_stock_item`
WHERE `stock_profile` IN ('alberta_curios');

INSERT INTO `bot_merchant_stock_item`
  (`stock_profile`, `item_index`, `item_id`, `stock_amount`, `sell_price`)
VALUES
  ('alberta_curios', 0, 909, 60, 0),
  ('alberta_curios', 1, 910, 30, 0),
  ('alberta_curios', 2, 911, 20, 0),
  ('alberta_curios', 3, 912, 10, 0);
