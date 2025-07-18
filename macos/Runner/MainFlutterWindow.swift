import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var keyboardMonitor: KeyboardMonitor?
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    
    // AIDEV-NOTE: Enhanced transparency approach based on GitHub research
    // Set FlutterViewController background to clear BEFORE setting as content view
    flutterViewController.backgroundColor = NSColor.clear
    
    // AIDEV-NOTE: Additional FlutterView transparency workarounds
    let flutterView = flutterViewController.view
    // Force the view hierarchy to use transparent backgrounds
    flutterView.setValue(false, forKey: "opaque")
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // AIDEV-NOTE: Comprehensive NSWindow transparency configuration
    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    self.hasShadow = false
    
    // AIDEV-NOTE: Enhanced FlutterView transparency configuration
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.backgroundColor = NSColor.clear.cgColor
    flutterViewController.view.layer?.isOpaque = false
    
    // AIDEV-NOTE: Optional NSVisualEffectView for blur effects
    // Enable with: FLUTTER_BLUR_EFFECT=true environment variable
    if ProcessInfo.processInfo.environment["FLUTTER_BLUR_EFFECT"] == "true" {
      setupVisualEffectView(flutterViewController: flutterViewController)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // AIDEV-NOTE: Debug transparency configuration (only in debug builds)
    #if DEBUG
    print("🔍 MainFlutterWindow transparency configured:")
    print("  - NSWindow.backgroundColor: \(String(describing: self.backgroundColor))")
    print("  - NSWindow.isOpaque: \(self.isOpaque)")
    print("  - FlutterViewController.backgroundColor: \(String(describing: flutterViewController.backgroundColor))")
    print("  - FlutterView.layer.backgroundColor: \(flutterViewController.view.layer?.backgroundColor as Any)")
    #endif

    // Setup keyboard monitoring channel
    setupKeyboardMonitoring(flutterViewController: flutterViewController)

    super.awakeFromNib()
  }
  
  private func setupKeyboardMonitoring(flutterViewController: FlutterViewController) {
    // Create keyboard monitoring channel
    let keyboardChannel = FlutterMethodChannel(
      name: "keyboard_monitor",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    
    keyboardMonitor = KeyboardMonitor(channel: keyboardChannel)
    
    // Handle method calls from Flutter
    keyboardChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "startMonitoring":
        self?.keyboardMonitor?.startMonitoring()
        result(nil)
      case "stopMonitoring":
        self?.keyboardMonitor?.stopMonitoring()
        result(nil)
      case "checkPermissions":
        let hasPermissions = KeyboardMonitor.checkAllPermissions()
        result(hasPermissions)
      case "checkAccessibilityPermissions":
        let hasPermissions = KeyboardMonitor.checkAccessibilityPermissions()
        result(hasPermissions)
      case "checkInputMonitoringPermissions":
        if #available(macOS 10.15, *) {
          let hasPermissions = KeyboardMonitor.checkInputMonitoringPermissions()
          result(hasPermissions)
        } else {
          result(true) // Not needed on older macOS versions
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  // AIDEV-NOTE: Setup visual effect view for advanced transparency effects
  private func setupVisualEffectView(flutterViewController: FlutterViewController) {
    guard let contentView = self.contentView else { return }
    
    let visualEffectView = NSVisualEffectView()
    visualEffectView.material = .underWindowBackground
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    
    // Insert behind Flutter content
    contentView.addSubview(visualEffectView, positioned: .below, relativeTo: flutterViewController.view)
    NSLayoutConstraint.activate([
      visualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      visualEffectView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      visualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor),
      visualEffectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
    ])
    
    #if DEBUG
    print("📐 NSVisualEffectView configured for blur effects")
    #endif
  }
}
