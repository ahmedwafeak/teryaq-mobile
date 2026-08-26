import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraScannerService {
  static final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from camera image file for medicine verification
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  /// Dispose ML Kit Text Recognizer
  static void dispose() {
    _textRecognizer.close();
  }
}
