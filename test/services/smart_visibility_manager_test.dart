import 'package:flutter_test/flutter_test.dart';
import 'package:overkeys/services/smart_visibility_manager.dart';

void main() {
  group('SmartVisibilityManager Tests', () {
    late SmartVisibilityManager manager;
    
    setUp(() {
      manager = SmartVisibilityManager(
        defaultLayerDelay: 500.0,
        customLayerDelay: 1000.0,
        debugEnabled: false,
      );
    });

    tearDown(() {
      manager.dispose();
    });

    test('should show on inactivity when conditions are met', () {
      manager.setLayerState(true);
      
      final shouldShow = manager.shouldShowOnInactivity(
        useUserLayouts: true,
        advancedSettingsEnabled: true,
        forceHidden: false,
        windowVisible: false,
        hasDefaultLayout: true,
      );
      
      expect(shouldShow, isTrue);
    });

    test('should not show when user layouts disabled', () {
      manager.setLayerState(true);
      
      final shouldShow = manager.shouldShowOnInactivity(
        useUserLayouts: false, // Disabled
        advancedSettingsEnabled: true,
        forceHidden: false,
        windowVisible: false,
        hasDefaultLayout: true,
      );
      
      expect(shouldShow, isFalse);
    });

    test('should not show when force hidden', () {
      manager.setLayerState(true);
      
      final shouldShow = manager.shouldShowOnInactivity(
        useUserLayouts: true,
        advancedSettingsEnabled: true,
        forceHidden: true, // Force hidden
        windowVisible: false,
        hasDefaultLayout: true,
      );
      
      expect(shouldShow, isFalse);
    });

    test('should not show when already visible', () {
      manager.setLayerState(true);
      
      final shouldShow = manager.shouldShowOnInactivity(
        useUserLayouts: true,
        advancedSettingsEnabled: true,
        forceHidden: false,
        windowVisible: true, // Already visible
        hasDefaultLayout: true,
      );
      
      expect(shouldShow, isFalse);
    });

    test('should use correct delay for default layer', () async {
      bool showCalled = false;
      
      manager.startInactivityTimer('default', true, () {
        showCalled = true;
      });
      
      // Should not trigger before delay
      await Future.delayed(Duration(milliseconds: 400));
      expect(showCalled, isFalse);
      
      // Should trigger after delay
      await Future.delayed(Duration(milliseconds: 200));
      expect(showCalled, isTrue);
    });

    test('should use correct delay for custom layer', () async {
      bool showCalled = false;
      
      manager.startInactivityTimer('custom', false, () {
        showCalled = true;
      });
      
      // Should not trigger before delay
      await Future.delayed(Duration(milliseconds: 900));
      expect(showCalled, isFalse);
      
      // Should trigger after delay  
      await Future.delayed(Duration(milliseconds: 200));
      expect(showCalled, isTrue);
    });

    test('should cancel timer and prevent show', () async {
      bool showCalled = false;
      
      manager.startInactivityTimer('test', false, () {
        showCalled = true;
      });
      
      // Cancel before timer expires
      await Future.delayed(Duration(milliseconds: 500));
      manager.cancelTimer();
      
      // Wait past original delay
      await Future.delayed(Duration(milliseconds: 600));
      expect(showCalled, isFalse);
    });

    test('should handle layer change during timer', () async {
      bool showCalled = false;
      
      manager.setLayerState(true);
      manager.startInactivityTimer('layer1', false, () {
        showCalled = true;
      });
      
      // Start timer for different layer (should cancel previous)
      await Future.delayed(Duration(milliseconds: 500));
      manager.startInactivityTimer('layer2', false, () {
        showCalled = true;
      });
      
      // Wait for original timer period
      await Future.delayed(Duration(milliseconds: 600));
      expect(showCalled, isFalse); // Should not trigger for layer1
      
      // Wait for new timer period
      await Future.delayed(Duration(milliseconds: 500));
      expect(showCalled, isTrue); // Should trigger for layer2
    });

    test('should skip overlay for quick succession of any key', () async {
      bool showCalled = false;
      
      manager.updateLayerState(layerName: 'test', isInToggledLayer: true);
      
      // First keypress - should start timer
      manager.resetInactivityTimer('test', () {
        showCalled = true;
      }, pressedKey: 'f7');
      
      // Quick succession of any key within window - should skip timer
      await Future.delayed(Duration(milliseconds: 100));
      manager.resetInactivityTimer('test', () {
        showCalled = true;
      }, pressedKey: 'f8'); // Different key, but still within window
      
      // Wait past original delay
      await Future.delayed(Duration(milliseconds: 1200));
      expect(showCalled, isFalse); // Should not show due to quick succession
    });

    test('should skip overlay for different keys within window', () async {
      bool showCalled = false;
      
      manager.updateLayerState(layerName: 'test', isInToggledLayer: true);
      
      // First keypress
      manager.resetInactivityTimer('test', () {
        showCalled = true;
      }, pressedKey: 'f7');
      
      // Different key within window - should also skip
      await Future.delayed(Duration(milliseconds: 100));
      manager.resetInactivityTimer('test', () {
        showCalled = true;
      }, pressedKey: 'f8');
      
      // Wait for the delay
      await Future.delayed(Duration(milliseconds: 1200));
      expect(showCalled, isFalse); // Should not show - any key within window skips
    });

    test('should allow overlay for same key after window expires', () async {
      bool showCalled = false;
      
      manager.updateLayerState(layerName: 'test', isInToggledLayer: true);
      
      // First keypress
      manager.resetInactivityTimer('test', () {
        showCalled = true;
      }, pressedKey: 'f7');
      
      // Same key after window expires - should restart timer normally
      await Future.delayed(Duration(milliseconds: 300)); // > 200ms window
      manager.resetInactivityTimer('test', () {
        showCalled = true;
      }, pressedKey: 'f7');
      
      // Wait for the delay
      await Future.delayed(Duration(milliseconds: 1200));
      expect(showCalled, isTrue); // Should show after window expires
    });
  });
}