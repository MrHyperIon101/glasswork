#include "desktop_shell.h"

#include <dlfcn.h>

#include <cstring>
#include <initializer_list>

namespace {

constexpr const char* kChannel = "dev.mrhyperion.glasswork/desktop";

// The parts of AppIndicator this uses. The library is loaded as the app starts rather than
// linked, so the app still starts on a desktop without it, only with no tray to keep it in.
struct Indicator {
  void* library = nullptr;
  GObject* (*create)(const char* id, const char* icon_name, int category) = nullptr;
  void (*set_status)(GObject* indicator, int status) = nullptr;
  void (*set_menu)(GObject* indicator, GtkMenu* menu) = nullptr;
  void (*set_title)(GObject* indicator, const char* title) = nullptr;
  void (*set_icon_theme_path)(GObject* indicator, const char* path) = nullptr;
};

// AppIndicatorCategory and AppIndicatorStatus, as the library numbers them.
const int kCategoryApplicationStatus = 0;
const int kStatusPassive = 0;
const int kStatusActive = 1;

// Ayatana's, which current desktops ship, or else the original it replaced.
bool LoadIndicator(Indicator* out) {
  for (const char* name :
       {"libayatana-appindicator3.so.1", "libappindicator3.so.1"}) {
    void* library = dlopen(name, RTLD_LAZY | RTLD_LOCAL);
    if (library == nullptr) continue;

    Indicator loaded;
    loaded.library = library;
    loaded.create = reinterpret_cast<GObject* (*)(const char*, const char*, int)>(
        dlsym(library, "app_indicator_new"));
    loaded.set_status = reinterpret_cast<void (*)(GObject*, int)>(
        dlsym(library, "app_indicator_set_status"));
    loaded.set_menu = reinterpret_cast<void (*)(GObject*, GtkMenu*)>(
        dlsym(library, "app_indicator_set_menu"));
    loaded.set_title = reinterpret_cast<void (*)(GObject*, const char*)>(
        dlsym(library, "app_indicator_set_title"));
    loaded.set_icon_theme_path = reinterpret_cast<void (*)(GObject*, const char*)>(
        dlsym(library, "app_indicator_set_icon_theme_path"));

    if (loaded.create != nullptr && loaded.set_status != nullptr &&
        loaded.set_menu != nullptr && loaded.set_title != nullptr &&
        loaded.set_icon_theme_path != nullptr) {
      *out = loaded;
      return true;
    }
    dlclose(library);
  }
  return false;
}

}  // namespace

struct _DesktopShell {
  GtkApplication* application;
  GtkWindow* window;
  FlMethodChannel* channel;

  Indicator indicator;
  bool indicator_loaded;

  // While the tray icon is shown.
  GObject* tray;
  GtkWidget* menu;

  // Whether closing the window leaves the app running in the tray.
  bool keep_in_tray;
};

void desktop_shell_present(DesktopShell* shell) {
  gtk_widget_show(GTK_WIDGET(shell->window));
  // The time of the click that asked for it, so the desktop lets the window come forward.
  gtk_window_present_with_time(shell->window, gtk_get_current_event_time());
}

static void tell_dart(DesktopShell* shell, const char* method) {
  fl_method_channel_invoke_method(shell->channel, method, nullptr, nullptr,
                                  nullptr, nullptr);
}

static void on_open(GtkMenuItem* item, gpointer data) {
  desktop_shell_present(static_cast<DesktopShell*>(data));
}

static void on_new_task(GtkMenuItem* item, gpointer data) {
  DesktopShell* shell = static_cast<DesktopShell*>(data);
  desktop_shell_present(shell);
  tell_dart(shell, "newTask");
}

static void on_new_note(GtkMenuItem* item, gpointer data) {
  DesktopShell* shell = static_cast<DesktopShell*>(data);
  desktop_shell_present(shell);
  tell_dart(shell, "newNote");
}

static void on_quit(GtkMenuItem* item, gpointer data) {
  DesktopShell* shell = static_cast<DesktopShell*>(data);
  g_application_quit(G_APPLICATION(shell->application));
}

static void add_item(GtkWidget* menu,
                     const char* label,
                     GCallback callback,
                     DesktopShell* shell) {
  GtkWidget* item = gtk_menu_item_new_with_label(label);
  g_signal_connect(item, "activate", callback, shell);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
}

