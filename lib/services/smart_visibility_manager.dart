import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../models/keyboard_layouts.dart';

/// Centralized smart visibility logic with comprehensive state management
///   Quick Succession Flow
//
//   1. F19 trigger → Layer activated, ignore flag set
//   2. Right key (< quick succession window) → ⚡ Quick succession detected → _layerSuppressed = true
//   3. Timer continues → 1400ms delay respected
//   4. Timer expires → 👻 Smart Visibility: Skipping show - layer Cursor suppressed (quick succession
//   detected, user is proficient)
//   5. Final result: No overlay shown → User demonstrated proficiency, stay out of their way
//
//   Slow Succession Flow:
//
//   1. F19 trigger → Layer activated, ignore flag set
//   2. Right key (> quick succession window) → No suppression, normal timer
//   3. Timer expires → ✅ Smart Visibility: Showing overlay after inactivity
//   4. Final result: Overlay shown → User needs help
//
//   Now the system respects user proficiency:
//   - Fast typists (quick succession) → Overlay completely suppressed (never shows)
//   - Slower typists → Overlay shows after delay to help
//
//   This implements the perfect adaptive UX:
//   - Proficient users: System stays completely out of the way ✅
//   - Users who need help: System provides assistance after appropriate delay ✅
//
//   The quick succession logic is now working exactly as intended! 🎉
class SmartVisibilityManager {
  Timer? _inactivityTimer;
  Timer? _layerShowTimer;
  Timer? _opacitySaveTimer;
  bool _isInToggledLayer = false;
  String _currentLayerName = '';
  String? _defaultLayerName;

  double _defaultLayerDelay;
  double _customLayerDelay;
  double quickSuccessionWindow;
  bool debugEnabled;

  // Quick succession logic - suppress overlay when user demonstrates proficiency
  bool _ignoreNextKeypress = false;
  bool _layerSuppressed =
      false; // Suppress overlay for entire session when quick succession detected
  DateTime? _layerActivationTime;

  // Visibility state management
  bool _isVisible = true;
  bool _forceHidden = false;

  // Opacity management
  double _opacity = 0.85;
  double _lastOpacity = 0.85;

  // Auto-hide management
  bool _autoHideEnabled = false;
  double _autoHideDuration = 2.0; // seconds
  Timer? _autoHideTimer;

  // Layer registry and state
  final Map<String, KeyboardLayout> _layerRegistry = {};
  KeyboardLayout? _currentLayout;
  final Set<String> _activeTriggers = {};

  // AIDEV-NOTE: Stack-based layer state management for proper restoration
  final List<LayerState> _layerStack = [];

  final Function(bool visible)? onVisibilityChange;
  final Function(KeyboardLayout layout)? onLayerChange;
  final Function(bool hasActiveTimer)? onTimerStateChange;
  final Function(double opacity)? onOpacityChange;
  final Function()? onFadeIn;
  final Function()? onFadeOut;
  final Function(String message, Duration duration)? onShowOverlay;
  final Function(String key, dynamic value)? onSavePreference;
  final Function()? onSetupTray;

  SmartVisibilityManager({
    required double defaultLayerDelay,
    required double customLayerDelay,
    this.quickSuccessionWindow = 200.0,
    required this.debugEnabled,
    this.onVisibilityChange,
    this.onLayerChange,
    this.onTimerStateChange,
    this.onOpacityChange,
    this.onFadeIn,
    this.onFadeOut,
    this.onShowOverlay,
    this.onSavePreference,
    this.onSetupTray,
  })  : _defaultLayerDelay = defaultLayerDelay,
        _customLayerDelay = customLayerDelay;

  /// Update delay settings
  void updateDelays({
    double? defaultLayerDelay,
    double? customLayerDelay,
  }) {
    if (defaultLayerDelay != null) {
      _defaultLayerDelay = defaultLayerDelay;
    }
    if (customLayerDelay != null) {
      _customLayerDelay = customLayerDelay;
    }
  }

  /// Update full configuration without recreating manager
  void updateConfiguration({
    double? defaultLayerDelay,
    double? customLayerDelay,
    double? quickSuccessionWindow,
    bool? debugEnabled,
  }) {
    updateDelays(
      defaultLayerDelay: defaultLayerDelay,
      customLayerDelay: customLayerDelay,
    );
    if (quickSuccessionWindow != null) {
      this.quickSuccessionWindow = quickSuccessionWindow;
    }
    if (debugEnabled != null) {
      this.debugEnabled = debugEnabled;
    }
  }

