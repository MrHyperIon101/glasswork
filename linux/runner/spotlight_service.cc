#include "spotlight_service.h"

#include <cstring>

namespace {

constexpr const char* kChannel = "dev.mrhyperion.glasswork/spotlight";
constexpr const char* kObjectPath = "/dev/mrhyperion/glasswork/Spotlight";
constexpr const char* kErrorNotReady = "dev.mrhyperion.glasswork.Error.NotReady";
constexpr const char* kErrorFailed = "dev.mrhyperion.glasswork.Error.Failed";

// Long enough for a cold start of the app behind it; short enough that a Spotlight left
// waiting on a broken one gives up and shows the rest of its results.
constexpr guint kReadyDeadlineMs = 8000;

constexpr const char* kIntrospection =
    "<node>"
    "  <interface name='dev.mrhyperion.glasswork.Spotlight'>"
    "    <method name='Query'>"
    "      <arg type='s' name='text' direction='in'/>"
    "      <arg type='u' name='limit' direction='in'/>"
    "      <arg type='aa{sv}' name='results' direction='out'/>"
    "    </method>"
    "    <method name='Recents'>"
    "      <arg type='u' name='limit' direction='in'/>"
    "      <arg type='aa{sv}' name='results' direction='out'/>"
    "    </method>"
    "    <method name='PreviewAdd'>"
    "      <arg type='s' name='text' direction='in'/>"
    "      <arg type='a{sv}' name='preview' direction='out'/>"
    "    </method>"
    "    <method name='AddTask'>"
    "      <arg type='s' name='text' direction='in'/>"
    "      <arg type='s' name='id' direction='out'/>"
    "    </method>"
    "    <method name='Activate'>"
    "      <arg type='s' name='id' direction='in'/>"
    "      <arg type='u' name='timestamp' direction='in'/>"
    "      <arg type='b' name='opened' direction='out'/>"
    "    </method>"
    "  </interface>"
    "</node>";

}  // namespace

struct _SpotlightService {
  GDBusNodeInfo* node;
  GDBusConnection* connection;
  guint registration;

  FlMethodChannel* channel;
  DesktopShell* shell;

  // Whether Dart has said it can answer.
  bool ready;
  // Calls waiting for it, oldest first.
  GQueue waiting;
};

// One D-Bus call on its way to Dart and back.
typedef struct {
  SpotlightService* service;
  GDBusMethodInvocation* invocation;
  gchar* method;
  FlValue* args;
  guint32 timestamp;
  guint deadline;
} Call;

static void call_free(Call* call) {
  if (call->deadline != 0) g_source_remove(call->deadline);
  g_object_unref(call->invocation);
  g_free(call->method);
  fl_value_unref(call->args);
  g_free(call);
}

// --- Dart's answers, as D-Bus values ---------------------------------------------------

static GVariant* to_variant(FlValue* value);

static GVariant* map_to_dict(FlValue* map) {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("a{sv}"));
  if (map != nullptr && fl_value_get_type(map) == FL_VALUE_TYPE_MAP) {
    for (size_t i = 0; i < fl_value_get_length(map); i++) {
      FlValue* key = fl_value_get_map_key(map, i);
      if (fl_value_get_type(key) != FL_VALUE_TYPE_STRING) continue;
      g_variant_builder_add(&builder, "{sv}", fl_value_get_string(key),
                            to_variant(fl_value_get_map_value(map, i)));
    }
  }
  return g_variant_builder_end(&builder);
}