// The folder holding the tray icon: data/tray, beside the executable.
static gchar* tray_icon_folder() {
  g_autofree gchar* executable = g_file_read_link("/proc/self/exe", nullptr);
  if (executable == nullptr) return nullptr;
  g_autofree gchar* bundle = g_path_get_dirname(executable);
  return g_build_filename(bundle, "data", "tray", nullptr);
}

static void show_tray(DesktopShell* shell) {
  if (shell->tray != nullptr || !shell->indicator_loaded) return;

  shell->menu = gtk_menu_new();
  g_object_ref_sink(shell->menu);
  add_item(shell->menu, "Open Glasswork", G_CALLBACK(on_open), shell);
  add_item(shell->menu, "New task", G_CALLBACK(on_new_task), shell);
  add_item(shell->menu, "New note", G_CALLBACK(on_new_note), shell);
  gtk_menu_shell_append(GTK_MENU_SHELL(shell->menu),
                        gtk_separator_menu_item_new());
  add_item(shell->menu, "Quit Glasswork", G_CALLBACK(on_quit), shell);
  gtk_widget_show_all(shell->menu);

  shell->tray = shell->indicator.create(APPLICATION_ID, "glasswork-tray",
                                        kCategoryApplicationStatus);
  g_autofree gchar* folder = tray_icon_folder();
  if (folder != nullptr) shell->indicator.set_icon_theme_path(shell->tray, folder);
  shell->indicator.set_title(shell->tray, "Glasswork");
  shell->indicator.set_menu(shell->tray, GTK_MENU(shell->menu));
  shell->indicator.set_status(shell->tray, kStatusActive);
}

static void hide_tray(DesktopShell* shell) {
  if (shell->tray != nullptr) {
    shell->indicator.set_status(shell->tray, kStatusPassive);
    g_clear_object(&shell->tray);
  }
  if (shell->menu != nullptr) {
    gtk_widget_destroy(shell->menu);
    g_clear_object(&shell->menu);
  }
}

static gboolean on_delete(GtkWidget* window, GdkEvent* event, gpointer data) {
  DesktopShell* shell = static_cast<DesktopShell*>(data);
  if (!shell->keep_in_tray || shell->tray == nullptr) return FALSE;
  // Kept running, and reachable from the tray icon.
  gtk_widget_hide(window);
  return TRUE;
}

static void on_method_call(FlMethodChannel* channel,
                           FlMethodCall* call,
                           gpointer data) {
  DesktopShell* shell = static_cast<DesktopShell*>(data);
  const gchar* method = fl_method_call_get_name(call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "trayAvailable") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(shell->indicator_loaded)));
  } else if (strcmp(method, "setKeepInTray") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    bool keep = args != nullptr &&
                fl_value_get_type(args) == FL_VALUE_TYPE_BOOL &&
                fl_value_get_bool(args);
    shell->keep_in_tray = keep;
    if (keep) {
      show_tray(shell);
    } else {
      hide_tray(shell);
      // Closing it would now quit, so a window waiting in the tray comes back.
      if (!gtk_widget_get_visible(GTK_WIDGET(shell->window))) {
        desktop_shell_present(shell);
      }
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(shell->tray != nullptr)));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("Desktop channel could not answer %s: %s", method, error->message);
  }
}

DesktopShell* desktop_shell_new(GtkApplication* application,
                                GtkWindow* window,
                                FlView* view) {
  DesktopShell* shell = g_new0(DesktopShell, 1);
  shell->application = application;
  shell->window = window;
  shell->indicator_loaded = LoadIndicator(&shell->indicator);

  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  shell->channel = fl_method_channel_new(fl_engine_get_binary_messenger(engine),
                                         kChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(shell->channel, on_method_call,
                                            shell, nullptr);
  g_signal_connect(window, "delete-event", G_CALLBACK(on_delete), shell);
  return shell;
}

void desktop_shell_free(DesktopShell* shell) {
  hide_tray(shell);
  g_clear_object(&shell->channel);
  if (shell->indicator.library != nullptr) dlclose(shell->indicator.library);
  g_free(shell);
}