  /// Set the default layer name for comparison
  void setDefaultLayer(String? defaultLayerName) {
    _defaultLayerName = defaultLayerName;
  }

  /// Register a layer in the layer registry
  void registerLayer(String layerName, KeyboardLayout layout) {
    _layerRegistry[layerName] = layout;
  }

  /// Register multiple layers
  void registerLayers(Map<String, KeyboardLayout> layers) {
    _layerRegistry.addAll(layers);
  }

  /// Get registered layer by name
  KeyboardLayout? getLayer(String layerName) {
    return _layerRegistry[layerName];
  }

  /// Clear all registered layers
  void clearLayers() {
    _layerRegistry.clear();
  }

  /// Request visibility change with reason - handles UI callbacks
  void requestVisibilityChange(VisibilityRequest request) {
    final previousVisible = _isVisible;

    switch (request.type) {
      case VisibilityRequestType.show:
        if (_forceHidden &&
            request.reason != 'force_show' &&
            request.reason != 'tray_click' &&
            request.reason != 'move_mode') {
          return;
        }
        _isVisible = true;
        _forceHidden = false;
        _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
        // Always trigger UI updates for show requests
        onVisibilityChange?.call(true);
        onOpacityChange?.call(_opacity);
        onFadeIn?.call();
        break;
      case VisibilityRequestType.hide:
        // Store current opacity before hiding
        if (_opacity > 0.0) {
          _lastOpacity = _opacity;
        }
        _isVisible = false;
        _opacity = 0.0;
        if (request.reason == 'force_hide') {
          _forceHidden = true;
        }
        // Always trigger UI updates for hide requests
        onVisibilityChange?.call(false);
        onOpacityChange?.call(_opacity);
        onFadeOut?.call();
        break;
      case VisibilityRequestType.toggle:
        if (_forceHidden && !_isVisible) {
          _forceHidden = false;
          _isVisible = true;
          _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
          onVisibilityChange?.call(true);
          onOpacityChange?.call(_opacity);
          onFadeIn?.call();
        } else {
          if (_isVisible) {
            // Store current opacity before hiding
            if (_opacity > 0.0) {
              _lastOpacity = _opacity;
            }
            _isVisible = false;
            _opacity = 0.0;
            _forceHidden = true;
            onVisibilityChange?.call(false);
            onOpacityChange?.call(_opacity);
            onFadeOut?.call();
          } else {
            _isVisible = true;
            _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
            onVisibilityChange?.call(true);
            onOpacityChange?.call(_opacity);
            onFadeIn?.call();
          }
        }
        break;
    }

    // Notify UI of visibility change
    if (previousVisible != _isVisible) {
      onVisibilityChange?.call(_isVisible);
    }

    // Notify UI of timer state changes
    _notifyTimerStateChange();
  }

  /// Check if should consume event based on triggers and state
  bool shouldConsumeEvent(
      String key, bool isPressed, Map<String, String> triggers) {
    // Always consume trigger key events to prevent system beep
    for (final trigger in triggers.values) {
      if (trigger.isNotEmpty && _matchesTriggerKey(key, trigger)) {
        return true;
      }
    }

    // Consume if key is part of active trigger combination
    if (_activeTriggers.contains(key)) {
      return true;
    }

    return false;
  }

  /// Check if key matches trigger (simplified version)
  bool _matchesTriggerKey(String key, String trigger) {
    final parts = trigger.split('+');
    final triggerKey = parts.last;
    return key.toLowerCase() == triggerKey.toLowerCase();
  }

  /// Show window with proper delay respecting configuration
  void showWithDelay(String layerName, {String? pressedKey}) {
    if (kDebugMode && debugEnabled) {
      debugPrint(
          '👁️ Smart Visibility: ShowWithDelay $layerName (force hidden: $_forceHidden)');
    }

    // Clear force hidden when triggering any layer (triggered layers should always be able to show)
    if (_forceHidden) {
      _forceHidden = false;
      if (kDebugMode && debugEnabled) {
        debugPrint(
            '🔓 Smart Visibility: Force hidden cleared - triggered layer $layerName can now show');
      }
    }

    // Always start timers for layer switching, even when force hidden
    resetInactivityTimer(layerName, () {
      if (kDebugMode && debugEnabled) {
        debugPrint(
            '👁️ Smart Visibility: Timer expired - showing $layerName (force hidden: $_forceHidden)');
      }
      _isVisible = true;
      _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;

      // Allow UI fade for triggered layers even when force hidden
      // Only block default layer when force hidden
      if (!_forceHidden || layerName != _defaultLayerName) {
        onVisibilityChange?.call(true);
        onOpacityChange?.call(_opacity);
        onFadeIn?.call();
        if (_forceHidden &&
            layerName != _defaultLayerName &&
            kDebugMode &&
            debugEnabled) {
          debugPrint(
              '🔓 Smart Visibility: Triggered layer overrides force hidden ($layerName != $_defaultLayerName)');
        }
      } else {
        if (kDebugMode && debugEnabled) {
          debugPrint(
              '🔒 Smart Visibility: Default layer BLOCKED by force hidden ($layerName == $_defaultLayerName)');
        }
      }
    }, pressedKey: pressedKey);
  }

