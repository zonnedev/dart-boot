#!/bin/bash
# Converts path dependencies to hosted (version) dependencies for publishing.
# Run before `melos publish`, then run restore_paths.sh after.
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"

for pubspec in "$DIR"/packages/*/pubspec.yaml; do
  # Replace:
  #   boot_core:
  #     path: ../boot_core
  # With:
  #   boot_core: ^0.1.0
  perl -i -0pe 's/  (boot\w+):\n    path: \.\.\/\w+\n/  $1: ^0.1.0\n/g' "$pubspec"
done

echo "✓ Converted path deps to hosted deps in all packages"
echo "  Run scripts/restore_paths.sh after publishing to revert"
