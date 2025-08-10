import Cocoa
import Carbon
import FlutterMacOS

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var channel: FlutterMethodChannel?
    private var isMonitoring = false
    private var triggerKeys: Set<String> = []
    
    // AIDEV-NOTE: Overlay visibility optimization - controlled by Flutter overlay state
    private var isOverlayVisible = false // Start hidden, Flutter will update this
    
    // AIDEV-NOTE: Event batching for CPU optimization while maintaining zero keystroke loss
    private var eventBatch: [(String, Bool, [String: Bool])] = []
    private var batchTimer: Timer?
    private let batchInterval: TimeInterval = 0.002 // 2ms batching window
    
    // AIDEV-NOTE: Key event deduplication to prevent rapid repeats
    private var lastKeyEvents: [String: (Bool, Date)] = [:]
    private let keyRepeatThreshold: TimeInterval = 0.016 // ~60fps
    
    // AIDEV-NOTE: Reusable structures to reduce allocations
    private var reusableModifierDict: [String: Bool] = [:]
    
    // AIDEV-NOTE: Simple trigger sequence detection  
    private var lastTriggerTime: Date?
    private let triggerSequenceWindow: TimeInterval = 0.5 // 500ms window after trigger

    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func updateTriggerKeys(_ keys: [String]) {
        // AIDEV-NOTE: Normalize triggers to avoid case/order sensitivity
        self.triggerKeys = Set(keys.map { normalizeTrigger($0) })
    }
    
    // AIDEV-NOTE: Overlay visibility control for performance optimization
    func setOverlayVisible(_ visible: Bool) {
        isOverlayVisible = visible
        
        // If overlay becomes visible, flush any pending events immediately
        if visible && !eventBatch.isEmpty {
            flushEventBatch()
        }
    }
    
    // AIDEV-NOTE: Normalize trigger strings for consistent matching
    private func normalizeTrigger(_ trigger: String) -> String {
        let parts = trigger.lowercased().components(separatedBy: "+")
        let key = parts.last ?? ""
        let modifiers = Set(parts.dropLast())
        
        var result: [String] = []
        // Always use same order: cmd, alt, ctrl, shift, key
        if modifiers.contains("cmd") { result.append("cmd") }
        if modifiers.contains("alt") { result.append("alt") }
        if modifiers.contains("ctrl") { result.append("ctrl") }
        if modifiers.contains("shift") { result.append("shift") }
        result.append(key)
        
        return result.joined(separator: "+")
    }
    
    // AIDEV-NOTE: Event batching methods for CPU optimization
    private func batchKeyEvent(_ keyString: String, _ isPressed: Bool, _ modifiers: [String: Bool]) {
        let interval = getBatchInterval(keyString, modifiers)
        
        // For critical events (interval = 0), send immediately
        if interval <= 0 {
            let eventData = [keyString, isPressed, modifiers] as [Any]
            DispatchQueue.main.async {
                self.channel?.invokeMethod("onCriticalKeyEvents", arguments: [eventData])
            }
            return
        }
        
        // For regular events, use batching
        eventBatch.append((keyString, isPressed, modifiers))
        
        // Reset timer for each new event with dynamic interval
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.flushEventBatch()
        }
    }
    
    private func flushEventBatch() {
        guard !eventBatch.isEmpty else { return }
        
        // Simple approach: send all events, let Flutter handle them intelligently
        // Separate critical events (triggers) from regular events
        let criticalEvents = eventBatch.filter { (key, _, modifiers) in
            isTriggerKey(key, modifiers)
        }
        
        let regularEvents = eventBatch.filter { (key, _, modifiers) in
            !isTriggerKey(key, modifiers)
        }
        
        DispatchQueue.main.async {
            // Send critical events immediately with high priority
            if !criticalEvents.isEmpty {
                let criticalEventData = criticalEvents.map { (key, isPressed, modifiers) -> [Any] in
                    return [key, isPressed, modifiers]
                }
                self.channel?.invokeMethod("onCriticalKeyEvents", arguments: criticalEventData)
            }
            
            // Send regular events with normal priority
            if !regularEvents.isEmpty {
                let regularEventData = regularEvents.map { (key, isPressed, modifiers) -> [Any] in
                    return [key, isPressed, modifiers]
                }
                self.channel?.invokeMethod("onBatchedKeyEvents", arguments: regularEventData)
            }
        }
        
        eventBatch.removeAll()
    }
    
    // AIDEV-NOTE: Helper methods for event processing optimization
    private func shouldProcessEvent(_ keyString: String, _ modifiers: [String: Bool]) -> Bool {
        // AIDEV-NOTE: Always process all events for Smart Visibility Manager
        // The optimization comes from batching, not filtering events
        return true
    }
    
    private func getBatchInterval(_ keyString: String, _ modifiers: [String: Bool]) -> TimeInterval {
        // Use immediate processing for trigger keys
        if isTriggerKey(keyString, modifiers) {
            lastTriggerTime = Date() // Track trigger timing
            return 0.0 // No batching for critical events
        }
        
        // AIDEV-NOTE: Smart trigger sequence detection
        // If we're within the trigger sequence window, use minimal batching for responsiveness
        if let lastTrigger = lastTriggerTime {
            let timeSinceTrigger = Date().timeIntervalSince(lastTrigger)
            if timeSinceTrigger <= triggerSequenceWindow {
                return 0.001 // 1ms batching during trigger sequences (ultra-responsive)
            }
        }
        
        // Use longer batching when overlay is hidden to reduce CPU
        if !isOverlayVisible {
            return 0.008 // 8ms batching when hidden (less frequent updates)
        }
        
        // Use short batching when overlay is visible for responsiveness  
        return 0.002 // 2ms batching when visible
    }
    
    private func isTriggerKey(_ keyString: String, _ modifiers: [String: Bool]) -> Bool {
        let triggerString = createTriggerString(keyString: keyString, modifiers: modifiers)
        let normalizedTrigger = normalizeTrigger(triggerString)
        return triggerKeys.contains(normalizedTrigger)
    }
    
    private func shouldCoalesceKeyEvent(_ keyString: String, _ isPressed: Bool) -> Bool {
        let now = Date()
        
        if let (lastPressed, lastTime) = lastKeyEvents[keyString] {
            let timeDiff = now.timeIntervalSince(lastTime)
            
            // Coalesce rapid repeats of the same state
            if lastPressed == isPressed && timeDiff < keyRepeatThreshold {
                return true // Skip this duplicate event
            }
        }
        
        // Update tracking
        lastKeyEvents[keyString] = (isPressed, now)
        return false
    }
    
    private func isModifierKeyCode(_ keyCode: Int) -> Bool {
        switch keyCode {
        case 0x38, 0x3C, 0x3B, 0x3E, 0x3A, 0x3D, 0x37, 0x36, 0x39:
            return true
        default:
            return false
        }
    }
    
    
    private func extractModifiersEfficiently(from flags: CGEventFlags) -> [String: Bool] {
        // Reuse dictionary to avoid allocations
        reusableModifierDict.removeAll(keepingCapacity: true)
        
        reusableModifierDict["shift"] = flags.contains(.maskShift)
        reusableModifierDict["ctrl"] = flags.contains(.maskControl)
        reusableModifierDict["alt"] = flags.contains(.maskAlternate)
        reusableModifierDict["cmd"] = flags.contains(.maskCommand)
        reusableModifierDict["lshift"] = flags.contains(.maskShift)
        reusableModifierDict["rshift"] = flags.contains(.maskShift)
        reusableModifierDict["lctrl"] = flags.contains(.maskControl)
        reusableModifierDict["rctrl"] = flags.contains(.maskControl)
        reusableModifierDict["lalt"] = flags.contains(.maskAlternate)
        reusableModifierDict["ralt"] = flags.contains(.maskAlternate)
        reusableModifierDict["lcmd"] = flags.contains(.maskCommand)
        reusableModifierDict["rcmd"] = flags.contains(.maskCommand)
        
        return reusableModifierDict
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

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let keyboardMonitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                let shouldConsume = keyboardMonitor.handleKeyEvent(event: event, type: type)
                return shouldConsume ? nil : Unmanaged.passUnretained(event)
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
        
        // AIDEV-NOTE: Cleanup batching timer and flush any pending events
        batchTimer?.invalidate()
        batchTimer = nil
        
        if !eventBatch.isEmpty {
            flushEventBatch()
        }
        
        // Clear tracking data
        lastKeyEvents.removeAll()

        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
    }

    private func handleKeyEvent(event: CGEvent, type: CGEventType) -> Bool {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let keyString = macOSKeyCodeToString(keyCode: Int(keyCode))
        
        // AIDEV-NOTE: Handle different event types - flagsChanged for modifiers, keyDown/keyUp for regular keys
        let isPressed: Bool
        if type == .flagsChanged {
            // For modifier keys, determine press/release based on flag state
            let flags = event.flags
            isPressed = isModifierPressed(keyCode: Int(keyCode), flags: flags)
        } else {
            // For regular keys, use the event type
            isPressed = type == .keyDown
        }

        // AIDEV-NOTE: Use efficient modifier extraction to reduce allocations
        let modifiers = extractModifiersEfficiently(from: event.flags)
        
        // Track trigger timing for smart batching
        if isPressed && isTriggerKey(keyString, modifiers) {
            lastTriggerTime = Date()
        }
        
        // AIDEV-NOTE: Check for rapid key repeats to prevent duplicate processing
        if shouldCoalesceKeyEvent(keyString, isPressed) {
            let triggerString = createTriggerString(keyString: keyString, modifiers: modifiers)
            let normalizedTrigger = normalizeTrigger(triggerString)
            return triggerKeys.contains(normalizedTrigger)
        }
        
        // AIDEV-NOTE: Determine if we should process this event based on overlay visibility and triggers
        if shouldProcessEvent(keyString, modifiers) {
            // AIDEV-NOTE: Use event batching instead of immediate Flutter calls for performance
            batchKeyEvent(keyString, isPressed, modifiers)
        }
        
        // AIDEV-NOTE: Check if this is a registered trigger key that should be consumed
        let triggerString = createTriggerString(keyString: keyString, modifiers: modifiers)
        let normalizedTrigger = normalizeTrigger(triggerString)
        let shouldConsume = triggerKeys.contains(normalizedTrigger)
        
        return shouldConsume
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

    // AIDEV-NOTE: Create trigger string matching exact Flutter format from config
    private func createTriggerString(keyString: String, modifiers: [String: Bool]) -> String {
        var parts: [String] = []

        // AIDEV-NOTE: Always build explicit modifier combinations, no "hyper" shortcut
        let hasCtrl = modifiers["ctrl"] ?? false
        let hasAlt = modifiers["alt"] ?? false
        let hasCmd = modifiers["cmd"] ?? false
        let hasShift = modifiers["shift"] ?? false

        // AIDEV-NOTE: Match exact order and case from Flutter config: cmd+alt+ctrl+shift+F15 (lowercase)
        if hasCmd { parts.append("cmd") }
        if hasAlt { parts.append("alt") }
        if hasCtrl { parts.append("ctrl") }
        if hasShift { parts.append("shift") }

        // Add the key (keep original case to match config format)
        parts.append(keyString)

        return parts.joined(separator: "+")
    }

    // AIDEV-NOTE: Determine if a modifier key is pressed based on keyCode and flags
    private func isModifierPressed(keyCode: Int, flags: CGEventFlags) -> Bool {
        switch keyCode {
        case 0x38, 0x3C: // LShift, RShift
            return flags.contains(.maskShift)
        case 0x3B, 0x3E: // LControl, RControl
            return flags.contains(.maskControl)
        case 0x3A, 0x3D: // LAlt, RAlt
            return flags.contains(.maskAlternate)
        case 0x37, 0x36: // Cmd, RCmd
            return flags.contains(.maskCommand)
        case 0x39: // CapsLock
            return flags.contains(.maskAlphaShift)
        default:
            return false
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
