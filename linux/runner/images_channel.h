#ifndef RUNNER_IMAGES_CHANNEL_H_
#define RUNNER_IMAGES_CHANNEL_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// Images for notes from this desktop: chosen from files, or pasted from the clipboard, each
// made ready for a note (image_prep.h) before Dart sees it. Answers the
// dev.mrhyperion.glasswork/images channel.
typedef struct _ImagesChannel ImagesChannel;

ImagesChannel* images_channel_new(GtkWindow* window, FlView* view);

void images_channel_free(ImagesChannel* channel);

#endif  // RUNNER_IMAGES_CHANNEL_H_
