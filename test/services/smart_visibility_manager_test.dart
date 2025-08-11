import 'package:flutter_test/flutter_test.dart';
import 'package:overkeys/services/smart_visibility_manager.dart';
import 'package:overkeys/models/keyboard_layouts.dart';

void main() {
  group('SmartVisibilityManager Tests', () {
    late SmartVisibilityManager manager;
    bool fadeInCalled = false;
    List<String> callbackLog = [];

    setUp(() {
      fadeInCalled = false;
      callbackLog.clear();

      manager = SmartVisibilityManager(
        defaultLayerDelay: 10.0,
        customLayerDelay: 30.0,
        quickSuccessionWindow: 15.0,
        debugEnabled: false,
        onFadeIn: () {
          fadeInCalled = true;
          callbackLog.add('fadeIn');
        },
        onFadeOut: () {
          callbackLog.add('fadeOut');
        },
      );

      // Register test layers
      manager.registerLayer('GRAPHITE', qwerty);
      manager.registerLayer('Cursor', qwerty);
      manager.registerLayer('Number', qwerty);
      manager.setDefaultLayer('GRAPHITE');
    });

    tearDown(() {
      manager.dispose();
    });

    // Test: Basic timer functionality for default layer
    test('should show default layer after configured delay', () async {
      manager.showWithDelay('GRAPHITE');

      // Should not show immediately
      expect(fadeInCalled, isFalse);

      await Future.delayed(Duration(milliseconds: 10));
      expect(fadeInCalled, isTrue);
    });

    // Test: Basic timer functionality for custom layer
    test('should show custom layer after configured delay', () async {
      // Set layer state to toggled for custom layer timer to work
      manager.updateLayerState(layerName: 'Cursor', isInToggledLayer: true);
      manager.showWithDelay('Cursor');

      // Should not show immediately
      expect(fadeInCalled, isFalse);

      // Should not show before delay
      await Future.delayed(Duration(milliseconds: 20));
      expect(fadeInCalled, isFalse);

      // Should show after 30ms delay
      await Future.delayed(Duration(milliseconds: 20));
      expect(fadeInCalled, isTrue);
    });

    // Test: Timer cancellation
    test('should cancel timer and prevent show', () async {
      manager.updateLayerState(layerName: 'Cursor', isInToggledLayer: true);
      manager.showWithDelay('Cursor');

      // Cancel after 15ms
      await Future.delayed(Duration(milliseconds: 15));
      manager.cancelAllTimers();

      // Wait past original delay
      await Future.delayed(Duration(milliseconds: 20));
      expect(fadeInCalled, isFalse);
    });

    // Test: Toggle layer ON/OFF behavior
    test('should toggle custom layer ON and OFF correctly', () {
      // Toggle ON
      final resultOn = manager.handleToggleLayer('Cursor',
          defaultLayerName: 'GRAPHITE', isWindowVisible: false);

      expect(resultOn.type, LayerTransitionType.turnOn);
      expect(resultOn.targetLayerName, 'Cursor');
      expect(manager.isInToggledLayer, isTrue);
      expect(manager.currentLayerName, 'Cursor');

      // Toggle OFF (same layer)
      final resultOff = manager.handleToggleLayer('Cursor',
          defaultLayerName: 'GRAPHITE', isWindowVisible: true);

      expect(resultOff.type, LayerTransitionType.turnOff);
      expect(resultOff.targetLayerName, 'GRAPHITE');
      expect(manager.isInToggledLayer, isFalse);
      expect(manager.currentLayerName, 'GRAPHITE');
    });

    // Test: Layer stack push/pop behavior
    test('should maintain layer stack for proper restoration', () {
      // Start with GRAPHITE visible
      expect(manager.layerStack.length, 0);

      // Toggle to Cursor (pushes GRAPHITE)
      manager.handleToggleLayer('Cursor',
          defaultLayerName: 'GRAPHITE', isWindowVisible: true);
      expect(manager.layerStack.length, 1);
      expect(manager.layerStack.first.layerName, 'GRAPHITE');
      expect(manager.layerStack.first.wasVisible, isTrue);

      // Toggle to Number (pushes Cursor)
      manager.handleToggleLayer('Number',
          defaultLayerName: 'GRAPHITE', isWindowVisible: false);
      expect(manager.layerStack.length, 2);
      expect(manager.layerStack.last.layerName, 'Cursor');

      // Toggle OFF Number (pops to Cursor)
      final result = manager.handleToggleLayer('Number',
          defaultLayerName: 'GRAPHITE', isWindowVisible: true);
      expect(result.targetLayerName, 'Cursor');
      expect(manager.layerStack.length, 1);
    });

    // Test: Default layer timer logic (fixed bug)
    test('should show default layer even when not in toggled state', () async {
      manager.updateLayerState(layerName: 'GRAPHITE', isInToggledLayer: false);

      manager.resetInactivityTimer('GRAPHITE', () {
        fadeInCalled = true;
      });

      await Future.delayed(Duration(milliseconds: 30));
      expect(fadeInCalled, isTrue);
    });

    // Test: Custom layer timer requires toggled state
    test('should not show custom layer when not in toggled state', () async {
      manager.updateLayerState(layerName: 'Cursor', isInToggledLayer: false);

      manager.resetInactivityTimer('Cursor', () {
        fadeInCalled = true;
      });

      // Custom layer should NOT show when isInToggledLayer = false
      await Future.delayed(Duration(milliseconds: 30));
      expect(fadeInCalled, isFalse);
    });

    // Test: Quick succession detection suppresses overlay for entire session
    test(
        'should suppress overlay within quick succession window for entire session',
        () async {
      manager.updateLayerState(layerName: 'Cursor', isInToggledLayer: true);

      // First keypress - should be ignored (activation trigger)
      manager.resetInactivityTimer('Cursor', () {
        fadeInCalled = true;
      }, pressedKey: 'F19');

      await Future.delayed(Duration(milliseconds: 5)); // Within 15ms window

      // Second keypress within window - should suppress entire session
      manager.resetInactivityTimer('Cursor', () {
        fadeInCalled = true;
      }, pressedKey: 'A');

      await Future.delayed(
          Duration(milliseconds: 10)); // Allow quick succession to be detected

      // Third keypress - should still be suppressed (entire session)
      manager.resetInactivityTimer('Cursor', () {
        fadeInCalled = true;
      }, pressedKey: 'B');

      // Wait past delay - should not show due to suppression for entire session
      await Future.delayed(Duration(milliseconds: 50));
      expect(fadeInCalled, isFalse);
    });

    // Test: Configuration updates
    test('should update delays and quick succession window', () {
      expect(manager.defaultLayerDelay, 10.0);
      expect(manager.customLayerDelay, 30.0);
      expect(manager.quickSuccessionWindow, 15.0);

      manager.updateConfiguration(
        defaultLayerDelay: 300.0,
        customLayerDelay: 1500.0,
        quickSuccessionWindow: 150.0,
        debugEnabled: true,
      );

      expect(manager.defaultLayerDelay, 300.0);
      expect(manager.customLayerDelay, 1500.0);
      expect(manager.quickSuccessionWindow, 150.0);
      expect(manager.debugEnabled, isTrue);
    });

    // Test: Layer registry functionality
    test('should register and retrieve layers correctly', () {
      expect(manager.getLayer('GRAPHITE'), isNotNull);
      expect(manager.getLayer('Cursor'), isNotNull);
      expect(manager.getLayer('NonExistent'), isNull);

      final testLayout = qwerty;
      manager.registerLayer('TestLayer', testLayout);
      expect(manager.getLayer('TestLayer'), testLayout);

      manager.clearLayers();
      expect(manager.getLayer('GRAPHITE'), isNull);
    });

    // Test: Held layer behavior
    test('should handle held layer press and release', () {
      // Press held layer
      final pressResult = manager.handleHeldLayerPress('Cursor');
      expect(pressResult.type, LayerTransitionType.held);
      expect(manager.currentLayerName, 'Cursor');
      expect(manager.activeTriggers.contains('Cursor'), isTrue);

      // Release held layer
      final releaseResult = manager.handleHeldLayerRelease('GRAPHITE');
      expect(releaseResult.type, LayerTransitionType.heldRelease);
      expect(manager.currentLayerName, 'GRAPHITE');
      expect(manager.activeTriggers.isEmpty, isTrue);
    });

    // Test: Key event handling integration
    test('should handle complex key event scenarios', () {
      final triggers = {
        'Cursor': 'cmd+alt+ctrl+shift+F19',
        'Number': 'cmd+alt+ctrl+shift+F18',
      };

      // Toggle layer activation
      final result1 = manager.handleKeyEvent(
        key: 'F19',
        isPressed: true,
        triggers: triggers,
        useUserLayouts: true,
        advancedSettingsEnabled: true,
        hasDefaultLayout: true,
        isWindowVisible: false,
        onShow: () => fadeInCalled = true,
        defaultLayerName: 'GRAPHITE',
        isShiftDown: true,
        isCtrlDown: true,
        isAltDown: true,
        isCmdDown: true,
      );

      expect(result1.shouldConsume, isTrue);
      expect(result1.transition?.type, LayerTransitionType.turnOn);
      expect(manager.isInToggledLayer, isTrue);

      // Toggle same layer OFF
      final result2 = manager.handleKeyEvent(
        key: 'F19',
        isPressed: true,
        triggers: triggers,
        useUserLayouts: true,
        advancedSettingsEnabled: true,
        hasDefaultLayout: true,
        isWindowVisible: true,
        onShow: () => fadeInCalled = true,
        defaultLayerName: 'GRAPHITE',
        isShiftDown: true,
        isCtrlDown: true,
        isAltDown: true,
        isCmdDown: true,
      );

      expect(result2.shouldConsume, isTrue);
      expect(result2.transition?.type, LayerTransitionType.turnOff);
      expect(manager.isInToggledLayer, isFalse);
    });

    // Test: Reset behavior on layer state changes
    test('should reset flags when toggling layers', () {
      // Enter layer - sets flags
      manager.updateLayerState(layerName: 'Cursor', isInToggledLayer: true);

      // Simulate suppression activation
      manager.resetInactivityTimer('Cursor', () {}, pressedKey: 'A');
      manager.resetInactivityTimer('Cursor', () {},
          pressedKey: 'B'); // This should suppress

      // Exit layer - should reset flags
      manager.updateLayerState(layerName: 'GRAPHITE', isInToggledLayer: false);

      // Re-enter layer - flags should be reset
      manager.updateLayerState(layerName: 'Cursor', isInToggledLayer: true);

      // Timer should work normally now
      manager.resetInactivityTimer('Cursor', () {
        fadeInCalled = true;
      });

      // Should show after delay (suppression was reset)
      expectLater(
          Future.delayed(Duration(milliseconds: 30)).then((_) => fadeInCalled),
          completion(isTrue));
    });
  });
}
