/*
 * Glasswork's installer for Linux: one file that installs the app for the person who opens
 * it, updates an installation already there, or removes it.
 *
 * linux/packaging/build_installer.sh builds this program and appends the app to it, packed
 * as a gzip tarball, then a 16-byte trailer: the tarball's length, little-endian, and
 * GWSETUP1. Opened with no arguments it shows a window. With --install, or --uninstall
 * --yes, it does its work in the terminal instead.
 *
 * Everything goes in the home folder, so nothing asks for a password:
 *   ~/.local/opt/dev.mrhyperion.glasswork            the app, its VERSION and `uninstall`
 *   ~/.local/share/applications/<id>.desktop          its entry among the apps
 *   ~/.local/share/icons/hicolor/<size>/apps/<id>.png
 * Tasks and the sign-in live in ~/.local/share/dev.mrhyperion.glasswork, which installing
 * and updating never touch.
 *
 * An update unpacks next to the installed app, then swaps the two with renames, so a
 * failure at any step leaves the installed app as it was.
 */

#define _GNU_SOURCE

#include <errno.h>
#include <ftw.h>
#include <gio/gdesktopappinfo.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <gtk/gtk.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#ifdef GW_HAVE_ICON
#include "icon.h"
#endif

#define APP_ID "dev.mrhyperion.glasswork"
#define APP_NAME "Glasswork"
#define BINARY "glasswork"

#ifndef GW_VERSION
#define GW_VERSION "0.0.0+0"
#endif

static const char kMagic[8] = {'G', 'W', 'S', 'E', 'T', 'U', 'P', '1'};
enum { kTrailerSize = 16 };

static const int kIconSizes[] = {16, 24, 32, 48, 64, 128, 256, 512};

/* --- failing ------------------------------------------------------------------------ */

static gboolean fail(GError **error, const char *format, ...) G_GNUC_PRINTF(2, 3);

static gboolean fail(GError **error, const char *format, ...) {
  va_list args;
  va_start(args, format);
  char *message = g_strdup_vprintf(format, args);
  va_end(args);
  g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_FAILED, message);
  g_free(message);
  return FALSE;
}

/* --- where things go ---------------------------------------------------------------- */

static char *install_dir(void) {
  return g_build_filename(g_get_home_dir(), ".local", "opt", APP_ID, NULL);
}

static char *desktop_entry(void) {
  return g_build_filename(g_get_user_data_dir(), "applications", APP_ID ".desktop", NULL);
}

static char *icon_path(int size) {
  g_autofree char *dir = g_strdup_printf("%dx%d", size, size);
  return g_build_filename(g_get_user_data_dir(), "icons", "hicolor", dir, "apps",
                          APP_ID ".png", NULL);
}

static char *data_dir(void) {
  return g_build_filename(g_get_user_data_dir(), APP_ID, NULL);
}

/* [path] with the home folder written as ~, the way people read it. */
static char *home_relative(const char *path) {
  const char *home = g_get_home_dir();
  size_t length = strlen(home);
  if (length > 1 && strncmp(path, home, length) == 0 && path[length] == '/') {
    return g_strdup_printf("~%s", path + length);
  }
  return g_strdup(path);
}

/* The reminders' systemd units, which the app writes and an uninstall takes away. */
static char *reminder_unit(const char *name) {
  return g_build_filename(g_get_user_config_dir(), "systemd", "user", name, NULL);
}

/* --- versions ----------------------------------------------------------------------- */

/* "0.2.0+3" as four numbers, so versions compare as numbers rather than as text. */
static void parse_version(const char *text, long parts[4]) {
  for (int i = 0; i < 4; i++) parts[i] = 0;
  const char *p = text;
  for (int i = 0; i < 4 && p != NULL && *p != '\0'; i++) {
    char *end;
    parts[i] = strtol(p, &end, 10);
    if (end == p) break;
    p = end;
    if (*p != '.' && *p != '+') break;
    p++;
  }
}

static int compare_versions(const char *a, const char *b) {
  long x[4], y[4];
  parse_version(a, x);
  parse_version(b, y);
  for (int i = 0; i < 4; i++) {
    if (x[i] != y[i]) return x[i] < y[i] ? -1 : 1;
  }
  return 0;
}

/* "0.2.0 (build 3)" from "0.2.0+3". */
static char *describe_version(const char *version) {
  const char *plus = strchr(version, '+');
  if (plus == NULL) return g_strdup(version);
  return g_strdup_printf("%.*s (build %s)", (int)(plus - version), version, plus + 1);
}

/* The version installed now; "" for an install from before versions were recorded; NULL
   when there is no install. */
static char *installed_version(void) {
  g_autofree char *dir = install_dir();
  g_autofree char *binary = g_build_filename(dir, BINARY, NULL);
  if (!g_file_test(binary, G_FILE_TEST_IS_EXECUTABLE)) return NULL;

  g_autofree char *path = g_build_filename(dir, "VERSION", NULL);
  char *text = NULL;
  if (!g_file_get_contents(path, &text, NULL, NULL)) return g_strdup("");
  return g_strstrip(text);
}

/* --- the app inside this file ------------------------------------------------------- */

typedef struct {
  char *self;
  goffset payload_offset;
  goffset payload_size;
} Payload;

static gboolean find_payload(Payload *payload, GError **error) {
  payload->self = g_file_read_link("/proc/self/exe", NULL);
  if (payload->self == NULL) return fail(error, "Could not find this installer's own file.");

  FILE *file = fopen(payload->self, "rb");
  if (file == NULL) return fail(error, "Could not read %s: %s", payload->self, g_strerror(errno));

  struct stat st;
  unsigned char trailer[kTrailerSize];
  gboolean readable = fstat(fileno(file), &st) == 0 && st.st_size > kTrailerSize &&
                      fseeko(file, st.st_size - kTrailerSize, SEEK_SET) == 0 &&
                      fread(trailer, 1, kTrailerSize, file) == kTrailerSize;
  fclose(file);

  if (!readable || memcmp(trailer + 8, kMagic, sizeof kMagic) != 0) {
    return fail(error, "There is no app inside this file. Get the installer again.");
  }

  guint64 size = 0;
  for (int i = 7; i >= 0; i--) size = (size << 8) | trailer[i];
  if (size == 0 || size > (guint64)(st.st_size - kTrailerSize)) {
    return fail(error, "The app inside this installer is incomplete. Get the installer again.");
  }
  payload->payload_size = (goffset)size;
  payload->payload_offset = st.st_size - kTrailerSize - payload->payload_size;
  return TRUE;
}

