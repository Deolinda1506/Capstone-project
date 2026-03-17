import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/patient_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';

/// Scan screen - capture carotid ultrasound, upload to backend for analysis
/// Images stored in app-private encrypted storage (not Photo Gallery)
/// Uses Image.memory for web compatibility (Image.file not supported on web)
class ScanScreen extends StatefulWidget {
  final PatientModel? patient;

  const ScanScreen({super.key, this.patient});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _imageBytes;
  bool _uploading = false;

  Future<void> _analyze(BuildContext context) async {
    final auth = context.read<AuthService>();
    final api = auth.api;
    String? patientId = widget.patient?.id;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _uploading = true);
    try {
      if (patientId == null || patientId.isEmpty) {
        final createRes = await api.createPatient(identifier: null, facility: 'Gasabo');
        if (createRes.success && createRes.data != null) {
          patientId = createRes.data!['identifier'] as String? ?? createRes.data!['id'] as String?;
        }
      } else {
        final createRes = await api.createPatient(
          identifier: patientId,
          facility: 'Gasabo',
        );
        if (createRes.success) {
          patientId = createRes.data?['identifier'] as String? ?? patientId;
        }
      }
      if (patientId == null) {
        if (mounted) messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.t('couldNotCreatePatient'))),
        );
        return;
      }
      final uploadRes = await api.uploadScan(patientId, _imageBytes!);
      if (!mounted) return;
      if (uploadRes.success && uploadRes.data != null) {
        final result = uploadRes.data!['result'] as Map<String, dynamic>?;
        final risk = (result?['risk_level'] as String? ?? 'low').toLowerCase();
        final imt = (result?['imt_mm'] as num?)?.toDouble() ?? 0.0;
        final plaqueDetected = uploadRes.data!['plaque_detected'] as bool?;
        final overlayBase64 = uploadRes.data!['segmentation_overlay_base64'] as String?;
        final hasAiOverlay = uploadRes.data!['has_ai_overlay'] as bool? ?? false;
        final originalImageBase64 = overlayBase64 ?? base64Encode(_imageBytes!);
        if (mounted) context.push('/result', extra: {
          'risk': risk,
          'imt': imt,
          'plaqueDetected': plaqueDetected,
          'patientName': widget.patient?.name,
          'analyzedAt': DateTime.now().toIso8601String(),
          'segmentationOverlayBase64': overlayBase64,
          'originalImageBase64': originalImageBase64,
          'hasAiOverlay': hasAiOverlay,
        });
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(uploadRes.error ?? context.l10n.t('analysisFailed'))),
        );
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(
        SnackBar(content: Text('${context.l10n.t('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('carotidScan')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.patient != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.08),
                        AppTheme.accentTeal.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_outline, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.patient!.id != null)
                              Text(
                                widget.patient!.id!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              widget.patient!.name ?? 'Patient',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${widget.patient!.age} yrs • ${widget.patient!.gender}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                context.l10n.t('captureCarotidImage'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.t('captureCarotidImageDesc'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentTeal.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined, color: AppTheme.accentTeal, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.t('scanInstructions'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentTeal,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.accentTeal.withOpacity(0.08),
                        AppTheme.primaryBlue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentTeal.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart, size: 56, color: AppTheme.accentTeal.withOpacity(0.7)),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.t('noImageCaptured'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(context.l10n.t('camera')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: Text(context.l10n.t('gallery')),
                    ),
                  ),
                ],
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _uploading ? null : () => _analyze(context),
                  child: _uploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.t('analyze')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
