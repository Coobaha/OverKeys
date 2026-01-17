# Split Matrix Layouts

Split matrix layouts are an advanced configuration format in OverKeys designed for complex split keyboards like the Glove80, Moonlander, and other ergonomic keyboards with thumb clusters and explicit hand separation.

## Overview

The split matrix format provides precise control over:
- **Separate Hand Definition**: Explicit left and right hand layouts
- **Thumb Cluster Support**: Dedicated thumb key positioning
- **Flexible Row Structure**: Variable row lengths and empty rows
- **Homerow Configuration**: Custom tactile marker positioning
- **Null Key Support**: Invisible placeholders for layout gaps

## Basic Structure

```jsonc
{
    "name": "My Split Layout",
    "layoutStyle": "split_matrix_explicit",
    "leftHand": {
        "mainRows": [...],
        "thumbRows": [...]
    },
    "rightHand": {
        "mainRows": [...], 
        "thumbRows": [...]
    },
    "homeRow": {...},
    "trigger": "F20",
    "type": "held"
}
```

## Complete Example: Glove80 Symbol Layer

```jsonc
{
    "name": "Glove80 Symbol Layer",
    "layoutStyle": "split_matrix_explicit",
    "leftHand": {
        "mainRows": [
            [],  // Empty top row
            ["`", "]", "(", ")", ",", "."],
            ["[", "!", "{", "}", ";", "?"],
            ["#", "^", "=", "_", "$", "*"],
            ["~", "<", "|", "-", ">", "/"],
            ["..", "&", "'", "\"", "+", null]
        ],
        "thumbRows": [
            ["\\", ".", "*"],
            ["%", ":", "@"]
        ]
    },
    "rightHand": {
        "mainRows": [
            [],  // Empty top row
            [],  // Empty second row
            ["`", "SHIFT", "CMD", "ALT", "CTRL"],
            ["\"", "BSPC", "TAB", "⎵", "RET"],
            ["'", "DEL", "STAB", "INS", "ESC"],
            []   // Empty bottom row
        ],
        "thumbRows": [
            [],  // Empty thumb row
            [null, null, "SYM"]
        ]
    },
    "homeRow": {
        "rowIndex": 4,
        "leftPosition": 2,
        "rightPosition": 2
    },
    "trigger": "F20",
    "type": "held"
}
```

## Layout Configuration

### Hand Structure

Each hand (`leftHand` and `rightHand`) contains:

- **mainRows**: Array of key rows for the main keyboard matrix
- **thumbRows**: Array of key rows for thumb cluster keys

### Row Definition

```jsonc
"mainRows": [
    [],                           // Empty row (no keys)
    ["`", "]", "(", ")", ","],   // Populated row with keys
    ["[", "!", null, "}", ";"],  // Row with null gap
]
```

#### Key Guidelines:
- **Empty Rows**: Use `[]` for rows that don't exist on that hand
- **Null Keys**: Use `null` for invisible placeholders/gaps
- **String Keys**: Regular key symbols as strings
- **Flexible Length**: Rows can have different numbers of keys

### Thumb Clusters

Thumb clusters are defined separately from main rows:

```jsonc
"thumbRows": [
    ["\\", ".", "*"],     // First thumb row (3 keys)
    ["%", ":", "@"]       // Second thumb row (3 keys)
]
```

- Each thumb row is independent
- Can have different numbers of keys per row
- Support null placeholders for alignment

## Homerow Configuration

Configure tactile markers (homerow indicators) with precise positioning:

```jsonc
"homeRow": {
    "rowIndex": 4,      // 1-indexed row number (4th row from top)
    "leftPosition": 2,  // Column position on left hand
    "rightPosition": 2  // Column position on right hand
}
```

### Column Numbering System

**CRITICAL**: The column numbering reflects ergonomic finger mapping:

- **Left Hand**: Columns numbered **right-to-left** (c4→c3→c2→c1)
  ```
  c4  c3  c2  c1
  [Q] [W] [E] [R]
  ```

- **Right Hand**: Columns numbered **left-to-right** (c1→c2→c3→c4)
  ```
  c1  c2  c3  c4
  [Y] [U] [I] [O]
  ```

This ensures your **index fingers are always at position 1** on both hands, maintaining ergonomic consistency.

### Example Homerow Positions

For a QWERTY-style split layout with homerow on F and J:
```jsonc
"homeRow": {
    "rowIndex": 3,      // Third row (ASDF/JKL; row)
    "leftPosition": 1,  // F key (index finger, rightmost on left hand)
    "rightPosition": 1  // J key (index finger, leftmost on right hand)
}
```

## Layer Triggers

Split matrix layouts support dynamic layer switching:

```jsonc
"trigger": "F20",      // Key that activates this layer
"type": "held"         // "held" or "toggle"
```

### Trigger Types:
- **held**: Layer active only while trigger key is pressed
- **toggle**: Layer toggles on/off with each trigger press

## Layout Style Options

Set the `layoutStyle` field to control rendering:

- `"split_matrix_explicit"`: Full explicit hand definition (recommended)
- `"split_matrix"`: Standard split matrix with auto-detection
- `"matrix"`: Regular matrix layout
- `"standard"`: Standard staggered layout

## Physical Layout Configuration

Configure column offsets and thumb cluster positioning to match your specific split keyboard's physical layout (Go60, Glove80, Voyager, Corne, etc.).

### Column Offsets

Apply vertical offsets per column to match the physical stagger of your keyboard:

```jsonc
{
    "name": "My Layout",
    "layoutStyle": "split_matrix_explicit",
    "leftHand": { ... },
    "rightHand": { ... },
    "metadata": {
        "columnOffsets": {
            "left": {
                "C1": 0,      // Inner column (index finger)
                "C2": 0,
                "C3": -10,    // Negative = shift up
                "C4": -15,
                "C5": -10,
                "C6": 25      // Outer column (pinky) - positive = shift down
            },
            "right": {
                "C1": 0,      // Inner column (index finger)
                "C2": 0,
                "C3": -10,
                "C4": -15,
                "C5": -10,
                "C6": 25      // Outer column (pinky)
            }
        }
    }
}
```

Column numbering:
- C1 = innermost column (index finger side)
- C6 = outermost column (pinky side)
- Values are percentage of key size (25 = 25% of keySize shifted down)

### Thumb Cluster Positioning

Configure the gap between thumb clusters and vertical offset from main keyboard:

```jsonc
"metadata": {
    "thumbCluster": {
        "gap": 20.0,           // Pixels between left/right thumb clusters
        "verticalOffset": 10.0  // Pixels below the main keyboard rows
    }
}
```

Default values if not specified:
- `gap`: 40% of the main split width
- `verticalOffset`: 0 (flush with keyPadding)

### Complete Example with Physical Configuration

```jsonc
{
    "name": "Voyager Layout",
    "layoutStyle": "split_matrix_explicit",
    "leftHand": {
        "mainRows": [
            ["ESC", "1", "2", "3", "4", "5"],
            ["TAB", "Q", "W", "E", "R", "T"],
            ["CAPS", "A", "S", "D", "F", "G"],
            ["SHIFT", "Z", "X", "C", "V", "B"]
        ],
        "thumbRows": [
            ["SPACE", "BSPC"]
        ]
    },
    "rightHand": {
        "mainRows": [
            ["6", "7", "8", "9", "0", "-"],
            ["Y", "U", "I", "O", "P", "\\"],
            ["H", "J", "K", "L", ";", "'"],
            ["N", "M", ",", ".", "/", "SHIFT"]
        ],
        "thumbRows": [
            ["ENTER", "SPACE"]
        ]
    },
    "metadata": {
        "columnOffsets": {
            "left": { "C5": 15, "C6": 30 },
            "right": { "C5": 15, "C6": 30 }
        },
        "thumbCluster": {
            "gap": 40,
            "verticalOffset": 5
        }
    }
}
```

## Advanced Features

### Action Mappings

Map semantic labels in your layouts to actual key combinations. This separates what is displayed from what action is performed:

```jsonc
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