static gboolean extract_payload(const Payload *payload, const char *dest, GError **error) {
  const char *argv[] = {"tar", "-xzf", "-", "-C", dest, NULL};
  GError *spawn_error = NULL;
  GSubprocess *tar = g_subprocess_newv(
      argv, G_SUBPROCESS_FLAGS_STDIN_PIPE | G_SUBPROCESS_FLAGS_STDERR_SILENCE, &spawn_error);
  if (tar == NULL) {
    fail(error, "Could not start tar to unpack the app: %s", spawn_error->message);
    g_error_free(spawn_error);
    return FALSE;
  }

  FILE *file = fopen(payload->self, "rb");
  gboolean ok = file != NULL && fseeko(file, payload->payload_offset, SEEK_SET) == 0;
  GOutputStream *in = g_subprocess_get_stdin_pipe(tar);
  char buffer[1 << 16];
  goffset left = payload->payload_size;
  while (ok && left > 0) {
    size_t want = left < (goffset)sizeof buffer ? (size_t)left : sizeof buffer;
    size_t got = fread(buffer, 1, want, file);
    ok = got > 0 && g_output_stream_write_all(in, buffer, got, NULL, NULL, NULL);
    left -= (goffset)got;
  }
  if (file != NULL) fclose(file);
  g_output_stream_close(in, NULL, NULL);

  gboolean unpacked = g_subprocess_wait(tar, NULL, NULL) && g_subprocess_get_successful(tar);
  g_object_unref(tar);

  if (!ok || !unpacked) {
    return fail(error, "The app inside this installer could not be unpacked. The file may be "
                       "damaged or incomplete: get the installer again.");
  }
  return TRUE;
}

/* The start of [from], [length] bytes of it, written to [to] as a program. */
static gboolean copy_prefix(const char *from, goffset length, const char *to, GError **error) {
  FILE *in = fopen(from, "rb");
  FILE *out = fopen(to, "wb");
  gboolean ok = in != NULL && out != NULL;
  char buffer[1 << 16];
  goffset left = length;
  while (ok && left > 0) {
    size_t want = left < (goffset)sizeof buffer ? (size_t)left : sizeof buffer;
    size_t got = fread(buffer, 1, want, in);
    ok = got > 0 && fwrite(buffer, 1, got, out) == got;
    left -= (goffset)got;
  }
  if (in != NULL) fclose(in);
  if (out != NULL && fclose(out) != 0) ok = FALSE;
  if (!ok) return fail(error, "Could not write %s.", to);
  if (g_chmod(to, 0755) != 0) return fail(error, "Could not make %s runnable.", to);
  return TRUE;
}

/* --- files -------------------------------------------------------------------------- */

static int remove_entry(const char *path, const struct stat *st, int flag, struct FTW *ftw) {
  (void)st;
  (void)flag;
  (void)ftw;
  return remove(path);
}

static gboolean remove_tree(const char *path) {
  struct stat st;
  if (lstat(path, &st) != 0) return errno == ENOENT;
  return nftw(path, remove_entry, 16, FTW_DEPTH | FTW_PHYS) == 0;
}

static void run_quietly(const char *const *argv) {
  GSubprocess *process = g_subprocess_newv(
      argv, G_SUBPROCESS_FLAGS_STDOUT_SILENCE | G_SUBPROCESS_FLAGS_STDERR_SILENCE, NULL);
  if (process == NULL) return;
  g_subprocess_wait(process, NULL, NULL);
  g_object_unref(process);
}

/* [path] as one quoted argument of a desktop entry's Exec line. The entry's own escapes
   apply on top of the quoting, which is why a backslash takes four. */
static char *exec_argument(const char *path) {
  GString *out = g_string_new("\"");
  for (const char *c = path; *c != '\0'; c++) {
    switch (*c) {
      case '"':
      case '`':
      case '$':
        g_string_append(out, "\\\\");
        g_string_append_c(out, *c);
        break;
      case '\\':
        g_string_append(out, "\\\\\\\\");
        break;
      case '%':
        g_string_append(out, "%%");
        break;
      default:
        g_string_append_c(out, *c);
    }
  }
  g_string_append_c(out, '"');
  return g_string_free(out, FALSE);
}

static char *replace_all(const char *text, const char *from, const char *to) {
  g_auto(GStrv) parts = g_strsplit(text, from, -1);
  return g_strjoinv(to, parts);
}

/* Swaps [staged] in for the installed app, putting the old one back if that fails. */
static gboolean put_app_in_place(const char *staged, GError **error) {
  g_autofree char *dir = install_dir();
  g_autofree char *parent = g_path_get_dirname(dir);
  g_autofree char *old = NULL;

  if (g_file_test(dir, G_FILE_TEST_EXISTS)) {
    old = g_strdup_printf("%s/.%s-old-%d", parent, APP_ID, (int)getpid());
    remove_tree(old);
    if (g_rename(dir, old) != 0) {
      return fail(error, "Could not move the installed Glasswork aside: %s", g_strerror(errno));
    }
  }
  if (g_rename(staged, dir) != 0) {
    int saved = errno;
    if (old != NULL) g_rename(old, dir);
    return fail(error, "Could not put Glasswork in place: %s", g_strerror(saved));
  }
  if (old != NULL) remove_tree(old);
  return TRUE;
}

