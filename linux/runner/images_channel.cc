#include "images_channel.h"

#include <cstring>

#include "image_prep.h"

namespace {

constexpr const char* kChannel = "dev.mrhyperion.glasswork/images";

// At most this many images from one choice, so a stray select-all cannot freeze the app.
constexpr int kMostAtOnce = 20;

// An image as Dart reads it: its bytes, size and type.
FlValue* ImageValue(const PreparedImage& image) {
  FlValue* value = fl_value_new_map();
  gsize size = 0;
  const guint8* data = static_cast<const guint8*>(g_bytes_get_data(image.bytes, &size));
  fl_value_set_string_take(value, "bytes", fl_value_new_uint8_list(data, size));
  fl_value_set_string_take(value, "width", fl_value_new_int(image.width));
  fl_value_set_string_take(value, "height", fl_value_new_int(image.height));
  fl_value_set_string_take(value, "mime", fl_value_new_string(image.mime));
  return value;
}

void Respond(FlMethodCall* call, FlValue* result) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("Images channel could not answer: %s", error->message);
  }
}

// The files chosen, each made ready; any that cannot be read are left out.
void OnChosen(GtkNativeDialog* dialog, gint response, gpointer data) {
  g_autoptr(FlMethodCall) call = FL_METHOD_CALL(data);
  g_autoptr(FlValue) images = fl_value_new_list();

  if (response == GTK_RESPONSE_ACCEPT) {
    GSList* files = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(dialog));
    int count = 0;
    for (GSList* item = files; item != nullptr && count < kMostAtOnce; item = item->next) {
      PreparedImage image = {};
      g_autoptr(GError) error = nullptr;
      if (image_prep_from_file(static_cast<const char*>(item->data), &image, &error)) {
        fl_value_append_take(images, ImageValue(image));
        image_prep_clear(&image);
        count++;
      } else {
        g_warning("Could not read %s: %s", static_cast<const char*>(item->data),
                  error->message);
      }
    }
    g_slist_free_full(files, g_free);
  }

  Respond(call, images);
  g_object_unref(dialog);
}

void OnPasted(GtkClipboard* clipboard, GdkPixbuf* pixbuf, gpointer data) {
  g_autoptr(FlMethodCall) call = FL_METHOD_CALL(data);
  if (pixbuf == nullptr) {
    Respond(call, fl_value_new_null());
    return;
  }
  PreparedImage image = {};
  g_autoptr(GError) error = nullptr;
  if (!image_prep_from_pixbuf(pixbuf, &image, &error)) {
    g_warning("Could not read the pasted image: %s", error->message);
    Respond(call, fl_value_new_null());
    return;
  }
  Respond(call, ImageValue(image));
  image_prep_clear(&image);
}

}  // namespace

struct _ImagesChannel {
  GtkWindow* window;
  FlMethodChannel* channel;
};

static void on_method_call(FlMethodChannel* channel, FlMethodCall* call, gpointer data) {
  ImagesChannel* self = static_cast<ImagesChannel*>(data);
  const gchar* method = fl_method_call_get_name(call);

  if (strcmp(method, "pickImages") == 0) {
    // The desktop's own chooser, through its portal where there is one.
    GtkFileChooserNative* dialog = gtk_file_chooser_native_new(
        "Add images", self->window, GTK_FILE_CHOOSER_ACTION_OPEN, "_Add", "_Cancel");
    GtkFileChooser* chooser = GTK_FILE_CHOOSER(dialog);
    gtk_file_chooser_set_select_multiple(chooser, TRUE);
    gtk_file_chooser_set_local_only(chooser, TRUE);
    GtkFileFilter* filter = gtk_file_filter_new();
    gtk_file_filter_set_name(filter, "Images");
    gtk_file_filter_add_pixbuf_formats(filter);
    gtk_file_chooser_add_filter(chooser, filter);
    const gchar* pictures = g_get_user_special_dir(G_USER_DIRECTORY_PICTURES);
    if (pictures != nullptr) gtk_file_chooser_set_current_folder(chooser, pictures);

    // Answered when the chooser closes; the call is held until then.
    g_signal_connect(dialog, "response", G_CALLBACK(OnChosen), g_object_ref(call));
    gtk_native_dialog_show(GTK_NATIVE_DIALOG(dialog));
    return;
  }

  if (strcmp(method, "pasteImage") == 0) {
    GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_request_image(clipboard, OnPasted, g_object_ref(call));
    return;
  }

  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(call, response, nullptr);
}

ImagesChannel* images_channel_new(GtkWindow* window, FlView* view) {
  ImagesChannel* self = g_new0(ImagesChannel, 1);
  self->window = window;
  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->channel = fl_method_channel_new(fl_engine_get_binary_messenger(engine), kChannel,
                                        FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->channel, on_method_call, self, nullptr);
  return self;
}

void images_channel_free(ImagesChannel* self) {
  g_clear_object(&self->channel);
  g_free(self);
}
