import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// Only in the throwaway session tool/nested_session/run.sh makes: leaves the overview once
// the shell is up, so what is captured is the desktop and its windows; and lets a test press
// keys, move the pointer and copy text in that session, over D-Bus, as a person would.
const INTERFACE = `
<node>
  <interface name="dev.glasswork.Harness">
    <method name="Keys"><arg type="s" name="chords" direction="in"/></method>
    <method name="Type"><arg type="s" name="text" direction="in"/></method>
    <method name="Hold"><arg type="s" name="key" direction="in"/><arg type="b" name="down" direction="in"/></method>
    <method name="Move"><arg type="d" name="x" direction="in"/><arg type="d" name="y" direction="in"/></method>
    <method name="Copy"><arg type="s" name="text" direction="in"/></method>
  </interface>
</node>`;

const NAMES = {
    return: 0xff0d, escape: 0xff1b, tab: 0xff09, backspace: 0xff08,
    up: 0xff52, down: 0xff54, left: 0xff51, right: 0xff53, space: 0x20,
    ctrl: 0xffe3, alt: 0xffe9, shift: 0xffe1, super: 0xffeb,
};

export default class Harness extends Extension {
    enable() {
        const leave = () => Main.overview.hide();
        if (Main.layoutManager._startingUp)
            this._id = Main.layoutManager.connect('startup-complete', leave);
        else
            leave();

        const seat = global.stage.context.get_backend().get_default_seat();
        this._keyboard = seat.create_virtual_device(Clutter.InputDeviceType.KEYBOARD_DEVICE);
        this._pointer = seat.create_virtual_device(Clutter.InputDeviceType.POINTER_DEVICE);
        this._dbus = Gio.DBusExportedObject.wrapJSObject(INTERFACE, {
            // "ctrl+1 down return": each chord pressed and let go in turn.
            Keys: chords => {
                for (const chord of chords.split(/\s+/).filter(c => c)) {
                    const keys = chord.toLowerCase().split('+').map(k => NAMES[k] ?? k.codePointAt(0));
                    keys.forEach(k => this._key(k, true));
                    [...keys].reverse().forEach(k => this._key(k, false));
                }
            },
            Type: text => {
                for (const char of text) {
                    this._key(char.codePointAt(0), true);
                    this._key(char.codePointAt(0), false);
                }
            },
            // A key held down, or let go: Alt shows where a file is for as long as it is held.
            Hold: (key, down) => this._key(NAMES[key.toLowerCase()] ?? key.codePointAt(0), down),
            Move: (x, y) => this._pointer.notify_absolute_motion(GLib.get_monotonic_time(), x, y),
            Copy: text => St.Clipboard.get_default().set_text(St.ClipboardType.CLIPBOARD, text),
        });
        this._dbus.export(Gio.DBus.session, '/dev/glasswork/Harness');
    }

    _key(keyval, down) {
        this._keyboard.notify_keyval(GLib.get_monotonic_time(), keyval,
            down ? Clutter.KeyState.PRESSED : Clutter.KeyState.RELEASED);
    }

    disable() {
        this._dbus?.unexport();
        if (this._id)
            Main.layoutManager.disconnect(this._id);
    }
}
