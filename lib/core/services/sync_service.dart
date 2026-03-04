import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Sync status: Grey (offline), Green (online). Uses connectivity + optional backend health.
class SyncService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  String _status = AppConstants.syncOffline;

  String get status => _status;
  bool get isOffline => _status == AppConstants.syncOffline;
  bool get isSynced => _status == AppConstants.syncSynced;

  SyncService() {
    _init();
  }

  Future<void> _init() async {
    await _updateFromConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen((_) => _updateFromConnectivity());
  }

  Future<void> _updateFromConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
    _status = hasConnection ? AppConstants.syncSynced : AppConstants.syncOffline;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
