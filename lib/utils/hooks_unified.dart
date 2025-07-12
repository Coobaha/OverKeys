import 'dart:isolate';
import 'dart:io';

SendPort? sendPort;

void setHook(SendPort port) {
  sendPort = port;

  if (Platform.isMacOS) {
    throw UnsupportedError(
        'macOS keyboard monitoring cannot be done from isolates. Use KeyboardService directly in the main isolate.');
  } else if (Platform.isWindows) {
    // Windows implementation would go here
    throw UnimplementedError('Windows keyboard monitoring not implemented yet');
  } else {
    throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported');
  }
}

void unhook() {
  // No cleanup needed since we don't support isolate-based keyboard monitoring
}