static gboolean install_icons(const char *staging, GError **error) {
  for (size_t i = 0; i < G_N_ELEMENTS(kIconSizes); i++) {
    g_autofree char *size = g_strdup_printf("%dx%d", kIconSizes[i], kIconSizes[i]);
    g_autofree char *source = g_build_filename(staging, "share", "icons", "hicolor", size,
                                               "apps", APP_ID ".png", NULL);
    if (!g_file_test(source, G_FILE_TEST_EXISTS)) continue;

    g_autofree char *target = icon_path(kIconSizes[i]);
    g_autofree char *parent = g_path_get_dirname(target);
    if (g_mkdir_with_parents(parent, 0755) != 0) {
      return fail(error, "Could not create %s: %s", parent, g_strerror(errno));
    }
    g_autoptr(GFile) from = g_file_new_for_path(source);
    g_autoptr(GFile) to = g_file_new_for_path(target);
    if (!g_file_copy(from, to, G_FILE_COPY_OVERWRITE, NULL, NULL, NULL, error)) return FALSE;
  }
  return TRUE;
}

static gboolean write_desktop_entry(const char *staging, GError **error) {
  g_autofree char *template_path =
      g_build_filename(staging, "share", "applications", APP_ID ".desktop", NULL);
  g_autofree char *template = NULL;
  if (!g_file_get_contents(template_path, &template, NULL, error)) return FALSE;

  g_autofree char *dir = install_dir();
  g_autofree char *binary = g_build_filename(dir, BINARY, NULL);
  g_autofree char *uninstaller = g_build_filename(dir, "uninstall", NULL);
  g_autofree char *exec = exec_argument(binary);
  g_autofree char *quoted_uninstaller = exec_argument(uninstaller);
  g_autofree char *uninstall = g_strdup_printf("%s --uninstall", quoted_uninstaller);
  g_autofree char *with_exec = replace_all(template, "@EXEC@", exec);
  g_autofree char *entry = replace_all(with_exec, "@UNINSTALL@", uninstall);

  g_autofree char *path = desktop_entry();
  g_autofree char *parent = g_path_get_dirname(path);
  if (g_mkdir_with_parents(parent, 0755) != 0) {
    return fail(error, "Could not create %s: %s", parent, g_strerror(errno));
  }
  return g_file_set_contents(path, entry, -1, error);
}

/* Tells the desktop about the new entry and icons, where it keeps caches of them. */
static void refresh_desktop(void) {
  g_autofree char *hicolor = g_build_filename(g_get_user_data_dir(), "icons", "hicolor", NULL);
  g_autofree char *cache = g_build_filename(hicolor, "icon-theme.cache", NULL);
  if (g_file_test(cache, G_FILE_TEST_EXISTS)) {
    run_quietly((const char *[]){"gtk-update-icon-cache", "--quiet", "--ignore-theme-index",
                                 hicolor, NULL});
  }
  g_autofree char *apps = g_build_filename(g_get_user_data_dir(), "applications", NULL);
  if (g_file_test(apps, G_FILE_TEST_IS_DIR)) {
    run_quietly((const char *[]){"update-desktop-database", "--quiet", apps, NULL});
  }
}

/* --- the running app ---------------------------------------------------------------- */

/* Processes running the installed app. */
static GArray *running_instances(void) {
  GArray *pids = g_array_new(FALSE, FALSE, sizeof(pid_t));
  g_autofree char *dir = install_dir();
  g_autofree char *binary = g_build_filename(dir, BINARY, NULL);
  g_autofree char *deleted = g_strdup_printf("%s (deleted)", binary);

  GDir *proc = g_dir_open("/proc", 0, NULL);
  if (proc == NULL) return pids;
  const char *name;
  while ((name = g_dir_read_name(proc)) != NULL) {
    char *end;
    long pid = strtol(name, &end, 10);
    if (*end != '\0' || pid <= 0 || pid == (long)getpid()) continue;

    g_autofree char *link = g_strdup_printf("/proc/%ld/exe", pid);
    g_autofree char *exe = g_file_read_link(link, NULL);
    if (exe != NULL && (g_str_equal(exe, binary) || g_str_equal(exe, deleted))) {
      pid_t running = (pid_t)pid;
      g_array_append_val(pids, running);
    }
  }
  g_dir_close(proc);
  return pids;
}

static gboolean app_is_running(void) {
  g_autoptr(GArray) pids = running_instances();
  return pids->len > 0;
}

/* Asks the app to quit, and waits up to five seconds for it to. Every change the app makes
   is written as it happens, so there is nothing for it to save first. */
static gboolean close_app(GError **error) {
  g_autoptr(GArray) pids = running_instances();
  if (pids->len == 0) return TRUE;
  for (guint i = 0; i < pids->len; i++) kill(g_array_index(pids, pid_t, i), SIGTERM);

  for (int tries = 0; tries < 50; tries++) {
    if (!app_is_running()) return TRUE;
    g_usleep(100 * G_TIME_SPAN_MILLISECOND);
  }
  return fail(error, "Glasswork did not close. Quit it yourself, then try again.");
}

static gboolean launch_app(GError **error) {
  g_autofree char *entry = desktop_entry();
  g_autoptr(GDesktopAppInfo) info = g_desktop_app_info_new_from_filename(entry);
  if (info != NULL) {
    g_autoptr(GAppLaunchContext) context = NULL;
    GdkDisplay *display = gdk_display_get_default();
    if (display != NULL) context = G_APP_LAUNCH_CONTEXT(gdk_display_get_app_launch_context(display));
    return g_app_info_launch(G_APP_INFO(info), NULL, context, error);
  }

  g_autofree char *dir = install_dir();
  g_autofree char *binary = g_build_filename(dir, BINARY, NULL);
  char *argv[] = {binary, NULL};
  return g_spawn_async(NULL, argv, NULL, G_SPAWN_DEFAULT, NULL, NULL, NULL, error);
}

/* --- installing and removing -------------------------------------------------------- */

typedef void (*Report)(const char *status, gpointer data);

