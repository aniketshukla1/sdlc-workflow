# Migration safety — expand/contract, reversibility proven in CI

Never rewrite history in one deploy. Schema changes ship in phases so every deploy stays reversible.

## The pattern

1. **Expand** (MR 1): add the new table/column as nullable, dual-write old + new. Nothing reads the new shape yet. Fully backward compatible.
2. **Migrate** (deploy + backfill): backfill script fills new from old; verify row counts match.
3. **Contract** (MR 2, a later release): switch reads to the new shape, stop dual-write, drop the old. Only after the expand has run in prod.

## Rules

- Every migration must downgrade cleanly: the CI `migration-check` job runs `alembic upgrade head → downgrade base → upgrade head` on a scratch DB. Red = MR blocked.
- Destructive ops (drop column/table, type change, NOT NULL without default) get their OWN MR + backup note + rollback plan in the MR description. Never bundled with feature code.
- One logical migration chain per MR. Never edit a migration that already ran in prod — write a new one.
- Large tables: backfill batched + off-peak; state expected lock time in the MR.

## MR checklist addition

- [ ] `upgrade head` + `downgrade base` + `upgrade head` green locally
- [ ] Expand/contract phase stated (expand-only? contract of a prior expand?)
- [ ] Destructive? → backup + rollback plan linked
