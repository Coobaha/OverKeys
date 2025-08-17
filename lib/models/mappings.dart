// https://github.com/jtroo/kanata/blob/a9dabfcb07e22c9efa0bc15349780b10afacb6cd/parser/src/keys/mod.rs as guide

class Mappings {
  static const Map<String, String> keyMappings = {
    '◄': 'Left',
    '←': 'Left',
    '◀': 'Left',
    'LEFT': 'Left',
    '▲': 'Up',
    '↑': 'Up',
    'UP': 'Up',
    '►': 'Right',
    '→': 'Right',
    '▶': 'Right',
    'RIGHT': 'Right',
    '▼': 'Down',
    '↓': 'Down',
    'DOWN': 'Down',
    '⏎': 'Enter',
    '↵': 'Enter',
    '↩': 'Enter',
    '⌤': 'Enter',
    '␤': 'Enter',
    'ENTER': 'Enter',
    'ENT': 'Enter',
    'RETURN': 'Enter',
    'RET': 'Enter',
    '⌫': 'Backspace',
    '␈': 'Backspace',
    'BSPC': 'Backspace',
    'BS': 'Backspace',
    'BKSP': 'Backspace',
    'BKS': 'Backspace',
    '⌦': 'Delete',
    '␡': 'Delete',
    'DEL': 'Delete',
    'DELETE': 'Delete',
    '⭾': 'Tab',
    '↹': 'Tab',
    'TAB': 'Tab',
    '␣': ' ',
    '⎵': ' ',
    '␠': ' ',
    'SPC': ' ',
    'SPACE': ' ',
    '⎋': 'Escape',
    'ESC': 'Escape',
    '⇪': 'CapsLock',
    'CAPS': 'CapsLock',
    '⤓': 'PageDown',
    '⇟': 'PageDown',
    'PGDN': 'PageDown',
    '⤒': 'PageUp',
    '⇞': 'PageUp',
    'PGUP': 'PageUp',
    '⇱': 'Home',
    '⇤': 'Home',
    '↖': 'Home',
    'HOME': 'Home',
    '⇲': 'End',
    '⇥': 'End',
    '↘': 'End',
    'END': 'End',
    // Treating VK_(modifier) as default VK_(left modifier) for now
    // '⇧': 'Shift',
    // 'SFT': 'Shift',
    // 'SHFT': 'Shift',
    // 'SHIFT': 'Shift',
    '⇧': 'LShift', // Map Unicode shift symbol to LShift (matches Swift output)
    'SFT': 'LShift',
    'SHFT': 'LShift',
    'SHIFT': 'LShift',
    '‹⇧': 'LShift',
    'LSFT': 'LShift',
    'LSHFT': 'LShift',
    'LSHIFT': 'LShift',
    '⇧›': 'RShift',
    'RSFT': 'RShift',
    'RSHFT': 'RShift',
    'RSHIFT': 'RShift',
    // '⌃': 'Control',
    // '⎈': 'Control',
    // 'CTL': 'Control',
    // 'CTRL': 'Control',
    '⌃':
        'LControl', // Map Unicode control symbol to LControl (matches Swift output)
    '⎈': 'LControl',
    'CTL': 'LControl',
    'CTRL': 'LControl',
    '‹⌃': 'LControl',
    '‹⎈': 'LControl',
    'LCTL': 'LControl',
    'LCTRL': 'LControl',
    // '⌥': 'Alt',
    // '⎇': 'Alt',
    // 'ALT': 'Alt',
    '⌥': 'LAlt', // Map Unicode alt symbol to LAlt (matches Swift output)
    '⎇': 'LAlt',
    'ALT': 'LAlt',
    '‹⎇': 'LAlt',
    '‹⌥': 'LAlt',
    'LALT': 'LAlt',
    '⎇›': 'RAlt',
    '⌥›': 'RAlt',
    'RALT': 'RAlt',
    '⌃›': 'RControl',
    '⎈›': 'RControl',
    'RCTL': 'RControl',
    'RCTRL': 'RControl',
    '⌘': 'Cmd', // Map Unicode command symbol to Cmd (matches Swift output)
    '⊞': 'WIN',
    '◆': 'WIN',
    '❖': 'WIN',
    'WIN': 'Win',
    '⎀': 'INS',
    'INS': 'Insert',
    'INSERT': 'Insert',
    '🔢₀': 'NUM 0',
    '🔢₁': 'NUM 1',
    '🔢₂': 'NUM 2',
    '🔢₃': 'NUM 3',
    '🔢₄': 'NUM 4',
    '🔢₅': 'NUM 5',
    '🔢₆': 'NUM 6',
    '🔢₇': 'NUM 7',
    '🔢₈': 'NUM 8',
    '🔢₉': 'NUM 9',
    '🔢⁄': 'NUM /',
    '🔢₊': 'NUM +',
    '🔢∗': 'NUM *',
    '🔢₋': 'NUM -',
    '🔢．': 'NUM .',
    '⇭': 'NUM LOCK',
    'NLK': 'NUM LOCK',
    'NLCK': 'NUM LOCK',
    '⇳🔒': 'SCROLL LOCK',
    'SLCK': 'ScrollLock',
    'SCRLCK': 'ScrollLock',
    '‐': '-',
    '₌': '='
  };
  static String getKeyForSymbol(String symbol) {
    return keyMappings[symbol] ?? symbol;
  }

  static String getShiftedSymbol(String symbol) {
    const Map<String, String> shiftedSymbols = {
      '`': '~',
      '1': '!',
      '2': '@',
      '3': '#',
      '4': '\$',
      '5': '%',
      '6': '^',
      '7': '&',
      '8': '*',
      '9': '(',
      '0': ')',
      '-': '_',
      '=': '+',
      '[': '{',
      ']': '}',
      '\\': '|',
      ';': ':',
      '\'': '"',
      ',': '<',
      '.': '>',
      '/': '?'
    };

    return shiftedSymbols[symbol] ?? symbol;
  }

  // AIDEV-NOTE: Human-friendly names for ZMK keys and macros with shift mapping support
  static String getDisplayName(String zmkKey, Map<String, String>? actionMappings,
      {bool isShiftPressed = false, Map<String, String>? customShiftMappings}) {
    if (actionMappings != null && actionMappings.containsKey(zmkKey)) {
      // Don't return the action, just use this as indication this is a semantic key
      // The original zmkKey (like "Cut", "Copy") is already the display name we want
      return zmkKey;
    }

    // Apply custom shift mappings first if shift is pressed
    if (isShiftPressed && customShiftMappings != null) {
      final shiftedValue = customShiftMappings[zmkKey];
      if (shiftedValue != null) {
        return shiftedValue;
      }
    }

    // Apply default shift mappings
    if (isShiftPressed) {
      final defaultShifted = getShiftedSymbol(zmkKey);
      if (defaultShifted != zmkKey) {
        return defaultShifted;
      }
    }

    // Single character keys - return as uppercase
    if (zmkKey.length == 1) {
      return zmkKey.toUpperCase();
    }

    return zmkKey;
  }
}
