import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  static Future<List<int>> compressImage(Uint8List imageData, int quality) async {
    final result = await FlutterImageCompress.compressWithList(
      imageData,
      quality: quality,
    );
    return result;
  }
}

