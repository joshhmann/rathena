ALTER TABLE `bot_item_audit`
MODIFY COLUMN `action` enum('inventory_add','inventory_remove','equip','unequip','storage_deposit','storage_withdraw','consume','refine','reform','enchantgrade')
NOT NULL DEFAULT 'inventory_add';
