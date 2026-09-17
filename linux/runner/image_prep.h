#ifndef RUNNER_IMAGE_PREP_H_
#define RUNNER_IMAGE_PREP_H_

#include <gdk-pixbuf/gdk-pixbuf.h>

// An image made ready for a note: turned the way it was taken, no longer than
// kImagePrepLongestSide on its longest side, and encoded as JPEG, or as PNG where it has
// transparency to keep. A phone's photo is several megabytes; this is a few hundred
// kilobytes, which is what every device downloads.
typedef struct {
  GBytes* bytes;  // Owned: free with image_prep_clear.
  int width;
  int height;
  const char* mime;  // Static.
} PreparedImage;

extern const int kImagePrepLongestSide;

// False, with error set, when the file is not an image this desktop can read.
gboolean image_prep_from_file(const char* path, PreparedImage* out, GError** error);

gboolean image_prep_from_pixbuf(GdkPixbuf* pixbuf, PreparedImage* out, GError** error);

void image_prep_clear(PreparedImage* image);

#endif  // RUNNER_IMAGE_PREP_H_
