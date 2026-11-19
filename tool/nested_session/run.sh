#!/usr/bin/env bash
# Runs Glasswork in a throwaway headless GNOME Shell and screenshots that session's screen.
#
# Nothing of the real session is touched: the shell has a virtual monitor and no window on
# your desktop, and the session has its own HOME, settings, data and bus. It is how the
# Linux app and Glasswork Spotlight are checked on screen, and the only way to check the
# extension at all without loading it into the shell you are using.
#
#   tool/nested_session/run.sh OUT.png
#
# Set, to change what happens:
#   NESTED_APP=path        the Glasswork binary (the debug build); none to run no app
#   NESTED_WAIT=seconds    how long after starting the app before NESTED_THEN and the capture
#   NESTED_EXTENSION=1     install and enable Glasswork Spotlight in the session
#   NESTED_SERVICE=1       install the D-Bus activation file, so a call can wake the app
#   NESTED_MONITOR=WxH@R   the virtual monitor (default 1920x1080)
#   NESTED_MORE_EXTENSIONS='uuid …'  copies of these, from your own extensions folder, enabled
#                          too: to see Spotlight beside the extensions a real session runs
#   NESTED_THEN='...'      commands run in the session before the capture, e.g. gdbus calls
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out="$(realpath -m "${1:?an output .png}")"
app="${NESTED_APP:-$root/build/linux/x64/debug/bundle/glasswork}"

home="$(mktemp -d)"
# Unix sockets take at most 108 characters of path, so the runtime directory is short.
runtime="$(mktemp -d /tmp/gw-nested.XXXX)"
chmod 700 "$runtime"
cleanup() {
  # What the session's bus started — portals, the calendar, the file index — outlives the bus.
  # Closed here, from outside the session, and only what has this session's runtime directory,
  # so nothing of the real session is ever touched.
  for p in $(pgrep -u "$(id -u)" . 2>/dev/null); do
    { tr '\0' '\n' < "/proc/$p/environ"; } 2>/dev/null | grep -qx "XDG_RUNTIME_DIR=$runtime" &&
      kill "$p" 2>/dev/null
  done
  sleep 0.5
  # The session's portals mount these, and the mounts outlive it by a moment.
  for mount in doc gvfs; do fusermount3 -u -z "$runtime/$mount" 2>/dev/null; done
  rm -rf "$home" "$runtime" 2>/dev/null
}
trap cleanup EXIT

data="$home/.local/share"
mkdir -p "$data/gnome-shell/extensions" "$home/.config" "$home/.cache"
cp -r "$here/harness@glasswork.test" "$data/gnome-shell/extensions/"
extensions="'harness@glasswork.test'"
if [[ -n "${NESTED_EXTENSION:-}" ]]; then
  ext="$data/gnome-shell/extensions/spotlight@glasswork.mrhyperion.dev"
  cp -r "$root/linux/gnome-extension/spotlight@glasswork.mrhyperion.dev" "$ext"
  glib-compile-schemas "$ext/schemas"
  extensions+=", 'spotlight@glasswork.mrhyperion.dev'"
fi
for uuid in ${NESTED_MORE_EXTENSIONS:-}; do
  from="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$uuid"
  [[ -d "$from" ]] || from="/usr/share/gnome-shell/extensions/$uuid"
  [[ -d "$from" ]] || continue
  cp -r "$from" "$data/gnome-shell/extensions/" 2>/dev/null
  extensions+=", '$uuid'"
done
if [[ -n "${NESTED_SERVICE:-}" ]]; then
  mkdir -p "$data/dbus-1/services"
  printf '[D-BUS Service]\nName=dev.mrhyperion.glasswork\nExec=%s --background\n' "$app" \
    > "$data/dbus-1/services/dev.mrhyperion.glasswork.service"
fi

session=$(cat <<SESSION
gsettings set org.gnome.shell welcome-dialog-last-shown-version '999'
gsettings set org.gnome.shell disable-user-extensions false
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.shell enabled-extensions "[$extensions]"
gnome-shell --headless --virtual-monitor "${NESTED_MONITOR:-1920x1080}" \
  --wayland-display gw-nested --no-x11 > "$home/shell.log" 2>&1 &
shell=\$!
for _ in \$(seq 80); do
  gdbus introspect --session --dest org.gnome.Shell.Screenshot \
    --object-path /org/gnome/Shell/Screenshot >/dev/null 2>&1 && break
  sleep 0.5
done
app_pid=
if [[ "$app" != none ]]; then
  WAYLAND_DISPLAY=gw-nested GDK_BACKEND=wayland "$app" > "$home/app.log" 2>&1 &
  app_pid=\$!
fi
sleep ${NESTED_WAIT:-6}
${NESTED_THEN:-true}
python3 "$here/screenshot.py" "$out"
[[ -n "\$app_pid" ]] && kill \$app_pid 2>/dev/null
# A copy D-Bus woke is a child of the session's bus, not of this script: closed only if it
# is this binary and its runtime directory is this session's, so nothing else ever is.
for p in \$(pgrep -f -- "$app --background"); do
  grep -qz "XDG_RUNTIME_DIR=$runtime" /proc/\$p/environ 2>/dev/null && kill \$p
done
kill \$shell 2>/dev/null
wait
SESSION
)

env -i HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_DATA_HOME="$data" \
  XDG_CACHE_HOME="$home/.cache" XDG_RUNTIME_DIR="$runtime" PATH="$PATH" \
  LANG="${LANG:-C.UTF-8}" dbus-run-session -- bash -c "$session" > "$home/session.log" 2>&1

# The logs outlive the session, for whoever reads them next.
cp "$home/shell.log" "${out%.png}.shell.log" 2>/dev/null
cp "$home/app.log" "${out%.png}.app.log" 2>/dev/null
cp "$home/session.log" "${out%.png}.session.log" 2>/dev/null
[[ -f "$out" ]] && echo "captured $out" || { echo "no capture; see ${out%.png}.shell.log" >&2; exit 1; }
