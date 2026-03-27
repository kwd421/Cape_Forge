#!/bin/zsh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_CACHE="$PROJECT_DIR/.cache/clang/ModuleCache"

mkdir -p "$MODULE_CACHE"

cd "$PROJECT_DIR"

env \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
  SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" \
  swift build

exec "$PROJECT_DIR/.build/debug/CapeForge"
