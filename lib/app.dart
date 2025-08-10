import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:overkeys/services/config_service.dart';
import 'package:overkeys/services/kanata_service.dart';
import 'package:overkeys/services/preferences_service.dart';
import 'package:overkeys/services/platform/keyboard_service.dart';
import 'package:overkeys/services/smart_visibility_manager.dart';
import 'package:overkeys/utils/key_code_unified.dart';
import 'package:overkeys/widgets/status_overlay.dart';
import 'package:overkeys/widgets/layer_selector.dart';
import 'models/keyboard_layouts.dart';
import 'models/user_config.dart';
import 'screens/keyboard_screen.dart';
import 'utils/hooks_unified.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TrayListener, WindowListener {
  static const double _baseWindowPadding = 40; // Base padding around content

  // AIDEV-NOTE: Cache maximum layout width to prevent recalculation on layer switches
  double? _cachedMaxLayoutWidth;
  double? _cachedMaxLeftHandWidth;
  double? _cachedMaxRightHandWidth;

  // AIDEV-NOTE: Get cached maximum layout width for consistent positioning
  double? get maxLayoutWidth => _cachedMaxLayoutWidth;
  static const Duration _fadeDuration = Duration(milliseconds: 200);
  static const Duration _overlayDuration = Duration(milliseconds: 1000);
  // Opacity constants moved to SmartVisibilityManager

  // UI state
  bool _isWindowVisible =
      false; // Start hidden - only show through SmartVisibilityManager
  bool _isLayoutInitialized = false;
  bool _isInitializing = true;
  bool _ignoreMouseEvents = true;
  // Auto-hide timer moved to SmartVisibilityManager
  Timer? _opacityDebounceTimer;
  bool autoHideBeforeForceHide = false;
  bool autoHideBeforeMove = false;

  // General settings
  bool _launchAtStartup = false;
  bool _autoHideEnabled = false;
  double _autoHideDuration = 2.0;
  // Opacity now managed by SmartVisibilityManager
  double get _opacity => _smartVisibilityManager.opacity;
  KeyboardLayout _keyboardLayout = qwerty;
  KeyboardLayout? _initialKeyboardLayout;
  KeyboardLayout? _defaultUserLayout;

  // Keyboard settings
  String _keymapStyle = 'Staggered';
  bool _showTopRow = false;
  bool _showGraveKey = false;
  double _keySize = 48;
  double _keyBorderRadius = 2;
  double _keyBorderThickness = 0;
  double _keyPadding = 3;
  double _spaceWidth = 320;
  double _splitWidth = 100;
  double _lastRowSplitWidth = 100;
  double _keyShadowBlurRadius = 0;
  double _keyShadowOffsetX = 2;
  double _keyShadowOffsetY = 2;

  // Text settings
  String _fontFamily = 'GeistMono';
  String _initialFontFamily = 'GeistMono';
  FontWeight _fontWeight = FontWeight.w600;
  double _keyFontSize = 20;
  double _spaceFontSize = 14;

  // Markers settings
  double _markerOffset = 10;
  double _markerWidth = 10;
  double _markerHeight = 2;
  double _markerBorderRadius = 10;

  // Colors settings
  Color _keyColorPressed = const Color.fromARGB(255, 30, 30, 30);
  Color _keyColorNotPressed = const Color.fromARGB(255, 119, 171, 255);
  Color _markerColor = Colors.white;
  Color _markerColorNotPressed = Colors.black;
  Color _keyTextColor = Colors.white;
  Color _keyTextColorNotPressed = Colors.black;
  Color _keyBorderColorPressed = Colors.black;
  Color _keyBorderColorNotPressed = Colors.white;

  // Animations settings
  bool _animationEnabled = false;
  String _animationStyle = 'Raise';
  double _animationDuration = 100;
  double _animationScale = 2.0;

  // HotKey settings
  bool _hotKeysEnabled = true;
  HotKey _visibilityHotKey = HotKey(
    key: PhysicalKeyboardKey.keyQ,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  final HotKey _layerSwitchingHotKey = HotKey(
    key: PhysicalKeyboardKey.keyL,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  HotKey _autoHideHotKey = HotKey(
    key: PhysicalKeyboardKey.keyW,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  HotKey _toggleMoveHotKey = HotKey(
    key: PhysicalKeyboardKey.keyE,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  HotKey _preferencesHotKey = HotKey(
    key: PhysicalKeyboardKey.keyR,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  HotKey _increaseOpacityHotKey = HotKey(
    key: PhysicalKeyboardKey.arrowUp,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  HotKey _decreaseOpacityHotKey = HotKey(
    key: PhysicalKeyboardKey.arrowDown,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
  );
  bool _enableVisibilityHotKey = true;
  bool _enableAutoHideHotKey = true;
  bool _enableToggleMoveHotKey = true;
  bool _enablePreferencesHotKey = true;
  bool _enableIncreaseOpacityHotKey = true;
  bool _enableDecreaseOpacityHotKey = true;
  final bool _enableLayerSwitchingHotKey = false;

  // Learn settings
  bool _learningModeEnabled = false;
  Color _pinkyLeftColor = const Color(0xFFED3345);
  Color _ringLeftColor = const Color(0xFFFAA71D);
  Color _middleLeftColor = const Color(0xFF70C27B);
  Color _indexLeftColor = const Color(0xFF00AFEB);
  Color _indexRightColor = const Color(0xFF5985BF);
  Color _middleRightColor = const Color(0xFF97D6F5);
  Color _ringRightColor = const Color(0xFFFFE8A0);
  Color _pinkyRightColor = const Color(0xFFBDE0BF);

  // Advanced settings
  bool _advancedSettingsEnabled = false;
  bool _useUserLayout = false;
  bool _showAltLayout = false;
  bool _initialShowAltLayout = false;
  KeyboardLayout? _altLayout;
  bool _customFontEnabled = false;
  bool _debugModeEnabled = false;
  bool _thumbDebugModeEnabled = false;
  bool _use6ColLayout = false;
  bool _kanataEnabled = false;
  bool _keyboardFollowsMouse = false;
  Timer? _mouseCheckTimer;

  // Smart visibility manager
  late SmartVisibilityManager _smartVisibilityManager;

  // Layer switching mode
  bool _layerSwitchingMode = false;

  // Services
  final PreferencesService _prefsService = PreferencesService();
  final KanataService _kanataService = KanataService();

  // Overlay
  bool _showStatusOverlay = false;
  String _overlayMessage = '';
  Icon _statusIcon = const Icon(LucideIcons.eye);
  Timer? _overlayTimer;

  // Misc
  final Map<String, bool> _keyPressStates = {};
  final Map<String, String> _physicalKeyToVisualKey =
      {}; // Track physical->visual mapping
  Map<String, String>? _customShiftMappings;
  Map<String, String>? _actionMappings;
  List<KeyboardLayout> _userLayers = [];
  UserConfig? _userConfig;

  @override
  void initState() {
    super.initState();
    // Initialize SmartVisibilityManager with default values (updated with prefs in _loadAllPreferences)
    // Auto-hide settings will be updated in _loadAllPreferences
    _smartVisibilityManager = SmartVisibilityManager(
      defaultLayerDelay: 500.0,
      customLayerDelay: 1000.0,
      quickSuccessionWindow: 200.0,
      debugEnabled: _debugModeEnabled,
      onVisibilityChange: (visible) {
        setState(() {
          _isWindowVisible = visible;
        });
        if (kDebugMode && _debugModeEnabled) {
          debugPrint(
              '🔄 Smart Visibility: Visibility state updated - $_isWindowVisible');
        }
      },
      onOpacityChange: (opacity) {
        setState(() {
          // Opacity is now managed by SmartVisibilityManager, just trigger UI rebuild
        });
        if (kDebugMode && _debugModeEnabled) {
          debugPrint('🔆 Smart Visibility: Opacity state updated - $opacity');
        }
      },
      onFadeIn: () {
        if (kDebugMode && _debugModeEnabled) {
          debugPrint(
              '🔔 Smart Visibility: SmartVisibilityManager requesting _fadeIn()');
        }
        _fadeIn();
      },
      onFadeOut: () {
        if (kDebugMode && _debugModeEnabled) {
          debugPrint(
              '🔔 Smart Visibility: SmartVisibilityManager requesting _fadeOut()');
        }
        _fadeOut();
      },
      onLayerChange: (layout) {
        // AIDEV-NOTE: Layout updates are handled by _handleSmartTransition
        // This callback is mainly for future extensibility
        if (kDebugMode && _debugModeEnabled) {
          debugPrint(
              '🔄 Smart Visibility: Layer change callback - ${layout.name}');
        }
      },
      onTimerStateChange: (hasActiveTimer) {
        // Could be used for UI indicators in the future
        if (kDebugMode && _debugModeEnabled) {
          debugPrint(
              '🔔 Smart Visibility: Timer state changed - active: $hasActiveTimer');
        }
      },
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAllPreferences();
    // AIDEV-NOTE: Load user configuration immediately to ensure correct layout is set
    await _loadConfiguration();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _setupTray();
    _setupKeyListener(); // Now called AFTER _loadConfiguration completes
    _setupHotKeys();
    _setupMethodHandler();
    _initStartup();
    _setupKanataLayerChangeHandler();
    // Window size adjustment now happens in _loadAllPreferences() before position restoration
    // Auto-hide now handled by SmartVisibilityManager
    Future.delayed(const Duration(milliseconds: 100), () async {
      await _restoreWindowPosition();
      await _adjustWindowSize();

      // Show keyboard layout as initialized and sync with SmartVisibilityManager state
      setState(() {
        _isLayoutInitialized = true;
        _isWindowVisible = _smartVisibilityManager
            .isVisible; // Sync with SmartVisibilityManager
        // Opacity is now managed by SmartVisibilityManager
      });

      if (kDebugMode && _debugModeEnabled) {
        debugPrint(
            '🔄 UI: Startup sync - UI state synced with SmartVisibilityManager (visible: $_isWindowVisible, opacity: $_opacity)');
      }

      setState(() {
        _isInitializing = false; // Mark initialization as complete
        // Don't set _isWindowVisible = true; - let SmartVisibilityManager control it
      });
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    unhook();
    // Auto-hide timer moved to SmartVisibilityManager
    _overlayTimer?.cancel();
    _mouseCheckTimer?.cancel();
    _smartVisibilityManager.dispose();
    _kanataService.dispose();
    _keyboardService?.dispose();
    // No process to kill anymore
    _saveAllPreferences();
    super.dispose();
  }

  void _startMouseTracking() {
    _mouseCheckTimer?.cancel();
    if (_keyboardFollowsMouse && _advancedSettingsEnabled) {
      // AIDEV-NOTE: Mouse tracking should follow cursor, not force bottom center
      // TODO: Implement actual cursor following logic
    }
  }

  void _stopMouseTracking() {
    _mouseCheckTimer?.cancel();
  }

  Future<void> _loadAllPreferences() async {
    final prefs = await _prefsService.loadAllPreferences();

    setState(() {
      // General settings
      _launchAtStartup = prefs['launchAtStartup'];
      _autoHideEnabled = prefs['autoHideEnabled'];
      _autoHideDuration = prefs['autoHideDuration'];

      // Initialize SmartVisibilityManager with preferences
      _smartVisibilityManager.setOpacity(prefs['opacity']);
      _smartVisibilityManager.updateAutoHideSettings(
        enabled: _autoHideEnabled,
        duration: _autoHideDuration,
      );
      _keyboardLayout = availableLayouts
          .firstWhere((layout) => layout.name == prefs['keyboardLayoutName']);
      _initialKeyboardLayout = _keyboardLayout;

      // Keyboard settings
      _keymapStyle = prefs['keymapStyle'];
      _showTopRow = prefs['showTopRow'];
      _showGraveKey = prefs['showGraveKey'];
      _keySize = prefs['keySize'];
      _keyBorderRadius = prefs['keyBorderRadius'];
      _keyBorderThickness = prefs['keyBorderThickness'];
      _keyPadding = prefs['keyPadding'];
      _spaceWidth = prefs['spaceWidth'];
      _splitWidth = prefs['splitWidth'];
      _lastRowSplitWidth = prefs['lastRowSplitWidth'];
      _keyShadowBlurRadius = prefs['keyShadowBlurRadius'];
      _keyShadowOffsetX = prefs['keyShadowOffsetX'];
      _keyShadowOffsetY = prefs['keyShadowOffsetY'];

      // Text settings
      _fontFamily = prefs['fontFamily'];
      _fontWeight = prefs['fontWeight'];
      _keyFontSize = prefs['keyFontSize'];
      _spaceFontSize = prefs['spaceFontSize'];

      // Markers settings
      _markerOffset = prefs['markerOffset'];
      _markerWidth = prefs['markerWidth'];
      _markerHeight = prefs['markerHeight'];
      _markerBorderRadius = prefs['markerBorderRadius'];

      // Colors settings
      _keyColorPressed = prefs['keyColorPressed'];
      _keyColorNotPressed = prefs['keyColorNotPressed'];
      _markerColor = prefs['markerColor'];
      _markerColorNotPressed = prefs['markerColorNotPressed'];
      _keyTextColor = prefs['keyTextColor'];
      _keyTextColorNotPressed = prefs['keyTextColorNotPressed'];
      _keyBorderColorPressed = prefs['keyBorderColorPressed'];
      _keyBorderColorNotPressed = prefs['keyBorderColorNotPressed'];

      // Animations settings
      _animationEnabled = prefs['animationEnabled'];
      _animationStyle = prefs['animationStyle'];
      _animationDuration = prefs['animationDuration'];
      _animationScale = prefs['animationScale'];

      // HotKey settings
      _hotKeysEnabled = prefs['hotKeysEnabled'];
      _visibilityHotKey = prefs['visibilityHotKey'];
      _autoHideHotKey = prefs['autoHideHotKey'];
      _toggleMoveHotKey = prefs['toggleMoveHotKey'];
      _preferencesHotKey = prefs['preferencesHotKey'];
      _increaseOpacityHotKey = prefs['increaseOpacityHotKey'];
      _decreaseOpacityHotKey = prefs['decreaseOpacityHotKey'];
      _enableVisibilityHotKey = prefs['enableVisibilityHotKey'] ?? true;
      _enableAutoHideHotKey = prefs['enableAutoHideHotKey'] ?? true;
      _enableToggleMoveHotKey = prefs['enableToggleMoveHotKey'] ?? true;
      _enablePreferencesHotKey = prefs['enablePreferencesHotKey'] ?? true;
      _enableIncreaseOpacityHotKey =
          prefs['enableIncreaseOpacityHotKey'] ?? true;
      _enableDecreaseOpacityHotKey =
          prefs['enableDecreaseOpacityHotKey'] ?? true;

      // Learn settings
      _learningModeEnabled = prefs['learningModeEnabled'];
      _pinkyLeftColor = prefs['pinkyLeftColor'];
      _ringLeftColor = prefs['ringLeftColor'];
      _middleLeftColor = prefs['middleLeftColor'];
      _indexLeftColor = prefs['indexLeftColor'];
      _indexRightColor = prefs['indexRightColor'];
      _middleRightColor = prefs['middleRightColor'];
      _ringRightColor = prefs['ringRightColor'];
      _pinkyRightColor = prefs['pinkyRightColor'];

      // Advanced settings
      _advancedSettingsEnabled = prefs['advancedSettingsEnabled'];
      _useUserLayout = prefs['useUserLayout'];
      _showAltLayout = prefs['showAltLayout'];
      _customFontEnabled = prefs['customFontEnabled'];
      _debugModeEnabled = prefs['debugModeEnabled'];
      _thumbDebugModeEnabled = prefs['thumbDebugModeEnabled'];
      _use6ColLayout = prefs['use6ColLayout'];
      _kanataEnabled = prefs['kanataEnabled'];
      _layerSwitchingMode = prefs['layerSwitchingMode'] ?? false;
      _keyboardFollowsMouse = prefs['keyboardFollowsMouse'];

      // Update SmartVisibilityManager with loaded preferences
      if (kDebugMode && _debugModeEnabled) {
        debugPrint(
            '🔄 Smart Visibility: Loading preferences - default: ${prefs['defaultUserLayoutShowDelay'] ?? 500.0}ms, custom: ${prefs['customLayerDelay'] ?? 1000.0}ms, quick: ${prefs['quickSuccessionWindow'] ?? 200.0}ms');
      }
      _smartVisibilityManager.updateConfiguration(
        defaultLayerDelay: prefs['defaultUserLayoutShowDelay'] ?? 500.0,
        customLayerDelay: prefs['customLayerDelay'] ?? 1000.0,
        quickSuccessionWindow: prefs['quickSuccessionWindow'] ?? 200.0,
        debugEnabled: _debugModeEnabled,
      );

      // AIDEV-NOTE: Configuration updated above, no need to recreate manager
    });

    // AIDEV-NOTE: Window sizing and positioning will happen after initialization completes
  }

  // AIDEV-NOTE: Restores window position with validation for resolution changes
  Future<void> _restoreWindowPosition() async {
    // Load all preferences to get the window position
    final prefs = await _prefsService.loadAllPreferences();
    final savedPosition = prefs['windowPosition'] as Offset?;

    if (savedPosition != null) {
      // Validate position is still on screen (handle resolution changes)
      if (await _isPositionValid(savedPosition)) {
        await _setProgrammaticPosition(savedPosition);
      } else {
        // Position is off-screen, use default and save the new position
        await _setProgrammaticAlignment(Alignment.bottomCenter);
        final newPosition = await windowManager.getPosition();
        await _prefsService.setWindowPosition(newPosition);
      }
    } else {
      // Use default position (bottomCenter) for first launch
      await _setProgrammaticAlignment(Alignment.bottomCenter);
    }
  }

  // AIDEV-NOTE: Validates position using actual screen dimensions from native APIs
  Future<bool> _isPositionValid(Offset position) async {
    try {
      Size screenBounds;

      // AIDEV-NOTE: Get real screen dimensions from native API
      if (Platform.isMacOS && _keyboardService != null) {
        try {
          // Access the method channel directly through the service
          screenBounds =
              await (_keyboardService as dynamic).getScreenDimensions();
        } catch (e) {
          screenBounds = const Size(1920, 1080);
        }
      } else {
        // Fallback for other platforms or if service unavailable
        screenBounds = const Size(1920, 1080);
      }

      final windowSize = await windowManager.getSize();

      // AIDEV-NOTE: Allow window overflow as long as at least one edge is visible
      // This means we can position windows partially off-screen for better UX
      const minVisibleEdge = 20.0; // Minimum pixels that must remain visible

      // Check if at least some part of the window would be visible on screen
      final hasHorizontalOverlap = position.dx < screenBounds.width &&
          position.dx + windowSize.width > 0;
      final hasVerticalOverlap = position.dy < screenBounds.height &&
          position.dy + windowSize.height > 0;

      // Ensure at least minVisibleEdge pixels are visible on each axis
      final hasMinVisibleHorizontal =
          position.dx + minVisibleEdge < screenBounds.width &&
              position.dx + windowSize.width - minVisibleEdge > 0;
      final hasMinVisibleVertical =
          position.dy + minVisibleEdge < screenBounds.height &&
              position.dy + windowSize.height - minVisibleEdge > 0;

      return hasHorizontalOverlap &&
          hasVerticalOverlap &&
          hasMinVisibleHorizontal &&
          hasMinVisibleVertical;
    } catch (e) {
      // If validation fails, assume position is valid for safety
      return true;
    }
  }

  Future<void> _saveAllPreferences() async {
    // AIDEV-NOTE: Get current window position before saving preferences
    final currentPosition = await windowManager.getPosition();

    final prefs = {
      // General settings
      'launchAtStartup': _launchAtStartup,
      'autoHideEnabled': _autoHideEnabled,
      'autoHideDuration': _autoHideDuration,
      'opacity': _opacity,
      'keyboardLayoutName': _initialKeyboardLayout!.name,
      'windowPosition': currentPosition,

      // Keyboard settings
      'keymapStyle': _keymapStyle,
      'showTopRow': _showTopRow,
      'showGraveKey': _showGraveKey,
      'keySize': _keySize,
      'keyBorderRadius': _keyBorderRadius,
      'keyBorderThickness': _keyBorderThickness,
      'keyPadding': _keyPadding,
      'spaceWidth': _spaceWidth,
      'splitWidth': _splitWidth,
      'lastRowSplitWidth': _lastRowSplitWidth,
      'keyShadowBlurRadius': _keyShadowBlurRadius,
      'keyShadowOffsetX': _keyShadowOffsetX,
      'keyShadowOffsetY': _keyShadowOffsetY,

      // Text settings
      'fontFamily': _fontFamily,
      'fontWeight': _fontWeight,
      'keyFontSize': _keyFontSize,
      'spaceFontSize': _spaceFontSize,

      // Markers settings
      'markerOffset': _markerOffset,
      'markerWidth': _markerWidth,
      'markerHeight': _markerHeight,
      'markerBorderRadius': _markerBorderRadius,

      // Colors settings
      'keyColorPressed': _keyColorPressed,
      'keyColorNotPressed': _keyColorNotPressed,
      'markerColor': _markerColor,
      'markerColorNotPressed': _markerColorNotPressed,
      'keyTextColor': _keyTextColor,
      'keyTextColorNotPressed': _keyTextColorNotPressed,
      'keyBorderColorPressed': _keyBorderColorPressed,
      'keyBorderColorNotPressed': _keyBorderColorNotPressed,

      // Animations settings
      'animationEnabled': _animationEnabled,
      'animationStyle': _animationStyle,
      'animationDuration': _animationDuration,
      'animationScale': _animationScale,

      // HotKey settings
      'hotKeysEnabled': _hotKeysEnabled,
      'visibilityHotKey': _visibilityHotKey,
      'autoHideHotKey': _autoHideHotKey,
      'toggleMoveHotKey': _toggleMoveHotKey,
      'preferencesHotKey': _preferencesHotKey,
      'increaseOpacityHotKey': _increaseOpacityHotKey,
      'decreaseOpacityHotKey': _decreaseOpacityHotKey,
      'enableVisibilityHotKey': _enableVisibilityHotKey,
      'enableAutoHideHotKey': _enableAutoHideHotKey,
      'enableToggleMoveHotKey': _enableToggleMoveHotKey,
      'enablePreferencesHotKey': _enablePreferencesHotKey,
      'enableIncreaseOpacityHotKey': _enableIncreaseOpacityHotKey,
      'enableDecreaseOpacityHotKey': _enableDecreaseOpacityHotKey,

      // Learn settings
      'learningModeEnabled': _learningModeEnabled,
      'pinkyLeftColor': _pinkyLeftColor,
      'ringLeftColor': _ringLeftColor,
      'middleLeftColor': _middleLeftColor,
      'indexLeftColor': _indexLeftColor,
      'indexRightColor': _indexRightColor,
      'middleRightColor': _middleRightColor,
      'ringRightColor': _ringRightColor,
      'pinkyRightColor': _pinkyRightColor,

      // Advanced settings
      'advancedSettingsEnabled': _advancedSettingsEnabled,
      'useUserLayout': _useUserLayout,
      'showAltLayout': _showAltLayout,
      'customFontEnabled': _customFontEnabled,
      'use6ColLayout': _use6ColLayout,
      'kanataEnabled': _kanataEnabled,
      'layerSwitchingMode': _layerSwitchingMode,
      'keyboardFollowsMouse': _keyboardFollowsMouse,
    };

    await _prefsService.saveAllPreferences(prefs);
  }

  Future<void> _loadConfiguration() async {
    await _loadCustomShiftMappings();
    if (_advancedSettingsEnabled) {
      if (_useUserLayout) {
        await _loadUserLayout();
        await _loadUserLayers();
      }
      if (_showAltLayout) {
        await _loadAltLayout();
      }
      if (_customFontEnabled) {
        await _loadCustomFont();
      }
      if (_kanataEnabled) {
        await _useKanata();
      }
      if (_keyboardFollowsMouse) {
        _startMouseTracking();
      }
    }
  }

  Future<void> _loadCustomShiftMappings() async {
    final configService = ConfigService();
    final shiftMappings = await configService.getCustomShiftMappings();
    final actionMappings = await configService.getActionMappings();
    final config = await configService.getConfig();
    setState(() {
      _customShiftMappings = shiftMappings;
      _actionMappings = actionMappings;
      _userConfig = config;
    });
  }

  void _setupKanataLayerChangeHandler() {
    _kanataService.onLayerChange = (newLayout, isDefaultUserLayout) {
      setState(() {
        _keyboardLayout = newLayout;
        _updateAutoHideBasedOnLayer(isDefaultUserLayout);
      });
      _adjustWindowSize(); // Adjust window for new layout
      // Don't show directly - let SmartVisibilityManager control visibility
      // _fadeIn(); // REMOVED - bypass eliminated
    };
  }

  void _updateAutoHideBasedOnLayer(bool isDefaultUserLayout) {
    if (!isDefaultUserLayout && _autoHideEnabled) {
      _autoHideEnabled = false;
      _smartVisibilityManager.updateAutoHideSettings(enabled: false);
      autoHideBeforeMove = true;
    } else if (isDefaultUserLayout && autoHideBeforeMove) {
      _autoHideEnabled = true;
      _smartVisibilityManager.updateAutoHideSettings(
        enabled: true,
        duration: _autoHideDuration,
      );
      autoHideBeforeMove = false;
    }
  }

  Future<void> _useKanata() async {
    if (_kanataEnabled && _advancedSettingsEnabled) {
      _kanataService.connect();
    }
  }

  Future<void> _loadUserLayout() async {
    if (!_useUserLayout) {
      return;
    }

    final configService = ConfigService();
    final userLayout = await configService.getUserLayout();

    if (userLayout != null) {
      setState(() {
        _defaultUserLayout = userLayout;
        if (!_kanataEnabled) {
          _keyboardLayout = userLayout;
        }
        _isLayoutInitialized = true; // Mark layout as ready for rendering
      });

      // Update SmartVisibilityManager with default layout info
      _smartVisibilityManager.setDefaultLayer(userLayout.name);

      // Register this layout with SmartVisibilityManager
      _smartVisibilityManager.registerLayer(userLayout.name, userLayout);

      // Also register all available standard layouts
      for (final layout in availableLayouts) {
        _smartVisibilityManager.registerLayer(layout.name, layout);
      }

      // AIDEV-NOTE: Don't adjust window size here - wait for all layers to load first
      // Don't show window during initialization - let SmartVisibilityManager control visibility
    }
  }

  Future<void> _loadUserLayers() async {
    if (!_useUserLayout) return;

    final configService = ConfigService();
    final layers = await configService.getUserLayers() ?? [];

    setState(() {
      _userLayers = layers;
      // AIDEV-NOTE: Invalidate cached widths when user layers change
      _cachedMaxLayoutWidth = null;
      _cachedMaxLeftHandWidth = null;
      _cachedMaxRightHandWidth = null;
    });

    // Register all user layers with SmartVisibilityManager
    for (final layer in layers) {
      _smartVisibilityManager.registerLayer(layer.name, layer);
      if (kDebugMode && _debugModeEnabled) {
        debugPrint(
            '🔧 Smart Visibility: Registered user layer "${layer.name}"');
      }
    }

    // AIDEV-NOTE: Now that all layers are loaded, calculate final window size
    _adjustWindowSize();
  }

  Future<void> _loadAltLayout() async {
    if (!_showAltLayout) return;
    final configService = ConfigService();
    final altLayout = await configService.getAltLayout();

    if (altLayout != null) {
      setState(() {
        _altLayout = altLayout;
      });
    }
  }

  Future<void> _loadCustomFont() async {
    if (!_customFontEnabled || !_advancedSettingsEnabled) return;

    final configService = ConfigService();
    final customFont = await configService.getCustomFont();

    if (customFont != null) {
      setState(() {
        _fontFamily = customFont;
      });
    }
  }

  Future<void> _initStartup() async {
    if (Platform.isWindows) {
      _launchAtStartup = await launchAtStartup.isEnabled();
    } else {
      _launchAtStartup = false; // Not supported on macOS yet
    }
    setState(() {});
  }

  Future<void> _handleStartupToggle(bool enable) async {
    if (Platform.isWindows) {
      if (enable) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    }
    await _initStartup();
  }

  KeyboardLayout _getCurrentLayout() {
    return _keyboardLayout;
  }

  double _calculateRequiredHeight() {
    KeyboardLayout currentLayout = _getCurrentLayout();

    // Use actual preference values for accurate calculation
    double keySize = _keySize;
    double keyPadding = _keyPadding;

    // Calculate main keyboard rows height
    int visibleRows =
        _showTopRow ? currentLayout.keys.length : currentLayout.keys.length - 1;
    double mainRowsHeight = visibleRows * (keySize + keyPadding * 2) +
        (visibleRows - 1) * keyPadding;

    // Calculate thumb cluster height if present
    double thumbClusterHeight = 0;
    if (currentLayout.thumbCluster != null) {
      // Find maximum rows in left or right thumb cluster
      int maxThumbRows = math.max(currentLayout.thumbCluster!.leftKeys.length,
          currentLayout.thumbCluster!.rightKeys.length);
      thumbClusterHeight = maxThumbRows * (keySize + keyPadding * 2) +
          (maxThumbRows - 1) * keyPadding +
          keyPadding * 2; // Extra spacing between main and thumb
    }

    double totalHeight =
        mainRowsHeight + thumbClusterHeight + _baseWindowPadding * 2;

    return totalHeight;
  }

  // AIDEV-NOTE: Helper method to get maximum keys for a layout side (left=true, right=false)
  // Considers both main rows AND thumb clusters to find the true maximum width
  int _getMaxKeysForLayout(KeyboardLayout layout, bool isLeftSide) {
    int maxMainKeys = 0;
    int maxThumbKeys = 0;

    if (isLeftSide && layout.leftHand != null) {
      // Check main hand rows
      for (var row in layout.leftHand!.rows) {
        int nonNullKeys = row.where((key) => key != null).length;
        if (nonNullKeys > maxMainKeys) maxMainKeys = nonNullKeys;
      }
      // Check thumb cluster rows separately
      if (layout.thumbCluster != null) {
        for (var row in layout.thumbCluster!.leftKeys) {
          int nonNullKeys = row.where((key) => key != null).length;
          if (nonNullKeys > maxThumbKeys) maxThumbKeys = nonNullKeys;
        }
      }
    } else if (!isLeftSide && layout.rightHand != null) {
      // Check main hand rows
      for (var row in layout.rightHand!.rows) {
        int nonNullKeys = row.where((key) => key != null).length;
        if (nonNullKeys > maxMainKeys) maxMainKeys = nonNullKeys;
      }
      // Check thumb cluster rows separately
      if (layout.thumbCluster != null) {
        for (var row in layout.thumbCluster!.rightKeys) {
          int nonNullKeys = row.where((key) => key != null).length;
          if (nonNullKeys > maxThumbKeys) maxThumbKeys = nonNullKeys;
        }
      }
    }

    // AIDEV-NOTE: Return the maximum of main keys or thumb keys to ensure proper width
    return math.max(maxMainKeys, maxThumbKeys);
  }

  double _calculateRequiredWidth() {
    KeyboardLayout currentLayout = _getCurrentLayout();
    double keySize = _keySize;
    double keyPadding = _keyPadding;

    // For split matrix layouts, calculate based on left+right hand + gap
    if (currentLayout.leftHand != null && currentLayout.rightHand != null) {
      // AIDEV-NOTE: Use cached maximum width to prevent window jumping on layer switches
      if (_cachedMaxLayoutWidth == null) {
        double maxTotalLayoutWidth = 0.0;

        // Create list of all layouts to check (all user layers only)
        List<KeyboardLayout> allLayouts = _userLayers
            .where((layer) => layer.leftHand != null && layer.rightHand != null)
            .toList();

        // Calculate required width for each layout and find maximum
        double maxLeftHandWidth = 0.0;
        double maxRightHandWidth = 0.0;

        for (final layout in allLayouts) {
          double layoutWidth =
              _calculateSplitLayoutWidth(layout, keySize, keyPadding);
          if (layoutWidth > maxTotalLayoutWidth) {
            maxTotalLayoutWidth = layoutWidth;
          }

          // Calculate individual hand widths for consistent positioning
          int maxLeftKeys = _getMaxKeysForLayout(layout, true);
          int maxRightKeys = _getMaxKeysForLayout(layout, false);

          double leftWidth = maxLeftKeys * (keySize + keyPadding * 2) +
              (maxLeftKeys - 1) * keyPadding;
          double rightWidth = maxRightKeys * (keySize + keyPadding * 2) +
              (maxRightKeys - 1) * keyPadding;

          if (leftWidth > maxLeftHandWidth) maxLeftHandWidth = leftWidth;
          if (rightWidth > maxRightHandWidth) maxRightHandWidth = rightWidth;
        }

        _cachedMaxLayoutWidth = maxTotalLayoutWidth;
        _cachedMaxLeftHandWidth = maxLeftHandWidth;
        _cachedMaxRightHandWidth = maxRightHandWidth;
      }

      // Add fixed elements that don't vary per layout
      double debugModeWidth = _debugModeEnabled ? 76.0 : 0.0;
      double layerSwitchingWidth = 320.0;
      double finalWidth = _cachedMaxLayoutWidth! +
          _baseWindowPadding * 2 +
          20 +
          debugModeWidth +
          layerSwitchingWidth;

      return finalWidth;
    } else {
      // For regular layouts, find the longest row
      int maxKeys = 0;
      int startRow = _showTopRow ? 0 : 1;

      for (int i = startRow; i < currentLayout.keys.length; i++) {
        if (currentLayout.keys[i].length > maxKeys) {
          maxKeys = currentLayout.keys[i].length;
        }
      }

      // Account for space bar width if present
      double totalWidth =
          maxKeys * (keySize + keyPadding * 2) + (maxKeys - 1) * keyPadding;

      // Check if any row has space key and adjust
      for (int i = startRow; i < currentLayout.keys.length; i++) {
        for (String? key in currentLayout.keys[i]) {
          if (key == " ") {
            // Space key is wider
            totalWidth += _spaceWidth - keySize;
            break;
          }
        }
      }

      double finalWidth = totalWidth + _baseWindowPadding * 2 + 20;

      return finalWidth;
    }
  }

  // AIDEV-NOTE: Calculate exact width for a specific split layout including both main and thumb areas
  double _calculateSplitLayoutWidth(
      KeyboardLayout layout, double keySize, double keyPadding) {
    int maxLeftKeys = _getMaxKeysForLayout(layout, true);
    int maxRightKeys = _getMaxKeysForLayout(layout, false);

    double leftWidth = maxLeftKeys * (keySize + keyPadding * 2) +
        (maxLeftKeys - 1) * keyPadding;
    double rightWidth = maxRightKeys * (keySize + keyPadding * 2) +
        (maxRightKeys - 1) * keyPadding;
    double gap = _splitWidth;

    double totalLayoutWidth = leftWidth + gap + rightWidth;

    return totalLayoutWidth;
  }

  Future<void> _adjustWindowSize() async {
    // Don't show window during size adjustment - let SmartVisibilityManager control visibility

    // Calculate precise dimensions based on layout content
    double height = _calculateRequiredHeight();
    double width = _calculateRequiredWidth();

    // AIDEV-NOTE: setSize may move window, so preserve position
    final positionBefore = await windowManager.getPosition();
    await windowManager.setSize(Size(width, height));

    // AIDEV-NOTE: Restore position if setSize moved it
    final positionAfter = await windowManager.getPosition();
    if (positionBefore != positionAfter) {
      await _setProgrammaticPosition(positionBefore);
    }

    // AIDEV-NOTE: Don't reset position here - it's handled in _restoreWindowPosition()
  }

  void _fadeOut() {
    if (kDebugMode && _debugModeEnabled) {
      debugPrint(
          '👁️ UI: _fadeOut() called - opacity will be managed by SmartVisibilityManager');
    }
    setState(() {
      // AIDEV-NOTE: Exit moving mode when keyboard gets hidden
      if (!_ignoreMouseEvents) {
        _ignoreMouseEvents = true;
        windowManager.setIgnoreMouseEvents(_ignoreMouseEvents);
      }
    });
  }

  /// Simple UI fade in - state managed by SmartVisibilityManager callbacks
  void _fadeIn() {
    if (kDebugMode && _debugModeEnabled) {
      debugPrint(
          '🛠️ UI: _fadeIn() called - state managed by SmartVisibilityManager');
    }
    // Auto-hide now handled by SmartVisibilityManager
  }

  /// AIDEV-NOTE: Handle transitions controlled entirely by SmartVisibilityManager
  void _handleSmartTransition(LayerTransition transition, String? triggerKey) {
    // For toggle OFF transitions with fadeout, delay layout update to prevent visual glitch
    // For toggle OFF without fadeout, update immediately
    if (transition.type != LayerTransitionType.turnOff ||
        !transition.shouldFadeOut) {
      setState(() {
        // Update layout immediately for non-turnOff transitions or turnOff without fadeout
        if (transition.layout != null) {
          _keyboardLayout = transition.layout!;
          if (kDebugMode && _debugModeEnabled) {
            debugPrint(
                '🔄 UI: Layout updated to ${transition.layout!.name} immediately');
          }
        }
      });
    }

    // Let SmartVisibilityManager handle all visibility decisions with proper delays
    if (transition.shouldStartTimer) {
      if (kDebugMode && _debugModeEnabled) {
        debugPrint(
            '🔔 Smart Visibility: Starting smart timer for ${transition.targetLayerName}');
      }
      _smartVisibilityManager.showWithDelay(
        transition.targetLayerName,
        pressedKey: triggerKey,
      );
    } else if (transition.shouldFadeOut) {
      if (kDebugMode && _debugModeEnabled) {
        debugPrint('🔔 Smart Visibility: SmartVisibilityManager hiding window');
      }
      _smartVisibilityManager.hide();

      // For toggle OFF transitions, update layout after fadeout starts
      if (transition.type == LayerTransitionType.turnOff) {
        Future.delayed(_fadeDuration, () {
          setState(() {
            if (transition.layout != null) {
              _keyboardLayout = transition.layout!;
              if (kDebugMode && _debugModeEnabled) {
                debugPrint(
                    '🔄 UI: Layout updated to ${transition.layout!.name} after fadeout');
              }
            }
          });
        });
      }
    }

    // Adjust window size for new layout
    if (transition.layout != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _adjustWindowSize();
      });
    }
  }

  KeyboardService? _keyboardService;

  void _setupKeyListener() {
    if (Platform.isMacOS) {
      _setupMacOSKeyboardMonitoring();
    } else {
      // Fallback to isolate approach for other platforms
      final receivePort = ReceivePort();
      Isolate.spawn(setHook, receivePort.sendPort)
          .then((_) {})
          .catchError((error) {
        if (kDebugMode) {
          debugPrint('Error spawning Isolate: $error');
        }
      });
      receivePort.listen(_handleKeyEvent);
    }
  }

  void _setupMacOSKeyboardMonitoring() async {
    _keyboardService = KeyboardService.create();

    // Check permissions first
    final hasPermissions = await _keyboardService!.checkPermissions();
    if (!hasPermissions) {
      debugPrint(
          "ERROR: macOS keyboard monitoring requires both Accessibility and Input Monitoring permissions.");
      debugPrint(
          "Please enable them in System Preferences > Security & Privacy > Privacy");
      debugPrint(
          "1. Go to System Preferences > Security & Privacy > Privacy > Accessibility");
      debugPrint("2. Add your IDE (IntelliJ/VS Code/Terminal) and enable it");
      debugPrint("3. Also add to Input Monitoring if on macOS 10.15+");
      debugPrint("4. Restart the app after granting permissions");
      return; // Don't crash, just return
    }

    // Extract trigger keys from config and send to native layer
    final triggerKeys = <String>[];

    for (final layout in _userLayers) {
      final trigger = layout.trigger;
      if (trigger != null && trigger.isNotEmpty) {
        triggerKeys.add(trigger);
      }
    }

    await _keyboardService!.updateTriggerKeys(triggerKeys);

    // Start monitoring using the platform channel
    await _keyboardService!.startMonitoring((List<dynamic> message) {
      final shouldConsumeEvent = _handleKeyEvent(message);
      return shouldConsumeEvent;
    });
  }

  bool _handleKeyEvent(dynamic message) {
    if (message is! List) {
      if (kDebugMode && _debugModeEnabled) {
        debugPrint('🔑 Key Event: Invalid message format, returning false');
      }
      return false;
    }

    // Handle session unlock
    if (message[0] is String && message[0] == 'session_unlock') {
      setState(() => _keyPressStates.clear());
      return false;
    }

    String key;
    bool isPressed;
    bool isShiftDown = false;
    bool isCtrlDown = false;
    bool isAltDown = false;
    bool isCmdDown = false;

    // Parse message format (macOS string or Windows int)
    if (message[0] is String) {
      final keyName = message[0] as String;
      isPressed = message[1] as bool;

      // Handle modifier parsing
      if (message[2] is bool) {
        isShiftDown = message[2] as bool;
      } else if (message[2] is Map) {
        final modifiers = Map<String, dynamic>.from(message[2] as Map);
        isShiftDown = modifiers['shift'] ?? false;
        isCtrlDown = modifiers['ctrl'] ?? false;
        isAltDown = modifiers['alt'] ?? false;
        isCmdDown = modifiers['cmd'] ?? false;
      }

      key = getKeyFromStringKeyShift(keyName, isShiftDown);
    } else if (message[0] is int) {
      final keyCode = message[0] as int;
      isPressed = message[1] as bool;
      isShiftDown = message[2] as bool;
      key = getKeyFromKeyCodeShift(keyCode, isShiftDown);
    } else {
      return false;
    }

    // Update visual key state
    setState(() {
      if (message[0] is String) {
        final keyName = message[0] as String;
        if (isPressed) {
          _physicalKeyToVisualKey[keyName] = key;
          _keyPressStates[key] = true;
        } else {
          final pressedVisualKey = _physicalKeyToVisualKey[keyName];
          if (pressedVisualKey != null) {
            _keyPressStates[pressedVisualKey] = false;
            _physicalKeyToVisualKey.remove(keyName);
          }
        }
      } else {
        _keyPressStates[key] = isPressed;
      }
    });

    // Handle reverse action mapping
    _handleReverseActionMapping(
        key, isPressed, isShiftDown, isCtrlDown, isAltDown, isCmdDown);

    // Early return when force hidden and not user layout enabled
    // But allow layer switching even when force hidden
    if (_smartVisibilityManager.isForceHidden &&
        (!_useUserLayout || !_advancedSettingsEnabled)) {
      // Auto-hide now handled by SmartVisibilityManager
      return false;
    }

    // AIDEV-NOTE: Use unified SmartVisibilityManager key handling
    final result = _smartVisibilityManager.handleKeyEvent(
      key: key,
      isPressed: isPressed,
      triggers: _getTriggers(),
      useUserLayouts: _useUserLayout,
      advancedSettingsEnabled: _advancedSettingsEnabled,
      hasDefaultLayout: _defaultUserLayout != null,
      isWindowVisible: _isWindowVisible,
      onShow:
          () {}, // No longer used - SmartVisibilityManager handles all showing internally
      defaultLayerName: _defaultUserLayout?.name,
    );

    // Handle layer transition if provided
    if (result.transition != null) {
      _handleSmartTransition(result.transition!, key);
    }

    // Notify SmartVisibilityManager of key activity (handles auto-hide internally)
    if (isPressed) {
      _smartVisibilityManager.onKeyActivity();
    }

    return result.shouldConsume;
  }

  // Auto-hide logic moved to SmartVisibilityManager

  // AIDEV-NOTE: Get triggers map for SmartVisibilityManager
  Map<String, String> _getTriggers() {
    final triggers = <String, String>{};
    for (final layout in _userLayers) {
      if (layout.trigger != null && layout.trigger!.isNotEmpty) {
        final key = layout.type == 'held' ? '${layout.name}_held' : layout.name;
        triggers[key] = layout.trigger!;
      }
    }
    return triggers;
  }

  void _toggleAutoHide(bool enable) {
    _smartVisibilityManager.toggleAutoHideWithOverlay(
      enable,
      showOverlay: _showOverlay,
      savePreferences: _saveAllPreferences,
      setupTray: _setupTray,
    );

    // Handle multi-window notification
    DesktopMultiWindow.getAllSubWindowIds().then((windowIds) {
      for (final id in windowIds) {
        DesktopMultiWindow.invokeMethod(
            id, 'updateAutoHideFromMainWindow', enable);
      }
    });
  }

  void _adjustOpacity(bool increase) {
    if (_smartVisibilityManager.isForceHidden) return;

    // Use SmartVisibilityManager for opacity adjustment
    final oldOpacity = _smartVisibilityManager.opacity;
    _smartVisibilityManager.adjustOpacity(increase);
    final newOpacity = _smartVisibilityManager.opacity;

    if (newOpacity != oldOpacity) {
      _showOverlay(
          'Opacity: ${(newOpacity * 100).round()}%',
          increase
              ? const Icon(LucideIcons.plusCircle)
              : const Icon(LucideIcons.minusCircle));

      _opacityDebounceTimer?.cancel();
      _opacityDebounceTimer = Timer(const Duration(milliseconds: 125), () {
        _saveAllPreferences();
        DesktopMultiWindow.getAllSubWindowIds().then((windowIds) {
          for (final id in windowIds) {
            DesktopMultiWindow.invokeMethod(
                id, 'updateOpacity', {'opacity': newOpacity});
          }
        });
      });
    }
  }

  void _showOverlay(String message, Icon icon) {
    setState(() {
      _overlayMessage = message;
      _statusIcon = icon;
      _showStatusOverlay = true;
    });
    _overlayTimer?.cancel();
    _overlayTimer = Timer(_overlayDuration, () {
      setState(() => _showStatusOverlay = false);
    });
  }

  // AIDEV-NOTE: Layer switching functionality for mouse-based layer selection
  List<KeyboardLayout> _getAvailableLayers() {
    List<KeyboardLayout> layers = [];

    // AIDEV-NOTE: Add user custom layouts first to prioritize them in dropdown
    if (_userLayers.isNotEmpty) {
      layers.addAll(_userLayers);
    }

    // Add base layouts for layer switching, avoiding duplicates by name
    for (final baseLayout in availableLayouts) {
      if (!layers.any((layer) => layer.name == baseLayout.name)) {
        layers.add(baseLayout);
      }
    }

    return layers;
  }

  void _switchToLayer(KeyboardLayout newLayer) {
    setState(() {
      _keyboardLayout = newLayer;
    });

    // Show status overlay to indicate layer switch
    _showOverlay('Switched to ${newLayer.name}',
        const Icon(LucideIcons.layers, color: Colors.white));

    // Adjust window size for new layout
    _adjustWindowSize();
  }

  void _toggleLayerSwitchingMode() {
    setState(() {
      _layerSwitchingMode = !_layerSwitchingMode;
      // AIDEV-NOTE: Enable mouse events when layer switching mode is active for dropdown interaction
      if (_layerSwitchingMode && _ignoreMouseEvents) {
        _ignoreMouseEvents = false;
        windowManager.setIgnoreMouseEvents(_ignoreMouseEvents);
      }
    });

    final message = _layerSwitchingMode
        ? 'Layer switching enabled'
        : 'Layer switching disabled';
    final icon = _layerSwitchingMode
        ? const Icon(LucideIcons.layers, color: Colors.white)
        : const Icon(LucideIcons.keyboard, color: Colors.white);

    _showOverlay(message, icon);
    _saveAllPreferences();
    _setupTray(); // Update menu to show new state
  }

  String _formatHotkey(HotKey hotkey, bool enabled) {
    if (!_hotKeysEnabled || !enabled) return '';

    final modifiers = hotkey.modifiers?.map((m) {
      switch (m) {
        case HotKeyModifier.alt:
          return '⌥';
        case HotKeyModifier.control:
          return '⌃';
        case HotKeyModifier.shift:
          return '⇧';
        case HotKeyModifier.meta:
          return '⊞';
        default:
          return '';
      }
    }).join('');

    final keyName = hotkey.key.keyLabel;
    return modifiers!.isNotEmpty ? '$modifiers$keyName' : keyName;
  }

  Future<void> _setupTray() async {
    final String iconPath = Platform.isWindows
        ? 'assets/images/app_icon.ico'
        : 'assets/images/app_icon.png';
    await Future.wait([
      trayManager.setIcon(iconPath),
      trayManager.setToolTip('OverKeys'),
    ]);
    trayManager.setContextMenu(Menu(items: [
      MenuItem.checkbox(
        key: 'toggle_mouse_events',
        label:
            'Move\t${_formatHotkey(_toggleMoveHotKey, _enableToggleMoveHotKey)}',
        checked: !_ignoreMouseEvents,
        onClick: (menuItem) {
          setState(() {
            _ignoreMouseEvents = !_ignoreMouseEvents;
            windowManager.setIgnoreMouseEvents(_ignoreMouseEvents);
            if (_ignoreMouseEvents) {
              _fadeIn();
              _showOverlay('Move disabled', const Icon(LucideIcons.lock));
            } else {
              // AIDEV-NOTE: Force show keyboard when enabling move mode
              _smartVisibilityManager.requestVisibilityChange(VisibilityRequest(
                  type: VisibilityRequestType.show, reason: 'move_mode'));
              _showOverlay('Move enabled', const Icon(LucideIcons.move));
            }
          });
        },
      ),
      MenuItem.separator(),
      MenuItem.checkbox(
        key: 'toggle_auto_hide',
        label:
            'Auto Hide\t${_formatHotkey(_autoHideHotKey, _enableAutoHideHotKey)}',
        checked: _autoHideEnabled,
        onClick: (menuItem) {
          _toggleAutoHide(!_autoHideEnabled);
        },
      ),
      MenuItem.checkbox(
        key: 'toggle_layer_switching',
        label:
            'Layer Switching Mode\t${_formatHotkey(_layerSwitchingHotKey, _enableLayerSwitchingHotKey)}',
        checked: _layerSwitchingMode,
      ),
      MenuItem.separator(),
      MenuItem(
          key: 'reset_position',
          label: 'Reset Position',
          onClick: (menuItem) {
            _setProgrammaticAlignment(Alignment.bottomCenter);
            _showOverlay('Position reset', const Icon(LucideIcons.locateFixed));
          }),
      MenuItem.separator(),
      MenuItem(
        key: 'preferences',
        label:
            'Preferences\t${_formatHotkey(_preferencesHotKey, _enablePreferencesHotKey)}',
        onClick: (menuItem) {
          _showPreferences();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'toggle_visibility',
        label:
            'Hide/Show\t${_formatHotkey(_visibilityHotKey, _enableVisibilityHotKey)}',
        onClick: (menuItem) {
          onTrayIconMouseDown();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'reload_config',
        label: 'Reload Config',
        onClick: (menuItem) {
          _loadConfiguration();
          _showOverlay('Config Reloaded', const Icon(LucideIcons.refreshCw));
        },
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit',
        label: 'Exit',
      ),
    ]));
  }

  Future<void> _setupHotKeys() async {
    await hotKeyManager.unregisterAll();

    if (!_hotKeysEnabled) {
      _setupTray();
      return;
    }

    if (_enableAutoHideHotKey) {
      await hotKeyManager.register(
        _autoHideHotKey,
        keyDownHandler: (hotKey) {
          _toggleAutoHide(!_autoHideEnabled);
        },
      );
    }

    if (_enableVisibilityHotKey) {
      await hotKeyManager.register(
        _visibilityHotKey,
        keyDownHandler: (hotKey) {
          setState(() {
            onTrayIconMouseDown();
          });
        },
      );
    }

    if (_enableToggleMoveHotKey) {
      await hotKeyManager.register(
        _toggleMoveHotKey,
        keyDownHandler: (hotKey) {
          setState(() {
            _ignoreMouseEvents = !_ignoreMouseEvents;
            windowManager.setIgnoreMouseEvents(_ignoreMouseEvents);
            if (_ignoreMouseEvents) {
              _fadeIn();
              _showOverlay('Move disabled', const Icon(LucideIcons.lock));
            } else {
              // AIDEV-NOTE: Force show keyboard when enabling move mode
              _smartVisibilityManager.requestVisibilityChange(VisibilityRequest(
                  type: VisibilityRequestType.show, reason: 'move_mode'));
              _showOverlay('Move enabled', const Icon(LucideIcons.move));
            }
          });
        },
      );
    }

    if (_enablePreferencesHotKey) {
      await hotKeyManager.register(
        _preferencesHotKey,
        keyDownHandler: (hotKey) {
          _showOverlay(
              'Opening Preferences', const Icon(LucideIcons.appWindow));
          _showPreferences();
        },
      );
    }

    if (_enableIncreaseOpacityHotKey) {
      await hotKeyManager.register(
        _increaseOpacityHotKey,
        keyDownHandler: (hotKey) {
          _adjustOpacity(true);
        },
      );
    }

    if (_enableDecreaseOpacityHotKey) {
      await hotKeyManager.register(
        _decreaseOpacityHotKey,
        keyDownHandler: (hotKey) {
          _adjustOpacity(false);
        },
      );
    }

    if (_enableLayerSwitchingHotKey) {
      await hotKeyManager.register(
        _layerSwitchingHotKey,
        keyDownHandler: (hotKey) {
          _toggleLayerSwitchingMode();
        },
      );
    }

    _setupTray();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'preferences') {
      _showPreferences();
      return;
    }

    if (menuItem.key == 'toggle_layer_switching') {
      _toggleLayerSwitchingMode();
      return;
    }

    if (menuItem.key == 'exit') {
      DesktopMultiWindow.getAllSubWindowIds().then((windowIds) async {
        for (final id in windowIds) {
          await WindowController.fromWindowId(id).close();
        }
        await windowManager.close();
        exit(0);
      }).catchError((error) {
        if (kDebugMode) {
          debugPrint('Error closing windows: $error');
        }
        windowManager.close();
        exit(0);
      });
      return;
    }
    _setupTray();
  }

  @override
  void onTrayIconMouseDown() {
    // Always toggle force hidden state regardless of current visibility
    if (_smartVisibilityManager.isForceHidden) {
      _smartVisibilityManager.requestVisibilityChange(VisibilityRequest(
          type: VisibilityRequestType.show, reason: 'tray_click'));
      _showOverlay('Keyboard Shown', const Icon(LucideIcons.eye));
      if (kDebugMode && _debugModeEnabled) {
        debugPrint('🔄 Global: Force hidden OFF - keyboard can show again');
      }
    } else {
      _smartVisibilityManager.requestVisibilityChange(VisibilityRequest(
          type: VisibilityRequestType.hide, reason: 'force_hide'));
      _showOverlay('Keyboard Hidden', const Icon(LucideIcons.eyeOff));
      if (kDebugMode && _debugModeEnabled) {
        debugPrint('🔄 Global: Force hidden ON - keyboard will stay hidden');
      }
    }
    windowManager.blur();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu(
      // ignore: deprecated_member_use
      bringAppToFront: true,
    );
  }

  @override
  void onWindowFocus() {
    windowManager.blur();
  }

  bool _isProgrammaticMove = false;

  // AIDEV-NOTE: Helper to set position programmatically without triggering save
  Future<void> _setProgrammaticPosition(Offset position) async {
    _isProgrammaticMove = true;
    await windowManager.setPosition(position);
    _isProgrammaticMove = false;
  }

  // AIDEV-NOTE: Helper to set alignment programmatically without triggering save
  Future<void> _setProgrammaticAlignment(Alignment alignment) async {
    _isProgrammaticMove = true;
    await windowManager.setAlignment(alignment);
    _isProgrammaticMove = false;
  }

  @override
  void onWindowMoved() {
    // AIDEV-NOTE: Only save position for user moves after initialization
    if (_isInitializing || _isProgrammaticMove) {
      return;
    }

    // AIDEV-NOTE: This is a user-initiated move, save it
    _saveWindowPosition();
  }

  Future<void> _saveWindowPosition() async {
    try {
      final position = await windowManager.getPosition();
      await _prefsService.setWindowPosition(position);
    } catch (e) {
      // Ignore position save errors
    }
  }

  bool _preferencesLaunching = false;
  Process? _preferencesProcess;

  Future<void> _showPreferences() async {
    try {
      // Check if preferences process is already running
      if (_preferencesProcess != null) {
        // Process exists, don't create another window
        return;
      }

      // Check if we're already launching
      if (_preferencesLaunching) {
        return;
      }

      _preferencesLaunching = true;

      // Launch preferences as a separate process (original working approach)
      final process = await Process.start(
        Platform.resolvedExecutable,
        ['preferences'],
        runInShell: false,
        environment: Platform.environment,
      );

      // Track this process
      _preferencesProcess = process;

      // Clean up when process exits
      process.exitCode.then((exitCode) {
        _preferencesProcess = null;
        _preferencesLaunching = false;
      });

      _preferencesLaunching = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error launching preferences: $e');
      }
      _preferencesLaunching = false;
    }
  }

  void _setupMethodHandler() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      switch (call.method) {
        // General settings
        case 'updateLaunchAtStartup':
          final launchAtStartupValue = call.arguments as bool;
          setState(() {
            _launchAtStartup = launchAtStartupValue;
            _handleStartupToggle(launchAtStartupValue);
          });
        case 'updateAutoHideEnabled':
          final autoHideEnabled = call.arguments as bool;
          _smartVisibilityManager.updateAutoHideSettings(
              enabled: autoHideEnabled);
        case 'updateAutoHideDuration':
          final autoHideDuration = call.arguments as double;
          _smartVisibilityManager.updateAutoHideSettings(
              duration: autoHideDuration);
        case 'updateOpacity':
          final opacity = call.arguments as double;
          _smartVisibilityManager.setOpacity(opacity);
        // setState will be triggered by onOpacityChange callback
        case 'updateLayerShowDelay':
          final layerShowDelay = call.arguments as double;
          _smartVisibilityManager.updateDelays(
              customLayerDelay: layerShowDelay);
        case 'updateDefaultUserLayoutShowDelay':
          final defaultUserLayoutShowDelay = call.arguments as double;
          _smartVisibilityManager.updateDelays(
              defaultLayerDelay: defaultUserLayoutShowDelay);
        case 'updateQuickSuccessionWindow':
          final quickSuccessionWindow = call.arguments as double;
          _smartVisibilityManager.updateConfiguration(
              quickSuccessionWindow: quickSuccessionWindow);
        case 'updateLayout':
          final layoutName = call.arguments as String;
          setState(() {
            if ((_kanataEnabled || _useUserLayout) &&
                _advancedSettingsEnabled) {
              _initialKeyboardLayout = availableLayouts
                  .firstWhere((layout) => layout.name == layoutName);
            } else {
              _keyboardLayout = availableLayouts
                  .firstWhere((layout) => layout.name == layoutName);
              _initialKeyboardLayout = _keyboardLayout;
            }
          });
          _adjustWindowSize(); // Adjust window for new layout
          _fadeIn();

        // Keyboard settings
        case 'updateKeymapStyle':
          final keymapStyle = call.arguments as String;
          setState(() => _keymapStyle = keymapStyle);
        case 'updateShowTopRow':
          final showTopRow = call.arguments as bool;
          setState(() => _showTopRow = showTopRow);
          _adjustWindowSize();
        case 'updateShowGraveKey':
          final showGraveKey = call.arguments as bool;
          setState(() => _showGraveKey = showGraveKey);
        case 'updateKeySize':
          final keySize = call.arguments as double;
          setState(() => _keySize = keySize);
        case 'updateKeyBorderRadius':
          final keyBorderRadius = call.arguments as double;
          setState(() => _keyBorderRadius = keyBorderRadius);
        case 'updateKeyBorderThickness':
          final keyBorderThickness = call.arguments as double;
          setState(() => _keyBorderThickness = keyBorderThickness);
        case 'updateKeyPadding':
          final keyPadding = call.arguments as double;
          setState(() => _keyPadding = keyPadding);
        case 'updateSpaceWidth':
          final spaceWidth = call.arguments as double;
          setState(() => _spaceWidth = spaceWidth);
        case 'updateSplitWidth':
          final splitWidth = call.arguments as double;
          setState(() => _splitWidth = splitWidth);
        case 'updateLastRowSplitWidth':
          final lastRowSplitWidth = call.arguments as double;
          setState(() => _lastRowSplitWidth = lastRowSplitWidth);
        case 'updateKeyShadowBlurRadius':
          final keyShadowBlurRadius = call.arguments as double;
          setState(() => _keyShadowBlurRadius = keyShadowBlurRadius);
        case 'updateKeyShadowOffsetX':
          final keyShadowOffsetX = call.arguments as double;
          setState(() => _keyShadowOffsetX = keyShadowOffsetX);
        case 'updateKeyShadowOffsetY':
          final keyShadowOffsetY = call.arguments as double;
          setState(() => _keyShadowOffsetY = keyShadowOffsetY);

        // Text settings
        case 'updateFontFamily':
          final fontFamily = call.arguments as String;
          setState(() {
            if (_customFontEnabled && _advancedSettingsEnabled) {
              _initialFontFamily = fontFamily;
            } else {
              _initialFontFamily = _fontFamily = fontFamily;
            }
          });
        case 'updateFontWeight':
          final fontWeightIndex = call.arguments as int;
          setState(() => _fontWeight = FontWeight.values[fontWeightIndex]);
        case 'updateKeyFontSize':
          final keyFontSize = call.arguments as double;
          setState(() => _keyFontSize = keyFontSize);
        case 'updateSpaceFontSize':
          final spaceFontSize = call.arguments as double;
          setState(() => _spaceFontSize = spaceFontSize);

        // Markers settings
        case 'updateMarkerOffset':
          final markerOffset = call.arguments as double;
          setState(() => _markerOffset = markerOffset);
        case 'updateMarkerWidth':
          final markerWidth = call.arguments as double;
          setState(() => _markerWidth = markerWidth);
        case 'updateMarkerHeight':
          final markerHeight = call.arguments as double;
          setState(() => _markerHeight = markerHeight);
        case 'updateMarkerBorderRadius':
          final markerBorderRadius = call.arguments as double;
          setState(() => _markerBorderRadius = markerBorderRadius);

        // Colors settings
        case 'updateKeyColorPressed':
          final keyColorPressed = call.arguments as int;
          setState(() => _keyColorPressed = Color(keyColorPressed));
        case 'updateKeyColorNotPressed':
          final keyColorNotPressed = call.arguments as int;
          setState(() => _keyColorNotPressed = Color(keyColorNotPressed));
        case 'updateMarkerColor':
          final markerColor = call.arguments as int;
          setState(() => _markerColor = Color(markerColor));
        case 'updateMarkerColorNotPressed':
          final markerColorNotPressed = call.arguments as int;
          setState(() => _markerColorNotPressed = Color(markerColorNotPressed));
        case 'updateKeyTextColor':
          final keyTextColor = call.arguments as int;
          setState(() => _keyTextColor = Color(keyTextColor));
        case 'updateKeyTextColorNotPressed':
          final keyTextColorNotPressed = call.arguments as int;
          setState(
              () => _keyTextColorNotPressed = Color(keyTextColorNotPressed));
        case 'updateKeyBorderColorPressed':
          final keyBorderColorPressed = call.arguments as int;
          setState(() => _keyBorderColorPressed = Color(keyBorderColorPressed));
        case 'updateKeyBorderColorNotPressed':
          final keyBorderColorNotPressed = call.arguments as int;
          setState(() =>
              _keyBorderColorNotPressed = Color(keyBorderColorNotPressed));

        // Animations settings
        case 'updateAnimationEnabled':
          final animationEnabled = call.arguments as bool;
          setState(() => _animationEnabled = animationEnabled);
        case 'updateAnimationStyle':
          final animationStyle = call.arguments as String;
          setState(() => _animationStyle = animationStyle);
        case 'updateAnimationDuration':
          final animationDuration = call.arguments as double;
          setState(() => _animationDuration = animationDuration);
        case 'updateAnimationScale':
          final animationScale = call.arguments as double;
          setState(() => _animationScale = animationScale);

        // HotKey settings
        case 'updateHotKeysEnabled':
          final hotKeysEnabled = call.arguments as bool;
          setState(() {
            _hotKeysEnabled = hotKeysEnabled;
            _setupHotKeys();
          });
        case 'updateVisibilityHotKey':
          final hotKeyJson = call.arguments as String;
          final newHotKey = HotKey.fromJson(jsonDecode(hotKeyJson));
          await hotKeyManager.unregister(_visibilityHotKey);
          setState(() => _visibilityHotKey = newHotKey);
          await _setupHotKeys();
        case 'updateAutoHideHotKey':
          final hotKeyJson = call.arguments as String;
          final newHotKey = HotKey.fromJson(jsonDecode(hotKeyJson));
          await hotKeyManager.unregister(_autoHideHotKey);
          setState(() => _autoHideHotKey = newHotKey);
          await _setupHotKeys();
        case 'updateToggleMoveHotKey':
          final hotKeyJson = call.arguments as String;
          final newHotKey = HotKey.fromJson(jsonDecode(hotKeyJson));
          await hotKeyManager.unregister(_toggleMoveHotKey);
          setState(() => _toggleMoveHotKey = newHotKey);
          await _setupHotKeys();
        case 'updatePreferencesHotKey':
          final hotKeyJson = call.arguments as String;
          final newHotKey = HotKey.fromJson(jsonDecode(hotKeyJson));
          await hotKeyManager.unregister(_preferencesHotKey);
          setState(() => _preferencesHotKey = newHotKey);
          await _setupHotKeys();
        case 'updateIncreaseOpacityHotKey':
          final hotKeyJson = call.arguments as String;
          final newHotKey = HotKey.fromJson(jsonDecode(hotKeyJson));
          await hotKeyManager.unregister(_increaseOpacityHotKey);
          setState(() => _increaseOpacityHotKey = newHotKey);
          await _setupHotKeys();
        case 'updateDecreaseOpacityHotKey':
          final hotKeyJson = call.arguments as String;
          final newHotKey = HotKey.fromJson(jsonDecode(hotKeyJson));
          await hotKeyManager.unregister(_decreaseOpacityHotKey);
          setState(() => _decreaseOpacityHotKey = newHotKey);
          await _setupHotKeys();
        case 'updateEnableVisibilityHotKey':
          final enabled = call.arguments as bool;
          setState(() => _enableVisibilityHotKey = enabled);
          await _setupHotKeys();
        case 'updateEnableAutoHideHotKey':
          final enabled = call.arguments as bool;
          setState(() => _enableAutoHideHotKey = enabled);
          await _setupHotKeys();
        case 'updateEnableToggleMoveHotKey':
          final enabled = call.arguments as bool;
          setState(() => _enableToggleMoveHotKey = enabled);
          await _setupHotKeys();
        case 'updateEnablePreferencesHotKey':
          final enabled = call.arguments as bool;
          setState(() => _enablePreferencesHotKey = enabled);
          await _setupHotKeys();
        case 'updateEnableIncreaseOpacityHotKey':
          final enabled = call.arguments as bool;
          setState(() => _enableIncreaseOpacityHotKey = enabled);
          await _setupHotKeys();
        case 'updateEnableDecreaseOpacityHotKey':
          final enabled = call.arguments as bool;
          setState(() => _enableDecreaseOpacityHotKey = enabled);
          await _setupHotKeys();

        // Learn settings
        case 'updateLearningModeEnabled':
          final learningModeEnabled = call.arguments as bool;
          setState(() => _learningModeEnabled = learningModeEnabled);
        case 'updatePinkyLeftColor':
          final color = call.arguments as int;
          setState(() => _pinkyLeftColor = Color(color));
        case 'updateRingLeftColor':
          final color = call.arguments as int;
          setState(() => _ringLeftColor = Color(color));
        case 'updateMiddleLeftColor':
          final color = call.arguments as int;
          setState(() => _middleLeftColor = Color(color));
        case 'updateIndexLeftColor':
          final color = call.arguments as int;
          setState(() => _indexLeftColor = Color(color));
        case 'updateIndexRightColor':
          final color = call.arguments as int;
          setState(() => _indexRightColor = Color(color));
        case 'updateMiddleRightColor':
          final color = call.arguments as int;
          setState(() => _middleRightColor = Color(color));
        case 'updateRingRightColor':
          final color = call.arguments as int;
          setState(() => _ringRightColor = Color(color));
        case 'updatePinkyRightColor':
          final color = call.arguments as int;
          setState(() => _pinkyRightColor = Color(color));

        // Advanced settings
        case 'updateAdvancedSettingsEnabled':
          final advancedSettingsEnabled = call.arguments as bool;
          setState(() {
            _advancedSettingsEnabled = advancedSettingsEnabled;
            if (!advancedSettingsEnabled) {
              _initialShowAltLayout = _showAltLayout;
              if (_kanataEnabled) {
                _kanataService.disconnect();
                _keyboardLayout = _initialKeyboardLayout!;
              }
              if (_useUserLayout) {
                _keyboardLayout = _initialKeyboardLayout!;
              }
              _showAltLayout = false;
              if (_customFontEnabled) {
                _fontFamily = _initialFontFamily;
              }
              if (_keyboardFollowsMouse) {
                _stopMouseTracking();
              }
            } else {
              if (_initialShowAltLayout || _showAltLayout) {
                _showAltLayout = true;
              }
              if (_keyboardFollowsMouse) {
                _startMouseTracking();
              }
            }
          });

          if (_advancedSettingsEnabled) {
            if (_kanataEnabled) {
              _useKanata();
            }
            if (_useUserLayout && !_kanataEnabled) {
              _loadUserLayout();
            }
            if (_showAltLayout) {
              _loadAltLayout();
            }
            if (_customFontEnabled) {
              _loadCustomFont();
            }
          } else {
            _fadeIn();
          }
        case 'updateUseUserLayout':
          final useUserLayout = call.arguments as bool;
          setState(() {
            _useUserLayout = useUserLayout;
            if (useUserLayout) {
              _loadUserLayout();
            } else {
              setState(() {
                if (_initialKeyboardLayout != null && !_kanataEnabled) {
                  _keyboardLayout = _initialKeyboardLayout!;
                }
              });
              _fadeIn();
            }
          });
        case 'updateShowAltLayout':
          final showAltLayout = call.arguments as bool;
          setState(() {
            _showAltLayout = showAltLayout;
          });
          if (showAltLayout) {
            _loadAltLayout();
          }
          _fadeIn();
        case 'updateCustomFontEnabled':
          final customFontEnabled = call.arguments as bool;
          setState(() {
            _customFontEnabled = customFontEnabled;
            if (customFontEnabled) {
              _loadCustomFont();
            } else {
              _fontFamily = _initialFontFamily;
            }
          });
        case 'updateDebugModeEnabled':
          final debugModeEnabled = call.arguments as bool;
          setState(() {
            _debugModeEnabled = debugModeEnabled;
          });
          _adjustWindowSize(); // Recalculate window size for debug padding
        case 'updateThumbDebugModeEnabled':
          final thumbDebugModeEnabled = call.arguments as bool;
          setState(() {
            _thumbDebugModeEnabled = thumbDebugModeEnabled;
          });
          _adjustWindowSize(); // Recalculate window size for debug padding
        case 'updateUse6ColLayout':
          final use6ColLayout = call.arguments as bool;
          setState(() {
            _use6ColLayout = use6ColLayout;
          });
          _fadeIn();
        case 'updateKanataEnabled':
          final kanataEnabled = call.arguments as bool;
          setState(() {
            if (kanataEnabled && !_kanataEnabled) {
              _initialKeyboardLayout = _keyboardLayout;
              _kanataEnabled = true;
              _useKanata();
            } else if (!kanataEnabled && _kanataEnabled) {
              _kanataEnabled = false;
              _kanataService.disconnect();
              if (_initialKeyboardLayout != null) {
                _keyboardLayout = _initialKeyboardLayout!;
                _fadeIn();
              }
            }
          });
        case 'updateKeyboardFollowsMouse':
          final keyboardFollowsMouse = call.arguments as bool;
          setState(() {
            _keyboardFollowsMouse = keyboardFollowsMouse;
            if (keyboardFollowsMouse && _advancedSettingsEnabled) {
              _startMouseTracking();
            } else {
              _stopMouseTracking();
            }
          });

        case 'closePreferencesWindow':
          await WindowController.fromWindowId(fromWindowId).close();
          break;
        default:
          throw UnimplementedError('Unimplemented method ${call.method}');
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OverKeys',
      theme: Platform.isMacOS
          ? ThemeData(
              fontFamily: _fontFamily,
              fontFamilyFallback: const ['GeistMono', 'Manrope', 'sans-serif'],
              // AIDEV-NOTE: Enhanced transparency configuration for macOS
              brightness: Brightness.light,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              platform: TargetPlatform.macOS,
              scaffoldBackgroundColor: Colors.transparent,
              canvasColor: Colors.transparent,
              cardColor: Colors.transparent,
              dialogTheme:
                  const DialogThemeData(backgroundColor: Colors.transparent))
          : ThemeData(
              fontFamily: _fontFamily,
              fontFamilyFallback: const ['GeistMono', 'Manrope', 'sans-serif'],
              visualDensity: VisualDensity.adaptivePlatformDensity,
              platform: TargetPlatform.windows),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            AnimatedOpacity(
              opacity: _opacity,
              duration: _fadeDuration,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => windowManager.startDragging(),
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: _isLayoutInitialized
                        ? KeyboardScreen(
                            layout: _keyboardLayout,
                            keymapStyle: _keymapStyle,
                            showTopRow: _showTopRow,
                            showGraveKey: _showGraveKey,
                            keySize: _keySize,
                            keyBorderRadius: _keyBorderRadius,
                            keyBorderThickness: _keyBorderThickness,
                            keyPadding: _keyPadding,
                            spaceWidth: _spaceWidth,
                            splitWidth: _splitWidth,
                            lastRowSplitWidth: _lastRowSplitWidth,
                            keyShadowBlurRadius: _keyShadowBlurRadius,
                            keyShadowOffsetX: _keyShadowOffsetX,
                            keyShadowOffsetY: _keyShadowOffsetY,
                            keyFontSize: _keyFontSize,
                            spaceFontSize: _spaceFontSize,
                            fontWeight: _fontWeight,
                            markerOffset: _markerOffset,
                            markerWidth: _markerWidth,
                            markerHeight: _markerHeight,
                            markerBorderRadius: _markerBorderRadius,
                            keyColorPressed: _keyColorPressed,
                            keyColorNotPressed: _keyColorNotPressed,
                            markerColor: _markerColor,
                            markerColorNotPressed: _markerColorNotPressed,
                            keyTextColor: _keyTextColor,
                            keyTextColorNotPressed: _keyTextColorNotPressed,
                            keyBorderColorPressed: _keyBorderColorPressed,
                            keyBorderColorNotPressed: _keyBorderColorNotPressed,
                            animationEnabled: _animationEnabled,
                            animationStyle: _animationStyle,
                            animationDuration: _animationDuration,
                            animationScale: _animationScale,
                            learningModeEnabled: _learningModeEnabled,
                            pinkyLeftColor: _pinkyLeftColor,
                            ringLeftColor: _ringLeftColor,
                            middleLeftColor: _middleLeftColor,
                            indexLeftColor: _indexLeftColor,
                            indexRightColor: _indexRightColor,
                            middleRightColor: _middleRightColor,
                            ringRightColor: _ringRightColor,
                            pinkyRightColor: _pinkyRightColor,
                            showAltLayout:
                                _advancedSettingsEnabled && _showAltLayout,
                            altLayout: _altLayout,
                            use6ColLayout: _use6ColLayout,
                            keyPressStates: _keyPressStates,
                            customShiftMappings: _customShiftMappings,
                            actionMappings: _actionMappings,
                            config: _userConfig,
                            debugMode: _debugModeEnabled,
                            thumbDebugMode: _thumbDebugModeEnabled,
                            maxLayoutWidth: _cachedMaxLayoutWidth,
                            maxLeftHandWidth: _cachedMaxLeftHandWidth,
                            maxRightHandWidth: _cachedMaxRightHandWidth,
                          )
                        : const SizedBox
                            .shrink(), // Hide keyboard until layout is initialized
                  ),
                ),
              ),
            ),
            StatusOverlay(
              visible: _showStatusOverlay,
              message: _overlayMessage,
              icon: _statusIcon,
              backgroundColor: _keyColorNotPressed,
              textColor: _keyTextColorNotPressed,
              keySize: _keySize,
              keyBorderRadius: _keyBorderRadius,
            ),
            LayerSelector(
              availableLayers: _getAvailableLayers(),
              currentLayer: _keyboardLayout,
              onLayerChanged: _switchToLayer,
              isVisible: _layerSwitchingMode && _isWindowVisible,
              opacity: _opacity,
              keyColorNotPressed: _keyColorNotPressed,
              keyTextColorNotPressed: _keyTextColorNotPressed,
              keyBorderColorNotPressed: _keyBorderColorNotPressed,
              keyBorderRadius: _keyBorderRadius,
              keyBorderThickness: _keyBorderThickness,
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  // AIDEV-NOTE: Track which semantic actions are currently active based on key combinations
  final Set<String> _activeSemanticActions = <String>{};

  // AIDEV-NOTE: Handle reverse action mapping - detect shortcuts and highlight semantic action keys
  void _handleReverseActionMapping(String key, bool isPressed, bool isShiftDown,
      bool isCtrlDown, bool isAltDown, bool isCmdDown) {
    // Only process if we have action mappings loaded
    final actionMappings = _actionMappings;
    if (actionMappings == null || actionMappings.isEmpty) return;

    // Build the key combination string in the same format as action mappings
    final String keyCombination = _buildKeyCombination(
        key, isShiftDown, isCtrlDown, isAltDown, isCmdDown);

    // Find all semantic actions that match this key combination (exact match only)
    final matchingActions = <String>[];
    actionMappings.forEach((semanticAction, actionKeyCombination) {
      if (_normalizeKeyCombination(actionKeyCombination) ==
          _normalizeKeyCombination(keyCombination)) {
        matchingActions.add(semanticAction);
      }
    });

    // For release events, only clear actions that were previously set by the exact same combination
    final partialMatchingActions = <String>[];
    if (!isPressed) {
      // Only clear actions that are currently active and match the releasing key
      for (final activeAction in _activeSemanticActions.toList()) {
        final actionCombination = actionMappings[activeAction];
        if (actionCombination != null &&
            _normalizeKeyCombination(actionCombination)
                .contains(_normalizeKeyCombination(key))) {
          partialMatchingActions.add(activeAction);
        }
      }
    }

    final allMatchingActions =
        {...matchingActions, ...partialMatchingActions}.toList();

    if (allMatchingActions.isNotEmpty) {
      // Update active semantic actions tracking
      setState(() {
        for (final action in allMatchingActions) {
          if (isPressed) {
            _activeSemanticActions.add(action);
          } else {
            _activeSemanticActions.remove(action);
          }
        }
      });

      // Find all keys in the current layout that have these semantic labels
      final currentLayout = _keyboardLayout;
      final semanticKeys = <String>[];

      // Search through all keys in the layout
      for (final row in currentLayout.keys) {
        for (final layoutKey in row) {
          if (layoutKey != null && allMatchingActions.contains(layoutKey)) {
            semanticKeys.add(layoutKey);
          }
        }
      }

      // Also check split matrix layouts (leftHand/rightHand)
      if (currentLayout.leftHand != null) {
        for (final row in currentLayout.leftHand!.rows) {
          for (final layoutKey in row) {
            if (layoutKey != null && allMatchingActions.contains(layoutKey)) {
              semanticKeys.add(layoutKey);
            }
          }
        }
      }
      if (currentLayout.rightHand != null) {
        for (final row in currentLayout.rightHand!.rows) {
          for (final layoutKey in row) {
            if (layoutKey != null && allMatchingActions.contains(layoutKey)) {
              semanticKeys.add(layoutKey);
            }
          }
        }
      }

      // Also check thumb cluster
      if (currentLayout.thumbCluster != null) {
        // Check left thumb keys
        for (final row in currentLayout.thumbCluster!.leftKeys) {
          for (final layoutKey in row) {
            if (layoutKey != null && allMatchingActions.contains(layoutKey)) {
              semanticKeys.add(layoutKey);
            }
          }
        }
        // Check right thumb keys
        for (final row in currentLayout.thumbCluster!.rightKeys) {
          for (final layoutKey in row) {
            if (layoutKey != null && allMatchingActions.contains(layoutKey)) {
              semanticKeys.add(layoutKey);
            }
          }
        }
      }

      // Update the key press states for all matching semantic keys
      setState(() {
        for (final semanticKey in semanticKeys) {
          // Only highlight if the semantic action is currently active
          final shouldBePressed = _activeSemanticActions.contains(semanticKey);
          _keyPressStates[semanticKey] = shouldBePressed;
        }
      });
    }
  }

  // AIDEV-NOTE: Build key combination string in action mappings format (cmd+c, cmd+shift+z, etc.)
  String _buildKeyCombination(String key, bool isShiftDown, bool isCtrlDown,
      bool isAltDown, bool isCmdDown) {
    final parts = <String>[];

    // Add modifiers in standard order: cmd, ctrl, alt, shift
    if (isCmdDown) parts.add('cmd');
    if (isCtrlDown) parts.add('ctrl');
    if (isAltDown) parts.add('alt');
    if (isShiftDown) parts.add('shift');

    // Add the key (convert to lowercase to match action mappings format)
    parts.add(key.toLowerCase());

    return parts.join('+');
  }

  // AIDEV-NOTE: Normalize key combinations for comparison (handle variations in spacing, case, etc.)
  String _normalizeKeyCombination(String combination) {
    return combination.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  }
}
