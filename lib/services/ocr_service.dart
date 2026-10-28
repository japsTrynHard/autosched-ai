import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrScanResult {
  const OcrScanResult({
    required this.imagePath,
    required this.recognizedText,
    required this.sourceLabel,
    required this.scannedAt,
    this.qrCodeValue,
  });

  final String imagePath;
  final String recognizedText;
  final String sourceLabel;
  final DateTime scannedAt;
  final String? qrCodeValue;

  bool get hasText => recognizedText.trim().isNotEmpty;
  bool get hasQrCode => qrCodeValue != null && qrCodeValue!.trim().isNotEmpty;
}

class OcrService {
  OcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<OcrScanResult?> scanWithCamera() {
    return _pickAndExtract(
      source: ImageSource.camera,
      sourceLabel: 'Camera COR scan',
    );
  }

  Future<OcrScanResult?> uploadFromGallery() {
    return _pickAndExtract(
      source: ImageSource.gallery,
      sourceLabel: 'Gallery COR upload',
    );
  }

  Future<OcrScanResult?> _pickAndExtract({
    required ImageSource source,
    required String sourceLabel,
  }) async {
    final pickedImage = await _picker.pickImage(
      source: source,
      // High enough for COR tables, but small enough for fast OCR and
      // optional Groq vision fallback when a key is configured.
      imageQuality: 95,
      maxWidth: 2600,
      maxHeight: 2600,
    );

    if (pickedImage == null) return null;

    final inputImage = InputImage.fromFilePath(pickedImage.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

    try {
      final recognizedText = await recognizer.processImage(inputImage);
      String? qrValue;
      try {
        final barcodes = await barcodeScanner.processImage(inputImage);
        for (final barcode in barcodes) {
          final value = barcode.rawValue?.trim();
          if (value != null && value.isNotEmpty) {
            qrValue = value;
            break;
          }
        }
      } catch (_) {
        // QR detection is a helper layer only. OCR schedule extraction should
        // still continue even if QR detection fails on a blurry COR image.
      }

      return OcrScanResult(
        imagePath: pickedImage.path,
        recognizedText: _orderedText(recognizedText),
        sourceLabel: sourceLabel,
        scannedAt: DateTime.now(),
        qrCodeValue: qrValue,
      );
    } finally {
      await recognizer.close();
      await barcodeScanner.close();
    }
  }

  String _orderedText(RecognizedText recognizedText) {
    final lines = recognizedText.blocks.expand((block) => block.lines).toList();
    if (lines.isEmpty) return recognizedText.text.trim();

    lines.sort((a, b) {
      final topDiff = a.boundingBox.top.compareTo(b.boundingBox.top);
      if ((a.boundingBox.top - b.boundingBox.top).abs() <= 10) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return topDiff;
    });

    final buffer = StringBuffer();
    double? lastTop;
    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;
      if (lastTop != null && (line.boundingBox.top - lastTop).abs() > 22) {
        buffer.writeln();
      }
      buffer.writeln(text);
      lastTop = line.boundingBox.top;
    }

    final ordered = buffer.toString().trim();
    return ordered.isEmpty ? recognizedText.text.trim() : ordered;
  }
}
