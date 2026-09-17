#include "image_prep.h"

#include <algorithm>
#include <cmath>

const int kImagePrepLongestSide = 2048;

namespace {

// Whether any pixel is less than fully opaque. A screenshot carries an alpha channel with
// nothing see-through in it, and is far smaller as a JPEG.
bool HasTransparency(GdkPixbuf* pixbuf) {
  if (!gdk_pixbuf_get_has_alpha(pixbuf) || gdk_pixbuf_get_n_channels(pixbuf) != 4) {
    return false;
  }
  const int width = gdk_pixbuf_get_width(pixbuf);
  const int height = gdk_pixbuf_get_height(pixbuf);
  const int stride = gdk_pixbuf_get_rowstride(pixbuf);
  const guchar* pixels = gdk_pixbuf_read_pixels(pixbuf);
  for (int y = 0; y < height; y++) {
    const guchar* row = pixels + y * stride;
    for (int x = 0; x < width; x++) {
      if (row[x * 4 + 3] != 255) return true;
    }
  }
  return false;
}

// The same picture without its alpha channel, for a JPEG, which has none.
GdkPixbuf* WithoutAlpha(GdkPixbuf* pixbuf) {
  const int width = gdk_pixbuf_get_width(pixbuf);
  const int height = gdk_pixbuf_get_height(pixbuf);
  GdkPixbuf* opaque = gdk_pixbuf_new(GDK_COLORSPACE_RGB, FALSE, 8, width, height);
  const int from_stride = gdk_pixbuf_get_rowstride(pixbuf);
  const int to_stride = gdk_pixbuf_get_rowstride(opaque);
  const guchar* from = gdk_pixbuf_read_pixels(pixbuf);
  guchar* to = gdk_pixbuf_get_pixels(opaque);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      for (int c = 0; c < 3; c++) {
        to[y * to_stride + x * 3 + c] = from[y * from_stride + x * 4 + c];
      }
    }
  }
  return opaque;
}

}  // namespace

gboolean image_prep_from_pixbuf(GdkPixbuf* pixbuf, PreparedImage* out, GError** error) {
  // A camera stores which way up in EXIF; turned here, so every device shows it upright.
  g_autoptr(GdkPixbuf) oriented = gdk_pixbuf_apply_embedded_orientation(pixbuf);
  if (oriented == nullptr) oriented = GDK_PIXBUF(g_object_ref(pixbuf));

  const int width = gdk_pixbuf_get_width(oriented);
  const int height = gdk_pixbuf_get_height(oriented);
  const double scale =
      std::min(1.0, static_cast<double>(kImagePrepLongestSide) / std::max(width, height));

  g_autoptr(GdkPixbuf) sized = nullptr;
  if (scale < 1.0) {
    sized = gdk_pixbuf_scale_simple(oriented,
                                    std::max(1, static_cast<int>(std::lround(width * scale))),
                                    std::max(1, static_cast<int>(std::lround(height * scale))),
                                    GDK_INTERP_HYPER);
  } else {
    sized = GDK_PIXBUF(g_object_ref(oriented));
  }

  gchar* buffer = nullptr;
  gsize size = 0;
  gboolean saved;
  if (HasTransparency(sized)) {
    saved = gdk_pixbuf_save_to_buffer(sized, &buffer, &size, "png", error, nullptr);
    out->mime = "image/png";
  } else {
    g_autoptr(GdkPixbuf) opaque = gdk_pixbuf_get_has_alpha(sized)
                                       ? WithoutAlpha(sized)
                                       : GDK_PIXBUF(g_object_ref(sized));
    saved = gdk_pixbuf_save_to_buffer(opaque, &buffer, &size, "jpeg", error, "quality",
                                      "85", nullptr);
    out->mime = "image/jpeg";
  }
  if (!saved) return FALSE;

  out->bytes = g_bytes_new_take(buffer, size);
  out->width = gdk_pixbuf_get_width(sized);
  out->height = gdk_pixbuf_get_height(sized);
  return TRUE;
}

gboolean image_prep_from_file(const char* path, PreparedImage* out, GError** error) {
  g_autoptr(GdkPixbuf) pixbuf = gdk_pixbuf_new_from_file(path, error);
  if (pixbuf == nullptr) return FALSE;
  return image_prep_from_pixbuf(pixbuf, out, error);
}

void image_prep_clear(PreparedImage* image) {
  g_clear_pointer(&image->bytes, g_bytes_unref);
}