static gboolean install(const Payload *payload, gboolean may_close, Report report, gpointer data,
                        GError **error) {
  g_autofree char *dir = install_dir();
  g_autofree char *parent = g_path_get_dirname(dir);
  if (g_mkdir_with_parents(parent, 0755) != 0) {
    return fail(error, "Could not create %s: %s", parent, g_strerror(errno));
  }

  report("Unpacking Glasswork…", data);
  // Next to where it goes, so putting it in place is a rename rather than a copy.
  g_autofree char *staging = g_strdup_printf("%s/.%s-setup-XXXXXX", parent, APP_ID);
  if (g_mkdtemp(staging) == NULL) {
    return fail(error, "Could not make a folder to unpack into: %s", g_strerror(errno));
  }

  g_autofree char *app = g_build_filename(staging, "app", NULL);
  g_autofree char *binary = g_build_filename(app, BINARY, NULL);
  g_autofree char *uninstaller = g_build_filename(app, "uninstall", NULL);

  gboolean ok = extract_payload(payload, staging, error);
  if (ok && !g_file_test(binary, G_FILE_TEST_IS_EXECUTABLE)) {
    ok = fail(error, "There is no app inside this installer. Get the installer again.");
  }
  // The installer, without the app inside it, stays with the app to remove it later.
  if (ok) ok = copy_prefix(payload->self, payload->payload_offset, uninstaller, error);

  if (ok && app_is_running()) {
    if (!may_close) {
      ok = fail(error, "Glasswork is open. Quit it first, or run this with --close-running.");
    } else {
      report("Closing Glasswork…", data);
      ok = close_app(error);
    }
  }
  if (ok) {
    report("Putting Glasswork in place…", data);
    ok = put_app_in_place(app, error);
  }
  if (ok) {
    report("Adding Glasswork to your apps…", data);
    ok = install_icons(staging, error) && write_desktop_entry(staging, error);
    if (ok) refresh_desktop();
  }

  remove_tree(staging);
  return ok;
}

static void remove_reminders(void) {
  const char *timer = APP_ID "-reminders.timer";
  g_autofree char *timer_path = reminder_unit(timer);
  g_autofree char *service_path = reminder_unit(APP_ID "-reminders.service");
  g_autofree char *wants = g_build_filename(g_get_user_config_dir(), "systemd", "user",
                                            "timers.target.wants", timer, NULL);

  gboolean present = g_file_test(timer_path, G_FILE_TEST_EXISTS) ||
                     g_file_test(service_path, G_FILE_TEST_EXISTS);
  if (!present) return;

  run_quietly((const char *[]){"systemctl", "--user", "disable", "--now", timer, NULL});
  g_unlink(wants);
  g_unlink(timer_path);
  g_unlink(service_path);
  run_quietly((const char *[]){"systemctl", "--user", "daemon-reload", NULL});
}

static gboolean uninstall(gboolean remove_data, Report report, gpointer data, GError **error) {
  if (app_is_running()) {
    report("Closing Glasswork…", data);
    if (!close_app(error)) return FALSE;
  }

  report("Removing Glasswork…", data);
  remove_reminders();

  g_autofree char *entry = desktop_entry();
  g_unlink(entry);
  for (size_t i = 0; i < G_N_ELEMENTS(kIconSizes); i++) {
    g_autofree char *icon = icon_path(kIconSizes[i]);
    g_unlink(icon);
  }
  refresh_desktop();

  g_autofree char *dir = install_dir();
  if (!remove_tree(dir)) return fail(error, "Could not remove %s.", dir);

  if (remove_data) {
    g_autofree char *stored = data_dir();
    if (!remove_tree(stored)) return fail(error, "Could not remove %s.", stored);
  }
  return TRUE;
}

/* --- pages -------------------------------------------------------------------------- */

typedef struct {
  const char *title;
  const char *subtitle;
  const char *body;
  const char *note;
  gboolean working;
  const char *status;
  const char *check;
  const char *secondary;
  const char *primary;
  gboolean destructive;
} PageSpec;

typedef struct {
  GtkWidget *root;
  GtkWidget *status;
  GtkWidget *bar;
  GtkWidget *check;
  GtkWidget *secondary;
  GtkWidget *primary;
} Page;

/* The app's icon at full size, or NULL if this was built without it. Owned here. */
static GdkPixbuf *icon_pixbuf(void) {
#ifdef GW_HAVE_ICON
  static GdkPixbuf *icon = NULL;
  static gboolean loaded = FALSE;
  if (!loaded) {
    loaded = TRUE;
    GdkPixbufLoader *loader = gdk_pixbuf_loader_new();
    gboolean ok = gdk_pixbuf_loader_write(loader, kIcon, kIconLength, NULL);
    ok = gdk_pixbuf_loader_close(loader, NULL) && ok;
    if (ok) icon = g_object_ref(gdk_pixbuf_loader_get_pixbuf(loader));
    g_object_unref(loader);
  }
  return icon;
#else
  return NULL;
#endif
}

/* The app's icon, drawn sharp at twice its size for a scaled screen. */
static GtkWidget *app_icon(void) {
  enum { kSize = 96 };
  GdkPixbuf *full = icon_pixbuf();
  if (full != NULL) {
    GdkPixbuf *scaled = gdk_pixbuf_scale_simple(full, kSize * 2, kSize * 2, GDK_INTERP_HYPER);
    cairo_surface_t *surface = gdk_cairo_surface_create_from_pixbuf(scaled, 2, NULL);
    GtkWidget *image = gtk_image_new_from_surface(surface);
    cairo_surface_destroy(surface);
    g_object_unref(scaled);
    return image;
  }
  GtkWidget *fallback = gtk_image_new_from_icon_name(APP_ID, GTK_ICON_SIZE_DIALOG);
  gtk_image_set_pixel_size(GTK_IMAGE(fallback), kSize);
  return fallback;
}

/* How wide the text beside the icon is. Fixed, so every page is the same width and a long
   sentence wraps rather than widening the window. */
enum { kTextWidth = 340 };

/* Makes [label] wrap at [width]. Its height is then measured at that width however GTK
   asks, rather than at some narrower guess that leaves a gap under the text. */
static void wrap_label(GtkWidget *label, int width) {
  gtk_label_set_xalign(GTK_LABEL(label), 0);
  gtk_label_set_line_wrap(GTK_LABEL(label), TRUE);
  gtk_label_set_line_wrap_mode(GTK_LABEL(label), PANGO_WRAP_WORD_CHAR);
  gtk_label_set_max_width_chars(GTK_LABEL(label), 1);
  gtk_widget_set_size_request(label, width, -1);
}

