import 'dart:async';
import 'package:flutter/foundation.dart';

/// AIDEV-NOTE: Centralized smart visibility logic with comprehensive state management
class SmartVisibilityManager {
  Timer? _inactivityTimer;
  Timer? _layerShowTimer;
  bool _isInToggledLayer = false;
  String _currentLayerName = '';
  String? _defaultLayerName;
  
  double _defaultLayerDelay;
  double _customLayerDelay;
  final double quickSuccessionWindow;
  final bool debugEnabled;
  
  // Quick succession detection
  DateTime? _lastKeypressTime;
  
  SmartVisibilityManager({
    required double defaultLayerDelay,
    required double customLayerDelay,
    this.quickSuccessionWindow = 200.0, // 200ms default
    required this.debugEnabled,
  }) : _defaultLayerDelay = defaultLayerDelay,
       _customLayerDelay = customLayerDelay;

  /// Update delay settings
  void updateDelays({
    double? defaultLayerDelay,
    double? customLayerDelay,
  }) {
    if (defaultLayerDelay != null) _defaultLayerDelay = defaultLayerDelay;
    if (customLayerDelay != null) _customLayerDelay = customLayerDelay;
  }

  /// Set the default layer name for comparison
  void setDefaultLayer(String? defaultLayerName) {
    _defaultLayerName = defaultLayerName;
  }

  /// Check if we should show overlay after inactivity
  bool shouldShowOnInactivity({
    required bool useUserLayouts,
    required bool advancedSettingsEnabled,
    required bool forceHidden,
    required bool windowVisible,
    required bool hasDefaultLayout,
  }) {
    if (!useUserLayouts || !advancedSettingsEnabled) {
      if (kDebugMode && debugEnabled) {
        debugPrint('❌ Smart Visibility: User layouts disabled or advanced settings off');
      }
      return false;
    }
    if (forceHidden || windowVisible) {
      if (kDebugMode && debugEnabled) {
        debugPrint('❌ Smart Visibility: Force hidden or already visible');
      }
      return false;
    }
    if (!hasDefaultLayout) {
      if (kDebugMode && debugEnabled) {
        debugPrint('❌ Smart Visibility: No default layout defined');
      }
      return false;
    }

    if (kDebugMode && debugEnabled) {
      debugPrint('🔍 Smart Visibility: Current=$_currentLayerName, Default=$_defaultLayerName, InToggled=$_isInToggledLayer');
    }
    return true;
  }

  /// Reset inactivity timer for the current layer
  void resetInactivityTimer(String layerName, VoidCallback onShow, {String? pressedKey}) {
    final now = DateTime.now();
    
    // Always cancel existing timer first
    _inactivityTimer?.cancel();
    
    // Quick succession detection - skip if any key pressed within window
    if (_lastKeypressTime != null) {
      final timeSinceLastPress = now.difference(_lastKeypressTime!).inMilliseconds;
      if (timeSinceLastPress <= quickSuccessionWindow) {
        if (kDebugMode && debugEnabled) {
          debugPrint('⚡ Smart Visibility: Quick succession detected (${timeSinceLastPress}ms) - skipping overlay for key "$pressedKey"');
        }
        _lastKeypressTime = now;
        return; // Skip showing overlay for quick succession
      }
    }
    
    _lastKeypressTime = now;
    
    final isDefaultLayer = layerName == _defaultLayerName;
    final delay = isDefaultLayer ? _defaultLayerDelay : _customLayerDelay;
    _currentLayerName = layerName;
    
    if (kDebugMode && debugEnabled) {
      debugPrint('🔄 Smart Visibility: Starting inactivity timer for $layerName (${delay}ms) - key: $pressedKey');
    }
    
    _inactivityTimer = Timer(Duration(milliseconds: delay.round()), () {
      if (_currentLayerName == layerName && _isInToggledLayer) {
        if (kDebugMode && debugEnabled) {
          debugPrint('✅ Smart Visibility: Showing overlay after inactivity for $layerName');
        }
        onShow();
      } else if (kDebugMode && debugEnabled) {
        debugPrint('❌ Smart Visibility: Skipping show - layer changed from $layerName to $_currentLayerName, toggled state: $_isInToggledLayer');
      }
    });
  }

  /// Start or restart inactivity timer for current layer (legacy method)
  void startInactivityTimer(String layerName, bool isDefaultLayer, VoidCallback onShow) {
    _cancelAllTimers();
    
    final delay = isDefaultLayer ? _defaultLayerDelay : _customLayerDelay;
    _currentLayerName = layerName;
    
    if (kDebugMode && debugEnabled) {
      debugPrint('🔄 Smart Visibility: Starting timer for $layerName (${delay}ms)');
    }
    
    _inactivityTimer = Timer(Duration(milliseconds: delay.round()), () {
      if (_currentLayerName == layerName) {
        if (kDebugMode && debugEnabled) {
          debugPrint('✅ Smart Visibility: Timer expired for $layerName');
        }
        onShow();
      } else if (kDebugMode && debugEnabled) {
        debugPrint('❌ Smart Visibility: Skipping show - layer changed from $layerName to $_currentLayerName');
      }
    });
  }

  /// Update layer state and current layer name
  void updateLayerState({
    required String layerName,
    required bool isInToggledLayer,
  }) {
    _currentLayerName = layerName;
    _isInToggledLayer = isInToggledLayer;
    
    if (kDebugMode && debugEnabled) {
      debugPrint('📱 Smart Visibility: Layer state updated - $layerName (toggled: $isInToggledLayer)');
    }
  }

  /// Set layer state (legacy method)
  void setLayerState(bool isInCustomLayer) {
    _isInToggledLayer = isInCustomLayer;
  }

  /// Cancel all timers
  void cancelAllTimers() {
    _cancelAllTimers();
  }

  /// Cancel any active timer (legacy method)
  void cancelTimer() {
    _cancelAllTimers();
  }

  void _cancelAllTimers() {
    if (kDebugMode && debugEnabled && 
        (_layerShowTimer?.isActive == true || _inactivityTimer?.isActive == true)) {
      debugPrint('🛑 Smart Visibility: Canceling pending timers');
    }
    _layerShowTimer?.cancel();
    _inactivityTimer?.cancel();
  }

  /// Get current layer name
  String get currentLayerName => _currentLayerName;

  /// Check if currently in toggled layer
  bool get isInToggledLayer => _isInToggledLayer;

  /// Get current delay settings
  double get defaultLayerDelay => _defaultLayerDelay;
  double get customLayerDelay => _customLayerDelay;

  void dispose() {
    _cancelAllTimers();
  }
}