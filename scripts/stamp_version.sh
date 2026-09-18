#!/usr/bin/env bash
#
# Stamp the release version into pubspec.yaml and print it:
#
#   version: <base>-<sha7>+<build>
#
# - build: highest build number across existing releases, +1 — every release
#   gets a higher Android versionCode.
# - base: the patch bump of the last release's version (`1.0.0` -> `1.0.1`),
#   unless pubspec.yaml already carries something higher — edit `version:`
#   there to jump to `1.1.0` / `2.0.0` and this honours it.
#
# Needs `gh` authenticated (GH_TOKEN in CI) and must run from the repo root.
set -euo pipefail

pubspec_base=$(grep -m1 '^version:' pubspec.yaml |
  sed -E 's/^version:[[:space:]]*//; s/\+.*//')

tags=$(gh release list --limit 100 --json tagName --jq \
  '[.[] | select(.tagName | test("\\+[0-9]+$")) | .tagName]')
last_tag=$(printf '%s' "$tags" | jq -r '.[0] // ""')
last_build=$(printf '%s' "$tags" | jq -r '[.[] | split("+")[1] | tonumber] | max // 0')
next_build=$((last_build + 1))

last_version=$(printf '%s' "$last_tag" | sed -E 's/^v//; s/[-+].*//')
if [ -z "$last_version" ]; then
  base="$pubspec_base"
else
  IFS=. read -r major minor patch <<<"$last_version"
  bumped="$major.$minor.$((patch + 1))"
  base=$(printf '%s\n%s\n' "$bumped" "$pubspec_base" | sort -V | tail -1)
fi

sha="${GITHUB_SHA:-$(git rev-parse HEAD)}"
stamped="$base-${sha:0:7}+$next_build"

sed -i "s/^version:.*/version: $stamped/" pubspec.yaml
echo "Stamped version: $stamped (base $base, build $next_build)" >&2
printf '%s' "$stamped"