static GtkWidget *text_label(const char *text, const char *style_class) {
  GtkWidget *label = gtk_label_new(text);
  wrap_label(label, kTextWidth);
  if (style_class != NULL) {
    gtk_style_context_add_class(gtk_widget_get_style_context(label), style_class);
  }
  return label;
}

static Page build_page(const PageSpec *spec) {
  Page page = {0};

  GtkWidget *root = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_container_set_border_width(GTK_CONTAINER(root), 24);

  GtkWidget *top = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 20);
  GtkWidget *icon = app_icon();
  gtk_widget_set_valign(icon, GTK_ALIGN_START);
  gtk_box_pack_start(GTK_BOX(top), icon, FALSE, FALSE, 0);

  GtkWidget *text = gtk_box_new(GTK_ORIENTATION_VERTICAL, 4);
  gtk_widget_set_valign(text, GTK_ALIGN_START);
  gtk_widget_set_margin_top(text, 8);

  GtkWidget *title = gtk_label_new(NULL);
  char *markup = g_markup_printf_escaped("<span size='x-large' weight='bold'>%s</span>",
                                         spec->title);
  gtk_label_set_markup(GTK_LABEL(title), markup);
  g_free(markup);
  wrap_label(title, kTextWidth);
  gtk_box_pack_start(GTK_BOX(text), title, FALSE, FALSE, 0);

  if (spec->subtitle != NULL) {
    gtk_box_pack_start(GTK_BOX(text), text_label(spec->subtitle, "dim-label"), FALSE, FALSE, 0);
  }
  if (spec->body != NULL) {
    GtkWidget *body = text_label(spec->body, NULL);
    gtk_widget_set_margin_top(body, 8);
    gtk_box_pack_start(GTK_BOX(text), body, FALSE, FALSE, 0);
  }
  if (spec->note != NULL) {
    GtkWidget *note = gtk_label_new(NULL);
    char *bold = g_markup_printf_escaped("<b>%s</b>", spec->note);
    gtk_label_set_markup(GTK_LABEL(note), bold);
    g_free(bold);
    wrap_label(note, kTextWidth);
    gtk_widget_set_margin_top(note, 8);
    gtk_box_pack_start(GTK_BOX(text), note, FALSE, FALSE, 0);
  }
  if (spec->working) {
    page.bar = gtk_progress_bar_new();
    gtk_widget_set_margin_top(page.bar, 14);
    gtk_box_pack_start(GTK_BOX(text), page.bar, FALSE, FALSE, 0);
    page.status = text_label(spec->status, "dim-label");
    gtk_box_pack_start(GTK_BOX(text), page.status, FALSE, FALSE, 0);
  }
  if (spec->check != NULL) {
    page.check = gtk_check_button_new_with_label(spec->check);
    // Narrower by the box beside it.
    wrap_label(gtk_bin_get_child(GTK_BIN(page.check)), kTextWidth - 36);
    gtk_widget_set_margin_top(page.check, 12);
    gtk_box_pack_start(GTK_BOX(text), page.check, FALSE, FALSE, 0);
  }

  gtk_box_pack_start(GTK_BOX(top), text, TRUE, TRUE, 0);
  gtk_box_pack_start(GTK_BOX(root), top, TRUE, TRUE, 0);

  if (spec->secondary != NULL || spec->primary != NULL) {
    // Each button as wide as its words, the way a Mac's are, rather than all as wide as
    // the longest.
    enum { kButtonWidth = 92 };
    GtkWidget *buttons = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_widget_set_halign(buttons, GTK_ALIGN_END);
    gtk_widget_set_margin_top(buttons, 24);
    if (spec->secondary != NULL) {
      page.secondary = gtk_button_new_with_label(spec->secondary);
      gtk_widget_set_size_request(page.secondary, kButtonWidth, -1);
      gtk_box_pack_start(GTK_BOX(buttons), page.secondary, FALSE, FALSE, 0);
    }
    if (spec->primary != NULL) {
      page.primary = gtk_button_new_with_label(spec->primary);
      gtk_widget_set_size_request(page.primary, kButtonWidth, -1);
      gtk_style_context_add_class(gtk_widget_get_style_context(page.primary),
                                  spec->destructive ? "destructive-action" : "suggested-action");
      gtk_widget_set_can_default(page.primary, TRUE);
      gtk_box_pack_start(GTK_BOX(buttons), page.primary, FALSE, FALSE, 0);
    }
    gtk_box_pack_end(GTK_BOX(root), buttons, FALSE, FALSE, 0);
  }

  page.root = root;
  return page;
}

/* Text a page holds, freed together once the page is built. */
typedef struct {
  PageSpec spec;
  char *owned[3];
} Text;

static void text_clear(Text *text) {
  for (size_t i = 0; i < G_N_ELEMENTS(text->owned); i++) g_clear_pointer(&text->owned[i], g_free);
}

typedef enum { OFFER_INSTALL, OFFER_UPDATE, OFFER_OPEN, OFFER_DOWNGRADE } Offer;

static Offer offer_for(const char *installed) {
  if (installed == NULL) return OFFER_INSTALL;
  if (*installed == '\0') return OFFER_UPDATE;
  int order = compare_versions(GW_VERSION, installed);
  return order > 0 ? OFFER_UPDATE : order == 0 ? OFFER_OPEN : OFFER_DOWNGRADE;
}

