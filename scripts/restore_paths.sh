#!/bin/bash
# Restores path dependencies after publishing.
set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"
git checkout -- packages/*/pubspec.yaml
echo "✓ Restored path deps from git"
