import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../models/cor_extraction_model.dart';
import '../services/cor_ai_extractor_service.dart';
import '../services/cor_text_parser.dart';
import '../services/ocr_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/brand_logo.dart';
import '../widgets/info_chip.dart';
import '../widgets/section_header.dart';

class CorScannerScreen extends StatefulWidget {
  const CorScannerScreen({super.key});

  @override
  State<CorScannerScreen> createState() => _CorScannerScreenState();
}

class _CorScannerScreenState extends State<CorScannerScreen> {
  final TextEditingController _ocrTextController = TextEditingController();
  final OcrService _ocrService = OcrService();
  final CorAiExtractorService _aiExtractor = const CorAiExtractorService();

  List<ExtractedClassEntry> _entries = const [];
  bool _isProcessing = false;
  bool _showRawText = false;
  String _processingMessage = 'Reading COR and detecting class schedule lines...';
  String? _selectedImagePath;
  String? _qrCodeValue;
  String _lastSource = 'Waiting for scan';
  DateTime? _lastScannedAt;

  @override
  void dispose() {
    _ocrTextController.dispose();
    super.dispose();
  }

  Future<void> _scanCamera() async {
    await _runRealOcr(() => _ocrService.scanWithCamera());
  }

  Future<void> _uploadFromGallery() async {
    await _runRealOcr(() => _ocrService.uploadFromGallery());
  }

