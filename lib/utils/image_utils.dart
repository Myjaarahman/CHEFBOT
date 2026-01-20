import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

Future<File> resizeImage(File file) async {
  final bytes = await file.readAsBytes();

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception("Failed to decode image");
  }

  final resized = img.copyResize(
    decoded,
    width: 640,
  );

  final newPath = p.join(
    file.parent.path,
    'resized_${p.basename(file.path)}',
  );

  final resizedFile = File(newPath)
    ..writeAsBytesSync(img.encodeJpg(resized, quality: 85));

  return resizedFile;
}