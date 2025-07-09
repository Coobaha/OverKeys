import Cocoa
import Carbon
import FlutterMacOS

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var channel: FlutterMethodChannel?
    private var isMonitoring = false

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        // Check for accessibility permissions
        if !AXIsProcessTrusted() {
            requestAccessibilityPermissions()
            return
        }

        // Check for input monitoring permissions (macOS 10.15+)
        if #available(macOS 10.15, *) {
            if !hasInputMonitoringPermission() {
                requestInputMonitoringPermissions()
                return
            }
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let keyboardMonitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                keyboardMonitor.handleKeyEvent(event: event, type: type)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isMonitoring = true
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
    }

    private func handleKeyEvent(event: CGEvent, type: CGEventType) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isPressed = type == .keyDown
        let flags = event.flags
        let isShiftDown = flags.contains(.maskShift)

        // Convert macOS key code to string
        let keyString = macOSKeyCodeToString(keyCode: Int(keyCode))

        // Send event to Flutter
        let eventData: [Any] = [keyString, isPressed, isShiftDown]

        DispatchQueue.main.async {
            self.channel?.invokeMethod("onKeyEvent", arguments: eventData)
        }

        // Handle session events (simplified for now)
        if type == .keyDown {
            // You could add session lock/unlock detection here if needed
        }
    }

    private func macOSKeyCodeToString(keyCode: Int) -> String {
        // AIDEV-NOTE: Synchronized with lib/utils/key_code_macos.dart mapping
        switch keyCode {
        // Letters
        case 0x00: return "A"
        case 0x0B: return "B"
        case 0x08: return "C"
        case 0x02: return "D"
        case 0x0E: return "E"
        case 0x03: return "F"
        case 0x05: return "G"
        case 0x04: return "H"
        case 0x22: return "I"
        case 0x26: return "J"
        case 0x28: return "K"
        case 0x25: return "L"
        case 0x2E: return "M"
        case 0x2D: return "N"
        case 0x1F: return "O"
        case 0x23: return "P"
        case 0x0C: return "Q"
        case 0x0F: return "R"
        case 0x01: return "S"
        case 0x11: return "T"
        case 0x20: return "U"
        case 0x09: return "V"
        case 0x0D: return "W"
        case 0x07: return "X"
        case 0x10: return "Y"
        case 0x06: return "Z"
        
        // Numbers
        case 0x1D: return "0"
        case 0x12: return "1"
        case 0x13: return "2"
        case 0x14: return "3"
        case 0x15: return "4"
        case 0x17: return "5"
        case 0x16: return "6"
        case 0x1A: return "7"
        case 0x1C: return "8"
        case 0x19: return "9"
        
        // Function keys
        case 0x7A: return "F1"
        case 0x78: return "F2"
        case 0x63: return "F3"
        case 0x76: return "F4"
        case 0x60: return "F5"
        case 0x61: return "F6"
        case 0x62: return "F7"
        case 0x64: return "F8"
        case 0x65: return "F9"
        case 0x6D: return "F10"
        case 0x67: return "F11"
        case 0x6F: return "F12"
        case 0x69: return "F13"
        case 0x6B: return "F14"
        case 0x71: return "F15"
        case 0x6A: return "F16"
        case 0x40: return "F17"
        case 0x4F: return "F18"
        case 0x50: return "F19"
        case 0x5A: return "F20"
        
        // Special keys
        case 0x24: return "Enter"
        case 0x30: return "Tab"
        case 0x33: return "Backspace"
        case 0x35: return "Escape"
        case 0x75: return "Delete"
        case 0x72: return "Insert"
        case 0x73: return "Home"
        case 0x77: return "End"
        case 0x74: return "PageUp"
        case 0x79: return "PageDown"
        case 0x7B: return "Left"
        case 0x7C: return "Right"
        case 0x7E: return "Up"
        case 0x7D: return "Down"
        
        // Modifier keys
        case 0x38: return "LShift"
        case 0x3C: return "RShift"
        case 0x3B: return "LControl"
        case 0x3E: return "RControl"
        case 0x3A: return "LAlt"
        case 0x3D: return "RAlt"
        case 0x37: return "Cmd"
        case 0x36: return "RCmd"
        case 0x39: return "CapsLock"
        case 0x31: return "Space"
        
        // Keypad
        case 0x52: return "0" // Keypad 0
        case 0x53: return "1" // Keypad 1
        case 0x54: return "2" // Keypad 2
        case 0x55: return "3" // Keypad 3
        case 0x56: return "4" // Keypad 4
        case 0x57: return "5" // Keypad 5
        case 0x58: return "6" // Keypad 6
        case 0x59: return "7" // Keypad 7
        case 0x5B: return "8" // Keypad 8
        case 0x5C: return "9" // Keypad 9
        case 0x43: return "*" // Keypad *
        case 0x45: return "+" // Keypad +
        case 0x4E: return "-" // Keypad -
        case 0x41: return "." // Keypad .
        case 0x4B: return "/" // Keypad /
        
        // Punctuation (basic mapping without shift)
        case 0x2B: return ","
        case 0x2F: return "."
        case 0x29: return ";"
        case 0x2C: return "/"
        case 0x32: return "`"
        case 0x27: return "'"
        case 0x21: return "["
        case 0x1E: return "]"
        case 0x2A: return "\\"
        case 0x18: return "="
        case 0x1B: return "-"
        
        default: return "Unknown"
        }
    }

    private func requestAccessibilityPermissions() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = "OverKeys needs accessibility access to monitor keyboard events. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @available(macOS 10.15, *)
    private func hasInputMonitoringPermission() -> Bool {
        // Try to create a simple event tap to test input monitoring permission
        let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, _, _, _ in return nil },
            userInfo: nil
        )

        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            return true
        }
        return false
    }

    @available(macOS 10.15, *)
    private func requestInputMonitoringPermissions() {
        let alert = NSAlert()
        alert.messageText = "Input Monitoring Access Required"
        alert.informativeText = "OverKeys needs input monitoring access to capture keyboard events. Please grant access in System Preferences > Security & Privacy > Privacy > Input Monitoring."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// Extension to check if the current process is trusted for accessibility
extension KeyboardMonitor {
    static func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    @available(macOS 10.15, *)
    static func checkInputMonitoringPermissions() -> Bool {
        let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, _, _, _ in return nil },
            userInfo: nil
        )

        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            return true
        }
        return false
    }

    static func checkAllPermissions() -> Bool {
        let hasAccessibility = AXIsProcessTrusted()

        if #available(macOS 10.15, *) {
            let hasInputMonitoring = checkInputMonitoringPermissions()
            return hasAccessibility && hasInputMonitoring
        } else {
            return hasAccessibility
        }
    }
}
