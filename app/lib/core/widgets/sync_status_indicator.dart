import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sync_service.dart';

/// Cloud Sync icon: Grey (offline), Orange (pending), Green (synced)
class SyncStatusIndicator extends StatelessWidget {
  final SyncService syncService;
  final double size;
  final bool showLabel;

  const SyncStatusIndicator({
    super.key,
    required this.syncService,
    this.size = 24,
    this.showLabel = true,
  });

  Color get _color {
    switch (syncService.status) {
      case 'offline':
        return AppTheme.syncOffline;
      case 'pending':
        return AppTheme.syncPending;
      case 'synced':
        return AppTheme.syncSynced;
      default:
        return AppTheme.syncOffline;
    }
  }

  String get _label {
    switch (syncService.status) {
      case 'offline':
        return 'Offline';
      case 'pending':
        return 'Syncing...';
      case 'synced':
        return 'Synced';
      default:
        return 'Offline';
    }
  }

  IconData get _icon {
    switch (syncService.status) {
      case 'offline':
        return Icons.cloud_off;
      case 'pending':
        return Icons.cloud_upload;
      case 'synced':
        return Icons.cloud_done;
      default:
        return Icons.cloud_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncService,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: _color, size: size),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                _label,
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
