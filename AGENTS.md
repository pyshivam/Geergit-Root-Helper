# Agent(Your) Work Contract

## Purpose

This file is the root work contract for `geergit_root_helper` — the **Geergit Root Helper** app: one Flutter codebase shipping for Android, Linux, macOS, and Windows under application id `com.geerxlabs.geergitroothelper`. Every agent editing this repo must follow the DOX hierarchy, use the skill router, and keep docs current as work progresses.

## Ownership

- Human maintainers own product decisions and final approval.
- Agents own precise execution, verification, and doc hygiene under this contract.

## MUST Read

- Read `docs/developer-guide.md` before starting any task: toolchain, per-platform run/build commands, verification recipes, and the commit-&-push-after-every-task rule.
- Read `DOX.md` before any edit for the DOX traversal and update rules.
- Read `CONTEXT.md` before using or adding domain terminology.
- Read `docs/coding-standards.md` before changing Dart code.
- Read `docs/agents/issue-tracker.md` for GitHub issue conventions.
- Read `docs/agents/triage-labels.md` for label mapping.
- Read `docs/agents/domain.md` for domain doc layout rules.

## Work Guidance

- Please remove all mannered prose.
- Must follow the Graft context graph for understanding and editing code.

### DOX traversal

1. Read this root `AGENTS.md`.
2. Identify every file or folder you expect to touch.
3. Walk from the repo root to each target path and read every `AGENTS.md` along the route.
4. Use the nearest `AGENTS.md` as the local contract; parent docs provide repo-wide rules.
5. After any meaningful change, update the closest owning `AGENTS.md` and refresh affected indexes.

### Skill router

Load the relevant skill before starting work. If a task fits multiple categories, load all that apply.

| Task type | Skill to load |
| --- | --- |
| Bug report / crash / regression | `diagnosing-bugs` |
| New feature / vertical slice | `tdd` |
| Design / API / module shape | `codebase-design` |
| Domain terminology or model change | `domain-modeling` |
| Refactor / architecture cleanup | `improve-codebase-architecture` |
| External API / library research | `research` |
| Code review | `code-review` |
| Merge conflict resolution | `resolving-merge-conflicts` |
| Planning a large chunk of work | `wayfinder` |
| Turning discussion into a spec | `to-spec` |
| Breaking a plan into tickets | `to-tickets` |
| Implementing a spec or tickets | `implement` |

### Feature work

For any non-trivial feature, run `/grill-with-docs` or `/to-spec` before implementation to align on scope and terminology. Bug fixes may skip this if the reproduction is clear.

### Issue tracker

Issues and PRDs live as GitHub issues in `pyshivam/Geergit-Root-Helper`. See `docs/agents/issue-tracker.md`.

### Coding standards

Repo-wide conventions live in `docs/coding-standards.md` — the single place for them. Read it before changing code, and extend it instead of restating rules in child docs.

### Docs before code

1. **Docs before code**: Document decisions, learnings, and architecture changes before implementing them.
2. **Update docs first**: When a decision changes or a lesson is learned, update the relevant documentation before touching code.
3. **Update existing docs before creating new docs**: When new knowledge extends or contradicts existing docs, update the existing doc first. Create a new doc only when the knowledge is genuinely new.
4. **Code follows docs**: Implementation must match the documented design. If the design changes, update the docs first.

### Numbered docs

- Number ADRs sequentially in `docs/adr/` (e.g., `0001-state-management.md`).
- Number feature plans sequentially in `docs/plans/` (e.g., `0001-device-discovery-flow.md`).
- Number interface specs sequentially in `docs/specs/` (e.g., `0001-root-shell-interface.md`).
- Update the nearest `AGENTS.md` Child DOX Index when a new numbered doc is created.

## Verification

- Run `flutter analyze` and `flutter test` before committing.
- Build the platform you touched: `flutter build linux --debug` on Linux, `flutter build apk --debug` on Android. macOS and Windows builds need their own host OS — if you cannot run one, say so instead of claiming it.
- Verify UI changes on a running target, not only in a widget test — see "Verifying a build" in `docs/developer-guide.md`.

## Child DOX Index

- `lib/AGENTS.md` — Dart application code (entry point, screens, widgets, state)
- `test/AGENTS.md` — Widget and unit tests
- `docs/AGENTS.md` — Agent instructions and domain documentation

<!-- graft:start -->
## Graft — repo context graph

This repo is indexed in `graft/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `graft map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `graft ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `graft grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `graft skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use it to skim an API surface.
- `graft callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `graft/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `graft ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `graft build` (deterministic,
no API key, $0).
<!-- graft:end -->
