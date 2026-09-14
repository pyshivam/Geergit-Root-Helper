# Documentation Agent Contract

## Purpose

Owns agent instructions and domain documentation: this DOX tree, `CONTEXT.md`, ADRs, plans, specs, and agent conventions.

## Ownership

- Agents update docs as a side effect of meaningful changes.
- Human maintainers own product vision and final terminology decisions.

## Local Contracts

- Read root `AGENTS.md` first.
- Read `DOX.md` for DOX framework rules.
- Read `docs/coding-standards.md` before changing code — docs that cite conventions or commands must match it.
- Read `docs/agents/domain.md` for domain doc layout rules.
- Read `docs/agents/issue-tracker.md` for issue tracker conventions.
- Read `docs/agents/triage-labels.md` for triage label mapping.

## Work Guidance

- Keep `CONTEXT.md` as a glossary only — no implementation details.
- Record repo-wide code conventions in `docs/coding-standards.md`; extend it rather than restating rules in child docs.
- Record durable how-to knowledge (toolchain, per-platform commands, verification recipes) in `docs/developer-guide.md`.
- Create an ADR in `docs/adr/` only when a decision is hard to reverse, surprising without context, and the result of a real trade-off.
- Update the nearest owning `AGENTS.md` when a change affects purpose, scope, ownership, workflows, or contracts.
- Refresh every affected Child DOX Index after structural changes.
- Delete stale or contradictory text instead of explaining history.

## Verification

- Run `flutter analyze` and `flutter test` from the repo root before committing doc changes, in case docs include code or config snippets.
- For markdown-only changes with no code impact, either may be skipped, but prefer running them.

## Child DOX Index

- `docs/agents/issue-tracker.md` — GitHub issue tracker conventions
- `docs/agents/triage-labels.md` — Triage label mapping
- `docs/agents/domain.md` — Domain doc layout rules
- `docs/developer-guide.md` — Toolchain, per-platform run/build commands, verification recipes
- `docs/coding-standards.md` — Repo-wide code conventions
- `docs/adr/` — Architecture Decision Records (numbered `NNNN-title.md`)
- `docs/plans/` — Numbered feature implementation plans
- `docs/specs/` — Numbered interface specifications
