package dev.mrhyperion.glasswork

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val pickRequest = 4201
    private var pending: MethodChannel.Result? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImages" -> pickImages(result)
                else -> result.notImplemented()
            }
        }
    }

    /// The system photo picker, which needs no permission, or on older phones the document
    /// picker for images.
    private fun pickImages(result: MethodChannel.Result) {
        // A second request while one is open ends the first with nothing.
        pending?.success(emptyList<Any>())
        pending = result
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Intent(MediaStore.ACTION_PICK_IMAGES)
                .putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, MOST_AT_ONCE)
        } else {
            Intent(Intent.ACTION_GET_CONTENT)
                .setType("image/*")
                .addCategory(Intent.CATEGORY_OPENABLE)
                .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        startActivityForResult(intent, pickRequest)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequest) return
        val result = pending ?: return
        pending = null

        val uris = mutableListOf<Uri>()
        if (resultCode == Activity.RESULT_OK && data != null) {
            val clip = data.clipData
            if (clip != null) {
                for (i in 0 until minOf(clip.itemCount, MOST_AT_ONCE)) uris.add(clip.getItemAt(i).uri)
            } else {
                data.data?.let { uris.add(it) }
            }
        }

        // Decoding a photo takes a moment; the app keeps drawing meanwhile.
        worker.execute {
            val images = uris.mapNotNull { uri ->
                try {
                    prepare(uri)
                } catch (error: Exception) {
                    android.util.Log.w("Glasswork", "Could not read $uri: ${error.message}")
                    null
                }
            }
            main.post { result.success(images) }
        }
    }

    /// An image made ready for a note, as the desktop does it: upright, no longer than
    /// LONGEST_SIDE on its longest side, and a JPEG, or a PNG where it has transparency.
    private fun prepare(uri: Uri): Map<String, Any> {
        val bitmap = decode(uri)
        val transparent = bitmap.hasAlpha() && hasTransparency(bitmap)
        val out = ByteArrayOutputStream()
        if (transparent) {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        } else {
            bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
        }
        return mapOf(
            "bytes" to out.toByteArray(),
            "width" to bitmap.width,
            "height" to bitmap.height,
            "mime" to if (transparent) "image/png" else "image/jpeg",
        )
    }

    private fun decode(uri: Uri): Bitmap {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // Turned upright from its EXIF by the decoder itself, and sized as it decodes.
            val source = ImageDecoder.createSource(contentResolver, uri)
            return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                val (width, height) = fitted(info.size.width, info.size.height)
                decoder.setTargetSize(width, height)
            }
        }

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        contentResolver.openInputStream(uri).use { BitmapFactory.decodeStream(it, null, bounds) }
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= LONGEST_SIDE) sample *= 2
        val decoded = contentResolver.openInputStream(uri).use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
        } ?: throw IllegalArgumentException("not an image")

        val degrees = contentResolver.openInputStream(uri).use { stream ->
            when (stream?.let { ExifInterface(it).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1) }) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        }
        val (width, height) = fitted(decoded.width, decoded.height)
        val scaled = Bitmap.createScaledBitmap(decoded, width, height, true)
        if (degrees == 0f) return scaled
        val turn = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(scaled, 0, 0, scaled.width, scaled.height, turn, true)
    }

    private fun fitted(width: Int, height: Int): Pair<Int, Int> {
        val scale = minOf(1.0, LONGEST_SIDE.toDouble() / max(width, height))
        return Pair(max(1, (width * scale).roundToInt()), max(1, (height * scale).roundToInt()))
    }

    private fun hasTransparency(bitmap: Bitmap): Boolean {
        val row = IntArray(bitmap.width)
        for (y in 0 until bitmap.height) {
            bitmap.getPixels(row, 0, bitmap.width, 0, y, bitmap.width, 1)
            if (row.any { (it ushr 24) != 0xFF }) return true
        }
        return false
    }

    companion object {
        private const val CHANNEL = "dev.mrhyperion.glasswork/images"
        private const val MOST_AT_ONCE = 20
        private const val LONGEST_SIDE = 2048
    }
}