  /// Show window immediately without delay (for held layers, manual overrides)
  void showImmediate(String layerName) {
    if (kDebugMode && debugEnabled) {
      debugPrint(
          '👁️ Smart Visibility: ShowImmediate $layerName (force hidden: $_forceHidden)');
    }

    // Allow held layers to work even when force hidden (they override global hide)
    _isVisible = true;
    _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;

    if (!_forceHidden || layerName != _defaultLayerName) {
      onVisibilityChange?.call(true);
      onOpacityChange?.call(_opacity);
      onFadeIn?.call();
      if (_forceHidden && kDebugMode && debugEnabled) {
        debugPrint(
            '🔓 Smart Visibility: Force hidden TEMPORARILY overridden for held layer');
      }
    } else {
      if (kDebugMode && debugEnabled) {
        debugPrint(
            '🔒 Smart Visibility: UI fade blocked - force hidden active');
      }
    }
  }

  /// Hide window
  void hide() {
    if (kDebugMode && debugEnabled) {
      debugPrint('👁️ Smart Visibility: Hiding window');
    }

    // Store current opacity before hiding
    if (_opacity > 0.0) {
      _lastOpacity = _opacity;
    }

    _isVisible = false;
    _opacity = 0.0;

    onVisibilityChange?.call(false);
    onOpacityChange?.call(_opacity);
    onFadeOut?.call();
  }

  /// Reset inactivity timer for the current layer
  void resetInactivityTimer(String layerName, VoidCallback onShow,
      {String? pressedKey}) {
    // Always cancel existing timer first
    _inactivityTimer?.cancel();

    // Always allow timers to start for layer switching logic, even when force hidden
    // The onShow callback will handle checking force hidden state

    // If layer is suppressed and this is the first call, skip showing overlay but keep layer active
    // However, if user continues typing after quick succession, we should respect the delay
    if (_layerSuppressed && pressedKey == null) {
      if (kDebugMode && debugEnabled) {
        debugPrint(
            '👻 Smart Visibility: Layer $layerName suppressed - user demonstrates proficiency, skipping initial overlay');
      }
      return; // Layer stays active but no overlay shown
    }

    // Handle keypress logic
    if (pressedKey != null) {
      // Handle ignore logic for trigger key
      if (_ignoreNextKeypress) {
        _ignoreNextKeypress = false;
        // Set the baseline time for quick succession detection after ignoring trigger
        _layerActivationTime = DateTime.now();
        // Fall through to start normal timer after ignoring trigger
      } else {
        // Check for quick succession only on the first keypress after the trigger
        if (_layerActivationTime != null && !_layerSuppressed) {
          final timeSinceActivation =
              DateTime.now().difference(_layerActivationTime!).inMilliseconds;
          if (timeSinceActivation <= quickSuccessionWindow) {
            // Quick succession detected - suppress overlay but continue with timer logic
            _layerSuppressed = true;
            if (kDebugMode && debugEnabled) {
              debugPrint(
                  '⚡ Smart Visibility: Quick succession detected (${timeSinceActivation}ms <= ${quickSuccessionWindow}ms) - suppressing current show but will respect delay for continued typing');
            }
            // Don't return - continue with normal timer logic for continued typing
          } else {
            // Outside quick succession window - ignore this keypress, let normal timer logic handle showing
            if (kDebugMode && debugEnabled) {
              debugPrint(
                  '🕰 Smart Visibility: Outside quick succession window (${timeSinceActivation}ms > ${quickSuccessionWindow}ms) - ignoring keypress, letting normal timer handle $layerName');
            }
            // Mark that we've processed the quick succession check
            _layerSuppressed =
                false; // Ensure subsequent keypresses don't get the quick succession treatment
          }
          // Clear the activation time after first quick succession check
          _layerActivationTime = null;
        }
        // For subsequent keypresses after quick succession check, just continue with normal timer logic
      }
    }

    final isDefaultLayer = layerName == _defaultLayerName;
    final delay = isDefaultLayer ? _defaultLayerDelay : _customLayerDelay;
    _currentLayerName = layerName;

    if (kDebugMode && debugEnabled) {
      debugPrint(
          '🔄 Smart Visibility: Starting inactivity timer for $layerName (${delay}ms) - key: $pressedKey');
    }

    _inactivityTimer = Timer(Duration(milliseconds: delay.round()), () {
      final isDefaultLayer = layerName == _defaultLayerName;
      // For default layer: only check layer name match (not toggled state)
      // For custom layers: check both layer name AND toggled state
      final shouldShow = (_currentLayerName == layerName) &&
          (isDefaultLayer || _isInToggledLayer);

      if (shouldShow) {
        // If layer is suppressed from quick succession, never show - user demonstrated proficiency
        if (_layerSuppressed) {
          if (kDebugMode && debugEnabled) {
            debugPrint(
                '👻 Smart Visibility: Skipping show - layer $layerName suppressed (quick succession detected, user is proficient)');
          }
          return;
        }

        // Only show if not suppressed

        // Update internal visibility state before calling UI callback
        _isVisible = true;
        _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
        onVisibilityChange?.call(true);
        onOpacityChange?.call(_opacity);
        onShow();
      }
    });

    _notifyTimerStateChange();
  }

