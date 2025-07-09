// macOS Virtual Key Codes based on HIToolbox/Events.h
// https://developer.apple.com/documentation/appkit/nsevent/specialkey

final Map<int, String> _macOSKeyCodeMap = {
  // Letters
  0x00: 'A',
  0x0B: 'B',
  0x08: 'C',
  0x02: 'D',
  0x0E: 'E',
  0x03: 'F',
  0x05: 'G',
  0x04: 'H',
  0x22: 'I',
  0x26: 'J',
  0x28: 'K',
  0x25: 'L',
  0x2E: 'M',
  0x2D: 'N',
  0x1F: 'O',
  0x23: 'P',
  0x0C: 'Q',
  0x0F: 'R',
  0x01: 'S',
  0x11: 'T',
  0x20: 'U',
  0x09: 'V',
  0x0D: 'W',
  0x07: 'X',
  0x10: 'Y',
  0x06: 'Z',
  
  // Numbers
  0x1D: '0',
  0x12: '1',
  0x13: '2',
  0x14: '3',
  0x15: '4',
  0x17: '5',
  0x16: '6',
  0x1A: '7',
  0x1C: '8',
  0x19: '9',
  
  // Function keys
  0x7A: 'F1',
  0x78: 'F2',
  0x63: 'F3',
  0x76: 'F4',
  0x60: 'F5',
  0x61: 'F6',
  0x62: 'F7',
  0x64: 'F8',
  0x65: 'F9',
  0x6D: 'F10',
  0x67: 'F11',
  0x6F: 'F12',
  0x69: 'F13',
  0x6B: 'F14',
  0x71: 'F15',
  0x6A: 'F16',
  0x40: 'F17',
  0x4F: 'F18',
  0x50: 'F19',
  0x5A: 'F20',
  
  // Special keys
  0x24: 'Enter',
  0x30: 'Tab',
  0x33: 'Backspace',
  0x35: 'Escape',
  0x75: 'Delete',
  0x72: 'Insert',
  0x73: 'Home',
  0x77: 'End',
  0x74: 'PageUp',
  0x79: 'PageDown',
  0x7B: 'Left',
  0x7C: 'Right',
  0x7E: 'Up',
  0x7D: 'Down',
  
  // Modifier keys
  0x38: 'LShift',
  0x3C: 'RShift',
  0x3B: 'LControl',
  0x3E: 'RControl',
  0x3A: 'LAlt',
  0x3D: 'RAlt',
  0x37: 'Cmd',
  0x36: 'RCmd',
  0x39: 'CapsLock',
  0x31: ' ', // Space
  
  // Keypad
  0x52: '0', // Keypad 0
  0x53: '1', // Keypad 1
  0x54: '2', // Keypad 2
  0x55: '3', // Keypad 3
  0x56: '4', // Keypad 4
  0x57: '5', // Keypad 5
  0x58: '6', // Keypad 6
  0x59: '7', // Keypad 7
  0x5B: '8', // Keypad 8
  0x5C: '9', // Keypad 9
  0x43: '*', // Keypad *
  0x45: '+', // Keypad +
  0x4E: '-', // Keypad -
  0x41: '.', // Keypad .
  0x4B: '/', // Keypad /
};

