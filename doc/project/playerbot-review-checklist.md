# Playerbot Review Checklist

Use this checklist before accepting external branch work.

## Baseline

- Is the branch based on current `master`?
- Did the contributor read the current handoff docs?

## Scope

- Did the branch stay inside its allowed files?
- Did it avoid guarded hotspots unless explicitly assigned?

## Accuracy

- Do docs match current implementation?
- Are labels honest about static config vs live runtime?
- Does it distinguish aggregate-gate proof from probe-only proof?

## Validation

- Are validation commands listed?
- Were they actually run?
- Do the claimed results line up with local reality?

## Integration Risk

- Will this collide with the active primary runtime lane?
- Does it overwrite slice-log or doc state from newer work?
- Is the final commit shape small and intentional?

## Decision

- accept
- request corrections
- reject due to scope drift
