# Tests Agent Contract

## Purpose

Widget and unit tests for the Dart application, run with `flutter test`.

## Ownership

- Agents edit code under this tree.

## Local Contracts

- Suites live in `test/` and mirror `lib/` paths (`test/widget_test.dart` covers the app shell).
- `flutter test` is the runner — no test framework or new dependency is added.
- Tests never change `lib/` to make an assertion pass — a mismatch is a finding to report.

## Work Guidance

- Assert observable behaviour — what a user sees or a caller receives. Not wiring, source text, or a restatement of the implementation.
- Name each case after the behaviour it defends, so a failure names the case.
- Cover boundaries, invariants, precedence, and error paths; delete a test that cannot fail when behaviour changes.

## Verification

- `flutter test` from the repo root runs this suite.
- `flutter analyze` covers this tree; run it before committing.