static GVariant* to_variant(FlValue* value) {
  switch (value == nullptr ? FL_VALUE_TYPE_NULL : fl_value_get_type(value)) {
    case FL_VALUE_TYPE_BOOL:
      return g_variant_new_boolean(fl_value_get_bool(value));
    case FL_VALUE_TYPE_INT:
      return g_variant_new_int64(fl_value_get_int(value));
    case FL_VALUE_TYPE_FLOAT:
      return g_variant_new_double(fl_value_get_float(value));
    case FL_VALUE_TYPE_STRING:
      return g_variant_new_string(fl_value_get_string(value));
    case FL_VALUE_TYPE_MAP:
      return map_to_dict(value);
    case FL_VALUE_TYPE_LIST: {
      // A list of words stays one ("as"), so a chip list reads naturally on the other side.
      bool words = true;
      for (size_t i = 0; i < fl_value_get_length(value); i++) {
        words &= fl_value_get_type(fl_value_get_list_value(value, i)) ==
                 FL_VALUE_TYPE_STRING;
      }
      GVariantBuilder builder;
      g_variant_builder_init(&builder, words ? G_VARIANT_TYPE("as") : G_VARIANT_TYPE("av"));
      for (size_t i = 0; i < fl_value_get_length(value); i++) {
        FlValue* item = fl_value_get_list_value(value, i);
        if (words) {
          g_variant_builder_add(&builder, "s", fl_value_get_string(item));
        } else {
          g_variant_builder_add(&builder, "v", to_variant(item));
        }
      }
      return g_variant_builder_end(&builder);
    }
    default:
      return g_variant_new_string("");
  }
}

static GVariant* list_of_dicts(FlValue* list) {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("aa{sv}"));
  if (list != nullptr && fl_value_get_type(list) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(list); i++) {
      g_variant_builder_add_value(&builder, map_to_dict(fl_value_get_list_value(list, i)));
    }
  }
  return g_variant_builder_end(&builder);
}

static void on_reply(GObject* object, GAsyncResult* result, gpointer data) {
  Call* call = static_cast<Call*>(data);
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response =
      fl_method_channel_invoke_method_finish(FL_METHOD_CHANNEL(object), result, &error);
  FlValue* value = response == nullptr
                       ? nullptr
                       : fl_method_response_get_result(response, &error);
  if (value == nullptr) {
    g_dbus_method_invocation_return_dbus_error(
        call->invocation, kErrorFailed,
        error != nullptr ? error->message : "Glasswork could not answer");
    call_free(call);
    return;
  }

  const gchar* method = call->method;
  GVariant* answer = nullptr;
  if (strcmp(method, "query") == 0 || strcmp(method, "recents") == 0) {
    answer = g_variant_new("(@aa{sv})", list_of_dicts(value));
  } else if (strcmp(method, "previewAdd") == 0) {
    answer = g_variant_new("(@a{sv})", map_to_dict(value));
  } else if (strcmp(method, "addTask") == 0) {
    const gchar* id =
        fl_value_get_type(value) == FL_VALUE_TYPE_STRING ? fl_value_get_string(value) : "";
    answer = g_variant_new("(s)", id);
  } else {
    gboolean opened =
        fl_value_get_type(value) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(value);
    // Opened in the app: the window comes forward to show it, even out of the tray. The
    // extension then gives it focus, which only the shell itself may do on Wayland.
    if (opened && call->service->shell != nullptr) {
      desktop_shell_present(call->service->shell);
    }
    answer = g_variant_new("(b)", opened);
  }
  g_dbus_method_invocation_return_value(call->invocation, answer);
  call_free(call);
}

static void forward(Call* call) {
  if (call->deadline != 0) {
    g_source_remove(call->deadline);
    call->deadline = 0;
  }
  fl_method_channel_invoke_method(call->service->channel, call->method, call->args,
                                  nullptr, on_reply, call);
}

static gboolean on_deadline(gpointer data) {
  Call* call = static_cast<Call*>(data);
  call->deadline = 0;
  g_queue_remove(&call->service->waiting, call);
  g_dbus_method_invocation_return_dbus_error(call->invocation, kErrorNotReady,
                                             "Glasswork is still starting");
  call_free(call);
  return G_SOURCE_REMOVE;
}

// --- the bus side ------------------------------------------------------------------------

