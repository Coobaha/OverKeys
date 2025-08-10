import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var keyboardMonitor: KeyboardMonitor?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    // AIDEV-NOTE: Overlay visibility should control optimization, not app focus
  }
  
  func setKeyboardMonitor(_ monitor: KeyboardMonitor) {
    self.keyboardMonitor = monitor
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
