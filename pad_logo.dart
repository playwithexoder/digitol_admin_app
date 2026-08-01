import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = 'assets/images/logo.png';
  final outputPath = 'assets/images/logo_splash.png';
  
  final bytes = File(inputPath).readAsBytesSync();
  final image = img.decodeImage(bytes);
  
  if (image == null) {
    // ignore: avoid_print
    print('Failed to decode image');
    return;
  }
  
  // Calculate new size with 30% padding
  final paddingFactor = 1.6;
  final newWidth = (image.width * paddingFactor).toInt();
  final newHeight = (image.height * paddingFactor).toInt();
  
  // Create a new image with transparent background
  final paddedImage = img.Image(width: newWidth, height: newHeight, numChannels: 4);
  
  // Calculate centered position
  final offsetX = (newWidth - image.width) ~/ 2;
  final offsetY = (newHeight - image.height) ~/ 2;
  
  // Composite the original image onto the center of the transparent padded image
  img.compositeImage(paddedImage, image, dstX: offsetX, dstY: offsetY);
  
  // Save
  File(outputPath).writeAsBytesSync(img.encodePng(paddedImage));
  // ignore: avoid_print
  print('Successfully created padded splash logo at $outputPath');
}
