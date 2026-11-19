"""Screenshots the GNOME Shell on this session bus: the private one run.sh makes.

GNOME lets only a few well-known names ask for a screenshot. On a private bus with no
settings daemon running, this simply owns one of them first.
"""
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

bus = Gio.bus_get_sync(Gio.BusType.SESSION)
bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
              "RequestName", GLib.Variant("(su)", ("org.gnome.SettingsDaemon.MediaKeys", 4)),
              None, Gio.DBusCallFlags.NONE, -1, None)
bus.call_sync("org.gnome.Shell.Screenshot", "/org/gnome/Shell/Screenshot",
              "org.gnome.Shell.Screenshot", "Screenshot",
              GLib.Variant("(bbs)", (False, False, sys.argv[1])), GLib.VariantType("(bs)"),
              Gio.DBusCallFlags.NONE, 15000, None)
