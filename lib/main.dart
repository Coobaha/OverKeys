import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'app.dart';
import 'screens/preferences_screen.dart';

/// Create and configure the preferences window (called from sub-window context)
Future<void> _createPreferencesWindow(WindowController controller) async {
  if (Platform.isMacOS) {
    await Future.delayed(const Duration(milliseconds: 200));
    WidgetsBinding.instance.scheduleFrame();
  }

  // Configure window via window_manager
  await windowManager.setTitle("OverKeys Preferences");
  await windowManager.setSize(const Size(1280, 720));
  await windowManager.setMinimumSize(const Size(828, 621));

  // Position at top-center of screen
  final screenBounds = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first)
      .size;
  final windowSize = const Size(1280, 720);
  final xPosition = (screenBounds.width - windowSize.width) / 2;
  final maxX = (screenBounds.width - windowSize.width - 50).clamp(0.0, double.infinity);
  await windowManager.setPosition(Offset(xPosition.clamp(50.0, maxX.clamp(50.0, double.infinity)), 50));

  await controller.show();
  await windowManager.focus();

  runApp(MaterialApp(
    title: 'OverKeys Preferences',
    theme: Platform.isMacOS
        ? ThemeData(
            brightness: Brightness.light,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            platform: TargetPlatform.macOS,
          )
        : ThemeData.dark().copyWith(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            platform: TargetPlatform.windows,
          ),
    home: PreferencesScreen(windowController: controller),
    debugShowCheckedModeBanner: false,
  ));
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    await Future.delayed(const Duration(milliseconds: 100));
    WidgetsBinding.instance.scheduleFrame();
  }

  await windowManager.ensureInitialized();

  // Handle sub-window creation via desktop_multi_window
  // When WindowController.create() is called, it spawns a new isolate with window ID in args
  if (args.isNotEmpty) {
    // This is a sub-window - get the controller with proper arguments from native side
    final controller = await WindowController.fromCurrentEngine();

    // The arguments property contains what was passed in WindowConfiguration
    if (controller.arguments == 'preferences') {
      await _createPreferencesWindow(controller);
      return;
    }
  }

  // Main window initialization
  await hotKeyManager.unregisterAll();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    packageName: packageInfo.packageName,
  );

  double windowWidth = 1000;
  double windowHeight = 330;

  WindowOptions windowOptions = Platform.isMacOS
      ? WindowOptions(
          skipTaskbar: true,
          title: "OverKeys",
          titleBarStyle: TitleBarStyle.hidden,
        )
      : WindowOptions(
          backgroundColor: Colors.transparent,
          skipTaskbar: true,
          title: "OverKeys",
          titleBarStyle: TitleBarStyle.hidden,
        );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (Platform.isMacOS) {
      await windowManager.setSize(Size(windowWidth, windowHeight));
      await windowManager.setSkipTaskbar(true);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.setAsFrameless();
      await windowManager.setIgnoreMouseEvents(true);
    } else {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setAsFrameless();
      await windowManager.setSize(Size(windowWidth, windowHeight));
      await windowManager.setIgnoreMouseEvents(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.show();
    }
  });

  runApp(const MainApp());
}
