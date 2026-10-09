import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../routes/app_router.dart';
import '../services/receipt_parser.dart';

/// Scanner Screen — handles receipt capture and OCR pipeline.
///
/// Pipeline:
/// 1. User selects image (camera or gallery)
/// 2. ML Kit extracts text via on-device OCR
/// 3. ReceiptParser extracts structured fields
/// 4. Navigate to ReviewReceiptScreen with parsed data
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // ── Platform Channel for device info / haptic feedback ─────────────────────
  static const _deviceChannel = MethodChannel('vn.edu.vku/device_info');

  // State
  bool _isProcessing = false;
  String? _statusMessage;
  File? _capturedImage;
  int? _batteryLevel;

  @override
  void initState() {
    super.initState();
    _fetchBatteryLevel();
  }

  Future<void> _fetchBatteryLevel() async {
    final level = await _getBatteryLevel();
    if (mounted) {
      setState(() => _batteryLevel = level);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ─── Platform Channel: Trigger haptic feedback ──────────────────────────────

  Future<void> _triggerHapticFeedback() async {
    try {
      await _deviceChannel.invokeMethod('triggerHaptic');
    } on PlatformException catch (e) {
      debugPrint('Haptic feedback error: ${e.message}');
      // Fallback to Flutter's built-in haptic
      HapticFeedback.lightImpact();
    } catch (_) {
      HapticFeedback.lightImpact();
    }
  }

  /// Get battery level via Platform Channel
  Future<int?> _getBatteryLevel() async {
    try {
      final level = await _deviceChannel.invokeMethod<int>('getBatteryLevel');
      return level;
    } on PlatformException catch (e) {
      debugPrint('Battery level error: ${e.message}');
      return null;
    }
  }

  // ─── OCR Pipeline ───────────────────────────────────────────────────────────

  Future<void> _captureAndProcess(ImageSource source) async {
    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = source == ImageSource.camera
            ? 'Đang mở máy ảnh...'
            : 'Đang mở thư viện ảnh...';
      });

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (picked == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        return;
      }

      final imageFile = File(picked.path);
      setState(() {
        _capturedImage = imageFile;
        _statusMessage = 'Đang nhận diện ký tự (OCR)...';
      });

      // ── ML Kit OCR ─────────────────────────────────────────────────────
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      setState(() => _statusMessage = 'Đang trích xuất thông tin hóa đơn...');

      // ── ReceiptParser ───────────────────────────────────────────────────
      final parsed = ReceiptParser.parse(rawText);

      // Trigger success haptic feedback via Platform Channel
      await _triggerHapticFeedback();

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });

      // Navigate to review screen with parsed receipt
      context.push(AppRoutes.review, extra: parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });
      _showError('Xử lý OCR thất bại: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn'),
        actions: [
          if (_batteryLevel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.battery_charging_full_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 2),
                    Text(
                      '$_batteryLevel%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          // Manual entry button
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.review),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            label: const Text(
              'Nhập tay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isProcessing
          ? _ProcessingOverlay(message: _statusMessage)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Captured Image Preview ──────────────────────────────
                  if (_capturedImage != null)
                    _ImagePreview(imageFile: _capturedImage!),

                  const SizedBox(height: 32),

                  // ── Pipeline Illustration ───────────────────────────────
                  _PipelineIllustration(),

                  const SizedBox(height: 40),

                  // ── Capture Buttons ─────────────────────────────────────
                  Text(
                    'Chụp Hóa Đơn',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chụp ảnh hoặc chọn từ thư viện để tự động trích xuất thông tin chi tiêu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Camera button
                  FilledButton.icon(
                    onPressed: () => _captureAndProcess(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Chụp ảnh'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Gallery button
                  OutlinedButton.icon(
                    onPressed: () => _captureAndProcess(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Chọn từ thư viện'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Loading overlay during OCR processing
class _ProcessingOverlay extends StatelessWidget {
  final String? message;

  const _ProcessingOverlay({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            message ?? 'Đang xử lý...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Preview of captured image
class _ImagePreview extends StatelessWidget {
  final File imageFile;

  const _ImagePreview({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        imageFile,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Visual pipeline diagram
class _PipelineIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final steps = [
      (Icons.camera_alt_rounded, 'Chụp'),
      (Icons.document_scanner_rounded, 'OCR'),
      (Icons.psychology_rounded, 'Trích xuất'),
      (Icons.verified_rounded, 'Kiểm tra'),
      (Icons.save_rounded, 'Lưu'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((entry) {
        final isLast = entry.key == steps.length - 1;
        final (icon, label) = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C4570).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: const Color(0xFF2C4570)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