static Text confirm_install_text(const char *installed, gboolean running) {
  Text t = {0};
  char *version = describe_version(GW_VERSION);
  t.owned[0] = g_strdup_printf("Version %s", version);
  t.spec.subtitle = t.owned[0];
  t.spec.secondary = "Cancel";

  switch (offer_for(installed)) {
    case OFFER_INSTALL:
      t.spec.title = "Install " APP_NAME;
      t.spec.body = "Tasks and projects, planned against the time you actually have. Installs "
                    "for you alone, in your home folder, so it needs no password.";
      t.spec.primary = "Install";
      break;
    case OFFER_UPDATE: {
      char *have = *installed ? describe_version(installed) : NULL;
      t.owned[1] = g_strdup_printf(
          "You have %s%s. Updating keeps your tasks, your sign-in and your reminders.",
          have ? "version " : "an earlier version", have ? have : "");
      g_free(have);
      t.spec.title = "Update " APP_NAME;
      t.spec.body = t.owned[1];
      t.spec.primary = "Update";
      break;
    }
    case OFFER_OPEN:
      t.spec.title = APP_NAME " is up to date";
      t.spec.body = "This version is already installed. Reinstalling puts back anything missing "
                    "from it, and keeps your tasks.";
      t.spec.secondary = "Reinstall";
      t.spec.primary = "Open " APP_NAME;
      running = FALSE;
      break;
    case OFFER_DOWNGRADE: {
      char *have = describe_version(installed);
      t.owned[1] = g_strdup_printf(
          "You have version %s, which is newer. Your tasks are kept, but an older version may "
          "not be able to open what a newer one saved.", have);
      g_free(have);
      t.spec.title = "Install an older " APP_NAME "?";
      t.spec.body = t.owned[1];
      t.spec.primary = "Install older version";
      break;
    }
  }
  if (running) t.spec.note = "Glasswork is open. It will close, and open again once updated.";
  g_free(version);
  return t;
}

static Text confirm_uninstall_text(gboolean installed, gboolean running) {
  Text t = {0};
  if (!installed) {
    t.spec.title = APP_NAME " is not installed";
    t.spec.body = "There is nothing here to remove.";
    t.spec.primary = "Close";
    return t;
  }
  t.spec.title = "Uninstall " APP_NAME "?";
  t.spec.body = "Removes the app, its place among your apps, and its reminders from this "
                "computer. If you sign in to sync, your tasks stay in your account.";
  t.spec.check = "Also delete the tasks and sign-in kept on this computer";
  t.spec.secondary = "Cancel";
  t.spec.primary = "Uninstall";
  t.spec.destructive = TRUE;
  if (running) t.spec.note = "Glasswork is open, and will be closed first.";
  return t;
}

static Text working_text(gboolean uninstalling, Offer offer, const char *status) {
  Text t = {0};
  t.spec.title = uninstalling           ? "Removing " APP_NAME
                 : offer == OFFER_UPDATE ? "Updating " APP_NAME
                 : offer == OFFER_OPEN   ? "Reinstalling " APP_NAME
                                         : "Installing " APP_NAME;
  t.spec.working = TRUE;
  t.spec.status = status;
  return t;
}

static Text result_text(gboolean uninstalling, Offer offer, gboolean ok, const char *error,
                        gboolean reopened, gboolean removed_data) {
  Text t = {0};
  if (!ok) {
    t.spec.title = uninstalling ? APP_NAME " could not be removed"
                                : APP_NAME " could not be installed";
    t.spec.body = error;
    t.spec.primary = "Close";
    return t;
  }
  if (uninstalling) {
    t.spec.title = APP_NAME " has been removed";
    if (removed_data) {
      t.spec.body = "Its tasks and sign-in were deleted from this computer too.";
    } else {
      g_autofree char *stored = data_dir();
      t.owned[0] = home_relative(stored);
      t.owned[1] = g_strdup_printf(
          "Your tasks and sign-in are still on this computer, in %s, for if you install it again.",
          t.owned[0]);
      t.spec.body = t.owned[1];
    }
    t.spec.primary = "Close";
    return t;
  }

  t.spec.title = offer == OFFER_UPDATE ? APP_NAME " is updated"
                 : offer == OFFER_OPEN  ? APP_NAME " has been reinstalled"
                                        : APP_NAME " is installed";
  if (reopened) {
    t.spec.body = "It has been opened again, and is ready.";
    t.spec.primary = "Done";
  } else {
    t.spec.body = "Find it with your other apps, or open it now.";
    t.spec.secondary = "Done";
    t.spec.primary = "Open " APP_NAME;
  }
  return t;
}

/* --- the window --------------------------------------------------------------------- */

typedef struct {
  GtkWidget *window;
  Page page;
  Payload payload;
  gboolean payload_ok;
  char *payload_error;
  gboolean uninstalling;
  char *installed;
  Offer offer;
  gboolean was_running;
  gboolean remove_data;
  gboolean working;
  guint pulse;
} Ui;

static void on_primary(GtkButton *button, Ui *ui);
static void on_secondary(GtkButton *button, Ui *ui);

static void show_page(Ui *ui, Text *text) {
  GtkWidget *child = gtk_bin_get_child(GTK_BIN(ui->window));
  if (child != NULL) gtk_container_remove(GTK_CONTAINER(ui->window), child);

  ui->page = build_page(&text->spec);
  text_clear(text);
  gtk_container_add(GTK_CONTAINER(ui->window), ui->page.root);
  if (ui->page.primary != NULL) {
    g_signal_connect(ui->page.primary, "clicked", G_CALLBACK(on_primary), ui);
  }
  if (ui->page.secondary != NULL) {
    g_signal_connect(ui->page.secondary, "clicked", G_CALLBACK(on_secondary), ui);
  }
  gtk_widget_show_all(ui->page.root);
  if (ui->page.primary != NULL) {
    gtk_widget_grab_default(ui->page.primary);
    gtk_widget_grab_focus(ui->page.primary);
  }
}

typedef struct {
  Ui *ui;
  char *status;
} StatusUpdate;

static gboolean set_status(gpointer data) {
  StatusUpdate *update = data;
  if (update->ui->page.status != NULL) {
    gtk_label_set_text(GTK_LABEL(update->ui->page.status), update->status);
  }
  g_free(update->status);
  g_free(update);
  return G_SOURCE_REMOVE;
}

static void report_to_window(const char *status, gpointer data) {
  StatusUpdate *update = g_new0(StatusUpdate, 1);
  update->ui = data;
  update->status = g_strdup(status);
  g_idle_add(set_status, update);
}

static void report_to_terminal(const char *status, gpointer data) {
  (void)data;
  printf("%s\n", status);
  fflush(stdout);
}

static gboolean pulse(gpointer data) {
  Ui *ui = data;
  if (ui->page.bar != NULL) gtk_progress_bar_pulse(GTK_PROGRESS_BAR(ui->page.bar));
  return G_SOURCE_CONTINUE;
}