  Future<void> _runRealOcr(Future<OcrScanResult?> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Scanning COR image with local OCR...';
    });

    try {
      final result = await action();
      if (result == null) {
        if (!mounted) return;
        _showSnackBar('No COR image selected.');
        return;
      }

      final text = result.recognizedText.trim();
      var entries = text.isEmpty ? <ExtractedClassEntry>[] : CorTextParser.parse(text);
      var usedAiFallback = false;
      Object? aiError;

      if (entries.isEmpty && _aiExtractor.isConfigured) {
        if (mounted) {
          setState(() {
            _processingMessage = 'Local OCR finished. Running Groq vision fallback for higher accuracy...';
          });
        }
        try {
          final aiEntries = await _aiExtractor.extractFromImagePath(
            result.imagePath,
            recognizedText: text,
          );
          if (aiEntries.isNotEmpty) {
            entries = aiEntries;
            usedAiFallback = true;
          }
        } catch (error) {
          aiError = error;
        }
      }

      setState(() {
        _selectedImagePath = result.imagePath;
        _lastSource = usedAiFallback ? '${result.sourceLabel} + Groq vision' : result.sourceLabel;
        _lastScannedAt = result.scannedAt;
        _qrCodeValue = result.qrCodeValue;
        _ocrTextController.text = text.isEmpty
            ? 'No readable local OCR text was detected. If Groq fallback is configured, AutoSched AI still tried to read the image. You can also paste COR text here.'
            : text;
        _entries = entries;
        _showRawText = true;
      });

      if (!mounted) return;
      if (entries.isNotEmpty) {
        _showSnackBar(
          '${usedAiFallback ? 'Groq vision fallback' : result.sourceLabel} completed. ${entries.length} possible class schedule/s detected${result.hasQrCode ? ' and QR verified' : ''}.',
        );
      } else if (aiError != null) {
        _showSnackBar(
          'Image was scanned, but no schedule was detected. Groq fallback also failed: $aiError',
          isError: true,
        );
      } else if (text.isEmpty) {
        _showSnackBar(
          'Image scanned, but no readable text was detected. Use a sharper COR screenshot or paste PDF text.',
          isError: true,
        );
      } else {
        _showSnackBar(
          'Text was detected, but no class schedule matched. Paste from the PDF or try a clearer image.',
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        'Scan failed: $error. Check camera permission and try a clearer image.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pasteFromClipboardAndParse() async {
    setState(() => _showRawText = true);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final pastedText = clipboard?.text?.trim() ?? '';
    if (pastedText.isEmpty) {
      _showSnackBar('Clipboard is empty. Paste the COR text in the box, then tap Extract Schedule from Text.', isError: true);
      return;
    }
    _ocrTextController.text = pastedText;
    await _parsePastedText();
  }

  Future<void> _parsePastedText() async {
    FocusScope.of(context).unfocus();
    final text = _ocrTextController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Paste COR text first, then tap Extract Schedule from Text.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Reading pasted COR text and matching schedule rows...';
    });

    var usedAiFallback = false;
    Object? aiError;
    var entries = <ExtractedClassEntry>[];

    try {
      entries = CorTextParser.parse(text);
      if (entries.isEmpty && _aiExtractor.isConfigured) {
        if (mounted) {
          setState(() {
            _processingMessage = 'Using Groq text fallback to recover the COR table...';
          });
        }
        try {
          final aiEntries = await _aiExtractor.extractFromText(text);
          if (aiEntries.isNotEmpty) {
            entries = aiEntries;
            usedAiFallback = true;
          }
        } catch (error) {
          aiError = error;
        }
      }

      setState(() {
        _entries = entries;
        _showRawText = true;
        _lastSource = usedAiFallback ? 'Pasted COR text + Groq fallback' : 'Pasted COR text';
        _lastScannedAt = DateTime.now();
        _qrCodeValue = null;
      });

      if (entries.isEmpty) {
        _showSnackBar(
          aiError == null
              ? 'No class schedule was detected. Try pasting the exact PDF text from SUBJECT CODE up to TOTAL UNITS.'
              : 'No class schedule was detected. Groq fallback also failed: $aiError',
          isError: true,
        );
      } else {
        _showSnackBar('${entries.length} class schedule/s detected from ${usedAiFallback ? 'Groq fallback' : 'pasted text'}. Review them before import.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _confirmImport() {
    final app = AppScope.of(context);
    final validEntries = _entries.where((entry) => entry.isReady).toList();
    if (validEntries.isEmpty) {
      _showSnackBar(
        'No valid class schedule to import. Please review the extracted fields first.',
        isError: true,
      );
      return;
    }

    app.importExtractedSchedule(validEntries);
    _showSnackBar(
      '${validEntries.length} class schedule/s imported, planner regenerated, and backup queued.',
    );
  }

  void _deleteEntry(String id) {
    setState(
      () => _entries = _entries.where((entry) => entry.id != id).toList(),
    );
  }

  void _upsertEntry(ExtractedClassEntry entry) {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    setState(() {
      if (index >= 0) {
        final next = [..._entries];
        next[index] = entry;
        _entries = next;
      } else {
        _entries = [..._entries, entry];
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
        backgroundColor: isError ? AppTheme.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final issues = app.issuesForExtractedEntries(_entries);
    final blockingIssues = issues.where((issue) => issue.isBlocking).length;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AutoTopBar(
        title: 'COR Scanner',
        subtitle: 'Scan or upload COR to import classes',
        actions: [
          IconButton(
            tooltip: 'Clear scanner',
            onPressed: () {
              _ocrTextController.clear();
              setState(() {
                _entries = const [];
                _selectedImagePath = null;
                _qrCodeValue = null;
                _lastSource = 'Waiting for scan';
                _lastScannedAt = null;
              });
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 122),
        children: [
          _ScannerHero(
            detectedCount: _entries.length,
            blockingIssues: blockingIssues,
            hasQrCode: _qrCodeValue != null && _qrCodeValue!.trim().isNotEmpty,
            isProcessing: _isProcessing,
          ),
          const SizedBox(height: 14),
          _ActionGrid(
            isProcessing: _isProcessing,
            onCamera: _scanCamera,
            onUpload: _uploadFromGallery,
            onPaste: _pasteFromClipboardAndParse,
          ),
          if (_selectedImagePath != null) ...[
            const SizedBox(height: 14),
            _ImagePreviewCard(
              imagePath: _selectedImagePath!,
              source: _lastSource,
              scannedAt: _lastScannedAt,
              onClear: () => setState(() => _selectedImagePath = null),
            ),
          ],
          if (_qrCodeValue != null && _qrCodeValue!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _QrVerificationCard(qrValue: _qrCodeValue!),
          ],
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: AutoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Detected Text Preview',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _parsePastedText(),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Parse'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera/gallery scan fills this automatically. You can also paste text from your COR PDF, then tap Extract Schedule from Text.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ocrTextController,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText:
                            'Recognized COR text will appear here after scanning...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _parsePastedText(),
                        icon: const Icon(Icons.document_scanner_rounded),
                        label: const Text('Extract Schedule from Text'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: _showRawText
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          SectionHeader(
            title: 'Review Extracted Schedule',
            subtitle: _entries.isEmpty
                ? 'Scan/upload a COR image, or paste text from your PDF. AutoSched AI will detect class schedule lines first.'
                : 'Edit wrong fields before confirming. Imported classes become fixed planner blocks and are saved to your account.',
            trailing: _entries.isEmpty
                ? null
                : TextButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Missing'),
                  ),
          ),
          if (_entries.isEmpty)
            _EmptyReviewCard(onStart: () => setState(() => _showRawText = true)),
          if (_entries.isNotEmpty)
            AutoCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip(
                    label: '${_entries.length} detected',
                    icon: Icons.fact_check_rounded,
                    color: AppTheme.primary,
                  ),
                  InfoChip(
                    label:
                        '${_entries.where((entry) => entry.isReady).length} ready',
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                  ),
                  InfoChip(
                    label: '$blockingIssues needs review',
                    icon: Icons.warning_rounded,
                    color: blockingIssues > 0
                        ? AppTheme.warning
                        : AppTheme.success,
                  ),
                  const InfoChip(
                    label: 'Human-in-the-loop',
                    icon: Icons.verified_user_rounded,
                    color: AppTheme.purple,
                  ),
                ],
              ),
            ),
          ..._entries.map((entry) {
            final entryIssues = issues
                .where((issue) => issue.entryId == entry.id)
                .toList();
            return _ExtractedEntryCard(
              entry: entry,
              issues: entryIssues,
              onEdit: () => _openEditor(entry: entry),
              onDelete: () => _deleteEntry(entry.id),
            );
          }),
          if (_entries.isNotEmpty) ...[
            const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: _confirmImport,
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Confirm and Import to Planner'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() => _entries = const []),
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Clear Review List'),
            ),
          ],
          SectionHeader(
            title: 'Scanner Status',
            subtitle:
                'Camera/gallery scanning is enabled. COR images are used temporarily; only reviewed schedule data is saved.',
          ),
        ],
      ),
      if (_isProcessing) _ScannerProgressOverlay(message: _processingMessage),
    ],
  ),
);
  }

  Future<void> _openEditor({ExtractedClassEntry? entry}) async {
    final result = await showModalBottomSheet<ExtractedClassEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ExtractedEntryEditor(entry: entry),
    );
    if (result != null) _upsertEntry(result);
  }
}


