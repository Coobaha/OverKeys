import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/user_config.dart';
import '../models/keyboard_layouts.dart';

class ConfigService {
  static const String _configFileName = 'overkeys_config.json';
  static const String _reloadTriggerFileName = '.reload_trigger';
  static UserConfig? _cachedConfig;

  Future<String> get _configPath async {
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, _configFileName);
  }

  Future<String> get _reloadTriggerPath async {
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, _reloadTriggerFileName);
  }

  Future<String> get configPath => _configPath;

  static void clearCache() {
    _cachedConfig = null;
  }

  /// Signal that config should be reloaded (for cross-process IPC)
  Future<void> signalReload() async {
    final triggerPath = await _reloadTriggerPath;
    final file = File(triggerPath);
    await file.writeAsString(DateTime.now().toIso8601String());
  }

  /// Check if reload was signaled and clear the trigger
  Future<bool> checkAndClearReloadSignal() async {
    final triggerPath = await _reloadTriggerPath;
    final file = File(triggerPath);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Get the config directory path for file watching
  Future<String> get configDirectoryPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<UserConfig> loadConfig({bool forceReload = false}) async {
    if (_cachedConfig != null && !forceReload) {
      return _cachedConfig!;
    }

    try {
      final path = await _configPath;
      final file = File(path);

      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        _cachedConfig = UserConfig.fromJson(json);
      } else {
        _cachedConfig = UserConfig();
        await saveConfig(_cachedConfig!);
      }
    } on FormatException catch (e) {
      debugPrint('Config parse error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error loading config: $e');
      _cachedConfig = UserConfig();
    }

    return _cachedConfig!;
  }

  Future<void> saveConfig(UserConfig config) async {
    try {
      final path = await _configPath;
      final file = File(path);
      final jsonString = jsonEncode(config.toJson());
      await file.writeAsString(jsonString);
      _cachedConfig = config;
    } catch (e) {
      debugPrint('Error saving config: $e');
    }
  }

  Future<KeyboardLayout?> getUserLayout() async {
    final config = await loadConfig();

    if (config.defaultUserLayout == null) {
      debugPrint(
          'Cannot get user layout: defaultUserLayout is not defined in the config file');
      return null;
    }

    final defaultLayoutName = config.defaultUserLayout;

    if (config.userLayouts != null) {
      for (final layout in config.userLayouts!) {
        if (layout.name == defaultLayoutName) {
          return layout;
        }
      }
    }

    try {
      return availableLayouts
          .firstWhere((layout) => layout.name == defaultLayoutName);
    } catch (e) {
      if (kDebugMode) {
        print('Default user layout "$defaultLayoutName" not found');
      }
      return null;
    }
  }

  Future<KeyboardLayout?> getAltLayout() async {
    final config = await loadConfig();

    if (config.altLayout == null) {
      debugPrint(
          'Cannot get alt layout: altLayout is not defined in the config file');
      return null;
    }

    final altLayoutName = config.altLayout;

    if (config.userLayouts != null) {
      for (final layout in config.userLayouts!) {
        if (layout.name == altLayoutName) {
          return layout;
        }
      }
    }

    try {
      return availableLayouts
          .firstWhere((layout) => layout.name == altLayoutName);
    } catch (e) {
      if (kDebugMode) {
        print('Alt layout "$altLayoutName" not found');
      }
      return null;
    }
  }

  Future<String?> getCustomFont() async {
    final config = await loadConfig();

    if (config.customFont == null) {
      debugPrint(
          'Cannot get custom font: customFont is not defined in the config file');
      return null;
    }

    return config.customFont;
  }

  Future<Map<String, String>?> getCustomShiftMappings() async {
    final config = await loadConfig();
    return config.customShiftMappings;
  }

  Future<Map<String, String>?> getActionMappings() async {
    final config = await loadConfig();
    return config.actionMappings;
  }

  Future<CycleGroup?> getCycleGroup() async {
    final config = await loadConfig();
    return config.cycleGroup;
  }

  Future<UserConfig?> getConfig() async {
    return await loadConfig();
  }

  Future<List<KeyboardLayout>?> getUserLayers() async {
    final config = await loadConfig();
    List<KeyboardLayout> layers = [];

    if (config.userLayouts != null) {
      layers.addAll(config.userLayouts!.where((l) => l.trigger != null));
    }

    return layers;
  }

  /// Get all user layouts (including those without triggers, for cycle group)
  Future<List<KeyboardLayout>?> getAllUserLayouts() async {
    final config = await loadConfig();
    return config.userLayouts;
  }
}
