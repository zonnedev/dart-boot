#!/bin/bash
# Runs all guide tests and reports results.
set -o pipefail

GUIDES_DIR="$(cd "$(dirname "$0")" && pwd)"
PASSED=()
FAILED=()
declare -A FAIL_OUTPUT

for dir in "$GUIDES_DIR"/0*/; do
  [ -d "$dir" ] || continue

  # Prefer todo_app subdir, then any dir with test/ folder, then first pubspec
  if [ -d "$dir/todo_app" ]; then
    app_dir="$dir/todo_app"
  else
    app_dir=$(find "$dir" -maxdepth 2 -type d -name "test" -exec dirname {} \; | head -1)
    [ -z "$app_dir" ] && app_dir=$(find "$dir" -maxdepth 2 -name "pubspec.yaml" -exec dirname {} \; | head -1)
  fi
  [ -z "$app_dir" ] && continue

  guide_name=$(basename "$dir")
  printf "\n━━━ %s ━━━\n" "$guide_name"

  output=$(cd "$app_dir" && boot test 2>&1)
  if echo "$output" | grep -q "All tests passed"; then
    PASSED+=("$guide_name")
    printf "  ✅ PASSED\n"
  else
    FAILED+=("$guide_name")
    FAIL_OUTPUT["$guide_name"]="$output"
    printf "  ❌ FAILED\n"
  fi
done

printf "\n\n════════════════════════════════════════\n"
printf "  RESULTS: %d passed, %d failed\n" "${#PASSED[@]}" "${#FAILED[@]}"
printf "════════════════════════════════════════\n"

if [ ${#FAILED[@]} -gt 0 ]; then
  for f in "${FAILED[@]}"; do
    printf "\n┌── ❌ %s ──────────────────────────────\n" "$f"
    echo "${FAIL_OUTPUT[$f]}" | grep -A2 "Error\|FAILED\|Expected\|Actual\|Some tests failed" | head -30
    printf "└──────────────────────────────────────────\n"
  done
  exit 1
fi

printf "\n🎉 All guides passed!\n"