class _ScannerProgressOverlay extends StatelessWidget {
  const _ScannerProgressOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Container(
        color: colors.scrim.withOpacity(0.36),
        alignment: Alignment.center,
        child: Container(
          width: 300,
          margin: const EdgeInsets.symmetric(horizontal: 22),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, AppTheme.purple, AppTheme.cyan],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.28),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  const AutoSchedMark(
                    size: 42,
                    borderRadius: 14,
                    showBorder: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'AutoSched AI is reading your COR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.25),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _LoadingDot(delay: 0),
                  SizedBox(width: 6),
                  _LoadingDot(delay: 160),
                  SizedBox(width: 6),
                  _LoadingDot(delay: 320),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDot extends StatefulWidget {
  const _LoadingDot({required this.delay});

  final int delay;

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _animation = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ScannerHero extends StatelessWidget {
  const _ScannerHero({
    required this.detectedCount,
    required this.blockingIssues,
    required this.hasQrCode,
    required this.isProcessing,
  });

  final int detectedCount;
  final int blockingIssues;
  final bool hasQrCode;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, AppTheme.purple, AppTheme.cyan],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Center(
                        child: AutoSchedMark(
                          size: 38,
                          borderRadius: 12,
                          showBorder: false,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan COR, import classes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Camera or gallery scan extracts your class schedule, then you approve every field.',
                      style: TextStyle(color: Colors.white70, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(value: '$detectedCount', label: 'Detected'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  value: '$blockingIssues',
                  label: 'Needs Review',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(value: hasQrCode ? 'Yes' : 'Check', label: 'QR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.isProcessing,
    required this.onCamera,
    required this.onUpload,
    required this.onPaste,
  });

  final bool isProcessing;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: [
        _ScanActionCard(
          title: 'Camera',
          subtitle: 'real scan',
          icon: Icons.camera_alt_rounded,
          color: AppTheme.primary,
          onTap: isProcessing ? null : onCamera,
        ),
        _ScanActionCard(
          title: 'Gallery',
          subtitle: 'COR image',
          icon: Icons.photo_library_rounded,
          color: AppTheme.purple,
          onTap: isProcessing ? null : onUpload,
        ),
        _ScanActionCard(
          title: 'Paste',
          subtitle: 'detected text',
          icon: Icons.content_paste_search_rounded,
          color: AppTheme.success,
          onTap: isProcessing ? null : onPaste,
        ),
      ],
    );
  }
}

class _ScanActionCard extends StatelessWidget {
  const _ScanActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _QrVerificationCard extends StatelessWidget {
  const _QrVerificationCard({required this.qrValue});

  final String qrValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AutoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR code detected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'AutoSched AI found the COR verification QR. The schedule still comes from the reviewed table fields.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    qrValue,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.imagePath,
    required this.source,
    required this.scannedAt,
    required this.onClear,
  });

  final String imagePath;
  final String source;
  final DateTime? scannedAt;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final file = File(imagePath);
    return AutoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scanned COR Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hide preview',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              file,
              width: double.infinity,
              height: 230,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: colors.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text(
                    'Image preview unavailable, but detected text can still be reviewed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                label: source,
                icon: Icons.document_scanner_rounded,
                color: AppTheme.primary,
              ),
              if (scannedAt != null)
                InfoChip(
                  label:
                      '${AutoDate.formatDate(scannedAt!)} • ${AutoDate.formatMinute(scannedAt!.hour * 60 + scannedAt!.minute)}',
                  icon: Icons.access_time_rounded,
                  color: AppTheme.purple,
                ),
              const InfoChip(
                label: 'scanned locally',
                icon: Icons.lock_outline_rounded,
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewCard extends StatelessWidget {
  const _EmptyReviewCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AutoCard(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.manage_search_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No extracted schedule yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Camera or Gallery to scan your COR. If you already copied text from a PDF, use Paste and then Extract Schedule from Text.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.content_paste_search_rounded),
            label: const Text('Paste COR Text'),
          ),
        ],
      ),
    );
  }
}

