import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class KeyRenderCache {
  static final KeyRenderCache _instance = KeyRenderCache._internal();
  factory KeyRenderCache() => _instance;
  KeyRenderCache._internal();

  // Cache storage
  final Map<String, Color> _colorCache = {};
  final Map<String, Matrix4> _transformCache = {};
  final Map<String, BoxDecoration> _decorationCache = {};

  // Cache keys for invalidation
  String? _lastThemeHash;
  String? _lastConfigHash;

  // Generate cache key from parameters
  String _generateColorKey(bool isPressed, bool learningMode, int fingerIndex) {
    return 'color_${isPressed}_${learningMode}_$fingerIndex';
  }

  String _generateTransformKey(
      bool isPressed, String animationStyle, double scale) {
    return 'transform_${isPressed}_${animationStyle}_$scale';
  }

  // Cached color calculation
  Color getCachedKeyColor({
    required bool isPressed,
    required bool learningMode,
    required int fingerIndex,
    required Color keyColorPressed,
    required Color keyColorNotPressed,
    required List<Color> fingerColors,
  }) {
    final key = _generateColorKey(isPressed, learningMode, fingerIndex);

    return _colorCache.putIfAbsent(key, () {
      if (isPressed) {
        return keyColorPressed;
      } else if (learningMode &&
          fingerIndex >= 0 &&
          fingerIndex < fingerColors.length) {
        return fingerColors[fingerIndex];
      } else {
        return keyColorNotPressed;
      }
    });
  }

  // Cached transform calculation
  Matrix4 getCachedTransform({
    required bool isPressed,
    required String animationStyle,
    required double animationScale,
    required double keySize,
  }) {
    final key =
        _generateTransformKey(isPressed, animationStyle, animationScale);

    return _transformCache.putIfAbsent(key, () {
      if (!isPressed) return Matrix4.identity();

      switch (animationStyle.toLowerCase()) {
        case 'depress':
          return Matrix4.translationValues(0, 2 * animationScale, 0);
        case 'raise':
          return Matrix4.translationValues(0, -2 * animationScale, 0);
        case 'grow':
          final scaleValue = 1 + 0.05 * animationScale;
          return Matrix4.identity()
            ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
            ..translateByDouble(
              -keySize * (scaleValue - 1) / (2 * scaleValue),
              -keySize * (scaleValue - 1) / (2 * scaleValue),
              0.0, 1.0,
            );
        case 'shrink':
          final scaleValue = 1 - 0.05 * animationScale;
          return Matrix4.identity()
            ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
            ..translateByDouble(
              keySize * (1 - scaleValue) / (2 * scaleValue),
              keySize * (1 - scaleValue) / (2 * scaleValue),
              0.0, 1.0,
            );
        default:
          return Matrix4.translationValues(0, 2 * animationScale, 0);
      }
    });
  }

  // Cache invalidation
  void invalidateCache({String? reason}) {
    _colorCache.clear();
    _transformCache.clear();
    _decorationCache.clear();

    if (kDebugMode && reason != null) {
      debugPrint('🗑️ KeyRenderCache: Cache invalidated - $reason');
    }
  }

  // Theme change detection
  void checkThemeChange(String themeHash) {
    if (_lastThemeHash != themeHash) {
      invalidateCache(reason: 'Theme change');
      _lastThemeHash = themeHash;
    }
  }

  // Configuration change detection
  void checkConfigChange(String configHash) {
    if (_lastConfigHash != configHash) {
      invalidateCache(reason: 'Config change');
      _lastConfigHash = configHash;
    }
  }

  Map<String, int> getCacheStats() => {
        'colorCacheSize': _colorCache.length,
        'transformCacheSize': _transformCache.length,
        'decorationCacheSize': _decorationCache.length,
      };
}
