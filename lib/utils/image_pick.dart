/// Picks an appropriately-sized image URL from a Spotify-style image list so we
/// don't decode a 640px album cover just to show a tiny drawer thumbnail.
class ImagePick {
  const ImagePick._();

  /// Returns the URL of the smallest image at least [targetWidth] wide; if none
  /// qualifies, the largest available. Entries without a width are considered
  /// only as a last resort (in list order). Returns null if there is no usable
  /// URL at all. Malformed entries are ignored.
  static String? bestUrl(List<dynamic> images, {required int targetWidth}) {
    String? bestAtLeast;
    int bestAtLeastW = 1 << 30;
    String? largest;
    int largestW = -1;
    String? firstUrlNoWidth;

    for (final entry in images) {
      if (entry is! Map) continue;
      final url = entry['url'];
      if (url is! String || url.isEmpty) continue;
      final width = entry['width'];
      if (width is! int) {
        firstUrlNoWidth ??= url;
        continue;
      }
      if (width > largestW) {
        largestW = width;
        largest = url;
      }
      if (width >= targetWidth && width < bestAtLeastW) {
        bestAtLeastW = width;
        bestAtLeast = url;
      }
    }

    return bestAtLeast ?? largest ?? firstUrlNoWidth;
  }
}