  /// Update layer state and current layer name
  void updateLayerState(
      {required String layerName, required bool isInToggledLayer}) {
    // Reset all flags when exiting layer
    if (_isInToggledLayer && !isInToggledLayer) {
      _layerSuppressed = false;
      _ignoreNextKeypress = false;
    }

    // Reset flags when entering new layer
    if ((!_isInToggledLayer && isInToggledLayer) ||
        (_isInToggledLayer && _currentLayerName != layerName)) {
      _layerSuppressed = false;
      _ignoreNextKeypress =
          true; // Set flag to ignore first keypress (activation trigger)
      _layerActivationTime = DateTime
          .now(); // Set activation timestamp for quick succession detection
    }

    _currentLayerName = layerName;
    _isInToggledLayer = isInToggledLayer;

    // Update current layout
    _currentLayout = _layerRegistry[layerName];

    if (kDebugMode && debugEnabled) {
      debugPrint(
          '📱 Smart Visibility: Layer state updated - $layerName (toggled: $isInToggledLayer)');
    }

    // Don't call onLayerChange here - let the app.dart handle timing based on transition type
  }

  /// Toggle layer - handles all layer switching logic
  bool toggleLayer(String layerName, {String? defaultLayerName}) {
    _cancelAllTimers();

    // If toggling same layer while active - turn OFF
    if (_isInToggledLayer && _currentLayerName == layerName) {
      _isInToggledLayer = false;
      _currentLayerName = defaultLayerName ?? '';
      _layerSuppressed = false;

      if (kDebugMode && debugEnabled) {
        debugPrint(
            '👋 Smart Visibility: Toggle OFF $layerName - returning to ${defaultLayerName ?? 'default'}');
      }
      return false; // Return false = layer OFF, switch to default
    }

    // Otherwise turn ON this layer
    _isInToggledLayer = true;
    _currentLayerName = layerName;
    _layerSuppressed = false;
    _ignoreNextKeypress = true;
    _layerActivationTime = DateTime
        .now(); // Set activation timestamp for quick succession detection
    return true; // Return true = layer ON
  }

  /// Cancel all timers and reset suppression
  void cancelAllTimers() {
    _cancelAllTimers();
    // Reset suppression when canceling timers (usually on layer toggle off)
    _layerSuppressed = false;
  }

  void _cancelAllTimers() {
    if (kDebugMode &&
        debugEnabled &&
        (_layerShowTimer?.isActive == true ||
            _inactivityTimer?.isActive == true)) {
      debugPrint('🛑 Smart Visibility: Canceling pending timers');
    }
    _layerShowTimer?.cancel();
    _inactivityTimer?.cancel();

    _notifyTimerStateChange();
  }

  /// Notify UI of timer state changes
  void _notifyTimerStateChange() {
    final hasActiveTimer = (_layerShowTimer?.isActive == true) ||
        (_inactivityTimer?.isActive == true);
    onTimerStateChange?.call(hasActiveTimer);
  }

  /// Get current layer name
  String get currentLayerName => _currentLayerName;

  /// Check if currently in toggled layer
  bool get isInToggledLayer => _isInToggledLayer;

