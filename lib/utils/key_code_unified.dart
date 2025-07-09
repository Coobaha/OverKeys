import 'dart:io';

// Import platform-specific implementations
import 'key_code.dart' as windows_keys;
import 'key_code_macos.dart' as macos_keys;

// Export the string key mapping function for external use
export 'key_code_macos.dart' show getKeyFromStringKeyShift;

/// Unified key code mapping that works across platforms
String getKeyFromKeyCodeShift(int keyCode, bool isShiftDown) {
  if (Platform.isWindows) {
    return windows_keys.getKeyFromKeyCodeShift(keyCode, isShiftDown);
  } else if (Platform.isMacOS) {
    return macos_keys.getKeyFromKeyCodeShift(keyCode, isShiftDown);
  } else {
    throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
  }
}

/// Unified string key name mapping for macOS events
String getKeyFromStringKeyShift(String keyName, bool isShiftDown) {
  if (Platform.isMacOS) {
    return macos_keys.getKeyFromStringKeyShift(keyName, isShiftDown);
  } else {
    // For other platforms, assume the keyName is already correct
    return keyName;
  }
}