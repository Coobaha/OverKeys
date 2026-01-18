class ThumbCluster {
  final List<List<String?>>
      leftKeys; // Array of thumb key rows for left side (supports null)
  final List<List<String?>>
      rightKeys; // Array of thumb key rows for right side (supports null)

  const ThumbCluster({
    required this.leftKeys,
    required this.rightKeys,
  });
}

/// A key with absolute position for physicalLayout rendering
class PhysicalKey {
  final int row;
  final int col;
  final double x;
  final double y;
  final String? label;
  final double w;
  final double h;
  final double rotate;

  const PhysicalKey({
    required this.row,
    required this.col,
    required this.x,
    required this.y,
    this.label,
    this.w = 1.0,
    this.h = 1.0,
    this.rotate = 0,
  });

  factory PhysicalKey.fromJson(Map<String, dynamic> json) {
    return PhysicalKey(
      row: json['row'] as int,
      col: json['col'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      label: json['label'] as String?,
      w: (json['w'] as num?)?.toDouble() ?? 1.0,
      h: (json['h'] as num?)?.toDouble() ?? 1.0,
      rotate: (json['rotate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// A thumb key with absolute position (uses id instead of row/col)
class PhysicalThumbKey {
  final String id;
  final double x;
  final double y;
  final String? label;
  final double w;
  final double h;
  final double rotate;

  const PhysicalThumbKey({
    required this.id,
    required this.x,
    required this.y,
    this.label,
    this.w = 1.0,
    this.h = 1.0,
    this.rotate = 0,
  });

  factory PhysicalThumbKey.fromJson(Map<String, dynamic> json) {
    return PhysicalThumbKey(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      label: json['label'] as String?,
      w: (json['w'] as num?)?.toDouble() ?? 1.0,
      h: (json['h'] as num?)?.toDouble() ?? 1.0,
      rotate: (json['rotate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Physical hand layout with positioned keys
class PhysicalHand {
  final List<PhysicalKey> keys;
  final List<PhysicalThumbKey> thumbKeys;

  const PhysicalHand({
    required this.keys,
    this.thumbKeys = const [],
  });

  factory PhysicalHand.fromJson(Map<String, dynamic> json) {
    return PhysicalHand(
      keys: (json['keys'] as List)
          .map((k) => PhysicalKey.fromJson(k as Map<String, dynamic>))
          .toList(),
      thumbKeys: json['thumbKeys'] != null
          ? (json['thumbKeys'] as List)
              .map((k) => PhysicalThumbKey.fromJson(k as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

enum PhysicalLayoutUnit { keyUnits, pixels, percent }

/// Physical layout with absolute key positioning
class PhysicalLayout {
  final PhysicalLayoutUnit unit;
  final double keySize;
  final double keyPadding;
  final PhysicalHand leftHand;
  final PhysicalHand rightHand;

  const PhysicalLayout({
    this.unit = PhysicalLayoutUnit.keyUnits,
    this.keySize = 54,
    this.keyPadding = 4,
    required this.leftHand,
    required this.rightHand,
  });

  factory PhysicalLayout.fromJson(Map<String, dynamic> json) {
    // Detect QMK/MoErgo format: has "layouts" with "LAYOUT" inside
    if (json['layouts'] != null) {
      return PhysicalLayout._fromQmkFormat(json);
    }

    PhysicalLayoutUnit unit = PhysicalLayoutUnit.keyUnits;
    if (json['unit'] != null) {
      switch (json['unit']) {
        case 'pixels':
          unit = PhysicalLayoutUnit.pixels;
          break;
        case 'percent':
          unit = PhysicalLayoutUnit.percent;
          break;
      }
    }

    return PhysicalLayout(
      unit: unit,
      keySize: (json['keySize'] as num?)?.toDouble() ?? 54,
      keyPadding: (json['keyPadding'] as num?)?.toDouble() ?? 4,
      leftHand: PhysicalHand.fromJson(json['leftHand'] as Map<String, dynamic>),
      rightHand:
          PhysicalHand.fromJson(json['rightHand'] as Map<String, dynamic>),
    );
  }

  /// Parse QMK/MoErgo info.json format
  /// Labels encode position: L_C6R1 = Left Column 6 Row 1, L_T1 = Left Thumb 1
  static PhysicalLayout _fromQmkFormat(Map<String, dynamic> json) {
    final layouts = json['layouts'] as Map<String, dynamic>;
    final layoutName = layouts.keys.first;
    final layoutData = layouts[layoutName] as Map<String, dynamic>;
    final keyList = layoutData['layout'] as List;

    List<PhysicalKey> leftKeys = [];
    List<PhysicalKey> rightKeys = [];
    List<PhysicalThumbKey> leftThumbs = [];
    List<PhysicalThumbKey> rightThumbs = [];

    // Find left hand min X to normalize both hands relative to it
    // This preserves the exact gap between hands from the original coordinates
    double leftMinX = double.infinity;
    for (final key in keyList) {
      final label = key['label'] as String? ?? '';
      final x = (key['x'] as num).toDouble();
      if (label.startsWith('L_')) {
        if (x < leftMinX) leftMinX = x;
      }
    }

    for (final key in keyList) {
      final label = key['label'] as String? ?? '';
      final x = (key['x'] as num).toDouble();
      final y = (key['y'] as num).toDouble();
      final w = (key['w'] as num?)?.toDouble() ?? 1.0;
      final h = (key['h'] as num?)?.toDouble() ?? 1.0;
      final r = (key['r'] as num?)?.toDouble() ?? 0;

      final isLeft = label.startsWith('L_');
      final isThumb = label.contains('_T');

      // Normalize all keys relative to left hand min X
      // This preserves the exact spacing between hands
      final normalizedX = x - leftMinX;

      if (isThumb) {
        final thumbKey = PhysicalThumbKey(
          id: label,
          x: normalizedX,
          y: y,
          w: w,
          h: h,
          rotate: r,
        );
        if (isLeft) {
          leftThumbs.add(thumbKey);
        } else {
          rightThumbs.add(thumbKey);
        }
      } else {
        int row = key['row'] as int? ?? 0;
        int col = key['col'] as int? ?? 0;

        // Right hand columns in QMK are typically 12-17, normalize to 0-5
        if (!isLeft && col >= 12) {
          col -= 12;
        }

        final physKey = PhysicalKey(
          row: row,
          col: col,
          x: normalizedX,
          y: y,
          w: w,
          h: h,
          rotate: r,
        );
        if (isLeft) {
          leftKeys.add(physKey);
        } else {
          rightKeys.add(physKey);
        }
      }
    }

    return PhysicalLayout(
      unit: PhysicalLayoutUnit.keyUnits,
      keySize: (json['keySize'] as num?)?.toDouble() ?? 54,
      keyPadding: (json['keyPadding'] as num?)?.toDouble() ?? 4,
      leftHand: PhysicalHand(keys: leftKeys, thumbKeys: leftThumbs),
      rightHand: PhysicalHand(keys: rightKeys, thumbKeys: rightThumbs),
    );
  }
}

class SplitHand {
  final List<List<String?>> rows;

  const SplitHand({
    required this.rows,
  });
}

class KeyboardLayout {
  final String name;
  final List<List<String?>> keys;
  final String? trigger;
  final String? type;
  final bool? foreign;
  final String?
      layoutStyle; // 'standard', 'matrix', 'split_matrix', 'split_matrix_thumb', 'split_matrix_explicit'
  final ThumbCluster?
      thumbCluster; // Optional thumb cluster for complex layouts
  final SplitHand? leftHand; // Explicit left hand layout
  final SplitHand? rightHand; // Explicit right hand layout
  final Map<String, dynamic>? metadata; // Additional layout metadata
  final PhysicalLayout? physicalLayout; // Absolute key positioning
  final String? activeKey; // Key label to highlight as pressed (layer indicator)

  const KeyboardLayout({
    required this.name,
    required this.keys,
    this.trigger,
    this.type,
    this.foreign,
    this.layoutStyle,
    this.thumbCluster,
    this.leftHand,
    this.rightHand,
    this.metadata,
    this.physicalLayout,
    this.activeKey,
  });
}

const qwerty = KeyboardLayout(
  name: 'QWERTY',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', "'"],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/'],
    [' '],
  ],
  metadata: {
    'homeRow': {
      'rowIndex': 2,
      'leftPosition': 3, // F key
      'rightPosition': 6, // J key
    }
  },
);

const colemak = KeyboardLayout(
  name: 'Colemak',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['Q', 'W', 'F', 'P', 'G', 'J', 'L', 'U', 'Y', ';', '[', ']'],
    ['A', 'R', 'S', 'T', 'D', 'H', 'N', 'E', 'I', 'O', "'"],
    ['Z', 'X', 'C', 'V', 'B', 'K', 'M', ',', '.', '/'],
    [' '],
  ],
  metadata: {
    'homeRow': {
      'rowIndex': 2,
      'leftPosition': 3, // T key
      'rightPosition': 5, // H key
    }
  },
);

const dvorak = KeyboardLayout(
  name: 'Dvorak',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['\'', ',', '.', 'P', 'Y', 'F', 'G', 'C', 'R', 'L', '/', '='],
    ['A', 'O', 'E', 'U', 'I', 'D', 'H', 'T', 'N', 'S', '-'],
    [';', 'Q', 'J', 'K', 'X', 'B', 'M', 'W', 'V', 'Z'],
    [' '],
  ],
);

const colemakdh = KeyboardLayout(
  name: 'Colemak-DH',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['Q', 'W', 'F', 'P', 'B', 'J', 'L', 'U', 'Y', ';', '[', ']'],
    ['A', 'R', 'S', 'T', 'G', 'M', 'N', 'E', 'I', 'O', "'"],
    ['X', 'C', 'D', 'V', 'Z', 'K', 'H', ',', '.', '/'],
    [' '],
  ],
);

const colemakdhMatrix = KeyboardLayout(
  name: 'Colemak-DH Matrix',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['Q', 'W', 'F', 'P', 'B', 'J', 'L', 'U', 'Y', ';', '[', ']'],
    ['A', 'R', 'S', 'T', 'G', 'M', 'N', 'E', 'I', 'O', "'"],
    ['Z', 'X', 'C', 'D', 'V', 'K', 'H', ',', '.', '/'],
    [' '],
  ],
);

const canary = KeyboardLayout(
  name: 'Canary',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ["W", "L", "Y", "P", "K", "Z", "X", "O", "U", ";", "[", "]"],
    ["C", "R", "S", "T", "B", "F", "N", "E", "I", "A", "'"],
    ["J", "V", "D", "G", "Q", "M", "H", "/", ",", "."],
    [" "],
  ],
);

const canaryMatrix = KeyboardLayout(
  name: 'Canary Matrix',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ["W", "L", "Y", "P", "B", "Z", "F", "O", "U", "'", "[", "]"],
    ["C", "R", "S", "T", "G", "M", "N", "E", "I", "A", ";"],
    ["Q", "J", "V", "D", "K", "X", "H", "/", ",", "."],
    [" "],
  ],
);

const canaria = KeyboardLayout(
  name: 'Canaria',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ["W", "L", "Y", "P", "K", "Z", "J", "O", "U", ";", "[", "]"],
    ["C", "R", "S", "T", "B", "F", "N", "E", "I", "A", "'"],
    ["X", "V", "D", "G", "Q", "M", "H", "/", ",", "."],
    [" "],
  ],
);

const workman = KeyboardLayout(
  name: 'Workman',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['Q', 'D', 'R', 'W', 'B', 'J', 'F', 'U', 'P', ';', '[', ']'],
    ['A', 'S', 'H', 'T', 'G', 'Y', 'N', 'E', 'O', 'I', "'"],
    ['Z', 'X', 'M', 'C', 'V', 'K', 'L', ',', '.', '/'],
    [' '],
  ],
);

const nerps = KeyboardLayout(
  name: 'NERPS',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['X', 'L', 'D', 'P', 'V', 'Z', 'K', 'O', 'U', ';', '[', ']'],
    ['N', 'R', 'T', 'S', 'G', 'Y', 'H', 'E', 'I', 'A', "/"],
    ['J', 'M', 'C', 'W', 'Q', 'B', 'F', "'", ',', '.'],
    [' '],
  ],
);

const norman = KeyboardLayout(
  name: 'Norman',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['Q', 'W', 'D', 'F', 'K', 'J', 'U', 'R', 'L', ';', '[', ']'],
    ['A', 'S', 'E', 'T', 'G', 'Y', 'N', 'I', 'O', 'H', "'"],
    ['Z', 'X', 'C', 'V', 'B', 'P', 'M', ',', '.', '/'],
    [' '],
  ],
);

const halmak = KeyboardLayout(
  name: 'Halmak',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['W', 'L', 'R', 'B', 'Z', ';', 'Q', 'U', 'D', 'J', '[', ']'],
    ['S', 'H', 'N', 'T', ',', '.', 'A', 'E', 'O', 'I', "'"],
    ['F', 'M', 'V', 'C', '/', 'G', 'P', 'X', 'K', 'Y'],
    [' '],
  ],
);

const engram = KeyboardLayout(
  name: 'Engram',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['B', 'Y', 'O', 'U', "'", '"', 'L', 'D', 'W', 'V', 'Z', '#'],
    ['C', 'I', 'E', 'A', ',', '.', 'H', 'T', 'S', 'N', 'Q'],
    ['G', 'X', 'J', 'K', '-', '?', 'R', 'M', 'F', 'P'],
    [' '],
  ],
);

const graphite = KeyboardLayout(
  name: 'Graphite',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['B', 'L', 'D', 'W', 'Z', "'", 'F', 'O', 'U', 'J', ';', '='],
    ['N', 'R', 'T', 'S', 'G', 'Y', 'H', 'A', 'E', 'I', ','],
    ['Q', 'X', 'M', 'C', 'V', 'K', 'P', '.', '-', '/'],
    [' '],
  ],
);

const gallium = KeyboardLayout(
  name: 'Gallium',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['B', 'L', 'D', 'C', 'V', 'J', 'Y', 'O', 'U', ',', '[', ']'],
    ['N', 'R', 'T', 'S', 'G', 'P', 'H', 'A', 'E', 'I', '/'],
    ['X', 'Q', 'M', 'W', 'Z', 'K', "F", "'", ';', '.'],
    [' '],
  ],
);

const galliumV2 = KeyboardLayout(
  name: 'Gallium V2',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['B', 'L', 'D', 'C', 'V', 'J', 'F', 'O', 'U', ',', '[', ']'],
    ['N', 'R', 'T', 'S', 'G', 'Y', 'H', 'A', 'E', 'I', '/'],
    ['X', 'Q', 'M', 'W', 'Z', 'K', 'P', "'", ';', '.'],
    [' '],
  ],
);

