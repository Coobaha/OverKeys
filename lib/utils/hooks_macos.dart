import 'dart:isolate';
import '../services/platform/keyboard_service.dart';

late KeyboardService _keyboardService;
SendPort? sendPort;

void setHook(SendPort port) {
  sendPort = port;
  _keyboardService = KeyboardService.create();
  
  _keyboardService.startMonitoring((List<dynamic> message) {
    sendPort?.send(message);
    
    // Handle session events - for macOS we could add sleep/wake detection here
    // For now, just pass through the keyboard events
  });
}

void unhook() {
  _keyboardService.stopMonitoring();
  _keyboardService.dispose();
}