# Playerbot Status Continuity Contract

## Purpose

This document defines the rules for how status effects (buffs, debuffs, and ailments) persist or clear across playerbot lifecycle events. It ensures that bots behave predictably during combat, death, respawn, and map transitions, with clear recovery and audit trails.

This contract is implementation-facing and aligns with the current foundation order.

## Status Continuity Rules

| Event | Status Class | Expected Behavior | Reason |
| --- | --- | --- | --- |
| **Death** | Common Buffs (Blessing, Agi UP) | **Clear** | Standard RO behavior; prevents "zombie" buffs. |
| **Death** | Common Ailments (Stun, Poison) | **Clear** | Standard RO behavior. |
| **Death** | Passive States (Weight, Cart) | **Persist** | Tied to inventory/loadout, not vitality. |
| **Respawn** | Any Remaining Status | **Reconcile** | Ensure live actor state matches intended "fresh" state. |
| **Map Change** | Common Buffs/Ailments | **Persist** | Standard RO behavior; maintains continuity during travel. |
| **Participation Recover** | Any Status | **No Change** | Recovering from a stuck dialog/trade should not affect combat state. |
| **Combat Interruption** | Any Status | **No Change** | Combat-only interrupts (e.g., target lost) do not affect status. |

## Authority Boundaries

| Authority | Responsibility |
| --- | --- |
| **Live Actor State** | The definitive source for which statuses are *currently* active on the `BL_PC`. |
| **Recovery Audit** | Records when a status was forced to clear or reconcile during a recovery event. |
| **Trace Ledger** | Provides the timeline of status changes (`status.applied`, `status.cleared`). |

## Minimum Observability

### Trace Requirements (`bot_trace_event`)
Every status transition issued or observed by a bot controller must emit a trace:
- `action`: `status.applied`, `status.cleared`, `status.expired`.
- `phase`: `combat` or `status`.
- `target_id`: The ID of the status change (`SC_ID`).
- `reason_code`: Why the change happened (e.g., `skill.cast`, `death.cleanup`, `map.change`).

### Audit Requirements (`bot_recovery_audit`)
An audit row must be created if a status is cleared as part of a failure-recovery or death-cleanup event:
- `scope`: `status`.
- `action`: `cleanup` or `reconcile`.
- `detail`: List of affected `SC_ID`s or a summary (e.g., `cleared.death.buffs`).

## Scenario Coverage Matrix

| Scenario Name | Goal | Expected Result |
| --- | --- | --- |
| `status-death-cleanup` | Prove buffs clear on bot death. | `SC_BLESSING` is absent after `playerbot_isdead` becomes true. |
| `status-map-continuity` | Prove buffs persist across `setpos`. | `SC_BLESSING` remains active after a map change. |
| `status-respawn-reconcile`| Prove "fresh" state after respawn. | No stale ailments or buffs from previous life remain. |
| `status-recovery-integrity`| Prove participation recovery is safe. | Active buffs are untouched after `playerbot_participationrecover`. |

## Explicit Non-Goals

- **No Combat AI**: This contract does not define *when* to cast buffs, only how they behave once present.
- **No Skill Rotation**: Does not cover skill-logic or priorities.
- **No Behavior Scripting**: Does not define "buffing" roles or personality-driven status management.

## Deferred Implementation (Future Hooks)

- **Loadout-Driven Buffs**: (Deferred) Statuses granted by specific equipment sets during respawn.
- **Persistent Ailments**: (Deferred) Support for specific RO-config debuffs that are intended to survive death.
- **Cross-Server Status**: (Deferred) Continuity when moving between different map-server instances.
