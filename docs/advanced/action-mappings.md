# Action Mappings

Action mappings provide a way to map semantic labels in your keyboard layouts to actual key combinations that can be executed. This separates **what is displayed** from **what action is performed**.

## Overview
## Configuration

Add an `actionMappings` section to your `overkeys_config.json`:

```json
{
  "actionMappings": {
    "ALL": "cmd+a",
    "CUT": "cmd+x", 
    "COPY": "cmd+c",
    "PASTE": "cmd+v",
    "UNDO": "cmd+z",
    "REDO": "cmd+shift+z",
    "FIND": "cmd+f",
    "LINE": "cmd+l",
    "WORD": "alt+shift+right",
    "PREV": "cmd+left",
    "NEXT": "cmd+right",
    "HOME": "cmd+up",
    "END": "cmd+down"
  }
}
```

## Supported Modifiers

### Primary Modifiers
- `cmd` - Command key (⌘) on macOS, Windows key on Windows
- `ctrl` - Control key (⌃)
- `alt` - Alt/Option key (⌥)  
- `shift` - Shift key (⇧)

### Left/Right Specific Modifiers
- `lcmd`, `rcmd` - Left/Right Command keys
- `lctrl`, `rctrl` - Left/Right Control keys
- `lalt`, `ralt` - Left/Right Alt keys
- `lshift`, `rshift` - Left/Right Shift keys

### Function Keys
- `f1` through `f24` - Function keys
- Special function keys: `f13`, `f14`, `f15`, etc.

### Special Keys
- `space` - Space bar
- `tab` - Tab key
- `enter` - Return/Enter key
- `backspace` - Backspace key
- `delete` - Delete key
- `escape` - Escape key
- `insert` - Insert key

### Arrow Keys
- `left`, `right`, `up`, `down` - Arrow keys
- `home`, `end` - Home and End keys
- `pageup`, `pagedown` - Page Up and Page Down keys

## Key Combination Syntax

### Single Keys
```json
{
  "ESC": "escape",
  "SPACE": "space",
  "TAB": "tab"
}
```

### Modifier + Key
```json
{
  "COPY": "cmd+c",
  "PASTE": "cmd+v",
  "SAVE": "cmd+s"
}
```

### Multiple Modifiers
```json
{
  "REDO": "cmd+shift+z",
  "FORCE_QUIT": "cmd+alt+escape",
  "SCREENSHOT": "cmd+shift+4"
}
```

### Function Key Combinations
```json
{
  "MISSION_CONTROL": "f3",
  "SPOTLIGHT": "cmd+space",
  "LAYER_TOGGLE": "alt+cmd+f20"
}
```

## Platform Differences

### macOS vs Windows/Linux
Action mappings can be platform-specific:

**macOS Style:**
```json
{
  "COPY": "cmd+c",
  "PASTE": "cmd+v",
  "UNDO": "cmd+z"
}
```

**Windows/Linux Style:**
```json
{
  "COPY": "ctrl+c",
  "PASTE": "ctrl+v", 
  "UNDO": "ctrl+z"
}
```

## Common Action Examples

### Text Editing
```json
{
  "ALL": "cmd+a",
  "CUT": "cmd+x",
  "COPY": "cmd+c", 
  "PASTE": "cmd+v",
  "UNDO": "cmd+z",
  "REDO": "cmd+shift+z",
  "FIND": "cmd+f",
  "REPLACE": "cmd+alt+f"
}
```

### Text Selection
```json
{
  "WORD": "alt+shift+right",
  "LINE": "cmd+shift+left",
  "PARA": "alt+shift+down",
  "ALL": "cmd+a"
}
```

### Navigation
```json
{
  "PREV": "cmd+left",
  "NEXT": "cmd+right", 
  "HOME": "cmd+up",
  "END": "cmd+down",
  "PAGE_UP": "pageup",
  "PAGE_DOWN": "pagedown"
}
```

### Window Management
```json
{
  "CLOSE": "cmd+w",
  "QUIT": "cmd+q",
  "MINIMIZE": "cmd+m",
  "HIDE": "cmd+h",
  "SWITCH": "cmd+tab"
}
```

### Developer Actions
```json
{
  "BUILD": "cmd+b",
  "RUN": "cmd+r",
  "DEBUG": "cmd+shift+d",
  "TERMINAL": "cmd+shift+t",
  "CONSOLE": "cmd+shift+c"
}
```

## Integration with Layouts

Action mappings work with any layout style. For example, in your glove80.json:

```json
{
  "userLayouts": [
    {
      "name": "Cursor Layer",
      "leftHand": {
        "mainRows": [
          ["CUT", "COPY", "PASTE"],
          ["ALL", "LINE", "WORD"],  
          ["UNDO", "REDO", "FIND"]
        ]
      }
    }
  ],
  "actionMappings": {
    "CUT": "cmd+x",
    "COPY": "cmd+c",
    "PASTE": "cmd+v",
    "ALL": "cmd+a",
    "LINE": "cmd+l", 
    "WORD": "alt+shift+right",
    "UNDO": "cmd+z",
    "REDO": "cmd+shift+z",
    "FIND": "cmd+f"
  }
}
```

## Reserved Action Names

Some action names are reserved for special OverKeys functionality:

- `TRANS` - Transparent (pass through)
- `NONE` - No action
- `LAYER_*` - Layer switching actions
- `TOG` - Toggle actions

## Best Practices

### 1. Consistent Naming
Use clear, descriptive action names:
- `ALL` instead of `SEL_ALL`
- `COPY` instead of `CP`
- `FIND` instead of `SEARCH`

### 2. Platform Consistency
Choose one platform style and stick to it throughout your config.

### 3. Logical Grouping
Group related actions together in your config for easier maintenance:

```json
{
  "actionMappings": {
    // Text editing
    "CUT": "cmd+x",
    "COPY": "cmd+c", 
    "PASTE": "cmd+v",
    
    // Selection
    "ALL": "cmd+a",
    "LINE": "cmd+l",
    "WORD": "alt+shift+right",
    
    // Navigation
    "PREV": "cmd+left",
    "NEXT": "cmd+right"
  }
}
```

### 4. Test Your Mappings
Always test action mappings in your target applications to ensure they work as expected.

## Troubleshooting

### Action Not Working
1. Check the key combination works manually in your target application
2. Verify the syntax matches the supported format
3. Ensure the action name in your layout matches the actionMappings key exactly (case-sensitive)

### Platform-Specific Issues
- On Windows/Linux, use `ctrl` instead of `cmd` for most shortcuts
- Some applications may have different key bindings than system defaults
- Function keys may behave differently between platforms

## Future Enhancements

Planned features for action mappings:
- Conditional mappings based on active application
- Macro sequences with multiple key combinations
- Time-delayed key sequences
- Integration with external automation tools
