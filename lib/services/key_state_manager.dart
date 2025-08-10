import 'package:flutter/foundation.dart';

class KeyStateManager {
  static final KeyStateManager _instance = KeyStateManager._internal();
  factory KeyStateManager() => _instance;
  KeyStateManager._internal();

  // Individual ValueNotifiers per key
  final Map<String, ValueNotifier<bool>> _keyNotifiers = {};

  // Performance metrics
  int _updateCount = 0;
  int _activeKeys = 0;

  // Get or create notifier for a key
  ValueNotifier<bool> getKeyNotifier(String key) {
    return _keyNotifiers.putIfAbsent(key, () {
      _activeKeys++;
      return ValueNotifier<bool>(false);
    });
  }

  // Update key state - no debouncing to ensure zero keystroke loss
  void updateKeyState(String key, bool isPressed,
      {Duration debounce = Duration.zero}) {
    final notifier = getKeyNotifier(key);
    _performUpdate(notifier, isPressed, key);
  }

  void _performUpdate(
      ValueNotifier<bool> notifier, bool isPressed, String key) {
    if (notifier.value != isPressed) {
      notifier.value = isPressed;
      _updateCount++;
    }
  }

  // Bulk operations for efficiency
  void updateMultipleKeys(Map<String, bool> updates) {
    for (final entry in updates.entries) {
      updateKeyState(entry.key, entry.value);
    }
  }

  // Clear all key states
  void clearAllKeys() {
    for (final notifier in _keyNotifiers.values) {
      if (notifier.value) {
        notifier.value = false;
      }
    }
    _updateCount++;
  }

  // Memory management
  void pruneUnusedKeys(Set<String> activeKeys) {
    final toRemove = <String>[];
    for (final key in _keyNotifiers.keys) {
      if (!activeKeys.contains(key)) {
        toRemove.add(key);
      }
    }

    for (final key in toRemove) {
      _keyNotifiers[key]?.dispose();
      _keyNotifiers.remove(key);
      _activeKeys--;
    }
  }

  // Performance metrics
  Map<String, dynamic> getPerformanceMetrics() => {
        'totalUpdates': _updateCount,
        'activeKeys': _activeKeys,
        'notifierCount': _keyNotifiers.length,
      };

  void dispose() {
    for (final notifier in _keyNotifiers.values) {
      notifier.dispose();
    }
    _keyNotifiers.clear();
  }
}
