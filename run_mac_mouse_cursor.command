#!/bin/zsh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$PROJECT_DIR/dist/Cape Forge.app"

"$PROJECT_DIR/package_mac_mouse_cursor.command"

exec open "$APP_PATH"
