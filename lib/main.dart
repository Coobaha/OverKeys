import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'app.dart';
import 'screens/preferences_screen.dart';

// AIDEV-NOTE: Simplified preferences window creation to avoid race conditions
Future<void> _createPreferencesWindow() async {
  // AIDEV-NOTE: Ensure Flutter is fully initialized before creating window
  if (Platform.isMacOS) {
    await Future.delayed(const Duration(milliseconds: 200));
    WidgetsBinding.instance.scheduleFrame();
  }

  const windowOptions = WindowOptions(
    title: "OverKeys Preferences",
    titleBarStyle: TitleBarStyle.normal,
    size: Size(1280, 720),
    center: false, // Don't auto-center
    minimumSize: Size(828, 621),
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitle("OverKeys Preferences");
    final String iconPath = Platform.isWindows
        ? "assets/images/app_icon.ico"
        : "assets/images/app_icon.png";
    await windowManager.setIcon(iconPath);
    await windowManager.setMinimumSize(const Size(828, 621));
    await windowManager.setSize(const Size(1280, 720)); // Ensure proper size

    // AIDEV-NOTE: Position at top-center of screen for better UX
    final screenBounds = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first)
        .size;
    final windowSize = const Size(1280, 720);
    final xPosition = (screenBounds.width - windowSize.width) / 2;
    // Force position to top of screen, away from bottom overlay
    await windowManager.setPosition(Offset(
        xPosition.clamp(50, screenBounds.width - windowSize.width - 50), 50));
    await windowManager.setSkipTaskbar(false);

    if (Platform.isMacOS) {
      // AIDEV-NOTE: macOS needs show() before focus() to avoid black screen
      await windowManager.show();
      await windowManager.focus();
    } else {
      await windowManager.focus();
      await windowManager.show();
    }
  });

  runApp(MaterialApp(
    title: 'OverKeys Preferences',
    theme: Platform.isMacOS
        ? ThemeData(
            // AIDEV-NOTE: Use light theme for macOS to avoid rendering issues
            brightness: Brightness.light,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            platform: TargetPlatform.macOS,
          )
        : ThemeData.dark().copyWith(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            platform: TargetPlatform.windows,
          ),
    home: PreferencesScreen(windowController: WindowController.fromWindowId(0)),
    debugShowCheckedModeBanner: false,
  ));
}

// AIDEV-NOTE: Multi-window preferences creation with proper window ID
Future<void> _createMultiWindowPreferences(int windowId) async {
  if (Platform.isMacOS) {
    await Future.delayed(const Duration(milliseconds: 200));
    WidgetsBinding.instance.scheduleFrame();
  }

  const windowOptions = WindowOptions(
    title: "OverKeys Preferences",
    titleBarStyle: TitleBarStyle.normal,
    size: Size(1280, 720),
    center: false, // Don't auto-center
    minimumSize: Size(828, 621),
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setTitle("OverKeys Preferences");
    final String iconPath = Platform.isWindows
        ? "assets/images/app_icon.ico"
        : "assets/images/app_icon.png";
    await windowManager.setIcon(iconPath);
    await windowManager.setMinimumSize(const Size(828, 621));
    await windowManager.setSize(const Size(1280, 720)); // Ensure proper size

    final screenBounds = MediaQueryData.fromView(
            WidgetsBinding.instance.platformDispatcher.views.first)
        .size;
    final windowSize = const Size(1280, 720);
    final xPosition = (screenBounds.width - windowSize.width) / 2;
    await windowManager.setPosition(Offset(
        xPosition.clamp(50, screenBounds.width - windowSize.width - 50), 50));
    await windowManager.setSkipTaskbar(false);

    if (Platform.isMacOS) {
      await windowManager.show();
      await windowManager.focus();
    } else {
      await windowManager.focus();
      await windowManager.show();
    }
  });

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
    home: PreferencesScreen(
        windowController: WindowController.fromWindowId(windowId)),
    debugShowCheckedModeBanner: false,
  ));
}

void main(List<String> args) async {
  final isSubWindow = args.firstOrNull == 'multi_window';

  // AIDEV-NOTE: Ensure proper Flutter engine initialization for macOS
  WidgetsFlutterBinding.ensureInitialized();

  // AIDEV-NOTE: macOS-specific initialization
  if (Platform.isMacOS) {
    await Future.delayed(const Duration(milliseconds: 100));
    WidgetsBinding.instance.scheduleFrame();
  }

  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  // Check for preferences argument (simplified single path)
  if (args.isNotEmpty && args[0] == "preferences") {
    await _createPreferencesWindow();
    return;
  }

  if (isSubWindow) {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;

    if (arguments["name"] == "preferences") {
      await _createMultiWindowPreferences(windowId);
    }
  } else {
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
        // AIDEV-NOTE: macOS transparency with native Swift support
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
}
