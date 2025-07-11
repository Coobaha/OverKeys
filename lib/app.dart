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
import 'package:overkeys/utils/key_code_unified.dart';
import 'package:overkeys/widgets/status_overlay.dart';
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
  static const double _defaultWindowWidth = 1000;
  static const double _defaultWindowHeight = 330;
  static const double _defaultTopRowExtraHeight = 80;
  static const double _defaultTopRowExtraWidth = 160;
  static const double _baseWindowPadding = 40; // Base padding around content
  static const Duration _fadeDuration = Duration(milliseconds: 200);
  static const Duration _overlayDuration = Duration(milliseconds: 1000);
  static const double _opacityStep = 0.05;
  static const double _minOpacity = 0.1;
  static const double _maxOpacity = 1.0;

  // UI state
  bool _isWindowVisible = true;
  bool _ignoreMouseEvents = true;
  Timer? _autoHideTimer;
  Timer? _opacityDebounceTimer;
  bool _forceHide = false;
  bool autoHideBeforeForceHide = false;
  bool autoHideBeforeMove = false;

  // General settings
  bool _launchAtStartup = false;
  bool _autoHideEnabled = false;
  double _autoHideDuration = 2.0;
  double _opacity = 0.6;
  double _lastOpacity = 0.6;
  KeyboardLayout _keyboardLayout = qwerty;
  KeyboardLayout? _initialKeyboardLayout;
  KeyboardLayout? _defaultUserLayout;

  // Keyboard settings
  String _keymapStyle = 'Staggered';
  bool _showTopRow = false;
  bool _showGraveKey = false;
  double _keySize = 48;
  double _keyBorderRadius = 12;
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
  bool _use6ColLayout = false;
  bool _kanataEnabled = false;
  bool _keyboardFollowsMouse = false;
  Timer? _mouseCheckTimer;

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
  final Map<String, String> _physicalKeyToVisualKey = {}; // Track physical->visual mapping
  Map<String, String>? _customShiftMappings;
  final Set<String> _activeTriggers = {};
  List<KeyboardLayout> _userLayers = [];
  UserConfig? _userConfig;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAllPreferences();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _setupTray();
    _setupKeyListener();
    _setupHotKeys();
    _setupMethodHandler();
    _initStartup();
    _setupKanataLayerChangeHandler();
    _loadConfiguration();
    if (_showTopRow) {
      _adjustWindowSize();
    }
    if (_autoHideEnabled) {
      _resetAutoHideTimer();
    }
    // Ensure keyboard is visible after initialization
    setState(() {
      _isWindowVisible = true;
      _opacity = _lastOpacity > 0 ? _lastOpacity : 0.6;
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    unhook();
    _autoHideTimer?.cancel();
    _overlayTimer?.cancel();
    _mouseCheckTimer?.cancel();
    _kanataService.dispose();
    _keyboardService?.dispose();
    // No process to kill anymore
    _saveAllPreferences();
    super.dispose();
  }

  void _startMouseTracking() {
    _mouseCheckTimer?.cancel();
    if (_keyboardFollowsMouse && _advancedSettingsEnabled) {
      _mouseCheckTimer = Timer.periodic(const Duration(milliseconds: 500),
          (_) => windowManager.setAlignment(Alignment.bottomCenter));
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
      _opacity = prefs['opacity'];
      _lastOpacity = prefs['opacity'];
      _keyboardLayout =
          availableLayouts.firstWhere((layout) => layout.name == prefs['keyboardLayoutName']);
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
      _enableIncreaseOpacityHotKey = prefs['enableIncreaseOpacityHotKey'] ?? true;
      _enableDecreaseOpacityHotKey = prefs['enableDecreaseOpacityHotKey'] ?? true;

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
      _use6ColLayout = prefs['use6ColLayout'];
      _kanataEnabled = prefs['kanataEnabled'];
      _keyboardFollowsMouse = prefs['keyboardFollowsMouse'];
    });

    // AIDEV-NOTE: Restore saved window position after preferences load
    await _restoreWindowPosition();
  }

  // AIDEV-NOTE: Restores window position with validation for resolution changes
  Future<void> _restoreWindowPosition() async {
    // Load all preferences to get the window position
    final prefs = await _prefsService.loadAllPreferences();
    final savedPosition = prefs['windowPosition'] as Offset?;
    
    if (kDebugMode) print('🔧 Restoring window position: $savedPosition');
    
    if (savedPosition != null) {
      // Validate position is still on screen (handle resolution changes)
      if (await _isPositionValid(savedPosition)) {
        if (kDebugMode) print('🔧 Position valid, restoring to: $savedPosition');
        await windowManager.setPosition(savedPosition);
      } else {
        if (kDebugMode) print('🔧 Position invalid, using default bottomCenter');
        // Position is off-screen, use default and save the new position
        await windowManager.setAlignment(Alignment.bottomCenter);
        final newPosition = await windowManager.getPosition();
        await _prefsService.setWindowPosition(newPosition);
      }
    } else {
      if (kDebugMode) print('🔧 No saved position, using default bottomCenter');
      // Use default position (bottomCenter) for first launch
      await windowManager.setAlignment(Alignment.bottomCenter);
    }
  }

  // AIDEV-NOTE: Validates if position is reasonable (basic bounds checking)
  Future<bool> _isPositionValid(Offset position) async {
    try {
      // Basic validation: ensure position is not extreme values
      // This handles most cases of invalid positions from resolution changes
      const minPosition = -100.0; // Allow some off-screen positioning
      const maxPosition = 5000.0; // Reasonable maximum for most setups
      
      return position.dx >= minPosition && 
             position.dx <= maxPosition &&
             position.dy >= minPosition && 
             position.dy <= maxPosition;
    } catch (e) {
      // If validation fails, assume position is invalid for safety
      return false;
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
    final mappings = await configService.getCustomShiftMappings();
    final config = await configService.getConfig();
    setState(() {
      _customShiftMappings = mappings;
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
      _fadeIn();
    };
  }

  void _updateAutoHideBasedOnLayer(bool isDefaultUserLayout) {
    if (!isDefaultUserLayout && _autoHideEnabled) {
      _autoHideEnabled = false;
      _autoHideTimer?.cancel();
      autoHideBeforeMove = true;
    } else if (isDefaultUserLayout && autoHideBeforeMove) {
      _autoHideEnabled = true;
      _resetAutoHideTimer();
      autoHideBeforeMove = false;
    }
  }

  Future<void> _useKanata() async {
    if (_kanataEnabled && _advancedSettingsEnabled) {
      _kanataService.connect();
    }
  }

  Future<void> _loadUserLayout() async {
    if (!_useUserLayout) return;

    final configService = ConfigService();
    final userLayout = await configService.getUserLayout();

    if (userLayout != null) {
      setState(() {
        _defaultUserLayout = userLayout;
        if (!_kanataEnabled) {
          _keyboardLayout = userLayout;
        }
      });
      _adjustWindowSize(); // Adjust window for new layout
      _fadeIn();
    }
  }

  Future<void> _loadUserLayers() async {
    if (!_useUserLayout) return;

    final configService = ConfigService();
    final layers = await configService.getUserLayers() ?? [];

    setState(() {
      _userLayers = layers;
    });
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
    int visibleRows = _showTopRow ? currentLayout.keys.length : currentLayout.keys.length - 1;
    double mainRowsHeight = visibleRows * (keySize + keyPadding * 2) + (visibleRows - 1) * keyPadding;
    
    // Calculate thumb cluster height if present
    double thumbClusterHeight = 0;
    if (currentLayout.thumbCluster != null) {
      // Find maximum rows in left or right thumb cluster
      int maxThumbRows = math.max(
        currentLayout.thumbCluster!.leftKeys.length,
        currentLayout.thumbCluster!.rightKeys.length
      );
      thumbClusterHeight = maxThumbRows * (keySize + keyPadding * 2) + 
                          (maxThumbRows - 1) * keyPadding + 
                          keyPadding * 2; // Extra spacing between main and thumb
    }
    
    double totalHeight = mainRowsHeight + thumbClusterHeight + _baseWindowPadding * 2;
    
    return totalHeight;
  }

  double _calculateRequiredWidth() {
    KeyboardLayout currentLayout = _getCurrentLayout();
    double keySize = _keySize;
    double keyPadding = _keyPadding;
    
    // For split matrix layouts, calculate based on left+right hand + gap
    if (currentLayout.leftHand != null && currentLayout.rightHand != null) {
      // Find the maximum keys in any row for left and right hands
      int maxLeftKeys = 0;
      int maxRightKeys = 0;
      
      for (var row in currentLayout.leftHand!.rows) {
        // Count non-null keys only
        int nonNullKeys = row.where((key) => key != null).length;
        if (nonNullKeys > maxLeftKeys) maxLeftKeys = nonNullKeys;
      }
      for (var row in currentLayout.rightHand!.rows) {
        // Count non-null keys only
        int nonNullKeys = row.where((key) => key != null).length;
        if (nonNullKeys > maxRightKeys) maxRightKeys = nonNullKeys;
      }
      
      // Add thumb cluster width if present
      if (currentLayout.thumbCluster != null) {
        for (var row in currentLayout.thumbCluster!.leftKeys) {
          int nonNullKeys = row.where((key) => key != null).length;
          if (nonNullKeys > maxLeftKeys) maxLeftKeys = nonNullKeys;
        }
        for (var row in currentLayout.thumbCluster!.rightKeys) {
          int nonNullKeys = row.where((key) => key != null).length;
          if (nonNullKeys > maxRightKeys) maxRightKeys = nonNullKeys;
        }
      }
      
      // Calculate total width: left hand + gap + right hand + padding
      double leftWidth = maxLeftKeys * (keySize + keyPadding * 2) + (maxLeftKeys - 1) * keyPadding;
      double rightWidth = maxRightKeys * (keySize + keyPadding * 2) + (maxRightKeys - 1) * keyPadding;
      double gap = _splitWidth;
      
      // AIDEV-NOTE: Add 20px safety margin to prevent Row overflow
      return leftWidth + gap + rightWidth + _baseWindowPadding * 2 + 20;
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
      double totalWidth = maxKeys * (keySize + keyPadding * 2) + (maxKeys - 1) * keyPadding;
      
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
      
      return totalWidth + _baseWindowPadding * 2 + 20;
    }
  }

  Future<void> _adjustWindowSize() async {
    _fadeIn();
    
    // Calculate precise dimensions based on layout content
    double height = _calculateRequiredHeight();
    double width = _calculateRequiredWidth();
    
    await windowManager.setSize(Size(width, height));
    
    // AIDEV-NOTE: Only reset to bottomCenter if no saved position exists
    final savedPosition = await _prefsService.getWindowPosition();
    if (savedPosition == null) {
      await windowManager.setAlignment(Alignment.bottomCenter);
    }
  }

  void _fadeOut() {
    if (!_isWindowVisible) return;
    setState(() {
      _lastOpacity = _opacity;
      _opacity = 0.0;
      _isWindowVisible = false;
    });
  }

  void _fadeIn() {
    if (_forceHide) return;
    if (!_isWindowVisible) {
      setState(() {
        _isWindowVisible = true;
        _opacity = _lastOpacity;
      });
    }
    _resetAutoHideTimer();
  }

  KeyboardService? _keyboardService;

  void _setupKeyListener() {
    if (Platform.isMacOS) {
      _setupMacOSKeyboardMonitoring();
    } else {
      // Fallback to isolate approach for other platforms
      final receivePort = ReceivePort();
      Isolate.spawn(setHook, receivePort.sendPort).then((_) {}).catchError((error) {
        if (kDebugMode) {
          print('Error spawning Isolate: $error');
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
      print("ERROR: macOS keyboard monitoring requires both Accessibility and Input Monitoring permissions.");
      print("Please enable them in System Preferences > Security & Privacy > Privacy");
      print("1. Go to System Preferences > Security & Privacy > Privacy > Accessibility");
      print("2. Add your IDE (IntelliJ/VS Code/Terminal) and enable it");
      print("3. Also add to Input Monitoring if on macOS 10.15+");
      print("4. Restart the app after granting permissions");
      return; // Don't crash, just return
    }
    
    // Start monitoring using the platform channel
    await _keyboardService!.startMonitoring((List<dynamic> message) {
      _handleKeyEvent(message);
    });
  }

  void _handleKeyEvent(dynamic message) {
    if (message is! List) return;

    String key;
    bool isPressed;
    bool isShiftDown;

    if (message[0] is String) {
      // Handle string-based key events (macOS format)
      if (message[0] == 'session_unlock') {
        setState(() => _keyPressStates.clear());
        return;
      }
      
      final keyName = message[0] as String;
      isPressed = message[1] as bool;
      isShiftDown = message[2] as bool;
      
      // Map string key names to layout keys
      key = getKeyFromStringKeyShift(keyName, isShiftDown);
    } else if (message[0] is int) {
      // Handle integer-based key events (Windows format)
      final keyCode = message[0] as int;
      isPressed = message[1] as bool;
      isShiftDown = message[2] as bool;
      key = getKeyFromKeyCodeShift(keyCode, isShiftDown);
    } else {
      return; // Invalid message format
    }

    // Key event processed: $key pressed: $isPressed shift: $isShiftDown
    
    setState(() {
      // For macOS string events, track physical key to visual key mapping
      if (message[0] is String) {
        final keyName = message[0] as String;
        
        if (isPressed) {
          // On press: track which visual key this physical key maps to
          _physicalKeyToVisualKey[keyName] = key;
          _keyPressStates[key] = true;
        } else {
          // On release: clear the visual key that was set during press
          final pressedVisualKey = _physicalKeyToVisualKey[keyName];
          if (pressedVisualKey != null) {
            _keyPressStates[pressedVisualKey] = false;
            _physicalKeyToVisualKey.remove(keyName);
          }
        }
        
      } else {
        // For Windows integer events, just track the mapped key
        _keyPressStates[key] = isPressed;
      }
    });
    
    if (_forceHide) return;
    if (_autoHideEnabled && !_isWindowVisible && isPressed) {
      _fadeIn();
    } else {
      _resetAutoHideTimer();
    }

    if (_useUserLayout && _advancedSettingsEnabled) {
      final activeLayer = _userLayers.where((l) => l.trigger == key);
      for (final layout in activeLayer) {
        if (layout.type == 'toggle' && isPressed) {
          setState(() {
            if (_keyboardLayout.name != layout.name) {
              _keyboardLayout = layout;
            } else if (_defaultUserLayout != null) {
              _keyboardLayout = _defaultUserLayout!;
            }
          });
        } else if (layout.type == 'held') {
          if (isPressed && !_activeTriggers.contains(key)) {
            setState(() {
              _keyboardLayout = layout;
              _activeTriggers.add(key);
            });
          } else if (!isPressed && _activeTriggers.contains(key)) {
            setState(() {
              if (_defaultUserLayout != null) {
                _keyboardLayout = _defaultUserLayout!;
              }
              _activeTriggers.remove(key);
            });
          }
        }
      }
    }
  }

  void _resetAutoHideTimer() {
    if (!_autoHideEnabled) return;

    _autoHideTimer?.cancel();
    _autoHideTimer =
        Timer(Duration(milliseconds: (_autoHideDuration * 1000).round()), _handleAutoHide);
  }

  void _handleAutoHide() {
    if (_autoHideEnabled && _isWindowVisible) {
      _fadeOut();
    }
  }

  void _toggleAutoHide(bool enable) {
    setState(() {
      _autoHideEnabled = enable;
      if (_autoHideEnabled) {
        _resetAutoHideTimer();
      } else {
        _autoHideTimer?.cancel();
        if (!_isWindowVisible) {
          _fadeIn();
        }
      }
    });
    _showOverlay(_autoHideEnabled ? 'Auto-hide Enabled' : 'Auto-hide Disabled',
        _autoHideEnabled ? const Icon(LucideIcons.timerReset) : const Icon(LucideIcons.timerOff));
    DesktopMultiWindow.getAllSubWindowIds().then((windowIds) {
      for (final id in windowIds) {
        DesktopMultiWindow.invokeMethod(id, 'updateAutoHideFromMainWindow', _autoHideEnabled);
      }
    });
    _saveAllPreferences();
    _setupTray();
  }

  void _adjustOpacity(bool increase) {
    if (_forceHide) return;

    final newLastOpacity = increase
        ? (_lastOpacity + _opacityStep).clamp(_minOpacity, _maxOpacity)
        : (_lastOpacity - _opacityStep).clamp(_minOpacity, _maxOpacity);

    if (newLastOpacity != _lastOpacity) {
      setState(() {
        _lastOpacity = newLastOpacity;
      });

      _showOverlay('Opacity: ${(_lastOpacity * 100).round()}%',
          increase ? const Icon(LucideIcons.plusCircle) : const Icon(LucideIcons.minusCircle));
    }

    _opacityDebounceTimer?.cancel();
    _opacityDebounceTimer = Timer(const Duration(milliseconds: 125), () {
      if (_opacity != _lastOpacity) {
        setState(() {
          _opacity = _lastOpacity;
        });
        _saveAllPreferences();
        DesktopMultiWindow.getAllSubWindowIds().then((windowIds) {
          for (final id in windowIds) {
            DesktopMultiWindow.invokeMethod(id, 'updateOpacityFromMainWindow', _opacity);
          }
        });
      }
    });
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
    final String iconPath =
        Platform.isWindows ? 'assets/images/app_icon.ico' : 'assets/images/app_icon.png';
    await Future.wait([
      trayManager.setIcon(iconPath),
      trayManager.setToolTip('OverKeys'),
    ]);
    trayManager.setContextMenu(Menu(items: [
      MenuItem.checkbox(
        key: 'toggle_mouse_events',
        label: 'Move\t${_formatHotkey(_toggleMoveHotKey, _enableToggleMoveHotKey)}',
        checked: !_ignoreMouseEvents,
        onClick: (menuItem) {
          setState(() {
            _ignoreMouseEvents = !_ignoreMouseEvents;
            windowManager.setIgnoreMouseEvents(_ignoreMouseEvents);
            if (_ignoreMouseEvents) {
              _fadeIn();
              _showOverlay('Move disabled', const Icon(LucideIcons.lock));
            } else {
              _showOverlay('Move enabled', const Icon(LucideIcons.move));
            }
          });
        },
      ),
      MenuItem.separator(),
      MenuItem.checkbox(
        key: 'toggle_auto_hide',
        label: 'Auto Hide\t${_formatHotkey(_autoHideHotKey, _enableAutoHideHotKey)}',
        checked: _autoHideEnabled,
        onClick: (menuItem) {
          _toggleAutoHide(!_autoHideEnabled);
        },
      ),
      MenuItem.separator(),
      MenuItem(
          key: 'reset_position',
          label: 'Reset Position',
          onClick: (menuItem) {
            windowManager.setAlignment(Alignment.bottomCenter);
            _showOverlay('Position reset', const Icon(LucideIcons.locateFixed));
          }),
      MenuItem.separator(),
      MenuItem(
        key: 'preferences',
        label: 'Preferences\t${_formatHotkey(_preferencesHotKey, _enablePreferencesHotKey)}',
        onClick: (menuItem) {
          _showPreferences();
        },
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'toggle_visibility',
        label: 'Hide/Show\t${_formatHotkey(_visibilityHotKey, _enableVisibilityHotKey)}',
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
          _showOverlay('Opening Preferences', const Icon(LucideIcons.appWindow));
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

    _setupTray();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'preferences') {
      _showPreferences();
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
          print('Error closing windows: $error');
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
    _forceHide = !_forceHide;
    _showOverlay(_forceHide ? 'Keyboard Hidden' : 'Keyboard Shown',
        _forceHide ? const Icon(LucideIcons.eyeOff) : const Icon(LucideIcons.eye));
    if (_isWindowVisible) {
      _fadeOut();
    } else {
      _fadeIn();
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

  @override
  void onWindowMoved() {
    // AIDEV-NOTE: Save window position when user moves the window
    if (kDebugMode) print('🔧 Window moved, saving position...');
    _saveWindowPosition();
  }

  Future<void> _saveWindowPosition() async {
    try {
      final position = await windowManager.getPosition();
      await _prefsService.setWindowPosition(position);
    } catch (e) {
      // Ignore errors during position saving to avoid blocking window movement
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
        print('Error launching preferences: $e');
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
          _toggleAutoHide(autoHideEnabled);
        case 'updateAutoHideDuration':
          final autoHideDuration = call.arguments as double;
          setState(() => _autoHideDuration = autoHideDuration);
        case 'updateOpacity':
          final opacity = call.arguments as double;
          setState(() {
            _opacity = opacity;
            _lastOpacity = opacity;
          });
        case 'updateLayout':
          final layoutName = call.arguments as String;
          setState(() {
            if ((_kanataEnabled || _useUserLayout) && _advancedSettingsEnabled) {
              _initialKeyboardLayout =
                  availableLayouts.firstWhere((layout) => layout.name == layoutName);
            } else {
              _keyboardLayout = availableLayouts.firstWhere((layout) => layout.name == layoutName);
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
          setState(() => _keyTextColorNotPressed = Color(keyTextColorNotPressed));
        case 'updateKeyBorderColorPressed':
          final keyBorderColorPressed = call.arguments as int;
          setState(() => _keyBorderColorPressed = Color(keyBorderColorPressed));
        case 'updateKeyBorderColorNotPressed':
          final keyBorderColorNotPressed = call.arguments as int;
          setState(() => _keyBorderColorNotPressed = Color(keyBorderColorNotPressed));

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
              windowManager.setAlignment(Alignment.bottomCenter);
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
      theme: Platform.isMacOS ? ThemeData(
          fontFamily: _fontFamily,
          fontFamilyFallback: const ['GeistMono', 'Manrope', 'sans-serif'],
          // AIDEV-NOTE: Enhanced transparency configuration for macOS
          brightness: Brightness.light,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          platform: TargetPlatform.macOS,
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: Colors.transparent,
          cardColor: Colors.transparent,
          dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent)) : ThemeData(
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
                    child: KeyboardScreen(
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
                      showAltLayout: _advancedSettingsEnabled && _showAltLayout,
                      altLayout: _altLayout,
                      use6ColLayout: _use6ColLayout,
                      keyPressStates: _keyPressStates,
                      customShiftMappings: _customShiftMappings,
                      config: _userConfig,
                    ),
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
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
