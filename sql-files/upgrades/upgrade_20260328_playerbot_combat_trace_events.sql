# Upgrade for playerbot combat trace enums.

ALTER TABLE `bot_trace_event`
  MODIFY COLUMN `phase` enum('controller','scheduler','move','interaction','reservation','reconcile','combat') NOT NULL default 'controller',
  MODIFY COLUMN `action` enum('controller.assigned','controller.released','scheduler.spawned','scheduler.parked','move.started','move.completed','move.failed','interaction.requested','interaction.completed','interaction.failed','reservation.acquired','reservation.denied','reservation.released','reconcile.started','reconcile.fixed','reconcile.failed','combat.requested','combat.completed','combat.failed','death.requested','death.completed','death.failed','death.observed','respawn.requested','respawn.completed','respawn.failed') NOT NULL default 'controller.assigned';