static void work(GTask *task, gpointer source, gpointer data, GCancellable *cancellable) {
  (void)source;
  (void)cancellable;
  Ui *ui = data;
  GError *error = NULL;
  gboolean ok = ui->uninstalling
                    ? uninstall(ui->remove_data, report_to_window, ui, &error)
                    : install(&ui->payload, TRUE, report_to_window, ui, &error);
  if (ok) {
    g_task_return_boolean(task, TRUE);
  } else {
    g_task_return_error(task, error);
  }
}

static void work_done(GObject *source, GAsyncResult *result, gpointer data) {
  (void)source;
  Ui *ui = data;
  GError *error = NULL;
  gboolean ok = g_task_propagate_boolean(G_TASK(result), &error);
  ui->working = FALSE;
  if (ui->pulse != 0) g_source_remove(ui->pulse);
  ui->pulse = 0;

  gboolean reopened = FALSE;
  if (ok && !ui->uninstalling && ui->was_running) reopened = launch_app(NULL);

  Text text = result_text(ui->uninstalling, ui->offer, ok, error ? error->message : NULL,
                          reopened, ui->remove_data);
  show_page(ui, &text);
  g_clear_error(&error);
}

static void start_work(Ui *ui) {
  ui->remove_data = ui->page.check != NULL &&
                    gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(ui->page.check));
  ui->was_running = !ui->uninstalling && app_is_running();
  ui->working = TRUE;

  Text text = working_text(ui->uninstalling, ui->offer, "Starting…");
  show_page(ui, &text);
  ui->pulse = g_timeout_add(120, pulse, ui);

  GTask *task = g_task_new(NULL, NULL, work_done, ui);
  g_task_set_task_data(task, ui, NULL);
  g_task_run_in_thread(task, work);
  g_object_unref(task);
}

static void on_primary(GtkButton *button, Ui *ui) {
  const char *label = gtk_button_get_label(button);
  if (g_str_equal(label, "Close") || g_str_equal(label, "Done")) {
    gtk_widget_destroy(ui->window);
  } else if (g_str_has_prefix(label, "Open ")) {
    GError *error = NULL;
    if (launch_app(&error)) {
      gtk_widget_destroy(ui->window);
    } else {
      Text text = result_text(FALSE, ui->offer, FALSE, error->message, FALSE, FALSE);
      text.spec.title = APP_NAME " could not be opened";
      show_page(ui, &text);
      g_error_free(error);
    }
  } else {
    start_work(ui);
  }
}

static void on_secondary(GtkButton *button, Ui *ui) {
  if (g_str_equal(gtk_button_get_label(button), "Reinstall")) {
    start_work(ui);
  } else {
    gtk_widget_destroy(ui->window);
  }
}

static gboolean on_delete(GtkWidget *window, GdkEvent *event, Ui *ui) {
  (void)window;
  (void)event;
  // Closing halfway through an update would leave it half done.
  return ui->working;
}

static int run_window(gboolean uninstalling) {
  Ui ui = {0};
  ui.uninstalling = uninstalling;
  ui.installed = installed_version();
  ui.offer = offer_for(ui.installed);

  GError *error = NULL;
  if (!uninstalling) {
    ui.payload_ok = find_payload(&ui.payload, &error);
    if (!ui.payload_ok) ui.payload_error = g_strdup(error->message);
    g_clear_error(&error);
  }

  ui.window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(ui.window),
                       uninstalling ? "Uninstall " APP_NAME : APP_NAME " Setup");
  gtk_window_set_resizable(GTK_WINDOW(ui.window), FALSE);
  gtk_window_set_position(GTK_WINDOW(ui.window), GTK_WIN_POS_CENTER);
  if (icon_pixbuf() != NULL) gtk_window_set_icon(GTK_WINDOW(ui.window), icon_pixbuf());
  g_signal_connect(ui.window, "delete-event", G_CALLBACK(on_delete), &ui);
  g_signal_connect(ui.window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

  Text text;
  if (uninstalling) {
    text = confirm_uninstall_text(ui.installed != NULL, app_is_running());
  } else if (!ui.payload_ok) {
    text = result_text(FALSE, ui.offer, FALSE, ui.payload_error, FALSE, FALSE);
  } else {
    text = confirm_install_text(ui.installed, app_is_running());
  }
  show_page(&ui, &text);
  gtk_widget_show(ui.window);
  gtk_main();

  g_free(ui.installed);
  g_free(ui.payload.self);
  g_free(ui.payload_error);
  return 0;
}