  /// Get current layout
  KeyboardLayout? get currentLayout => _currentLayout;

  /// Get visibility state
  bool get isVisible => _isVisible;

  /// Get force hidden state
  bool get isForceHidden => _forceHidden;

  /// Get opacity state
  double get opacity => _opacity;
  double get lastOpacity => _lastOpacity;

  /// Get auto-hide state
  bool get autoHideEnabled => _autoHideEnabled;
  double get autoHideDuration => _autoHideDuration;

  /// Set opacity and notify UI
  void setOpacity(double opacity) {
    _opacity = opacity.clamp(0.0, 1.0);
    if (_opacity > 0.0) {
      _lastOpacity = _opacity;
    }
    onOpacityChange?.call(_opacity);
  }

  /// Adjust opacity up or down
  void adjustOpacity(bool increase) {
    final newOpacity = increase
        ? (_opacity + 0.05).clamp(0.1, 1.0)
        : (_opacity - 0.05).clamp(0.1, 1.0);
    setOpacity(newOpacity);
  }

  /// Adjust opacity with overlay feedback and preference saving
  void adjustOpacityWithOverlay(
    bool increase, {
    required Function(String message, Icon icon) showOverlay,
    required Function() savePreferences,
    required Function(List<int> windowIds, double opacity) updateMultiWindow,
  }) {
    final oldOpacity = _opacity;
    adjustOpacity(increase);

    if (_opacity != oldOpacity) {
      final percentage = (_opacity * 100).round();
      final icon = increase
          ? const Icon(LucideIcons.plusCircle)
          : const Icon(LucideIcons.minusCircle);
      showOverlay('Opacity: $percentage%', icon);

      // Handle debounced saving and multi-window updates
      _scheduleOpacitySave(savePreferences, updateMultiWindow);
    }
  }

  /// Update auto-hide settings
  void updateAutoHideSettings({bool? enabled, double? duration}) {
    final wasEnabled = _autoHideEnabled;

    if (enabled != null) {
      _autoHideEnabled = enabled;
    }
    if (duration != null) {
      _autoHideDuration = duration;
    }

    // If auto-hide was just enabled and window is visible, start timer
    if (_autoHideEnabled && !wasEnabled && _isVisible) {
      _resetAutoHideTimer();
    }
    // If auto-hide was disabled, cancel timer and show if hidden
    else if (!_autoHideEnabled && wasEnabled) {
      _autoHideTimer?.cancel();
      if (!_isVisible) {
        _isVisible = true;
        _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
        onVisibilityChange?.call(true);
        onOpacityChange?.call(_opacity);
        onFadeIn?.call();
      }
    }
  }

  /// Toggle auto-hide with overlay feedback and preference saving
  void toggleAutoHideWithOverlay(
    bool enable, {
    required Function(String message, Icon icon) showOverlay,
    required Function() savePreferences,
    required Function() setupTray,
  }) {
    updateAutoHideSettings(enabled: enable);

    final status = enable ? 'enabled' : 'disabled';
    final icon = enable
        ? const Icon(LucideIcons.timerReset)
        : const Icon(LucideIcons.timerOff);
    showOverlay('Auto-hide $status', icon);

    savePreferences();
    setupTray();
  }

  /// Reset auto-hide timer
  void _resetAutoHideTimer() {
    if (!_autoHideEnabled) return;

    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(
      Duration(milliseconds: (_autoHideDuration * 1000).round()),
      _handleAutoHide,
    );
  }

  /// Handle auto-hide timeout
  void _handleAutoHide() {
    if (_autoHideEnabled && _isVisible) {
      // Store current opacity before hiding
      if (_opacity > 0.0) {
        _lastOpacity = _opacity;
      }
      _isVisible = false;
      _opacity = 0.0;
      onVisibilityChange?.call(false);
      onOpacityChange?.call(_opacity);
      onFadeOut?.call();
    }
  }

  /// Notify of key activity - resets auto-hide timer and shows if hidden
  void onKeyActivity() {
    if (_autoHideEnabled) {
      // Auto-show on keypress when hidden
      if (!_isVisible && !_forceHidden) {
        _isVisible = true;
        _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
        onVisibilityChange?.call(true);
        onOpacityChange?.call(_opacity);
        onFadeIn?.call();
      }
      // Reset timer on any key activity
      _resetAutoHideTimer();
    }
  }

  /// Get active triggers
  Set<String> get activeTriggers => Set.from(_activeTriggers);