final Map<(int, bool), String> _macOSKeyCodeShiftMap = {
  // Numbers with shift
  (0x1D, false): '0',
  (0x1D, true): ')',
  (0x12, false): '1',
  (0x12, true): '!',
  (0x13, false): '2',
  (0x13, true): '@',
  (0x14, false): '3',
  (0x14, true): '#',
  (0x15, false): '4',
  (0x15, true): '\$',
  (0x17, false): '5',
  (0x17, true): '%',
  (0x16, false): '6',
  (0x16, true): '^',
  (0x1A, false): '7',
  (0x1A, true): '&',
  (0x1C, false): '8',
  (0x1C, true): '*',
  (0x19, false): '9',
  (0x19, true): '(',
  
  // Punctuation
  (0x2B, false): ',', // Comma
  (0x2B, true): '<',
  (0x2F, false): '.', // Period
  (0x2F, true): '>',
  (0x29, false): ';', // Semicolon
  (0x29, true): ':',
  (0x2C, false): '/', // Slash
  (0x2C, true): '?',
  (0x21, false): '[', // Left bracket
  (0x21, true): '{',
  (0x1E, false): ']', // Right bracket
  (0x1E, true): '}',
  (0x2A, false): '\\', // Backslash
  (0x2A, true): '|',
  (0x32, false): '`', // Grave
  (0x32, true): '~',
  (0x27, false): "'", // Quote
  (0x27, true): '"',
  (0x18, false): '=', // Equal
  (0x18, true): '+',
  (0x1B, false): '-', // Minus
  (0x1B, true): '_',
};

// String key code mappings for macOS events that send string names
final Map<String, String> _macOSStringKeyMap = {
  // Basic keys - use actual key names from events
  '`': '`',
  ',': ',',
  '.': '.',
  '/': '/',
  '\\': '\\',
  '-': '-',
  '=': '=',
  '[': '[',
  ']': ']',
  ';': ';',
  "'": "'",
  // Numbers
  '1': '1', '2': '2', '3': '3', '4': '4', '5': '5',
  '6': '6', '7': '7', '8': '8', '9': '9', '0': '0',
  // Letters
  'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D', 'e': 'E', 'f': 'F',
  'g': 'G', 'h': 'H', 'i': 'I', 'j': 'J', 'k': 'K', 'l': 'L',
  'm': 'M', 'n': 'N', 'o': 'O', 'p': 'P', 'q': 'Q', 'r': 'R',
  's': 'S', 't': 'T', 'u': 'U', 'v': 'V', 'w': 'W', 'x': 'X',
  'y': 'Y', 'z': 'Z',
};

final Map<(String, bool), String> _macOSStringKeyShiftMap = {
  // Punctuation with shift - use actual key names from events
  ('`', false): '`',
  ('`', true): '~',
  (',', false): ',',
  (',', true): '<',
  ('.', false): '.',
  ('.', true): '>',
  ('/', false): '/',
  ('/', true): '?',
  ('\\', false): '\\',
  ('\\', true): '|',
  ('-', false): '-',
  ('-', true): '_',
  ('=', false): '=',
  ('=', true): '+',
  ('[', false): '[',
  ('[', true): '{',
  (']', false): ']',
  (']', true): '}',
  (';', false): ';',
  (';', true): ':',
  ("'", false): "'",
  ("'", true): '"',
  // Numbers with shift
  ('1', false): '1', ('1', true): '!',
  ('2', false): '2', ('2', true): '@',
  ('3', false): '3', ('3', true): '#',
  ('4', false): '4', ('4', true): '\$',
  ('5', false): '5', ('5', true): '%',
  ('6', false): '6', ('6', true): '^',
  ('7', false): '7', ('7', true): '&',
  ('8', false): '8', ('8', true): '*',
  ('9', false): '9', ('9', true): '(',
  ('0', false): '0', ('0', true): ')',
};

String getKeyFromKeyCodeShift(int keyCode, bool isShiftDown) {
  final shiftKey = _macOSKeyCodeShiftMap[(keyCode, isShiftDown)];
  if (shiftKey != null) return shiftKey;
  final key = _macOSKeyCodeMap[keyCode];
  if (key != null) return key;
  return '';
}

String getKeyFromStringKeyShift(String keyName, bool isShiftDown) {
  final shiftKey = _macOSStringKeyShiftMap[(keyName, isShiftDown)];
  if (shiftKey != null) return shiftKey;
  final key = _macOSStringKeyMap[keyName];
  if (key != null) return key;
  // Return the original key name if no mapping found
  return keyName;
}