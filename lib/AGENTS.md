# App Layer Agent Contract

## Purpose

Owns the Dart application layer: the entry point, screens, widgets, and app-level state.

## Ownership

- Agents edit code under this tree.
- Human maintainers approve product and UX decisions.

## Local Contracts

- Read root `AGENTS.md` first.
- Read `CONTEXT.md` for domain terminology.
- Follow `docs/coding-standards.md` for layout, identity, and dependency rules.

## Work Guidance

- `lib/main.dart` holds `main()` and the root `MaterialApp`.
- Organize by feature folder (`lib/<feature>/…`) once a second screen exists; keep shared widgets in `lib/widgets/` and pure helpers in `lib/utils/`.
- Prefer `const` constructors and small single-purpose widgets; extract at the second identical use.
- Do not add packages without explicit user approval.
- When a change alters app identity (name, id, window title), update every platform in the same change — see the identity table in `docs/coding-standards.md`.

## Verification

- `flutter analyze` and `flutter test` from the repo root before committing changes in this tree.
- Run the app on the platform you touched and exercise the changed path (see `docs/developer-guide.md`); a passing widget test alone does not verify a UI change.

## Child DOX Index

No child AGENTS.md files yet. Add one when a subfolder becomes a durable boundary with its own rules.