For complete documentation on action mappings syntax, modifiers, and platform differences, see [Action Mappings](action-mappings.md).

### Custom Shift Mappings

Define custom shifted symbols at the root level:

```jsonc
{
    "userLayouts": [...],
    "customShiftMappings": {
        "TAB": "STAB",
        ".": "...",
        ",": ";"
    }
}
```

### Multi-Layer Support

Configure multiple layers with different triggers:

```jsonc
"userLayouts": [
    {
        "name": "Base Layer",
        "layoutStyle": "split_matrix_explicit",
        // ... layout definition
    },
    {
        "name": "Symbol Layer", 
        "layoutStyle": "split_matrix_explicit",
        "trigger": "F20",
        "type": "held",
        // ... layout definition
    },
    {
        "name": "Number Layer",
        "layoutStyle": "split_matrix_explicit", 
        "trigger": "F21",
        "type": "toggle",
        // ... layout definition
    }
]
```

## Configuration Setup

1. **Enable Advanced Settings**:
   - Open OverKeys Preferences
   - Go to Advanced tab
   - Enable "Use User Layouts"

2. **Edit Configuration**:
   - Click "Open Config" button
   - Add your split matrix layout to `userLayouts` array
   - Set `defaultUserLayout` to your layout name

3. **Apply Changes**:
   - Save the configuration file
   - Restart OverKeys or reload config

## Troubleshooting

### Common Issues:

**Layout Not Displaying**:
- Verify `layoutStyle` is set to `"split_matrix_explicit"`
- Check JSON syntax for errors
- Ensure layout name matches `defaultUserLayout`

**Homerow Markers Missing**:
- Verify `homeRow` configuration exists
- Check `rowIndex` is 1-indexed (not 0-indexed)
- Confirm `leftPosition`/`rightPosition` are within row bounds

**Thumb Clusters Not Rendering**:
- Ensure `thumbRows` arrays are properly defined
- Check for empty arrays `[]` vs missing properties
- Verify key names are valid strings or `null`

**Key Press Detection Issues**:
- Use standard key names (see [Supported Keys](supported-keys.md))
- Avoid Unicode characters for primary layers
- Check trigger key is properly mapped

### Validation Tips:

1. **JSON Syntax**: Use a JSON validator to check syntax
2. **Row Consistency**: Ensure mainRows and thumbRows are properly structured
3. **Key Names**: Verify all key strings are valid
4. **Homerow Bounds**: Check positions don't exceed row lengths

## Migration from Standard Format

To convert a standard layout to split matrix format:

1. **Split the Keys**: Divide each row into left and right portions
2. **Add Hand Structure**: Wrap in `leftHand`/`rightHand` objects
3. **Extract Thumbs**: Move thumb keys to separate `thumbRows`
4. **Set Layout Style**: Add `"layoutStyle": "split_matrix_explicit"`
5. **Configure Homerow**: Add `homeRow` metadata for tactile markers

This format provides maximum flexibility for complex keyboard layouts while maintaining backwards compatibility with the standard format.