  /// Get registered layers
  Map<String, KeyboardLayout> get layerRegistry => Map.from(_layerRegistry);

  /// Get current delay settings
  double get defaultLayerDelay => _defaultLayerDelay;
  double get customLayerDelay => _customLayerDelay;

  /// Check if window should be visible (combines all visibility state)
  bool get shouldWindowBeVisible => _isVisible && !_forceHidden;

  /// Push current layer state onto stack
  void _pushLayerState(String layerName, bool isVisible) {
    final layout = _layerRegistry[layerName];
    final state = LayerState(
      layerName: layerName,
      wasVisible: isVisible,
      layout: layout,
    );
    _layerStack.add(state);
  }

  /// Pop previous layer state from stack
  LayerState? _popLayerState() {
    if (_layerStack.isEmpty) {
      return null;
    }

    final state = _layerStack.removeLast();
    return state;
  }

  /// Get current stack state for debugging
  List<LayerState> get layerStack => List.from(_layerStack);

  /// Internal debounced save handling
  void _scheduleOpacitySave(
      Function() savePrefs, Function(List<int>, double) updateWindows) {
    _opacitySaveTimer?.cancel();
    _opacitySaveTimer = Timer(const Duration(milliseconds: 125), () {
      savePrefs();
      DesktopMultiWindow.getAllSubWindowIds().then((windowIds) {
        updateWindows(windowIds, _opacity);
      });
    });
  }

  /// High-level unified key event handling
  KeyEventResult handleKeyEvent({
    required String key,
    required bool isPressed,
    required Map<String, String> triggers,
    required bool useUserLayouts,
    required bool advancedSettingsEnabled,
    required bool hasDefaultLayout,
    required bool isWindowVisible,
    required VoidCallback onShow,
    String? defaultLayerName,
  }) {
    // 🚫 FILTER OUT SPURIOUS MODIFIER EVENTS: Ignore modifier events for quick succession detection
    // These are spurious events from trigger combinations that should not trigger quick succession
    if (_isSpuriousModifierEvent(key, isPressed)) {
      return KeyEventResult(shouldConsume: false); // Ignore spurious events
    }
    // Handle key release events
    if (!isPressed) {
      // Check for held layer release (only log matches, not all checks)
      for (final entry in triggers.entries) {
        final trigger = entry.value;
        if (trigger.isNotEmpty && _matchesTriggerKey(key, trigger)) {
          if (entry.key.endsWith('_held')) {
            final transition = handleHeldLayerRelease(defaultLayerName);
            return KeyEventResult(
              shouldConsume: true,
              transition: transition,
              shouldShow: transition.shouldShow,
            );
          }
        }
      }

      return KeyEventResult(shouldConsume: false);
    }

    // Handle key press events
    bool shouldConsume = shouldConsumeEvent(key, isPressed, triggers);

    // Check for layer triggers
    for (final entry in triggers.entries) {
      final trigger = entry.value;
      if (trigger.isNotEmpty && _matchesTriggerKey(key, trigger)) {
        final layerName = entry.key;

        if (layerName.endsWith('_held')) {
          // Held layer activation
          final actualLayerName = layerName.replaceAll('_held', '');
          final transition = handleHeldLayerPress(actualLayerName);
          return KeyEventResult(
            shouldConsume: true,
            transition: transition,
            shouldShow: transition.shouldShow,
          );
        } else {
          // Toggle layer activation
          if (kDebugMode && debugEnabled) {
            debugPrint(
                '🔄 Smart Visibility: Toggle layer $layerName pressed (current: $_currentLayerName, visible: $isWindowVisible, forceHide: $_forceHidden)');
          }
          final transition = handleToggleLayer(
            layerName,
            defaultLayerName: defaultLayerName,
            isWindowVisible: isWindowVisible,
          );
          return KeyEventResult(
            shouldConsume: true,
            transition: transition,
            shouldShow: transition.shouldShow,
          );
        }
      }
    }

    // Handle regular keypress (not a trigger)
    if (_isInToggledLayer) {
      resetInactivityTimer(_currentLayerName, onShow, pressedKey: key);
    } else {
      // Don't auto-show default layer on every keypress - only show when explicitly needed
      // Default layer should only show during inactivity periods, not on active typing
    }

    return KeyEventResult(shouldConsume: shouldConsume);
  }