static void on_method_call(GDBusConnection* connection,
                           const gchar* sender,
                           const gchar* object_path,
                           const gchar* interface,
                           const gchar* method,
                           GVariant* parameters,
                           GDBusMethodInvocation* invocation,
                           gpointer data) {
  SpotlightService* service = static_cast<SpotlightService*>(data);

  Call* call = g_new0(Call, 1);
  call->service = service;
  call->invocation = G_DBUS_METHOD_INVOCATION(g_object_ref(invocation));
  call->args = fl_value_new_map();

  if (strcmp(method, "Query") == 0) {
    const gchar* text;
    guint32 limit;
    g_variant_get(parameters, "(&su)", &text, &limit);
    call->method = g_strdup("query");
    fl_value_set_string_take(call->args, "text", fl_value_new_string(text));
    fl_value_set_string_take(call->args, "limit", fl_value_new_int(limit));
  } else if (strcmp(method, "Recents") == 0) {
    guint32 limit;
    g_variant_get(parameters, "(u)", &limit);
    call->method = g_strdup("recents");
    fl_value_set_string_take(call->args, "limit", fl_value_new_int(limit));
  } else if (strcmp(method, "PreviewAdd") == 0 || strcmp(method, "AddTask") == 0) {
    const gchar* text;
    g_variant_get(parameters, "(&s)", &text);
    call->method = g_strdup(strcmp(method, "AddTask") == 0 ? "addTask" : "previewAdd");
    fl_value_set_string_take(call->args, "text", fl_value_new_string(text));
  } else {
    const gchar* id;
    g_variant_get(parameters, "(&su)", &id, &call->timestamp);
    call->method = g_strdup("activate");
    fl_value_set_string_take(call->args, "id", fl_value_new_string(id));
  }

  if (service->ready && service->channel != nullptr) {
    forward(call);
  } else {
    call->deadline = g_timeout_add(kReadyDeadlineMs, on_deadline, call);
    g_queue_push_tail(&service->waiting, call);
  }
}

static const GDBusInterfaceVTable kVtable = {on_method_call, nullptr, nullptr, {}};

// Dart, over the channel: the only thing it says is that it can answer now.
static void on_dart_call(FlMethodChannel* channel, FlMethodCall* method_call, gpointer data) {
  SpotlightService* service = static_cast<SpotlightService*>(data);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "ready") == 0) {
    service->ready = true;
    while (Call* call = static_cast<Call*>(g_queue_pop_head(&service->waiting))) {
      forward(call);
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

SpotlightService* spotlight_service_new() {
  SpotlightService* service = g_new0(SpotlightService, 1);
  service->node = g_dbus_node_info_new_for_xml(kIntrospection, nullptr);
  g_queue_init(&service->waiting);
  return service;
}

gboolean spotlight_service_register(SpotlightService* service,
                                    GDBusConnection* connection,
                                    GError** error) {
  service->connection = G_DBUS_CONNECTION(g_object_ref(connection));
  service->registration = g_dbus_connection_register_object(
      connection, kObjectPath, service->node->interfaces[0], &kVtable, service, nullptr,
      error);
  return service->registration != 0;
}

void spotlight_service_unregister(SpotlightService* service) {
  if (service->registration != 0) {
    g_dbus_connection_unregister_object(service->connection, service->registration);
    service->registration = 0;
  }
  g_clear_object(&service->connection);
}

void spotlight_service_attach(SpotlightService* service, FlView* view, DesktopShell* shell) {
  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  service->channel = fl_method_channel_new(fl_engine_get_binary_messenger(engine), kChannel,
                                           FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(service->channel, on_dart_call, service, nullptr);
  service->shell = shell;
}

void spotlight_service_free(SpotlightService* service) {
  while (Call* call = static_cast<Call*>(g_queue_pop_head(&service->waiting))) {
    g_dbus_method_invocation_return_dbus_error(call->invocation, kErrorNotReady,
                                               "Glasswork is closing");
    call_free(call);
  }
  spotlight_service_unregister(service);
  g_clear_object(&service->channel);
  g_clear_pointer(&service->node, g_dbus_node_info_unref);
  g_free(service);
}
