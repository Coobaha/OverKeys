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

## Physical Layout Configuration (Advanced)

For keyboards with non-standard geometries (curved keys, rotated thumb clusters, asymmetric layouts), the `physicalLayout` format provides absolute control over key positioning.

### When to Use physicalLayout

Use `physicalLayout` instead of columnOffsets when:
- Keys have rotation (angled thumb clusters)
- Keys vary in size (1u, 1.5u, 2u keys)
- Key positions don't follow a grid pattern
- You need pixel-perfect control over visualization

### Schema Overview

The `physicalLayout` is defined at the config root level and applies to all layouts. This avoids duplicating physical key positions across layers - only define it once.

```jsonc
{
    "physicalLayout": {
        "unit": "keyUnits",
        "leftHand": {
            "keys": [
                { "row": 0, "col": 0, "x": 0, "y": 0 },
                { "row": 0, "col": 1, "x": 1.0, "y": -0.1 },
                { "row": 0, "col": 2, "x": 2.0, "y": -0.15, "w": 1.5 }
            ],
            "thumbKeys": [
                { "id": "LT0", "x": 3.5, "y": 4.2, "rotate": -15 },
                { "id": "LT1", "x": 4.8, "y": 4.5, "rotate": -25, "w": 1.5 }
            ]
        },
        "rightHand": {
            "keys": [...],
            "thumbKeys": [...]
        }
    },
    "userLayouts": [
        {
            "name": "Base Layer",
            "layoutStyle": "split_matrix_explicit",
            "leftHand": { "mainRows": [...], "thumbRows": [...] },
            "rightHand": { "mainRows": [...], "thumbRows": [...] }
        },
        {
            "name": "Symbol Layer",
            "trigger": "F20",
            "type": "held",
            "layoutStyle": "split_matrix_explicit",
            "leftHand": { "mainRows": [...], "thumbRows": [...] },
            "rightHand": { "mainRows": [...], "thumbRows": [...] }
        }
    ]
}
```

### Field Reference

#### Root physicalLayout Object

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `unit` | string | No | `"keyUnits"` | Coordinate system: `"keyUnits"`, `"pixels"`, or `"percent"` |
| `keySize` | number | No | 54 | Base key size in pixels (when unit is keyUnits) |
| `keyPadding` | number | No | 4 | Padding between keys in pixels |
| `leftHand` | object | Yes | - | Left hand key positions |
| `rightHand` | object | Yes | - | Right hand key positions |

#### Hand Object (leftHand / rightHand)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `keys` | array | Yes | Main grid keys with position data |
| `thumbKeys` | array | No | Thumb cluster keys (can be positioned anywhere) |

#### Key Object (in keys array)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `row` | integer | Yes | - | Row index in the logical layout (links to mainRows) |
| `col` | integer | Yes | - | Column index in the logical layout |
| `x` | number | Yes | - | Horizontal position (in specified unit) |
| `y` | number | Yes | - | Vertical position (in specified unit) |
| `label` | string | No | - | Display label (overrides logical layout value) |
| `w` | number | No | 1.0 | Width multiplier (1.5 = 1.5u key) |
| `h` | number | No | 1.0 | Height multiplier |
| `rotate` | number | No | 0 | Rotation in degrees (clockwise) |

#### Thumb Key Object (in thumbKeys array)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | string | Yes | - | Unique identifier (e.g., "LT0", "RT1") |
| `x` | number | Yes | - | Horizontal position |
| `y` | number | Yes | - | Vertical position |
| `label` | string | No | - | Display label (overrides thumbRows value) |
| `w` | number | No | 1.0 | Width multiplier |
| `h` | number | No | 1.0 | Height multiplier |
| `rotate` | number | No | 0 | Rotation in degrees |

### Unit Systems

The `unit` field controls how x/y coordinates are interpreted:

- **keyUnits** (default): Coordinates are multiples of keySize + keyPadding. `x: 1.0` means "one key width to the right". Best for most keyboards.
- **pixels**: Raw pixel coordinates from top-left origin. Use when you need exact positioning.
- **percent**: Percentage of total hand width/height (0-100). Use for responsive layouts.

### Linking Physical to Logical Layout

The `physicalLayout` only controls visual positioning. The actual key labels come from the logical layout (`leftHand.mainRows` / `thumbRows`). Link them via:

- Main keys: `row` and `col` indices match into `mainRows[row][col]`
- Thumb keys: `id` matches by index into `thumbRows` (LT0 = thumbRows[0][0], LT1 = thumbRows[0][1], etc.)

This separation allows you to:
1. Define physical positions once
2. Switch logical layouts (symbols, numbers) without changing positions
3. Share physical configs between similar keyboards

### Complete Example: Voyager with Rotated Thumbs

See `docs/examples/voyager-physical-layout.json` for a complete working config with multiple layers sharing a single physicalLayout at the root level.

### Design Tips

1. **Start with keyUnits**: Easier to reason about than pixels
2. **Use row/col for main keys**: Maintains logical structure
3. **Thumb key IDs**: Use consistent naming (LT0, LT1 for left thumbs; RT0, RT1 for right)
4. **Rotation pivot**: Keys rotate around their center point
5. **Test incrementally**: Add a few keys at a time to verify positioning

### Backward Compatibility

When `physicalLayout` is absent, the renderer falls back to:
1. `metadata.columnOffsets` for column stagger
2. `metadata.thumbCluster` for thumb positioning
3. Standard grid-based rendering

You can use `physicalLayout` and `columnOffsets` together - physicalLayout takes precedence for keys it defines.

## QMK/MoErgo info.json Format

You can use the official QMK/MoErgo `info.json` format directly for `physicalLayout`. This lets you copy keyboard definitions from GitHub repos like [moergo-keyboards/go60-zmk-config](https://github.com/moergo-keyboards/go60-zmk-config).

### Format Detection

OverKeys auto-detects the format. If your JSON has a `layouts` key containing `LAYOUT`, it's parsed as QMK format:

```jsonc
{
    "physicalLayout": {
        "layouts": {
            "LAYOUT": {
                "layout": [
                    { "label": "L_C1R1", "row": 0, "col": 0, "x": 0, "y": 0.5 },
                    { "label": "L_T1", "row": 5, "col": 6, "x": 5.2, "y": 4.1, "r": 12.5 }
                ]
            }
        }
    }
}
```

### Label Convention

QMK labels encode position:
- `L_` / `R_` - Left or Right hand
- `C#` - Column number
- `R#` - Row number
- `T#` - Thumb key number

Examples:
- `L_C3R2` = Left hand, Column 3, Row 2
- `R_T1` = Right hand, Thumb key 1

### QMK Key Fields

| Field | Description |
|-------|-------------|
| `label` | Position identifier (L_C#R# or L_T#/R_T#) |
| `row` | Row index |
| `col` | Column index |
| `x` | Horizontal position in key units |
| `y` | Vertical position in key units |
| `w` | Width (default 1.0) |
| `h` | Height (default 1.0) |
| `r` | Rotation in degrees |
| `rx` | Rotation origin X (unused, for reference) |
| `ry` | Rotation origin Y (unused, for reference) |

### Usage

1. Find your keyboard's `info.json` on GitHub
2. Copy the entire file content
3. Paste it as the `physicalLayout` value in your OverKeys config:

```jsonc
{
    "defaultUserLayout": "My Layout",
    "physicalLayout": {
        "layouts": {
            "LAYOUT": {
                "layout": [...]
            }
        }
    },
    "userLayouts": [...]
}
```

The parser automatically:
- Splits keys into left/right hands by `L_`/`R_` prefix
- Identifies thumb keys by `_T` in the label
- Normalizes right hand positions to start from x=0
- Extracts row/col from label pattern or uses provided values

## Active Layer Indicator

Show which key activates a layer with a fingerprint icon. Add `activeKey` to your layer config referencing the physical key ID:

```jsonc
{
    "name": "Symbol Layer",
    "activeKey": "R_T1",
    "layoutStyle": "split_matrix_explicit",
    "leftHand": { ... },
    "rightHand": { ... }
}
```

The `activeKey` value matches the physical layout key ID:
- `L_T1`, `L_T2`, `L_T3` - Left thumb keys
- `R_T1`, `R_T2`, `R_T3` - Right thumb keys

When set, a fingerprint icon renders at that position using the pressed key styling (keyColorPressed, keyTextColor). This provides visual feedback showing which thumb activates the current layer.

Example layer configs:
```jsonc
{
    "name": "Cursor",
    "activeKey": "L_T1",
    ...
},
{
    "name": "Symbol",
    "activeKey": "R_T1",
    ...
},
{
    "name": "Number",
    "activeKey": "R_T2",
    ...
}
```
