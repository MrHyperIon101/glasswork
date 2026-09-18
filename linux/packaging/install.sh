#!/usr/bin/env bash
# Installs the Linux release build for this user, or updates an earlier install, through the
# same installer anyone else would open. See build_installer.sh to make that installer.
#
#   flutter build linux --release --dart-define-from-file=backend.json
#   linux/packaging/install.sh               install, or update an earlier install
#   linux/packaging/install.sh --uninstall   remove it again, keeping your tasks
#
# Everything goes under ~/.local, and nothing needs root. The app's data (tasks, the sign-in)
# lives in ~/.local/share/dev.mrhyperion.glasswork, and neither installing nor uninstalling
# touches it.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

"$here/build_installer.sh" --no-build --output "$work/setup" >/dev/null

if [[ "${1:-}" == "--uninstall" ]]; then
  "$work/setup" --uninstall --yes
else
  "$work/setup" --install --close-running
fi
