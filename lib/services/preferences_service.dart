import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  // General settings
  Future<bool> getLaunchAtStartup() async =>
      await _prefs.getBool('launchAtStartup') ?? false;
  Future<bool> getAutoHideEnabled() async =>
      await _prefs.getBool('autoHideEnabled') ?? false;
  Future<double> getAutoHideDuration() async =>
      await _prefs.getDouble('autoHideDuration') ?? 2.0;
  Future<String> getKeyboardLayoutName() async =>
      await _prefs.getString('layout') ?? 'QWERTY';
  Future<bool> getEnableAdvancedSettings() async =>
      await _prefs.getBool('enableAdvancedSettings') ?? false;
  Future<bool> getUseUserLayout() async =>
      await _prefs.getBool('useUserLayout') ?? false;
  Future<bool> getShowAltLayout() async =>
      await _prefs.getBool('showAltLayout') ?? false;
  Future<bool> getKanataEnabled() async =>
      await _prefs.getBool('kanataEnabled') ?? false;

  // Appearance settings
  Future<double> getOpacity() async =>
      await _prefs.getDouble('opacity') ?? 0.6;
  Future<Color> getKeyColorPressed() async =>
      Color(await _prefs.getInt('keyColorPressed') ?? 0xFF1E1E1E);
  Future<Color> getKeyColorNotPressed() async =>
      Color(await _prefs.getInt('keyColorNotPressed') ?? 0xFF77ABFF);
  Future<Color> getMarkerColor() async =>
      Color(await _prefs.getInt('markerColor') ?? 0xFFFFFFFF);
  Future<Color> getMarkerColorNotPressed() async =>
      Color(await _prefs.getInt('markerColorNotPressed') ?? 0xFF000000);
  Future<double> getMarkerOffset() async =>
      await _prefs.getDouble('markerOffset') ?? 10;
  Future<double> getMarkerWidth() async =>
      await _prefs.getDouble('markerWidth') ?? 10;
  Future<double> getMarkerHeight() async =>
      await _prefs.getDouble('markerHeight') ?? 2;
  Future<double> getMarkerBorderRadius() async =>
      await _prefs.getDouble('markerBorderRadius') ?? 10;

  // Keyboard settings
  Future<String> getKeymapStyle() async =>
      await _prefs.getString('keymapStyle') ?? 'Staggered';
  Future<bool> getShowTopRow() async =>
      await _prefs.getBool('showTopRow') ?? false;
  Future<bool> getShowGraveKey() async =>
      await _prefs.getBool('showGraveKey') ?? false;
  Future<double> getKeySize() async =>
      await _prefs.getDouble('keySize') ?? 48;
  Future<double> getKeyBorderRadius() async =>
      await _prefs.getDouble('keyBorderRadius') ?? 12;
  Future<double> getKeyPadding() async =>
      await _prefs.getDouble('keyPadding') ?? 3;
  Future<double> getSpaceWidth() async =>
      await _prefs.getDouble('spaceWidth') ?? 320;
  Future<double> getSplitWidth() async =>
      await _prefs.getDouble('splitWidth') ?? 100;

  // Text settings
  Future<String> getFontFamily() async =>
      await _prefs.getString('fontFamily') ?? 'GeistMono';
  Future<double> getKeyFontSize() async =>
      await _prefs.getDouble('keyFontSize') ?? 20;
  Future<double> getSpaceFontSize() async =>
      await _prefs.getDouble('spaceFontSize') ?? 14;
  Future<FontWeight> getFontWeight() async => FontWeight
      .values[await _prefs.getInt('fontWeight') ?? FontWeight.w500.index];
  Future<Color> getKeyTextColor() async =>
      Color(await _prefs.getInt('keyTextColor') ?? 0xFFFFFFFF);
  Future<Color> getKeyTextColorNotPressed() async =>
      Color(await _prefs.getInt('keyTextColorNotPressed') ?? 0xFF000000);

  // HotKey settings
  Future<bool> getHotKeysEnabled() async =>
      await _prefs.getBool('enableHotKeys') ?? false;
  Future<HotKey?> getVisibilityHotKey() async {
    final json = await _prefs.getString('visibilityHotKey');
    try {
      return HotKey.fromJson(jsonDecode(json!));
    } catch (e) {
      return HotKey(
        key: PhysicalKeyboardKey.keyQ,
        modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
      );
    }
  }
  Future<HotKey?> getAutoHideHotKey() async {
    final json = await _prefs.getString('autoHideHotKey');
    try {
      return HotKey.fromJson(jsonDecode(json!));
    } catch (e) {
      return HotKey(
        key: PhysicalKeyboardKey.keyW,
        modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
      );
    }
  }

  // Save methods
  Future<void> setLaunchAtStartup(bool value) async =>
      await _prefs.setBool('launchAtStartup', value);
  Future<void> setAutoHideEnabled(bool value) async =>
      await _prefs.setBool('autoHideEnabled', value);
  Future<void> setAutoHideDuration(double value) async =>
      await _prefs.setDouble('autoHideDuration', value);
  Future<void> setKeyboardLayoutName(String value) async =>
      await _prefs.setString('layout', value);
  Future<void> setEnableAdvancedSettings(bool value) async =>
      await _prefs.setBool('enableAdvancedSettings', value);
  Future<void> setUseUserLayout(bool value) async =>
      await _prefs.setBool('useUserLayout', value);
  Future<void> setShowAltLayout(bool value) async =>
      await _prefs.setBool('showAltLayout', value);
  Future<void> setKanataEnabled(bool value) async =>
      await _prefs.setBool('kanataEnabled', value);

  Future<void> setOpacity(double value) async =>
      await _prefs.setDouble('opacity', value);
  Future<void> setKeyColorPressed(Color value) async =>
      await _prefs.setInt('keyColorPressed', value.toARGB32());
  Future<void> setKeyColorNotPressed(Color value) async =>
      await _prefs.setInt('keyColorNotPressed', value.toARGB32());
  Future<void> setMarkerColor(Color value) async =>
      await _prefs.setInt('markerColor', value.toARGB32());
  Future<void> setMarkerColorNotPressed(Color value) async =>
      await _prefs.setInt('markerColorNotPressed', value.toARGB32());
  Future<void> setMarkerOffset(double value) async =>
      await _prefs.setDouble('markerOffset', value);
  Future<void> setMarkerWidth(double value) async =>
      await _prefs.setDouble('markerWidth', value);
  Future<void> setMarkerHeight(double value) async =>
      await _prefs.setDouble('markerHeight', value);
  Future<void> setMarkerBorderRadius(double value) async =>
      await _prefs.setDouble('markerBorderRadius', value);

  Future<void> setKeymapStyle(String value) async =>
      await _prefs.setString('keymapStyle', value);
  Future<void> setShowTopRow(bool value) async =>
      await _prefs.setBool('showTopRow', value);
  Future<void> setShowGraveKey(bool value) async =>
      await _prefs.setBool('showGraveKey', value);
  Future<void> setKeySize(double value) async =>
      await _prefs.setDouble('keySize', value);
  Future<void> setKeyBorderRadius(double value) async =>
      await _prefs.setDouble('keyBorderRadius', value);
  Future<void> setKeyPadding(double value) async =>
      await _prefs.setDouble('keyPadding', value);
  Future<void> setSpaceWidth(double value) async =>
      await _prefs.setDouble('spaceWidth', value);
  Future<void> setSplitWidth(double value) async =>
      await _prefs.setDouble('splitWidth', value);

  Future<void> setFontFamily(String value) async =>
      await _prefs.setString('fontFamily', value);
  Future<void> setKeyFontSize(double value) async =>
      await _prefs.setDouble('keyFontSize', value);
  Future<void> setSpaceFontSize(double value) async =>
      await _prefs.setDouble('spaceFontSize', value);
  Future<void> setFontWeight(FontWeight value) async =>
      await _prefs.setInt('fontWeight', value.index);
  Future<void> setKeyTextColor(Color value) async =>
      await _prefs.setInt('keyTextColor', value.toARGB32());
  Future<void> setKeyTextColorNotPressed(Color value) async =>
      await _prefs.setInt('keyTextColorNotPressed', value.toARGB32());

  Future<void> setHotKeysEnabled(bool value) async =>
      await _prefs.setBool('enableHotKeys', value);
  Future<void> setVisibilityHotKey(HotKey value) async => 
      await _prefs.setString('visibilityHotKey', jsonEncode(value.toJson()));
  Future<void> setAutoHideHotKey(HotKey value) async =>
      await _prefs.setString('autoHideHotKey', jsonEncode(value.toJson()));

  Future<Map<String, dynamic>> loadAllPreferences() async {
    return {
      // General settings
      'launchAtStartup': await getLaunchAtStartup(),
      'autoHideEnabled': await getAutoHideEnabled(),
      'autoHideDuration': await getAutoHideDuration(),
      'keyboardLayoutName': await getKeyboardLayoutName(),
      'enableAdvancedSettings': await getEnableAdvancedSettings(),
      'useUserLayout': await getUseUserLayout(),
      'showAltLayout': await getShowAltLayout(),
      'kanataEnabled': await getKanataEnabled(),

      // Appearance settings
      'opacity': await getOpacity(),
      'keyColorPressed': await getKeyColorPressed(),
      'keyColorNotPressed': await getKeyColorNotPressed(),
      'markerColor': await getMarkerColor(),
      'markerColorNotPressed': await getMarkerColorNotPressed(),
      'markerOffset': await getMarkerOffset(),
      'markerWidth': await getMarkerWidth(),
      'markerHeight': await getMarkerHeight(),
      'markerBorderRadius': await getMarkerBorderRadius(),

      // Keyboard settings
      'keymapStyle': await getKeymapStyle(),
      'showTopRow': await getShowTopRow(),
      'showGraveKey': await getShowGraveKey(),
      'keySize': await getKeySize(),
      'keyBorderRadius': await getKeyBorderRadius(),
      'keyPadding': await getKeyPadding(),
      'spaceWidth': await getSpaceWidth(),
      'splitWidth': await getSplitWidth(),

      // Text settings
      'fontFamily': await getFontFamily(),
      'keyFontSize': await getKeyFontSize(),
      'spaceFontSize': await getSpaceFontSize(),
      'fontWeight': await getFontWeight(),
      'keyTextColor': await getKeyTextColor(),
      'keyTextColorNotPressed': await getKeyTextColorNotPressed(),

      // HotKey settings
      'hotKeysEnabled': await getHotKeysEnabled(),
      'visibilityHotKey': await getVisibilityHotKey(),
      'autoHideHotKey': await getAutoHideHotKey(),
    };
  }

  Future<void> saveAllPreferences(Map<String, dynamic> prefs) async {
    // General settings
    await setLaunchAtStartup(prefs['launchAtStartup']);
    await setAutoHideEnabled(prefs['autoHideEnabled']);
    await setAutoHideDuration(prefs['autoHideDuration']);
    await setKeyboardLayoutName(prefs['keyboardLayoutName']);
    await setEnableAdvancedSettings(prefs['enableAdvancedSettings']);
    await setUseUserLayout(prefs['useUserLayout']);
    await setShowAltLayout(prefs['showAltLayout']);
    await setKanataEnabled(prefs['kanataEnabled']);

    // Appearance settings
    await setOpacity(prefs['opacity']);
    await setKeyColorPressed(prefs['keyColorPressed']);
    await setKeyColorNotPressed(prefs['keyColorNotPressed']);
    await setMarkerColor(prefs['markerColor']);
    await setMarkerColorNotPressed(prefs['markerColorNotPressed']);
    await setMarkerOffset(prefs['markerOffset']);
    await setMarkerWidth(prefs['markerWidth']);
    await setMarkerHeight(prefs['markerHeight']);
    await setMarkerBorderRadius(prefs['markerBorderRadius']);

    // Keyboard settings
    await setKeymapStyle(prefs['keymapStyle']);
    await setShowTopRow(prefs['showTopRow']);
    await setShowGraveKey(prefs['showGraveKey']);
    await setKeySize(prefs['keySize']);
    await setKeyBorderRadius(prefs['keyBorderRadius']);
    await setKeyPadding(prefs['keyPadding']);
    await setSpaceWidth(prefs['spaceWidth']);
    await setSplitWidth(prefs['splitWidth']);

    // Text settings
    await setFontFamily(prefs['fontFamily']);
    await setKeyFontSize(prefs['keyFontSize']);
    await setSpaceFontSize(prefs['spaceFontSize']);
    await setFontWeight(prefs['fontWeight']);
    await setKeyTextColor(prefs['keyTextColor']);
    await setKeyTextColorNotPressed(prefs['keyTextColorNotPressed']);

    // HotKey settings
    await setHotKeysEnabled(prefs['hotKeysEnabled']);
    await setVisibilityHotKey(prefs['visibilityHotKey']);
    await setAutoHideHotKey(prefs['autoHideHotKey']);
  }
}