const sturdy = KeyboardLayout(
  name: 'Sturdy',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['V', 'M', 'L', 'C', 'P', "X", 'F', 'O', 'U', 'J', '[', ']'],
    ['S', 'T', 'R', 'D', 'Y', '.', 'N', 'A', 'E', 'I', '/'],
    ['Z', 'K', 'Q', 'G', 'W', 'B', 'H', "'", ';', ','],
    [' '],
  ],
);

const sturdyAngle = KeyboardLayout(
  name: 'Sturdy Angle',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['V', 'M', 'L', 'C', 'P', "X", 'F', 'O', 'U', 'J', '[', ']'],
    ['S', 'T', 'R', 'D', 'Y', '.', 'N', 'A', 'E', 'I', '/'],
    ['K', 'Q', 'G', 'W', 'Z', 'B', 'H', "'", ';', ','],
    [' '],
  ],
);

const handsDown = KeyboardLayout(name: 'Hands Down', keys: [
  ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
  ['Q', 'C', 'H', 'P', 'V', 'K', 'Y', 'O', 'J', '/', '[', ']'],
  ['R', 'S', 'N', 'T', 'G', 'W', 'U', 'E', 'I', 'A', ';'],
  ['X', 'M', 'L', 'D', 'B', 'Z', 'F', "'", ',', '.'],
  [' '],
]);

