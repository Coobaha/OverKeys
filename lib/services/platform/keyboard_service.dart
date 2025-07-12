import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abstract interface for platform-specific keyboard monitoring
abstract class KeyboardService {
  static KeyboardService create() {
    if (Platform.isWindows) {
      return _WindowsKeyboardService();
    } else if (Platform.isMacOS) {
      return _MacOSKeyboardService();
    } else {
      throw UnsupportedError(
          'Platform ${Platform.operatingSystem} is not supported');
    }
  }

  /// Start monitoring keyboard events
  Future<void> startMonitoring(bool Function(List<dynamic>) onKeyEvent);

  /// Stop monitoring keyboard events
  Future<void> stopMonitoring();

  /// Check if platform has necessary permissions
  Future<bool> checkPermissions();

  /// Update the list of trigger keys that should be consumed
  Future<void> updateTriggerKeys(List<String> triggerKeys);

  /// Dispose of any resources
  void dispose();
}

class _WindowsKeyboardService extends KeyboardService {
  @override
  Future<void> startMonitoring(bool Function(List<dynamic>) onKeyEvent) async {
    // Windows implementation would be moved here
    throw UnimplementedError('Windows implementation not yet migrated');
  }

  @override
  Future<void> stopMonitoring() async {
    throw UnimplementedError('Windows implementation not yet migrated');
  }

  @override
  Future<bool> checkPermissions() async {
    return true; // Windows doesn't need special permissions
  }

  @override
  Future<void> updateTriggerKeys(List<String> triggerKeys) async {
    // Windows implementation would be added here
    throw UnimplementedError('Windows implementation not yet migrated');
  }

  @override
  void dispose() {
    // Windows cleanup
  }
}

class _MacOSKeyboardService extends KeyboardService {
  static const _channel = MethodChannel('keyboard_monitor');
  bool Function(List<dynamic>)? _onKeyEvent;
  bool _isInitialized = false;

  _MacOSKeyboardService() {
    // Don't initialize immediately - wait for startMonitoring call
  }

  void _initializeIfNeeded() {
    if (!_isInitialized) {
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onKeyEvent':
        final List<dynamic> eventData = call.arguments as List<dynamic>;
        // AIDEV-NOTE: Process event and return consumption decision synchronously
        try {
          final shouldConsume = _onKeyEvent?.call(eventData) ?? false;
          return shouldConsume;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error processing key event: $e');
          }
          // Default to not consuming on error to avoid blocking system shortcuts
          return false;
        }
      default:
        return null;
    }
  }

  @override
  Future<void> startMonitoring(bool Function(List<dynamic>) onKeyEvent) async {
    _initializeIfNeeded();
    _onKeyEvent = onKeyEvent;
    try {
      await _channel.invokeMethod('startMonitoring');
    } on PlatformException catch (e) {
      debugPrint('Failed to start keyboard monitoring: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> stopMonitoring() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
      _onKeyEvent = null;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop keyboard monitoring: ${e.message}');
    }
  }

  @override
  Future<bool> checkPermissions() async {
    try {
      final bool hasPermissions =
          await _channel.invokeMethod('checkPermissions');
      return hasPermissions;
    } on PlatformException catch (e) {
      debugPrint('Failed to check permissions: ${e.message}');
      return false;
    }
  }

  Future<bool> checkAccessibilityPermissions() async {
    try {
      final bool hasPermissions =
          await _channel.invokeMethod('checkAccessibilityPermissions');
      return hasPermissions;
    } on PlatformException catch (e) {
      debugPrint('Failed to check accessibility permissions: ${e.message}');
      return false;
    }
  }

  Future<bool> checkInputMonitoringPermissions() async {
    try {
      final bool hasPermissions =
          await _channel.invokeMethod('checkInputMonitoringPermissions');
      return hasPermissions;
    } on PlatformException catch (e) {
      debugPrint('Failed to check input monitoring permissions: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> updateTriggerKeys(List<String> triggerKeys) async {
    try {
      await _channel.invokeMethod('updateTriggerKeys', triggerKeys);
    } on PlatformException catch (e) {
      debugPrint('Failed to update trigger keys: ${e.message}');
      rethrow;
    }
  }

  // AIDEV-NOTE: Get actual screen dimensions from native macOS API
  Future<Size> getScreenDimensions() async {
    try {
      final result = await _channel.invokeMethod('getScreenDimensions');
      final screenData = Map<String, dynamic>.from(result);
      return Size(
        (screenData['width'] as num).toDouble(),
        (screenData['height'] as num).toDouble(),
      );
    } on PlatformException catch (e) {
      debugPrint('Failed to get screen dimensions: ${e.message}');
      // Fallback to a reasonable default if native call fails
      return const Size(1920, 1080);
    }
  }

  @override
  void dispose() {
    stopMonitoring();
  }
}
