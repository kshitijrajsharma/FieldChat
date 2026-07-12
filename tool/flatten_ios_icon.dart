import 'dart:io';

import 'package:image/image.dart';

/// Flattens assets/icon/app_icon.png into an alpha-free
/// assets/icon/app_icon_ios.png, working around a flutter_launcher_icons
/// 0.14.4 bug that blacks out the iOS icon on this source's 16-bit PNG.
///
/// Run with `dart run tool/flatten_ios_icon.dart` whenever the source icon
/// changes, then `just icons`.
void main() {
  const sourcePath = 'assets/icon/app_icon.png';
  const outputPath = 'assets/icon/app_icon_ios.png';

  // Matches pubspec.yaml's adaptive_icon_background.
  const bgR = 0x15;
  const bgG = 0x18;
  const bgB = 0x1B;

  var image = decodeImage(File(sourcePath).readAsBytesSync())!;
  image = image.convert(format: Format.uint8, numChannels: 4);

  final pixel = image.getPixel(0, 0);
  do {
    final a = pixel.a;
    final invA = 255 - a;
    pixel
      ..r = ((pixel.r * a + bgR * invA) / 255).round()
      ..g = ((pixel.g * a + bgG * invA) / 255).round()
      ..b = ((pixel.b * a + bgB * invA) / 255).round()
      ..a = 255;
  } while (pixel.moveNext());

  final flattened = image.convert(numChannels: 3);
  File(outputPath).writeAsBytesSync(encodePng(flattened));
  stdout.writeln(
    'wrote $outputPath (${flattened.width}x${flattened.height}, '
    'no alpha)',
  );
}
