# Frozen: our XMage arena

Day-to-day development now happens on Colosseo. `adapters/xmage-external-seat/` and `evaluation/`
are frozen as of commit `a7ec31c`: no changes except fixes needed to replay archived results.

## What it is still for

1. The regression oracle for the policy.
2. Replaying archived results: every study under `evaluation/xmage-*` can be re-run from this state.

## Scope

- `adapters/xmage-external-seat/`: frozen.
- `evaluation/xmage-*`: frozen.
- `evaluation/colosseo-parity/` is not part of this freeze.
