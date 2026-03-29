# Playerbot Status Continuity Contract

## Purpose

This document defines the rules for how status effects (buffs, debuffs, and ailments) persist or clear across playerbot lifecycle events. It ensures that bots behave predictably during combat, death, respawn, and map transitions, with clear recovery and audit trails.

## Status Continuity Summary String

The canonical representation of bot status for traces and audits is the **Status Summary String**:

`count=N,blessing=B,incagi=A,poison=P,stun=S`

- `count`: Total number of active `status_change` effects (`SC_MAX` scan).
- `blessing`: `1` if `SC_BLESSING` is active, else `0`.
- `incagi`: `1` if `SC_INCREASEAGI` is active, else `0`.
- `poison`: `1` if `SC_POISON` is active, else `0`.
- `stun`: `1` if `SC_STUN` is active, else `0`.

## Status Continuity Rules

| Event | Status Class | Expected Behavior | Reason |
| --- | --- | --- | --- |
| **Death** | Common Buffs (Blessing, Agi UP) | **Clear** | Standard RO behavior; prevents "zombie" buffs. |
| **Death** | Common Ailments (Stun, Poison) | **Clear** | Standard RO behavior. |
| **Death** | Passive States (Weight, Cart) | **Persist** | Tied to inventory/loadout, not vitality. |
| **Respawn** | Any Remaining Status | **Reconcile** | Ensure live actor state matches intended "fresh" state via `pc_playerbot_handle_respawn_cleanup`. |
| **Map Change** | Common Buffs/Ailments | **Persist** | Standard RO behavior; maintains continuity during travel. |
| **Participation Recover** | Any Status | **No Change** | Recovering from a stuck dialog/trade should not affect combat state. |

## Authority Boundaries

| Authority | Responsibility |
| --- | --- |
| **Live Actor State** | The definitive source for which statuses are *currently* active on the `BL_PC`. |
| **Recovery Audit** | Records when a status was forced to clear or reconcile during a recovery event (`scope='status'`, `action='cleanup'`). |
| **Trace Ledger** | Provides the timeline of status changes (`action='combat.completed'`, `target_type='status'`). |

## Minimum Observability

### Trace Requirements (`bot_trace_event`)
Status transitions issued via `playerbot_statusstart` or `playerbot_statusclear` must emit a trace:
- `action`: `combat.completed` or `combat.failed`.
- `phase`: `combat`.
- `target_type`: `status`.
- `target_id`: The `sc_type` ID as a string.
- `error_detail`: `status.applied` or `status.cleared`.

### Audit Requirements (`bot_recovery_audit`)
An audit row must be created if a status is cleared as part of a death-cleanup or respawn event:
- `scope`: `status`.
- `action`: `cleanup` or `reconcile`.
- `state_before` / `state_after`: The **Status Summary String** before and after the transition.
- `detail`: `death.cleanup`, `death.nochange`, or `respawn.reconciled`.

## Scenario Coverage Matrix

| Scenario Name | Goal | Expected Result |
| --- | --- | --- |
| `status-death-cleanup` | Prove buffs clear on bot death. | `count=0` (or reduced) and `blessing=0` after death. |
| `status-map-continuity` | Prove buffs persist across `setpos`. | `Status Summary String` remains identical after a map change. |
| `status-respawn-reconcile`| Prove "fresh" state after respawn. | No stale ailments or buffs from previous life remain. |

## Explicit Non-Goals

- **No Combat AI**: This contract does not define *when* to cast buffs, only how they behave once present.
- **No Skill Rotation**: Does not cover skill-logic or priorities.
- **No Behavior Scripting**: Does not define "buffing" roles or personality-driven status management.