const focal = KeyboardLayout(
  name: 'Focal',
  keys: [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
    ['V', 'L', 'H', 'G', 'K', 'Q', 'F', 'O', 'U', 'J', '[', ']'],
    ['S', 'R', 'N', 'T', 'B', 'Y', 'C', 'A', 'E', 'I', '/'],
    ['Z', 'X', 'M', 'D', 'P', "'", 'W', '.', ';', ','],
    [' '],
  ],
);

const russian = KeyboardLayout(
    name: 'Russian',
    keys: [
      ["", "", "", "", "", "", "", "", "", "", "", "", ""],
      ["й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з", "х", "ъ"],
      ["ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э"],
      ["я", "ч", "с", "м", "и", "т", "ь", "б", "ю", "."],
      [" "]
    ],
    foreign: true);

const arabic = KeyboardLayout(
    name: "Arabic",
    keys: [
      ["١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩", "٠", "", "", ""],
      ["ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج", "د"],
      ["ش", "س", "ي", "ب", "ل", "ا", "ت", "ن", "م", "ك", "ط"],
      ["ئ", "ء", "ؤ", "ر", "لا", "ى", "ة", "و", "ز", "ظ"],
      [" "]
    ],
    foreign: true);

const greek = KeyboardLayout(
    name: 'Greek',
    keys: [
      ["", "", "", "", "", "", "", "", "", "", "", "", ""],
      [";", "ς", "ε", "ρ", "τ", "υ", "θ", "ι", "ο", "π", "[", "]"],
      ["α", "σ", "δ", "φ", "γ", "η", "ξ", "κ", "λ", "", "'"],
      ["ζ", "χ", "ψ", "ω", "β", "ν", "μ", ",", ".", "/"],
      [" "]
    ],
    foreign: true);

final List<KeyboardLayout> availableLayouts = [
  qwerty,
  colemak,
  dvorak,
  canaria,
  canary,
  canaryMatrix,
  colemakdh,
  colemakdhMatrix,
  engram,
  focal,
  gallium,
  galliumV2,
  graphite,
  halmak,
  handsDown,
  nerps,
  norman,
  sturdy,
  sturdyAngle,
  workman,
  greek,
  arabic,
  russian,
];
