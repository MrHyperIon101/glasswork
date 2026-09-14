#!/usr/bin/env bash
# Installs the Linux release build for this user, with its icon and app grid entry.
#
#   flutter build linux --release
#   linux/packaging/install.sh               install, or update an earlier install
#   linux/packaging/install.sh --uninstall   remove it again
#
# Everything goes under ~/.local, and nothing needs root. The app's data (tasks, the
# sign-in) lives in ~/.local/share/dev.mrhyperion.glasswork, and neither installing nor
# uninstalling touches it.
set -euo pipefail
shopt -s nullglob

app_id="dev.mrhyperion.glasswork"
binary="glasswork"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bundle="$(cd "$here/../.." && pwd)/build/linux/x64/release/bundle"

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
app_dir="$HOME/.local/opt/$app_id"
entry="$data_home/applications/$app_id.desktop"
icons="$data_home/icons/hicolor"

# The icon sizes this repository has, e.g. "48x48".
sizes() {
  for icon in "$here"/icons/*/apps/"$app_id".png; do
    basename "$(dirname "$(dirname "$icon")")"
  done
}

# GNOME finds new icons without an icon cache, so none is created. One that already exists
# is kept current, since a cache that is there gets used.
refresh_icon_cache() {
  if [[ -f "$icons/icon-theme.cache" ]] && command -v gtk-update-icon-cache >/dev/null; then
    gtk-update-icon-cache --quiet --ignore-theme-index "$icons" || true
  fi
}

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -rf -- "${app_dir:?}"
  rm -f -- "$entry"
  for size in $(sizes); do
    rm -f -- "$icons/$size/apps/$app_id.png"
  done
  refresh_icon_cache
  echo "Removed. The app's data in $data_home/$app_id is untouched."
  exit 0
fi

if [[ ! -x "$bundle/$binary" ]]; then
  echo "There is no release build at $bundle." >&2
  echo "Build one first:  flutter build linux --release" >&2
  exit 1
fi

mkdir -p "$app_dir"
if command -v rsync >/dev/null; then
  rsync -a --delete "$bundle/" "$app_dir/"
else
  rm -rf -- "${app_dir:?}"
  mkdir -p "$app_dir"
  cp -a "$bundle/." "$app_dir/"
fi

for size in $(sizes); do
  install -D -m 644 "$here/icons/$size/apps/$app_id.png" "$icons/$size/apps/$app_id.png"
done
refresh_icon_cache

template="$(<"$here/$app_id.desktop")"
mkdir -p "$(dirname "$entry")"
printf '%s\n' "${template//@EXEC@/\"$app_dir/$binary\"}" > "$entry"

echo "Installed. Open it from the app grid, or run $app_dir/$binary"