class _ExtractedEntryCard extends StatelessWidget {
  const _ExtractedEntryCard({
    required this.entry,
    required this.issues,
    required this.onEdit,
    required this.onDelete,
  });

  final ExtractedClassEntry entry;
  final List<CorImportIssue> issues;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasBlockingIssue = issues.any((issue) => issue.isBlocking);
    final statusColor = hasBlockingIssue || entry.needsReview
        ? AppTheme.warning
        : AppTheme.success;

    return AutoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasBlockingIssue
                      ? Icons.warning_rounded
                      : Icons.check_circle_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.subjectCode,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subjectName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry.dayLabel} • ${entry.timeLabel} • ${entry.room}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit fields')),
                  PopupMenuItem(value: 'delete', child: Text('Delete entry')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(
                label: '${entry.units} units',
                icon: Icons.numbers_rounded,
              ),
              InfoChip(
                label: '${(entry.confidence * 100).round()}% scan confidence',
                icon: Icons.radar_rounded,
                color: statusColor,
              ),
              if (entry.instructor.trim().isNotEmpty)
                InfoChip(
                  label: entry.instructor,
                  icon: Icons.person_rounded,
                  color: AppTheme.purple,
                ),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      issue.isBlocking
                          ? Icons.error_rounded
                          : Icons.info_rounded,
                      color: issue.isBlocking
                          ? AppTheme.danger
                          : AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (entry.sourceLine.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Source: ${entry.sourceLine}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtractedEntryEditor extends StatefulWidget {
  const _ExtractedEntryEditor({this.entry});

  final ExtractedClassEntry? entry;

  @override
  State<_ExtractedEntryEditor> createState() => _ExtractedEntryEditorState();
}

class _ExtractedEntryEditorState extends State<_ExtractedEntryEditor> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _room;
  late final TextEditingController _units;
  late final TextEditingController _instructor;
  late int _weekday;
  late int _startMinute;
  late int _endMinute;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _code = TextEditingController(text: entry?.subjectCode ?? '');
    _name = TextEditingController(text: entry?.subjectName ?? '');
    _room = TextEditingController(text: entry?.room ?? 'TBA');
    _units = TextEditingController(text: '${entry?.units ?? 3}');
    _instructor = TextEditingController(text: entry?.instructor ?? '');
    _weekday = entry?.weekday ?? 1;
    _startMinute = entry?.startMinute ?? 8 * 60;
    _endMinute = entry?.endMinute ?? 10 * 60;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _room.dispose();
    _units.dispose();
    _instructor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.entry == null
                  ? 'Add Missing Class'
                  : 'Edit Extracted Class',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Correct the detected fields before importing to fixed class schedule.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Subject Code'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _weekday,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: List.generate(7, (index) => index + 1)
                        .map(
                          (day) => DropdownMenuItem(
                            value: day,
                            child: Text(AutoDate.weekdayLong(day)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _weekday = value ?? 1),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _units,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Units'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Start ${AutoDate.formatMinute(_startMinute)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.schedule_send_rounded),
                    label: Text('End ${AutoDate.formatMinute(_endMinute)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _room,
              decoration: const InputDecoration(labelText: 'Room'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructor,
              decoration: const InputDecoration(
                labelText: 'Instructor (optional)',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Reviewed Class'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialMinute = isStart ? _startMinute : _endMinute;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinute ~/ 60,
        minute: initialMinute % 60,
      ),
    );
    if (result == null) return;
    final value = result.hour * 60 + result.minute;
    setState(() {
      if (isStart) {
        _startMinute = value;
        if (_endMinute <= _startMinute) _endMinute = _startMinute + 90;
      } else {
        _endMinute = value;
      }
    });
  }

  void _save() {
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject code and name are required.')),
      );
      return;
    }
    if (_endMinute <= _startMinute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be later than start time.'),
        ),
      );
      return;
    }
    final entry = ExtractedClassEntry(
      id: widget.entry?.id ?? 'manual_${DateTime.now().microsecondsSinceEpoch}',
      subjectCode: _code.text.trim(),
      subjectName: _name.text.trim(),
      weekday: _weekday,
      startMinute: _startMinute,
      endMinute: _endMinute,
      room: _room.text.trim().isEmpty ? 'TBA' : _room.text.trim(),
      units: int.tryParse(_units.text.trim()) ?? 3,
      instructor: _instructor.text.trim(),
      confidence: 1.0,
      sourceLine:
          widget.entry?.sourceLine ?? 'Manually added after review.',
      needsReview: false,
    );
    Navigator.of(context).pop(entry);
  }
}
