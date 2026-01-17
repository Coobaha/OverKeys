import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Channel name for main window communication
const kMainWindowChannel = 'overkeys/main_window';

/// Channel name for preferences window communication
const kPreferencesChannel = 'overkeys/preferences';

/// Extension on WindowController to add close functionality via method channel
extension WindowControllerExtension on WindowController {
  /// Close the window by invoking window_close on its method handler
  Future<void> close() async {
    try {
      await invokeMethod('window_close');
    } catch (e) {
      // Window may already be closed or handler not set up
    }
  }
}

/// Service for managing multi-window communication
class MultiWindowService {
  MultiWindowService._();
  static final instance = MultiWindowService._();

  WindowController? _currentController;
  bool _isMainWindow = false;

  /// Initialize the service for the current window
  Future<void> initialize({required bool isMainWindow}) async {
    _isMainWindow = isMainWindow;
    _currentController = await WindowController.fromCurrentEngine();
  }

  /// Get the current window controller
  WindowController? get currentController => _currentController;

  /// Check if this is the main window
  bool get isMainWindow => _isMainWindow;

  /// Set up the method handler for this window
  /// The handler receives calls from other windows
  Future<void> setMethodHandler(
      Future<dynamic> Function(MethodCall call)? handler) async {
    if (_currentController == null) return;

    await _currentController!.setWindowMethodHandler(handler != null
        ? (call) async {
            if (call.method == 'window_close') {
              await windowManager.close();
              return null;
            }
            return await handler(call);
          }
        : null);
  }

  /// Get all sub-windows (excluding main window)
  Future<List<WindowController>> getAllSubWindows() async {
    final all = await WindowController.getAll();
    // Filter out main window (first one or check arguments)
    if (all.isEmpty) return [];

    // Return all except the first one (main window)
    return all.length > 1 ? all.sublist(1) : [];
  }

  /// Invoke method on all sub-windows
  Future<void> invokeMethodOnAllSubWindows(String method,
      [dynamic arguments]) async {
    final subWindows = await getAllSubWindows();
    for (final controller in subWindows) {
      try {
        await controller.invokeMethod(method, arguments);
      } catch (e) {
        // Window may not have handler set up yet
      }
    }
  }

  /// Invoke method on main window
  /// This requires the main window to have registered its method handler
  Future<dynamic> invokeMethodOnMainWindow(String method,
      [dynamic arguments]) async {
    final all = await WindowController.getAll();
    if (all.isEmpty) return null;

    // Main window is the first one
    try {
      return await all.first.invokeMethod(method, arguments);
    } catch (e) {
      // Main window handler may not be ready
      return null;
    }
  }
}