  /// Handle toggle layer transition with full logic
  LayerTransition handleToggleLayer(
    String layerName, {
    String? defaultLayerName,
    required bool isWindowVisible,
  }) {
    _cancelAllTimers();

    // If toggling same layer while active - turn OFF (POP from stack)
    if (_isInToggledLayer && _currentLayerName == layerName) {
      _isInToggledLayer = false;
      _layerSuppressed = false;

      // Pop previous state from stack
      final previousState = _popLayerState();

      if (previousState != null) {
        // Restore previous layer name but delay layout update until after transition
        _currentLayerName = previousState.layerName;
        // _currentLayout will be updated by app.dart after fadeout completes

        if (kDebugMode && debugEnabled) {
          debugPrint(
              '👋 Smart Visibility: Toggle OFF $layerName - restoring ${previousState.layerName} (was visible: ${previousState.wasVisible})');
        }

        return LayerTransition(
          type: LayerTransitionType.turnOff,
          targetLayerName: previousState.layerName,
          layout: previousState.layout,
          shouldFadeOut:
              !previousState.wasVisible, // Fade out if previous was hidden
          shouldStartTimer: previousState
              .wasVisible, // Start timer if layer should be visible
          shouldShow: false, // Never show immediately - let timer handle it
          useSmartVisibility: true, // Use SmartVisibilityManager for timing
        );
      } else {
        // Fallback to default if stack is empty
        _currentLayerName = defaultLayerName ?? '';
        final targetLayout = _layerRegistry[defaultLayerName ?? ''];
        _currentLayout = targetLayout;

        if (kDebugMode && debugEnabled) {
          debugPrint(
              '👋 Smart Visibility: Toggle OFF $layerName - no stack, fallback to ${defaultLayerName ?? 'default'}');
        }

        return LayerTransition(
          type: LayerTransitionType.turnOff,
          targetLayerName: defaultLayerName ?? '',
          layout: targetLayout,
          shouldFadeOut: true,
          shouldStartTimer: false,
          shouldShow: false, // Don't auto-show on fallback
          useSmartVisibility: true,
        );
      }
    }

    // Otherwise turn ON this layer (PUSH current state to stack)
    // Push current state before switching
    _pushLayerState(
        _currentLayerName.isEmpty ? defaultLayerName ?? '' : _currentLayerName,
        isWindowVisible);

    _isInToggledLayer = true;
    _currentLayerName = layerName;
    _layerSuppressed = false;
    _ignoreNextKeypress = true;

    // Get the target layout
    final targetLayout = _layerRegistry[layerName];
    _currentLayout = targetLayout;

    if (kDebugMode && debugEnabled) {
      debugPrint(
          '🎯 Smart Visibility: Toggle ON $layerName - ready to ignore activation trigger');
    }

    // Don't call onLayerChange here for toggle transitions - let app.dart handle timing

    return LayerTransition(
      type: LayerTransitionType.turnOn,
      targetLayerName: layerName,
      layout: targetLayout,
      shouldFadeOut: isWindowVisible,
      shouldStartTimer: true,
      shouldShow: false, // Never show immediately - always use timer
      useSmartVisibility: true, // Flag to use SmartVisibilityManager
    );
  }

  /// Handle held layer activation
  LayerTransition handleHeldLayerPress(String layerName) {
    _cancelAllTimers();

    // Add to active triggers
    _activeTriggers.add(layerName);

    // Get the layout for this layer
    final layout = _layerRegistry[layerName];
    _currentLayout = layout;
    _currentLayerName = layerName;

    // Notify layer change
    if (layout != null) {
      onLayerChange?.call(layout);
    }

    // Show held layers immediately (they should not have delays)
    if (!_forceHidden) {
      showImmediate(layerName);
    } else {
      // Even if force hidden, update opacity for when it becomes visible
      _opacity = _lastOpacity > 0.0 ? _lastOpacity : 0.85;
      onOpacityChange?.call(_opacity);
    }

    return LayerTransition(
      type: LayerTransitionType.held,
      targetLayerName: layerName,
      layout: layout,
      shouldFadeOut: false,
      shouldStartTimer: false,
      shouldShow: false, // SmartVisibilityManager handles it
      useSmartVisibility: true,
    );
  }

  /// Handle held layer release
  LayerTransition handleHeldLayerRelease(String? defaultLayerName) {
    _cancelAllTimers();

    // Clear active triggers (simplified - in real usage you'd track specific keys)
    _activeTriggers.clear();

    final targetLayerName = defaultLayerName ?? _defaultLayerName ?? '';
    final layout = _layerRegistry[targetLayerName];
    _currentLayout = layout;
    _currentLayerName = targetLayerName;

    // Notify layer change
    if (layout != null) {
      onLayerChange?.call(layout);
    }

    // Hide on held layer release, then show target if not force hidden
    hide();
    if (!_forceHidden) {
      showImmediate(targetLayerName);
    }

    return LayerTransition(
      type: LayerTransitionType.heldRelease,
      targetLayerName: targetLayerName,
      layout: layout,
      shouldFadeOut: false,
      shouldStartTimer: false,
      shouldShow: false, // SmartVisibilityManager handles it
      useSmartVisibility: true,
    );
  }

