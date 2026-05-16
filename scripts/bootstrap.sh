#!/usr/bin/env bash
# Bootstrap a fresh clone for local development.
# Installs node deps and builds the native compiler, no sandbox/credentials required.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

echo "==> npm install"
npm install

echo "==> make -C native/zero-c"
make -C native/zero-c

echo "==> npm install -w zero-lang (extension workspace)"
npm install -w zero-lang

echo
echo "bootstrap ok"
echo "next: npm run test:local"
