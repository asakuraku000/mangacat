import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => connectionStatusController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  void initialize() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    checkConnection();
  }

  Future<bool> checkConnection() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    return _isConnected;
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any of the results indicate a connection
    final bool connected = results.any((result) => result != ConnectivityResult.none);
    
    if (_isConnected != connected) {
      _isConnected = connected;
      connectionStatusController.add(_isConnected);
    }
  }

  void dispose() {
    connectionStatusController.close();
  }
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}