  // 🚫 SMART MODIFIER FILTERING: Detect spurious modifier events from trigger combos
  bool _isSpuriousModifierEvent(String key, bool isPressed) {
    // Only filter modifier events (both press and release)
    final isModifier = _isModifierKey(key);
    if (!isModifier) return false;

    // If we recently activated a layer via trigger, check if this modifier was part of the trigger
    if (_layerActivationTime != null && _currentLayerName.isNotEmpty) {
      final timeSinceActivation =
          DateTime.now().difference(_layerActivationTime!).inMilliseconds;

      // Within 200ms of layer activation, check if this modifier was part of the trigger combo
      if (timeSinceActivation <= 100) {
        // Check if the current layer has a trigger that includes this modifier
        final wasPartOfTrigger = _wasModifierPartOfLastTrigger(key);

        if (wasPartOfTrigger) {
          return true; // This modifier was part of the trigger combo
        }
      }
    }

    return false; // Not spurious
  }

  bool _wasModifierPartOfLastTrigger(String key) {
    // For the trigger "cmd+alt+ctrl+shift+F19", these modifiers should be filtered:
    // cmd, alt, ctrl, shift (but not F19, which is the actual trigger key)

    // Map key names to trigger format
    String triggerModifierName = '';
    switch (key) {
      case 'LControl':
      case 'RControl':
        triggerModifierName = 'ctrl';
        break;
      case 'LShift':
      case 'RShift':
        triggerModifierName = 'shift';
        break;
      case 'LAlt':
      case 'RAlt':
        triggerModifierName = 'alt';
        break;
      case 'Cmd':
      case 'RCmd':
        triggerModifierName = 'cmd';
        break;
      default:
        return false; // Not a modifier we track
    }

    // For now, assume all standard modifiers (cmd, alt, ctrl, shift) are part of F19 triggers
    // This could be enhanced to check the actual trigger string for the current layer
    final isStandardModifier =
        ['cmd', 'alt', 'ctrl', 'shift'].contains(triggerModifierName);

    return isStandardModifier;
  }

  bool _isModifierKey(String key) {
    switch (key) {
      case 'LControl':
      case 'RControl':
      case 'LShift':
      case 'RShift':
      case 'LAlt':
      case 'RAlt':
      case 'Cmd':
      case 'RCmd':
        return true;
      default:
        return false;
    }
  }

  void dispose() {
    _cancelAllTimers();
    _autoHideTimer?.cancel();
    _opacitySaveTimer?.cancel();
  }
}

/// Represents a layer transition with all necessary information
class LayerTransition {
  final LayerTransitionType type;
  final String targetLayerName;
  final KeyboardLayout? layout;
  final bool shouldFadeOut;
  final bool shouldStartTimer;
  final bool shouldShow;
  final bool
      useSmartVisibility; // Use SmartVisibilityManager for all visibility decisions

  LayerTransition({
    required this.type,
    required this.targetLayerName,
    this.layout,
    required this.shouldFadeOut,
    required this.shouldStartTimer,
    this.shouldShow = true,
    this.useSmartVisibility = false,
  });
}

enum LayerTransitionType {
  turnOn,
  turnOff,
  held,
  heldRelease,
}

/// Represents a visibility change request
class VisibilityRequest {
  final VisibilityRequestType type;
  final String reason;

  VisibilityRequest({
    required this.type,
    required this.reason,
  });
}

enum VisibilityRequestType {
  show,
  hide,
  toggle,
}

/// Represents a layer state in the stack for proper restoration
class LayerState {
  final String layerName;
  final bool wasVisible;
  final KeyboardLayout? layout;

  LayerState({
    required this.layerName,
    required this.wasVisible,
    this.layout,
  });

  @override
  String toString() => 'LayerState($layerName, visible: $wasVisible)';
}

/// Result of handling a key event
class KeyEventResult {
  final bool shouldConsume;
  final LayerTransition? transition;
  final bool shouldShow;

  KeyEventResult({
    required this.shouldConsume,
    this.transition,
    this.shouldShow = false,
  });
}