/* Draws every page to a PNG in [dir], to check how they look without clicking through. */
static int render_pages(const char *dir) {
  if (g_mkdir_with_parents(dir, 0755) != 0) {
    fprintf(stderr, "Could not create %s\n", dir);
    return 1;
  }
  struct {
    const char *name;
    Text text;
  } pages[] = {
      {"install", confirm_install_text(NULL, FALSE)},
      {"update", confirm_install_text("0.1.0+1", TRUE)},
      {"update-from-unknown", confirm_install_text("", FALSE)},
      {"up-to-date", confirm_install_text(GW_VERSION, FALSE)},
      {"downgrade", confirm_install_text("99.0.0+99", FALSE)},
      {"working", working_text(FALSE, OFFER_UPDATE, "Putting Glasswork in place…")},
      {"installed", result_text(FALSE, OFFER_INSTALL, TRUE, NULL, FALSE, FALSE)},
      {"updated-reopened", result_text(FALSE, OFFER_UPDATE, TRUE, NULL, TRUE, FALSE)},
      {"failed", result_text(FALSE, OFFER_INSTALL, FALSE,
                             "The app inside this installer could not be unpacked. The file may "
                             "be damaged or incomplete: get the installer again.",
                             FALSE, FALSE)},
      {"uninstall", confirm_uninstall_text(TRUE, TRUE)},
      {"uninstalled", result_text(TRUE, OFFER_OPEN, TRUE, NULL, FALSE, FALSE)},
  };

  for (size_t i = 0; i < G_N_ELEMENTS(pages); i++) {
    GtkWidget *offscreen = gtk_offscreen_window_new();
    Page page = build_page(&pages[i].text.spec);
    text_clear(&pages[i].text);
    gtk_container_add(GTK_CONTAINER(offscreen), page.root);
    gtk_widget_show_all(offscreen);
    if (page.bar != NULL) gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(page.bar), 0.6);
    while (gtk_events_pending()) gtk_main_iteration();

    // Drawn over the theme's window colour: an offscreen window has no ground of its own,
    // and text drawn onto nothing comes out fringed.
    int width = gtk_widget_get_allocated_width(offscreen);
    int height = gtk_widget_get_allocated_height(offscreen);
    cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_RGB24, width, height);
    cairo_t *cr = cairo_create(surface);
    GdkRGBA ground;
    if (!gtk_style_context_lookup_color(gtk_widget_get_style_context(offscreen),
                                        "theme_bg_color", &ground)) {
      gdk_rgba_parse(&ground, "#242424");
    }
    gdk_cairo_set_source_rgba(cr, &ground);
    cairo_paint(cr);
    gtk_widget_draw(offscreen, cr);
    cairo_destroy(cr);

    g_autofree char *file = g_strdup_printf("%s/%s.png", dir, pages[i].name);
    if (cairo_surface_write_to_png(surface, file) != CAIRO_STATUS_SUCCESS) {
      fprintf(stderr, "Could not draw %s\n", file);
    }
    cairo_surface_destroy(surface);
    gtk_widget_destroy(offscreen);
  }
  return 0;
}

/* --- in the terminal ---------------------------------------------------------------- */

static int install_in_terminal(gboolean may_close) {
  Payload payload = {0};
  GError *error = NULL;
  g_autofree char *installed = installed_version();
  Offer offer = offer_for(installed);

  gboolean ok = find_payload(&payload, &error) &&
                install(&payload, may_close, report_to_terminal, NULL, &error);
  g_free(payload.self);
  if (!ok) {
    fprintf(stderr, "%s\n", error->message);
    g_error_free(error);
    return 1;
  }

  g_autofree char *version = describe_version(GW_VERSION);
  printf("%s %s, version %s. Open it from your apps.\n", APP_NAME,
         offer == OFFER_UPDATE ? "is updated" : offer == OFFER_OPEN ? "is reinstalled"
                                                                  : "is installed",
         version);
  return 0;
}

static int uninstall_in_terminal(gboolean remove_data) {
  g_autofree char *installed = installed_version();
  if (installed == NULL) {
    printf("%s is not installed.\n", APP_NAME);
    return 0;
  }
  GError *error = NULL;
  if (!uninstall(remove_data, report_to_terminal, NULL, &error)) {
    fprintf(stderr, "%s\n", error->message);
    g_error_free(error);
    return 1;
  }
  g_autofree char *stored = data_dir();
  g_autofree char *data = home_relative(stored);
  if (remove_data) {
    printf("%s has been removed, with its tasks and sign-in.\n", APP_NAME);
  } else {
    printf("%s has been removed. Your tasks and sign-in are still in %s.\n", APP_NAME, data);
  }
  return 0;
}

int main(int argc, char **argv) {
  // A tar that stops reading early must be an error to report, not a signal that kills this.
  signal(SIGPIPE, SIG_IGN);

  gboolean opt_install = FALSE, opt_uninstall = FALSE, opt_yes = FALSE;
  gboolean opt_close = FALSE, opt_remove_data = FALSE, opt_version = FALSE;
  char *opt_render = NULL;
  GOptionEntry entries[] = {
      {"install", 0, 0, G_OPTION_ARG_NONE, &opt_install,
       "Install or update in the terminal, without a window", NULL},
      {"close-running", 0, 0, G_OPTION_ARG_NONE, &opt_close,
       "With --install, close Glasswork first if it is open", NULL},
      {"uninstall", 0, 0, G_OPTION_ARG_NONE, &opt_uninstall, "Remove Glasswork", NULL},
      {"yes", 0, 0, G_OPTION_ARG_NONE, &opt_yes,
       "With --uninstall, remove it in the terminal, without a window", NULL},
      {"remove-data", 0, 0, G_OPTION_ARG_NONE, &opt_remove_data,
       "With --uninstall --yes, also delete the tasks and sign-in kept on this computer", NULL},
      {"version", 0, 0, G_OPTION_ARG_NONE, &opt_version, "Print the version this installs", NULL},
      {"render", 0, G_OPTION_FLAG_HIDDEN, G_OPTION_ARG_FILENAME, &opt_render,
       "Draw each page to a PNG in DIR", "DIR"},
      {NULL, 0, 0, 0, NULL, NULL, NULL},
  };

  GOptionContext *context = g_option_context_new("- install " APP_NAME);
  g_option_context_add_main_entries(context, entries, NULL);
  GError *error = NULL;
  gboolean parsed = g_option_context_parse(context, &argc, &argv, &error);
  g_option_context_free(context);
  if (!parsed) {
    fprintf(stderr, "%s\n", error->message);
    g_error_free(error);
    return 2;
  }

  if (opt_version) {
    printf("%s\n", GW_VERSION);
    return 0;
  }
  // The copy kept with the app, which has no app inside it, only ever removes it.
  g_autofree char *self = g_file_read_link("/proc/self/exe", NULL);
  g_autofree char *name = self != NULL ? g_path_get_basename(self) : NULL;
  gboolean uninstalling = opt_uninstall || (name != NULL && g_str_equal(name, "uninstall"));

  if (opt_install) return install_in_terminal(opt_close);
  if (uninstalling && opt_yes) return uninstall_in_terminal(opt_remove_data);

  if (!gtk_init_check(&argc, &argv)) {
    fprintf(stderr, "There is no display to show the installer on. Run it with --install to "
                    "install in the terminal.\n");
    return 1;
  }
  // Dark, like the app.
  g_object_set(gtk_settings_get_default(), "gtk-application-prefer-dark-theme", TRUE, NULL);
  if (opt_render != NULL) return render_pages(opt_render);
  return run_window(uninstalling);
}
