import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/keyboard_layouts.dart';
import '../models/mappings.dart';
import '../models/user_config.dart';
import '../widgets/optimized_key_widget.dart';

// AIDEV-NOTE: Performance optimization - shared AutoSizeGroup for all keys
// This prevents each key from recalculating size independently
final AutoSizeGroup _keyTextGroup = AutoSizeGroup();

class KeyboardScreen extends StatelessWidget {
  final KeyboardLayout layout;
  final String keymapStyle;

  // AIDEV-NOTE: Separate AutoSizeGroups for different key types to prevent over-aggressive sizing
  static final AutoSizeGroup _singleCharGroup = AutoSizeGroup();
  static final AutoSizeGroup _multiCharGroup = AutoSizeGroup();
  static final AutoSizeGroup _spaceKeyGroup = AutoSizeGroup();
  final bool showTopRow;
  final bool showGraveKey;
  final double keySize;
  final double keyBorderRadius;
  final double keyBorderThickness;
  final double keyPadding;
  final double rowGap;
  final double spaceWidth;
  final double splitWidth;
  final double lastRowSplitWidth;
  final double keyShadowBlurRadius;
  final double keyShadowOffsetX;
  final double keyShadowOffsetY;
  final double keyFontSize;
  final double spaceFontSize;
  final FontWeight fontWeight;
  final double markerOffset;
  final double markerWidth;
  final double markerHeight;
  final double markerBorderRadius;
  final Color keyColorPressed;
  final Color keyColorNotPressed;
  final Color markerColor;
  final Color markerColorNotPressed;
  final Color keyTextColor;
  final Color keyTextColorNotPressed;
  final Color keyBorderColorPressed;
  final Color keyBorderColorNotPressed;
  final bool animationEnabled;
  final String animationStyle;
  final double animationDuration;
  final double animationScale;
  final bool learningModeEnabled;
  final Color pinkyLeftColor;
  final Color ringLeftColor;
  final Color middleLeftColor;
  final Color indexLeftColor;
  final Color indexRightColor;
  final Color middleRightColor;
  final Color ringRightColor;
  final Color pinkyRightColor;
  final bool showAltLayout;
  final KeyboardLayout? altLayout;
  final bool use6ColLayout;
  final Map<String, String>? customShiftMappings;
  final Map<String, String>?
      actionMappings; // AIDEV-NOTE: Semantic actions to key combinations
  final UserConfig? config;
  final bool
      isShiftPressed; // AIDEV-NOTE: Current shift state for custom shift mappings
  final bool debugMode;
  final bool thumbDebugMode;
  final double?
      maxLayoutWidth; // AIDEV-NOTE: Maximum layout width for consistent positioning
  final double?
      maxLeftHandWidth; // AIDEV-NOTE: Maximum left hand width across all layouts
  final double?
      maxRightHandWidth; // AIDEV-NOTE: Maximum right hand width across all layouts

  const KeyboardScreen({
    super.key,
    required this.layout,
    required this.keymapStyle,
    required this.showTopRow,
    required this.showGraveKey,
    required this.keySize,
    required this.keyBorderRadius,
    required this.keyBorderThickness,
    required this.keyPadding,
    required this.rowGap,
    required this.spaceWidth,
    required this.splitWidth,
    required this.lastRowSplitWidth,
    required this.keyShadowBlurRadius,
    required this.keyShadowOffsetX,
    required this.keyShadowOffsetY,
    required this.keyFontSize,
    required this.spaceFontSize,
    required this.fontWeight,
    required this.markerOffset,
    required this.markerWidth,
    required this.markerHeight,
    required this.markerBorderRadius,
    required this.keyColorPressed,
    required this.keyColorNotPressed,
    required this.markerColor,
    required this.markerColorNotPressed,
    required this.keyTextColor,
    required this.keyTextColorNotPressed,
    required this.keyBorderColorPressed,
    required this.keyBorderColorNotPressed,
    required this.animationEnabled,
    required this.animationStyle,
    required this.animationDuration,
    required this.animationScale,
    required this.learningModeEnabled,
    required this.pinkyLeftColor,
    required this.ringLeftColor,
    required this.middleLeftColor,
    required this.indexLeftColor,
    required this.indexRightColor,
    required this.middleRightColor,
    required this.ringRightColor,
    required this.pinkyRightColor,
    required this.showAltLayout,
    required this.altLayout,
    required this.use6ColLayout,
    this.customShiftMappings,
    this.actionMappings,
    this.config,
    this.isShiftPressed = false,
    this.debugMode = false,
    this.thumbDebugMode = false,
    this.maxLayoutWidth,
    this.maxLeftHandWidth,
    this.maxRightHandWidth,
  });

  /// Get effective physicalLayout - layout's own or config's global
  PhysicalLayout? _getEffectivePhysicalLayout() {
    return layout.physicalLayout ?? config?.physicalLayout;
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG MODE: Text rendering for layout analysis
    if (layout.name.contains("DEBUG")) {
      return buildDebugTextLayout();
    }

    // Physical layout takes precedence - absolute positioning mode
    final physLayout = _getEffectivePhysicalLayout();
    if (debugMode) {
      debugPrint('KeyboardScreen.build: physicalLayout=${physLayout != null}, layout.physicalLayout=${layout.physicalLayout != null}, config?.physicalLayout=${config?.physicalLayout != null}');
    }
    if (physLayout != null) {
      return buildPhysicalLayout();
    }

    // AIDEV-NOTE: Check for explicit split layouts first (fixes row alignment issues)
    if (layout.leftHand != null && layout.rightHand != null) {
      return buildExplicitSplitLayout();
    }

    // Check if this is a complex layout with thumb cluster
    bool hasThumbCluster = layout.thumbCluster != null;

    if (hasThumbCluster) {
      return buildSplitMatrixWithThumbLayout();
    } else {
      return buildStandardLayout();
    }
  }

  Widget buildStandardLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: layout.keys.asMap().entries.where((entry) {
            return showTopRow || entry.key > 0;
          }).map((entry) {
            int rowIndex = entry.key;
            List<String?> row = entry.value;
            return buildRow(rowIndex, row);
          }).toList(),
        ),
      ),
    );
  }

  /// Renders keyboard using absolute positioning from physicalLayout
  Widget buildPhysicalLayout() {
    final physical = _getEffectivePhysicalLayout()!;
    final unitSize = _getPhysicalUnitSize(physical);

    // Debug: print coordinate ranges for verification
    if (debugMode) {
      double lMainMin = double.infinity, lMainMax = 0;
      double lThumbMin = double.infinity, lThumbMax = 0;
      double rMainMin = double.infinity, rMainMax = 0;
      double rThumbMin = double.infinity, rThumbMax = 0;
      for (final k in physical.leftHand.keys) {
        lMainMin = math.min(lMainMin, k.x);
        lMainMax = math.max(lMainMax, k.x);
      }
      for (final k in physical.leftHand.thumbKeys) {
        lThumbMin = math.min(lThumbMin, k.x);
        lThumbMax = math.max(lThumbMax, k.x);
      }
      for (final k in physical.rightHand.keys) {
        rMainMin = math.min(rMainMin, k.x);
        rMainMax = math.max(rMainMax, k.x);
      }
      for (final k in physical.rightHand.thumbKeys) {
        rThumbMin = math.min(rThumbMin, k.x);
        rThumbMax = math.max(rThumbMax, k.x);
      }
      debugPrint('PhysicalLayout coords: L main($lMainMin-$lMainMax) thumb($lThumbMin-$lThumbMax) | R thumb($rThumbMin-$rThumbMax) main($rMainMin-$rMainMax)');
      // Print first few right hand keys to verify positions
      debugPrint('Right main keys: ${physical.rightHand.keys.take(6).map((k) => "r${k.row}c${k.col}@${k.x}").join(", ")}');
      debugPrint('Right thumb keys: ${physical.rightHand.thumbKeys.map((k) => "${k.id}@${k.x}").join(", ")}');
    }

    // Calculate bounding box for all keys
    final bounds = _calculatePhysicalBounds(physical, unitSize);

    // Build positioned keys for both hands
    List<Widget> positionedKeys = [];

    // Left hand keys
    for (final key in physical.leftHand.keys) {
      final pos = _convertToPixels(key.x, key.y, unitSize, physical.unit);
      final label = _getPhysicalKeyLabel(key, true);
      positionedKeys.add(_buildPositionedKey(
        key: key,
        label: label,
        x: pos.$1,
        y: pos.$2,
        unitSize: unitSize,
        isLeft: true,
      ));
    }

    // Left hand thumb keys
    for (int i = 0; i < physical.leftHand.thumbKeys.length; i++) {
      final thumbKey = physical.leftHand.thumbKeys[i];
      final pos =
          _convertToPixels(thumbKey.x, thumbKey.y, unitSize, physical.unit);
      final label = _getPhysicalThumbKeyLabel(thumbKey, i, true);
      positionedKeys.add(_buildPositionedThumbKey(
        thumbKey: thumbKey,
        label: label,
        x: pos.$1,
        y: pos.$2,
        unitSize: unitSize,
        isLeft: true,
        thumbIndex: i,
      ));
    }

    // Right hand keys - coordinates already include proper spacing from QMK format
    for (final key in physical.rightHand.keys) {
      final pos = _convertToPixels(key.x, key.y, unitSize, physical.unit);
      final label = _getPhysicalKeyLabel(key, false);
      if (debugMode && key.row == 0) {
        debugPrint('RIGHT r0c${key.col}: x=${key.x} -> pixel=${pos.$1}, label=$label');
      }
      positionedKeys.add(_buildPositionedKey(
        key: key,
        label: label,
        x: pos.$1,
        y: pos.$2,
        unitSize: unitSize,
        isLeft: false,
      ));
    }

    // Right hand thumb keys
    for (int i = 0; i < physical.rightHand.thumbKeys.length; i++) {
      final thumbKey = physical.rightHand.thumbKeys[i];
      final pos =
          _convertToPixels(thumbKey.x, thumbKey.y, unitSize, physical.unit);
      final label = _getPhysicalThumbKeyLabel(thumbKey, i, false);
      if (debugMode && thumbKey.id == 'R_T1') {
        debugPrint('RIGHT R_T1: x=${thumbKey.x} -> pixel=${pos.$1}, label=$label');
      }
      positionedKeys.add(_buildPositionedThumbKey(
        thumbKey: thumbKey,
        label: label,
        x: pos.$1,
        y: pos.$2,
        unitSize: unitSize,
        isLeft: false,
        thumbIndex: i,
      ));
    }

    // Layer name label at top-center
    final layerLabel = Positioned(
      left: 0,
      right: 0,
      top: -32,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: keyColorNotPressed,
            borderRadius: BorderRadius.circular(keyBorderRadius),
            border: keyBorderThickness > 0
                ? Border.all(color: keyBorderColorNotPressed, width: keyBorderThickness)
                : null,
          ),
          child: Text(
            layout.name,
            style: TextStyle(
              color: keyTextColorNotPressed,
              fontSize: keyFontSize * 0.85,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );

    // Active key fingerprint indicator
    Widget? activeKeyIndicator;
    if (layout.activeKey != null) {
      activeKeyIndicator = _buildActiveKeyIndicator(physical, unitSize);
    }

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        ...positionedKeys,
        if (activeKeyIndicator != null) activeKeyIndicator,
        layerLabel,
      ],
    );

    // Debug marker to verify physicalLayout rendering is active
    if (debugMode) {
      // Calculate key positions for debug markers
      final lC1x = 5.0 * unitSize;  // Left innermost main column
      final lT1x = 5.2 * unitSize;  // Left first thumb
      final rT1x = 11.3 * unitSize; // Right last thumb
      final r0c0x = 11.5 * unitSize; // Right innermost main column
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          ...positionedKeys,
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              color: Colors.red,
              child: Text('PHYSICAL LAYOUT', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
          // Debug: vertical lines for LEFT side
          Positioned(left: lC1x, top: 0, child: Container(width: 2, height: 300, color: Colors.yellow)),
          Positioned(left: lT1x, top: 0, child: Container(width: 2, height: 300, color: Colors.cyan)),
          // Debug: vertical lines for RIGHT side
          Positioned(left: rT1x, top: 0, child: Container(width: 2, height: 300, color: Colors.green)),
          Positioned(left: r0c0x, top: 0, child: Container(width: 2, height: 300, color: Colors.blue)),
        ],
      );
    }

    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.all(keyPadding),
      child: SizedBox(
        width: bounds.totalWidth,
        height: bounds.totalHeight,
        child: content,
      ),
    );
  }

  /// Gets the pixel size for one unit based on physicalLayout settings
  double _getPhysicalUnitSize(PhysicalLayout physical) {
    switch (physical.unit) {
      case PhysicalLayoutUnit.keyUnits:
        // QMK coordinates use key units where 1 unit = 1 key width
        // We use keySize + keyPadding so adjacent keys (x=0, x=1) have proper spacing
        return keySize + keyPadding;
      case PhysicalLayoutUnit.pixels:
        return 1.0;
      case PhysicalLayoutUnit.percent:
        // Percent mode - will need container width, use keySize as base
        return keySize / 100.0;
    }
  }

  /// Convert x,y coordinates to pixel positions
  (double, double) _convertToPixels(
      double x, double y, double unitSize, PhysicalLayoutUnit unit) {
    return (x * unitSize, y * unitSize);
  }

  /// Build fingerprint indicator for active layer key
  Widget? _buildActiveKeyIndicator(PhysicalLayout physical, double unitSize) {
    final activeKey = layout.activeKey;
    if (activeKey == null) return null;

    // Search thumb keys first (most common for layer keys)
    for (final thumbKey in physical.leftHand.thumbKeys) {
      if (thumbKey.id == activeKey) {
        return _buildFingerprintAtPosition(thumbKey.x, thumbKey.y, thumbKey.w, thumbKey.h, thumbKey.rotate, unitSize);
      }
    }
    for (final thumbKey in physical.rightHand.thumbKeys) {
      if (thumbKey.id == activeKey) {
        return _buildFingerprintAtPosition(thumbKey.x, thumbKey.y, thumbKey.w, thumbKey.h, thumbKey.rotate, unitSize);
      }
    }

    // Search main keys (activeKey can be label like "L_C1R3" or match by label content)
    for (final key in physical.leftHand.keys) {
      final label = _getPhysicalKeyLabel(key, true);
      if (activeKey == 'L_C${key.col + 1}R${key.row + 1}' || label == activeKey) {
        return _buildFingerprintAtPosition(key.x, key.y, key.w, key.h, key.rotate, unitSize);
      }
    }
    for (final key in physical.rightHand.keys) {
      final label = _getPhysicalKeyLabel(key, false);
      if (activeKey == 'R_C${key.col + 1}R${key.row + 1}' || label == activeKey) {
        return _buildFingerprintAtPosition(key.x, key.y, key.w, key.h, key.rotate, unitSize);
      }
    }

    return null;
  }

  /// Render fingerprint icon at physical position
  Widget _buildFingerprintAtPosition(double x, double y, double w, double h, double rotate, double unitSize) {
    final pos = _convertToPixels(x, y, unitSize, PhysicalLayoutUnit.keyUnits);
    final keyW = keySize * w;
    final keyH = keySize * h;

    Widget indicator = Container(
      width: keyW + keyPadding * 2,
      height: keyH + keyPadding * 2,
      padding: EdgeInsets.all(keyPadding),
      child: Container(
        decoration: BoxDecoration(
          color: keyColorPressed,
          borderRadius: BorderRadius.circular(keyBorderRadius),
          border: keyBorderThickness > 0
              ? Border.all(color: keyBorderColorPressed, width: keyBorderThickness)
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.fingerprint,
            color: keyTextColor,
            size: keyFontSize * 1.8,
          ),
        ),
      ),
    );

    if (rotate != 0) {
      indicator = Transform.rotate(
        angle: rotate * (math.pi / 180),
        alignment: Alignment.topLeft,
        child: indicator,
      );
    }

    return Positioned(
      left: pos.$1,
      top: pos.$2,
      child: indicator,
    );
  }

  /// Calculate bounding box for all keys in physical layout
  ({double leftWidth, double rightWidth, double totalWidth, double totalHeight})
      _calculatePhysicalBounds(PhysicalLayout physical, double unitSize) {
    double maxX = 0;
    double maxY = 0;

    // Calculate bounds across all keys (both hands share same coordinate space)
    for (final key in physical.leftHand.keys) {
      final pos = _convertToPixels(key.x, key.y, unitSize, physical.unit);
      final keyW = keySize * key.w;
      final keyH = keySize * key.h;
      maxX = math.max(maxX, pos.$1 + keyW + keyPadding * 2);
      maxY = math.max(maxY, pos.$2 + keyH + keyPadding * 2);
    }
    for (final thumbKey in physical.leftHand.thumbKeys) {
      final pos = _convertToPixels(thumbKey.x, thumbKey.y, unitSize, physical.unit);
      final keyW = keySize * thumbKey.w;
      final keyH = keySize * thumbKey.h;
      maxX = math.max(maxX, pos.$1 + keyW + keyPadding * 2);
      maxY = math.max(maxY, pos.$2 + keyH + keyPadding * 2);
    }
    for (final key in physical.rightHand.keys) {
      final pos = _convertToPixels(key.x, key.y, unitSize, physical.unit);
      final keyW = keySize * key.w;
      final keyH = keySize * key.h;
      maxX = math.max(maxX, pos.$1 + keyW + keyPadding * 2);
      maxY = math.max(maxY, pos.$2 + keyH + keyPadding * 2);
    }
    for (final thumbKey in physical.rightHand.thumbKeys) {
      final pos = _convertToPixels(thumbKey.x, thumbKey.y, unitSize, physical.unit);
      final keyW = keySize * thumbKey.w;
      final keyH = keySize * thumbKey.h;
      maxX = math.max(maxX, pos.$1 + keyW + keyPadding * 2);
      maxY = math.max(maxY, pos.$2 + keyH + keyPadding * 2);
    }

    return (
      leftWidth: maxX,  // Not used separately anymore
      rightWidth: 0.0,  // Not used separately anymore
      totalWidth: maxX,
      totalHeight: maxY,
    );
  }

  /// Get label for a physical key from logical layout
  String? _getPhysicalKeyLabel(PhysicalKey key, bool isLeft) {
    // If key has explicit label, use it
    if (key.label != null) return key.label;

    // Otherwise look up from logical layout
    final hand = isLeft ? layout.leftHand : layout.rightHand;
    if (hand != null &&
        key.row < hand.rows.length &&
        key.col < hand.rows[key.row].length) {
      return hand.rows[key.row][key.col];
    }
    return null;
  }

  /// Get label for a physical thumb key from logical layout
  String? _getPhysicalThumbKeyLabel(
      PhysicalThumbKey thumbKey, int index, bool isLeft) {
    // If thumb key has explicit label, use it
    if (thumbKey.label != null) return thumbKey.label;

    // Otherwise look up from thumb cluster
    if (layout.thumbCluster != null) {
      final thumbKeys =
          isLeft ? layout.thumbCluster!.leftKeys : layout.thumbCluster!.rightKeys;
      // Parse id to get row/col (e.g., "LT0" -> row 0, col 0; "LT1" -> row 0, col 1)
      // Simple approach: flatten thumb keys and use index
      int flatIndex = 0;
      for (int row = 0; row < thumbKeys.length; row++) {
        for (int col = 0; col < thumbKeys[row].length; col++) {
          if (flatIndex == index) {
            return thumbKeys[row][col];
          }
          flatIndex++;
        }
      }
    }
    return null;
  }

  /// Build a positioned key widget with rotation support
  Widget _buildPositionedKey({
    required PhysicalKey key,
    required String? label,
    required double x,
    required double y,
    required double unitSize,
    required bool isLeft,
  }) {
    final keyW = keySize * key.w;
    final keyH = keySize * key.h;

    Widget keyWidget;
    if (debugMode) {
      // Debug: use simple box to isolate layout issues
      keyWidget = Container(
        width: keyW + keyPadding * 2,
        height: keyH + keyPadding * 2,
        decoration: BoxDecoration(
          color: isLeft ? Colors.blue.withOpacity(0.5) : Colors.red.withOpacity(0.5),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Center(child: Text(label ?? '?', style: TextStyle(fontSize: 10, color: Colors.white))),
      );
    } else {
      keyWidget = Container(
        width: keyW + keyPadding * 2,
        height: keyH + keyPadding * 2,
        child: buildOptimizedKey(key.row, label, key.col),
      );
    }

    // Apply rotation around top-left corner (QMK uses position as pivot)
    if (key.rotate != 0) {
      keyWidget = Transform.rotate(
        angle: key.rotate * (math.pi / 180),
        alignment: Alignment.topLeft,
        child: keyWidget,
      );
    }

    // Debug: add marker showing actual position for boundary keys
    if (debugMode && key.row == 0 && ((key.col == 5 && isLeft) || (key.col == 0 && !isLeft))) {
      return Positioned(
        left: x,
        top: y,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            keyWidget,
            Positioned(
              left: 0,
              top: 0,
              child: Container(width: 10, height: 10, color: isLeft ? Colors.orange : Colors.red),
            ),
          ],
        ),
      );
    }
    return Positioned(
      left: x,
      top: y,
      child: keyWidget,
    );
  }

  /// Build a positioned thumb key widget with rotation support
  Widget _buildPositionedThumbKey({
    required PhysicalThumbKey thumbKey,
    required String? label,
    required double x,
    required double y,
    required double unitSize,
    required bool isLeft,
    required int thumbIndex,
  }) {
    final keyW = keySize * thumbKey.w;
    final keyH = keySize * thumbKey.h;

    Widget keyWidget = SizedBox(
      width: keyW + keyPadding * 2,
      height: keyH + keyPadding * 2,
      child: buildOptimizedKey(-1, label, thumbIndex, isThumbKey: true),
    );

    // Apply rotation around top-left corner (QMK rx/ry = x/y means pivot at position)
    if (thumbKey.rotate != 0) {
      keyWidget = Transform.rotate(
        angle: thumbKey.rotate * (math.pi / 180),
        alignment: Alignment.topLeft,
        child: keyWidget,
      );
    }

    return Positioned(
      left: x,
      top: y,
      child: keyWidget,
    );
  }

  Widget buildDebugTextLayout() {
    StringBuffer debug = StringBuffer();
    debug.writeln("DEBUG: Glove80 Layout Analysis");
    debug.writeln("Layout: ${layout.name}");
    debug.writeln("Keys matrix: ${layout.keys.length} rows");

    for (int i = 0; i < layout.keys.length; i++) {
      List<String?> row = layout.keys[i];
      int leftCount = _getLeftSideCount(i);
      int rightStart = _getRightSideStart(i, row.length);

      debug.writeln(
          "Row $i: ${row.length} keys, left=$leftCount, right_start=$rightStart");
      debug.write("  LEFT:  [");
      for (int j = 0; j < leftCount && j < row.length; j++) {
        debug.write(
            "${row[j]?.isEmpty != false ? '_' : row[j]}${j < leftCount - 1 ? ',' : ''}");
      }
      debug.write("] | RIGHT: [");
      for (int j = rightStart; j < row.length; j++) {
        debug.write(
            "${row[j]?.isEmpty != false ? '_' : row[j]}${j < row.length - 1 ? ',' : ''}");
      }
      debug.writeln("]");
    }

    if (layout.thumbCluster != null) {
      debug.writeln("Thumb Cluster:");
      debug.writeln("  Left: ${layout.thumbCluster!.leftKeys}");
      debug.writeln("  Right: ${layout.thumbCluster!.rightKeys}");
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          debug.toString(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildSplitMatrixWithThumbLayout() {
    List<Widget> mainRows = [];

    // Build main matrix rows
    for (int i = 0; i < layout.keys.length; i++) {
      if (!showTopRow && i == 0) continue;
      mainRows.add(buildSplitMatrixRow(i, layout.keys[i]));
    }

    // Build thumb cluster if present
    Widget? thumbClusterWidget;
    if (layout.thumbCluster != null) {
      thumbClusterWidget = buildThumbCluster(layout.thumbCluster!);
    }

    double thumbVerticalOffset = _getThumbClusterVerticalOffset();
    double maxOffsetHeight = _getMaxColumnOffset();

    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.all(keyPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...mainRows,
          if (thumbClusterWidget != null) ...[
            // Minimal gap - just rowGap plus any configured vertical offset
            SizedBox(height: rowGap + thumbVerticalOffset),
            thumbClusterWidget,
          ],
          // Extra space at bottom for offset keys overflow
          SizedBox(height: maxOffsetHeight),
        ],
      ),
    );
  }

  // AIDEV-NOTE: Dedicated rendering for explicit split layouts - fixes row alignment by using separate left/right hand data
  Widget buildExplicitSplitLayout() {
    List<Widget> mainRows = [];

    // Get the maximum number of rows between left and right hands
    int maxRows = math.max(
        layout.leftHand?.rows.length ?? 0, layout.rightHand?.rows.length ?? 0);

    // Build main matrix rows using separate left/right hand data
    for (int i = 0; i < maxRows; i++) {
      if (!showTopRow && i == 0) continue;
      mainRows.add(buildExplicitSplitRow(i));
    }

    // Build thumb cluster if present
    Widget? thumbClusterWidget;
    if (layout.thumbCluster != null) {
      thumbClusterWidget = buildThumbCluster(layout.thumbCluster!);
    }

    // Use fixed-width container to prevent layout shifting when switching layers
    double thumbVerticalOffset = _getThumbClusterVerticalOffset();
    double maxOffsetHeight = _getMaxColumnOffset();

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...mainRows,
        if (thumbClusterWidget != null) ...[
          // Minimal gap - just rowGap plus any configured vertical offset
          SizedBox(height: rowGap + thumbVerticalOffset),
          thumbClusterWidget,
        ],
        // Extra space at bottom for offset keys overflow
        SizedBox(height: maxOffsetHeight),
      ],
    );

    // If we have maxLayoutWidth, use it for consistent positioning
    if (maxLayoutWidth != null) {
      content = SizedBox(
        width: maxLayoutWidth,
        child: content,
      );
    }

    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.all(keyPadding),
      child: content,
    );
  }

  // AIDEV-NOTE: Renders a single row using separate left/right hand data - prevents alignment issues
  Widget buildExplicitSplitRow(int rowIndex) {
    // Get left hand keys for this row (or empty if row doesn't exist)
    List<String?> leftKeys = [];
    if (layout.leftHand != null && rowIndex < layout.leftHand!.rows.length) {
      leftKeys = layout.leftHand!.rows[rowIndex];
    }

    // Get right hand keys for this row (or empty if row doesn't exist)
    List<String?> rightKeys = [];
    if (layout.rightHand != null && rowIndex < layout.rightHand!.rows.length) {
      rightKeys = layout.rightHand!.rows[rowIndex];
    }

    // Build left hand key widgets with column labels (C6 to C1, right to left)
    List<Widget> leftWidgets = [];
    for (int i = 0; i < leftKeys.length; i++) {
      Widget keyWidget = buildOptimizedKey(rowIndex, leftKeys[i], i);

      // Add column label for debug mode (left hand: C6 to C1)
      if (debugMode) {
        int columnNumber = leftKeys.length - i; // C6, C5, C4, C3, C2, C1
        keyWidget = Stack(
          children: [
            keyWidget,
            Positioned(
              bottom: 2,
              left: 2,
              child: Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'C$columnNumber',
                  style: TextStyle(
                      fontSize: 6,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      }

      // Apply column offset for physical layout accuracy (left hand)
      double columnOffset = _getLeftColumnOffset(i, leftKeys.length);
      if (columnOffset != 0) {
        keyWidget = Container(
          margin: EdgeInsets.only(top: columnOffset),
          child: keyWidget,
        );
      }

      leftWidgets.add(keyWidget);
      if (i < leftKeys.length - 1) {
        leftWidgets.add(SizedBox(width: keyPadding));
      }
    }

    // Build right hand key widgets with column labels (C1 to C6, left to right)
    List<Widget> rightWidgets = [];
    for (int i = 0; i < rightKeys.length; i++) {
      Widget keyWidget = buildOptimizedKey(rowIndex, rightKeys[i], i);

      // Add column label for debug mode (right hand: C1 to C6)
      if (debugMode) {
        int columnNumber = i + 1; // C1, C2, C3, C4, C5, C6
        keyWidget = Stack(
          children: [
            keyWidget,
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'C$columnNumber',
                  style: TextStyle(
                      fontSize: 6,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      }

      // Apply column offset for physical layout accuracy (right hand)
      double columnOffset = _getRightColumnOffset(i, rightKeys.length);
      if (columnOffset != 0) {
        keyWidget = Container(
          margin: EdgeInsets.only(top: columnOffset),
          child: keyWidget,
        );
      }

      rightWidgets.add(keyWidget);
      if (i < rightKeys.length - 1) {
        rightWidgets.add(SizedBox(width: keyPadding));
      }
    }

    // Calculate dynamic widths based on actual key layout to prevent cropping
    double calculatedLeftWidth = _calculateLeftHandWidth();
    double calculatedRightWidth = _calculateRightHandWidth();

    // AIDEV-NOTE: Use maximum hand widths if available to prevent shifting between layouts
    double leftHandWidth = maxLeftHandWidth ?? calculatedLeftWidth;
    double rightHandWidth = maxRightHandWidth ?? calculatedRightWidth;

    // Row height is just the key size + padding - offset keys overflow and overlap with adjacent rows
    double rowHeight = keySize + (keyPadding * 2);

    Widget rowWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none, // Allow overflow for offset keys
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add row label for debug mode
          if (debugMode) ...[
            Container(
              width: 30,
              height: keySize,
              alignment: Alignment.center,
              child: Text(
                'R${rowIndex + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          // Left hand - fixed width container, allows overflow for offset keys
          SizedBox(
            width: leftHandWidth,
            height: rowHeight,
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: leftWidgets.isEmpty && debugMode
                      ? [Text('LEFT EMPTY', style: TextStyle(fontSize: 10))]
                      : leftWidgets,
                ),
              ),
            ),
          ),
          // Split gap
          SizedBox(width: splitWidth),
          // Right hand - fixed width container, allows overflow for offset keys
          SizedBox(
            width: rightHandWidth,
            height: rowHeight,
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: rightWidgets.isEmpty && debugMode
                      ? [Text('RIGHT EMPTY', style: TextStyle(fontSize: 10))]
                      : rightWidgets,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowGap / 2),
      child: rowWidget,
    );
  }

  Widget buildThumbCluster(ThumbCluster thumbCluster) {
    // Use configured thumb gap from metadata, or default to 40% of split width
    double thumbGap = _getThumbClusterGap();

    // Calculate hand widths to match main keyboard layout
    double calculatedLeftWidth = _calculateLeftHandWidth();
    double calculatedRightWidth = _calculateRightHandWidth();
    double leftHandWidth = maxLeftHandWidth ?? calculatedLeftWidth;
    double rightHandWidth = maxRightHandWidth ?? calculatedRightWidth;

    Widget thumbWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left thumb cluster - aligned with left hand width
          SizedBox(
            width: leftHandWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to inner edge
              children: [
                buildThumbClusterSide(thumbCluster.leftKeys, true),
              ],
            ),
          ),
          // Split gap (same as main keyboard)
          SizedBox(width: splitWidth),
          // Right thumb cluster - aligned with right hand width
          SizedBox(
            width: rightHandWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Align to inner edge
              children: [
                buildThumbClusterSide(thumbCluster.rightKeys, false),
              ],
            ),
          ),
        ],
      ),
    );

    // Add thumb debug visualization
    if (thumbDebugMode) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.3),
          border: Border.all(color: Colors.purple, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text('THUMB CLUSTER',
                style: TextStyle(fontSize: 10, color: Colors.purple)),
            thumbWidget,
          ],
        ),
      );
    }

    return thumbWidget;
  }

  Widget buildThumbClusterSide(List<List<String?>> thumbKeys, bool isLeft) {
    List<Widget> thumbRows = [];

    for (int rowIndex = 0; rowIndex < thumbKeys.length; rowIndex++) {
      List<Widget> rowWidgets = [];
      List<String?> keys = thumbKeys[rowIndex];

      // Handle empty rows - render as invisible spacer to maintain row structure
      if (keys.isEmpty) {
        thumbRows.add(SizedBox(
            height: keySize + keyPadding * 2)); // Same height as normal row
        if (rowIndex < thumbKeys.length - 1) {
          thumbRows.add(SizedBox(height: rowGap)); // Row spacing
        }
        continue;
      }

      for (int keyIndex = 0; keyIndex < keys.length; keyIndex++) {
        String? key = keys[keyIndex];
        Widget thumbKey =
            buildOptimizedKey(-1, key, keyIndex, isThumbKey: true);

        // Add thumb debug numbering based on Glove80 layout
        if (thumbDebugMode) {
          // Calculate thumb key number based on Glove80 layout
          int thumbKeyNumber = _getThumbKeyNumber(rowIndex, keyIndex, isLeft);
          thumbKey = Stack(
            children: [
              thumbKey,
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('T$thumbKeyNumber',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        }

        rowWidgets.add(thumbKey);
        if (keyIndex < keys.length - 1) {
          rowWidgets.add(SizedBox(width: keyPadding));
        }
      }

      if (rowWidgets.isNotEmpty) {
        thumbRows.add(Row(
          mainAxisAlignment:
              isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: rowWidgets,
        ));
        if (rowIndex < thumbKeys.length - 1) {
          thumbRows.add(SizedBox(height: rowGap));
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: thumbRows,
    );
  }

  Widget buildSplitMatrixRow(int rowIndex, List<String?> keys) {
    // Determine split point based on row
    int leftSideCount = _getLeftSideCount(rowIndex);
    int rightSideStart = _getRightSideStart(rowIndex, keys.length);

    // Build left hand keys
    List<Widget> leftKeys = [];
    for (int i = 0; i < leftSideCount && i < keys.length; i++) {
      leftKeys.add(buildOptimizedKey(rowIndex, keys[i], i));
      if (i < leftSideCount - 1) {
        leftKeys.add(SizedBox(width: keyPadding));
      }
    }

    // Build right hand keys
    List<Widget> rightKeys = [];
    for (int i = rightSideStart; i < keys.length; i++) {
      rightKeys.add(buildOptimizedKey(rowIndex, keys[i], i));
      if (i < keys.length - 1) {
        rightKeys.add(SizedBox(width: keyPadding));
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowGap / 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Left hand - right aligned
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: leftKeys,
            ),
            // Split gap
            SizedBox(width: splitWidth),
            // Right hand - left aligned
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: rightKeys,
            ),
          ],
        ),
      ),
    );
  }

  int _getLeftSideCount(int rowIndex) {
    // BEST: Use leftHand data when available (explicit format)
    if (layout.leftHand != null && rowIndex < layout.leftHand!.rows.length) {
      int leftCount = layout.leftHand!.rows[rowIndex].length;
      return leftCount;
    }

    // SMART: Auto-detect split point by analyzing key density
    List<String?> row = layout.keys[rowIndex];

    // Strategy 1: Find natural break - look for sequence of empty keys
    int consecutiveEmpty = 0;
    int lastNonEmptyIndex = -1;

    for (int i = 0; i < row.length; i++) {
      if (row[i]?.isEmpty != false) {
        consecutiveEmpty++;
      } else {
        if (consecutiveEmpty >= 2) {
          // Found a gap of 2+ empty keys, split before the gap
          return lastNonEmptyIndex + 1;
        }
        consecutiveEmpty = 0;
        lastNonEmptyIndex = i;
      }
    }

    // Strategy 2: Split roughly in half (ergonomic keyboards usually slightly left-heavy)
    int halfPoint = (row.length / 2).floor();
    return halfPoint;
  }

  int _getRightSideStart(int rowIndex, int totalKeys) {
    // FIXED: For new format, right side always starts immediately after left side
    if (layout.leftHand != null && layout.rightHand != null) {
      // New explicit format: right side starts right after left side
      return _getLeftSideCount(rowIndex);
    }

    // EMERGENCY FIX: Force correct right side start for Glove80
    if (layout.name.contains("Glove80")) {
      int leftCount = _getLeftSideCount(rowIndex);
      List<String?> row = layout.keys[rowIndex];

      // For new format compatibility: right side starts immediately after left
      if (row.length == 10) {
        // 5+5 format
        return leftCount;
      }

      // Find first non-empty key after position leftCount (old format)
      for (int i = leftCount; i < row.length; i++) {
        if (row[i]?.isNotEmpty == true) {
          return i;
        }
      }
      // Fallback
      return leftCount + 1;
    }

    // Generic fallback
    return _getLeftSideCount(rowIndex);
  }

  Widget buildRow(int rowIndex, List<String?> keys) {
    List<Widget> rowWidgets = [];

    if (keymapStyle != 'Matrix' && keymapStyle != 'Split Matrix') {
      for (int i = 0; i < keys.length; i++) {
        if (rowIndex == 0 && i == 0 && !showGraveKey) continue;

        bool isLastKeyFirstRow =
            rowIndex == 0 && i == keys.length - 1 && showGraveKey;
        rowWidgets.add(buildOptimizedKey(rowIndex, keys[i], i,
            isLastKeyFirstRow: isLastKeyFirstRow));
      }
    } else {
      int startIndex =
          (rowIndex == 0 && (keymapStyle != 'Split Matrix' || !showGraveKey))
              ? 1
              : 0;
      int endIndex = (rowIndex == 0) ? 11 : (use6ColLayout ? 12 : 10);

      // Special handling for first row in Split Matrix with 6 columns
      if (rowIndex == 0 && keymapStyle == 'Split Matrix' && use6ColLayout) {
        rowWidgets.add(buildOptimizedKey(rowIndex, keys[0], 0));

        for (int i = 1; i < 6; i++) {
          rowWidgets.add(buildOptimizedKey(rowIndex, keys[i], i));
        }

        rowWidgets.add(SizedBox(width: splitWidth));

        for (int i = 6; i < 11; i++) {
          rowWidgets.add(buildOptimizedKey(rowIndex, keys[i], i));
        }

        rowWidgets.add(buildOptimizedKey(rowIndex, keys[11], 11));
      } else {
        for (int i = startIndex; i < keys.length && i < endIndex; i++) {
          if (keymapStyle == 'Split Matrix') {
            if ((rowIndex == 0 && i == 6) ||
                (i == (use6ColLayout ? 6 : 5) &&
                    rowIndex > 0 &&
                    rowIndex < 4)) {
              rowWidgets.add(SizedBox(width: splitWidth));
            } else if (i == keys.length ~/ 2 &&
                rowIndex == 4 &&
                keys.length != 1) {
              rowWidgets.add(SizedBox(width: lastRowSplitWidth));
            }
          }

          if (keymapStyle == 'Split Matrix' &&
              rowIndex == 4 &&
              keys[i] == " " &&
              keys.length == 1) {
            rowWidgets.add(buildOptimizedKey(rowIndex, keys[i], i));
            rowWidgets.add(SizedBox(width: lastRowSplitWidth));
            rowWidgets.add(buildOptimizedKey(rowIndex, keys[i], i));
          } else {
            rowWidgets.add(buildOptimizedKey(rowIndex, keys[i], i));
          }
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rowWidgets,
      ),
    );
  }

  // AIDEV-NOTE: Replace buildKeys() method with OptimizedKeyWidget creation
  Widget buildOptimizedKey(int rowIndex, String? key, int keyIndex,
      {bool isLastKeyFirstRow = false, bool isThumbKey = false}) {
    // Handle null as invisible placeholder
    if (key == null) {
      return Padding(
        padding: EdgeInsets.all(keyPadding),
        child: SizedBox(width: keySize, height: keySize),
      );
    }

    // Generate unique physical key identifier
    final physicalKey = _generatePhysicalKeyId(rowIndex, keyIndex, key);

    return OptimizedKeyWidget(
      keyLabel: key,
      physicalKey: physicalKey,
      rowIndex: rowIndex,
      keyIndex: keyIndex,
      keySize: keySize,
      keyBorderRadius: keyBorderRadius,
      keyBorderThickness: keyBorderThickness,
      keyPadding: keyPadding,
      keyFontSize: keyFontSize,
      fontWeight: fontWeight,
      keyColorPressed: keyColorPressed,
      keyColorNotPressed: keyColorNotPressed,
      keyTextColor: keyTextColor,
      keyTextColorNotPressed: keyTextColorNotPressed,
      keyBorderColorPressed: keyBorderColorPressed,
      keyBorderColorNotPressed: keyBorderColorNotPressed,
      animationEnabled: animationEnabled,
      animationStyle: animationStyle,
      animationDuration: animationDuration,
      animationScale: animationScale,
      learningModeEnabled: learningModeEnabled,
      fingerColors: [
        pinkyLeftColor,
        ringLeftColor,
        middleLeftColor,
        indexLeftColor,
        indexRightColor,
        middleRightColor,
        ringRightColor,
        pinkyRightColor,
      ],
      actionMappings: actionMappings,
      isLastKeyFirstRow: isLastKeyFirstRow,
      spaceWidth: spaceWidth,
      autoSizeGroup: _getAutoSizeGroup(key),
      isShiftPressed: isShiftPressed,
      customShiftMappings: customShiftMappings,
      isActiveKey: layout.activeKey != null && key == layout.activeKey,
    );
  }

  // AIDEV-NOTE: Generate unique physical key identifier
  String _generatePhysicalKeyId(int rowIndex, int keyIndex, String? key) {
    // AIDEV-NOTE: Use the base layout key for consistent physical key mapping
    // This ensures the same physical key is tracked regardless of layer switches
    if (key == null) return 'null_${rowIndex}_$keyIndex';

    // Get the base layout key at this position for consistent physical key identification
    String baseKey = key;
    if (showAltLayout && altLayout != null) {
      // Use the base layout (current layout when altLayout is not shown)
      // We need to get the base key from the main layout, not the alt layout
      if (rowIndex < layout.keys.length &&
          keyIndex < layout.keys[rowIndex].length) {
        final baseLayoutKey = layout.keys[rowIndex][keyIndex];
        if (baseLayoutKey != null) {
          baseKey = baseLayoutKey;
        }
      }
    }

    // Use Mappings.getKeyForSymbol to get the physical key that keyboard events will send
    return Mappings.getKeyForSymbol(baseKey);
  }

  // AIDEV-NOTE: Choose appropriate AutoSizeGroup based on key content to prevent over-aggressive sizing
  AutoSizeGroup? _getAutoSizeGroup(String? key) {
    if (key == null || key.isEmpty) return null;

    // Space key gets its own group
    if (key == ' ') return _spaceKeyGroup;

    // Single character keys
    if (key.length <= 1) return _singleCharGroup;

    // Multi-character keys (like "delete", "enter", etc.)
    return _multiCharGroup;
  }

  // ignore: unused_element
  Widget _buildKeyText(
      String? key, Color textColor, double fontSize, FontWeight fontWeight) {
    if (key == null) return const SizedBox.shrink();

    // AIDEV-NOTE: Apply action mappings and display name processing with shift state
    final displayText = Mappings.getDisplayName(key, actionMappings,
        isShiftPressed: isShiftPressed,
        customShiftMappings: customShiftMappings);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: _buildOptimizedKeyText(
        displayText,
        textColor,
        fontSize,
        fontWeight,
      ),
    );
  }

  // AIDEV-NOTE: Optimized text rendering with shared AutoSizeGroup
  Widget _buildOptimizedKeyText(String displayText, Color textColor,
      double fontSize, FontWeight fontWeight) {
    return AutoSizeText(
      displayText,
      group: _keyTextGroup, // Use shared group for performance
      style: TextStyle(
        color: textColor,
        fontWeight: fontWeight,
        fontSize: fontSize,
        // AIDEV-NOTE: Let fontFamily inherit from Theme automatically
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      minFontSize: 8,
      overflow: TextOverflow.visible,
      wrapWords: false, // Only break at word boundaries, not mid-word
    );
  }

  // AIDEV-NOTE: Maps thumb keys to T1-T6 numbering for debug visualization
  int _getThumbKeyNumber(int rowIndex, int keyIndex, bool isLeft) {
    if (isLeft) {
      // Left thumb cluster mapping: T1-T3 (top), T4-T6 (bottom)
      if (rowIndex == 0) {
        // Top row: T1, T2, T3
        return 1 + keyIndex;
      } else if (rowIndex == 1) {
        // Bottom row: T4, T5, T6
        return 4 + keyIndex;
      }
    } else {
      // Right thumb cluster mapping: T1-T3 (top), T4-T6 (bottom)
      if (rowIndex == 0) {
        // Top row: T1, T2, T3
        return 1 + keyIndex;
      } else if (rowIndex == 1) {
        // Bottom row: T4, T5, T6
        return 4 + keyIndex;
      }
    }
    return 9; // Fallback for unknown positions
  }

  // Gets effective metadata - checks layout first, then falls back to global config
  Map<String, dynamic>? _getEffectiveMetadata() {
    if (layout.metadata != null) return layout.metadata;
    return config?.metadata;
  }

  // Calculates vertical offset for left hand columns (normalized so min offset = 0)
  double _getLeftColumnOffset(int columnIndex, int totalColumns) {
    double minOffset = _getMinColumnOffset();

    final metadata = _getEffectiveMetadata();
    if (metadata != null && metadata['columnOffsets'] != null) {
      final columnOffsets = metadata['columnOffsets'] as Map<String, dynamic>;
      final leftOffsets = columnOffsets['left'] as Map<String, dynamic>?;

      if (leftOffsets != null) {
        int columnNumber = totalColumns - columnIndex; // C6, C5, C4, C3, C2, C1
        String columnKey = 'C$columnNumber';

        if (leftOffsets.containsKey(columnKey)) {
          double offsetPercentage = leftOffsets[columnKey].toDouble();
          double rawOffset = keySize * (offsetPercentage / 100.0);
          // Normalize: subtract minOffset so most negative becomes 0
          return rawOffset - minOffset;
        }
      }
    }

    // Default offset for columns without config: normalize against minOffset
    return -minOffset;
  }

  // Calculates vertical offset for right hand columns (normalized so min offset = 0)
  double _getRightColumnOffset(int columnIndex, int totalColumns) {
    double minOffset = _getMinColumnOffset();

    final metadata = _getEffectiveMetadata();
    if (metadata != null && metadata['columnOffsets'] != null) {
      final columnOffsets = metadata['columnOffsets'] as Map<String, dynamic>;
      final rightOffsets = columnOffsets['right'] as Map<String, dynamic>?;

      if (rightOffsets != null) {
        int columnNumber = columnIndex + 1; // C1, C2, C3, C4, C5, C6
        String columnKey = 'C$columnNumber';

        if (rightOffsets.containsKey(columnKey)) {
          double offsetPercentage = rightOffsets[columnKey].toDouble();
          double rawOffset = keySize * (offsetPercentage / 100.0);
          return rawOffset - minOffset;
        }
      }
    }

    return -minOffset;
  }

  // Gets min offset (most negative) to use as baseline
  double _getMinColumnOffset() {
    double minOffset = 0.0;

    final metadata = _getEffectiveMetadata();
    if (metadata != null && metadata['columnOffsets'] != null) {
      final columnOffsets = metadata['columnOffsets'] as Map<String, dynamic>;

      final leftOffsets = columnOffsets['left'] as Map<String, dynamic>?;
      if (leftOffsets != null) {
        for (var value in leftOffsets.values) {
          double offsetPixels = keySize * (value.toDouble() / 100.0);
          minOffset = math.min(minOffset, offsetPixels);
        }
      }

      final rightOffsets = columnOffsets['right'] as Map<String, dynamic>?;
      if (rightOffsets != null) {
        for (var value in rightOffsets.values) {
          double offsetPixels = keySize * (value.toDouble() / 100.0);
          minOffset = math.min(minOffset, offsetPixels);
        }
      }
    }

    return minOffset;
  }

  // Calculates maximum column offset (relative to baseline) for container height
  double _getMaxColumnOffset() {
    double maxOffset = 0.0;
    double minOffset = _getMinColumnOffset();

    final metadata = _getEffectiveMetadata();
    if (metadata != null && metadata['columnOffsets'] != null) {
      final columnOffsets = metadata['columnOffsets'] as Map<String, dynamic>;

      final leftOffsets = columnOffsets['left'] as Map<String, dynamic>?;
      if (leftOffsets != null) {
        for (var value in leftOffsets.values) {
          double offsetPixels = keySize * (value.toDouble() / 100.0);
          // Normalize to baseline (most negative becomes 0)
          double normalizedOffset = offsetPixels - minOffset;
          maxOffset = math.max(maxOffset, normalizedOffset);
        }
      }

      final rightOffsets = columnOffsets['right'] as Map<String, dynamic>?;
      if (rightOffsets != null) {
        for (var value in rightOffsets.values) {
          double offsetPixels = keySize * (value.toDouble() / 100.0);
          double normalizedOffset = offsetPixels - minOffset;
          maxOffset = math.max(maxOffset, normalizedOffset);
        }
      }
    }

    return maxOffset;
  }

  // Gets thumb cluster gap from metadata or uses default
  double _getThumbClusterGap() {
    final metadata = _getEffectiveMetadata();
    if (metadata != null && metadata['thumbCluster'] != null) {
      final thumbConfig = metadata['thumbCluster'] as Map<String, dynamic>;
      if (thumbConfig['gap'] != null) {
        return thumbConfig['gap'].toDouble();
      }
    }
    return splitWidth * 0.4; // Default: 40% of main split width
  }

  // Gets thumb cluster vertical offset from metadata
  double _getThumbClusterVerticalOffset() {
    final metadata = _getEffectiveMetadata();
    if (metadata != null && metadata['thumbCluster'] != null) {
      final thumbConfig = metadata['thumbCluster'] as Map<String, dynamic>;
      if (thumbConfig['verticalOffset'] != null) {
        return thumbConfig['verticalOffset'].toDouble();
      }
    }
    return 0.0;
  }

  // Calculate left hand width based on actual rendered key dimensions
  double _calculateLeftHandWidth() {
    if (layout.leftHand == null) return 300.0; // Fallback for non-split layouts

    double maxRowWidth = 0.0;

    // Check main rows - calculate actual rendered width
    for (int rowIndex = 0;
        rowIndex < layout.leftHand!.rows.length;
        rowIndex++) {
      List<String?> row = layout.leftHand!.rows[rowIndex];
      double rowWidth = _calculateRowWidth(row, rowIndex);
      if (rowWidth > maxRowWidth) {
        maxRowWidth = rowWidth;
      }
    }

    // Check thumb cluster if present
    if (layout.thumbCluster != null) {
      for (int rowIndex = 0;
          rowIndex < layout.thumbCluster!.leftKeys.length;
          rowIndex++) {
        List<String?> row = layout.thumbCluster!.leftKeys[rowIndex];
        double rowWidth = _calculateRowWidth(row, -1); // Use -1 for thumb keys
        if (rowWidth > maxRowWidth) {
          maxRowWidth = rowWidth;
        }
      }
    }

    // Add minimum padding to prevent edge cropping + debug mode padding
    double debugPadding =
        debugMode ? 8.0 : 0.0; // EdgeInsets.all(4) = 8px total width
    return maxRowWidth + 20 + debugPadding;
  }

  // AIDEV-NOTE: Calculate right hand width based on actual rendered key dimensions
  double _calculateRightHandWidth() {
    if (layout.rightHand == null) {
      return 300.0; // Fallback for non-split layouts
    }

    double maxRowWidth = 0.0;

    // Check main rows - calculate actual rendered width
    for (int rowIndex = 0;
        rowIndex < layout.rightHand!.rows.length;
        rowIndex++) {
      List<String?> row = layout.rightHand!.rows[rowIndex];
      double rowWidth = _calculateRowWidth(row, rowIndex);
      if (rowWidth > maxRowWidth) {
        maxRowWidth = rowWidth;
      }
    }

    // Check thumb cluster if present
    if (layout.thumbCluster != null) {
      for (int rowIndex = 0;
          rowIndex < layout.thumbCluster!.rightKeys.length;
          rowIndex++) {
        List<String?> row = layout.thumbCluster!.rightKeys[rowIndex];
        double rowWidth = _calculateRowWidth(row, -1); // Use -1 for thumb keys
        if (rowWidth > maxRowWidth) {
          maxRowWidth = rowWidth;
        }
      }
    }

    // Add minimum padding to prevent edge cropping + debug mode padding
    double debugPadding =
        debugMode ? 8.0 : 0.0; // EdgeInsets.all(4) = 8px total width
    return maxRowWidth + 20 + debugPadding;
  }

  // AIDEV-NOTE: Calculate actual rendered width of a row based on key types
  double _calculateRowWidth(List<String?> row, int rowIndex) {
    double totalWidth = 0.0;

    for (int i = 0; i < row.length; i++) {
      String? key = row[i];
      if (key == null) {
        // Null keys take up space (invisible placeholder)
        totalWidth += keySize + (keyPadding * 2);
      } else {
        // Calculate actual key width based on key type
        double keyWidth;
        if (key == " ") {
          keyWidth = spaceWidth;
        } else if (rowIndex == 0 && i == row.length - 1) {
          // isLastKeyFirstRow
          keyWidth = keySize * 2 + keyPadding / 2;
        } else {
          keyWidth = keySize;
        }
        totalWidth += keyWidth + (keyPadding * 2);
      }
    }

    return totalWidth;
  }

  // ignore: unused_element
  Matrix4 _getAnimationTransform(bool isPressed) {
    if (!animationEnabled || !isPressed) {
      return Matrix4.identity();
    }
    switch (animationStyle.toLowerCase()) {
      case 'depress':
        return Matrix4.translationValues(0, 2 * animationScale, 0); // Move down
      case 'raise':
        return Matrix4.translationValues(0, -2 * animationScale, 0); // Move up
      case 'grow':
        final scaleValue = 1 + 0.05 * animationScale;
        return Matrix4.identity()
          ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
          ..translateByDouble(
            -keySize * (scaleValue - 1) / (2 * scaleValue),
            -keySize * (scaleValue - 1) / (2 * scaleValue),
            0.0, 1.0,
          );
      case 'shrink':
        final scaleValue = 1 - 0.05 * animationScale;
        return Matrix4.identity()
          ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
          ..translateByDouble(
            keySize * (1 - scaleValue) / (2 * scaleValue),
            keySize * (1 - scaleValue) / (2 * scaleValue),
            0.0, 1.0,
          );
      default:
        return Matrix4.translationValues(
            0, 2 * animationScale, 0); // Default animation
    }
  }

  // ignore: unused_element
  Matrix4 _getMarkerAnimationTransform(bool isPressed) {
    if (!animationEnabled || !isPressed) {
      return Matrix4.identity();
    }
    switch (animationStyle.toLowerCase()) {
      case 'depress':
        return Matrix4.translationValues(0, 2 * animationScale, 0);
      case 'raise':
        return Matrix4.translationValues(0, -2 * animationScale, 0);
      case 'grow':
        final scaleValue = 1 + 0.05 * animationScale;
        if (showAltLayout) {
          return Matrix4.identity()
            ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
            ..translateByDouble(
              -markerWidth * (scaleValue - 1) / (2 * scaleValue),
              -markerWidth * (scaleValue - 1) / (2 * scaleValue),
              0.0, 1.0,
            );
        } else {
          return Matrix4.identity()
            ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
            ..translateByDouble(
              -markerWidth * (scaleValue - 1) / (2 * scaleValue),
              -markerHeight * (scaleValue - 1) / (2 * scaleValue) +
                  0.8 * animationScale,
              0.0, 1.0,
            );
        }
      case 'shrink':
        final scaleValue = 1 - 0.05 * animationScale;
        if (showAltLayout) {
          return Matrix4.identity()
            ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
            ..translateByDouble(
              markerWidth * (1 - scaleValue) / (2 * scaleValue),
              markerWidth * (1 - scaleValue) / (2 * scaleValue),
              0.0, 1.0,
            );
        } else {
          return Matrix4.identity()
            ..scaleByDouble(scaleValue, scaleValue, 1.0, 1.0)
            ..translateByDouble(
              markerWidth * (1 - scaleValue) / (2 * scaleValue),
              markerHeight * (1 - scaleValue) / (2 * scaleValue) -
                  0.8 * animationScale,
              0.0, 1.0,
            );
        }
      default:
        return Matrix4.translationValues(0, 2 * animationScale, 0);
    }
  }

  // ignore: unused_element
  String _getAltLayoutKey(int rowIndex, int keyIndex) {
    if (altLayout == null || rowIndex >= altLayout!.keys.length) {
      return "";
    }
    List<String?> altRow = altLayout!.keys[rowIndex];
    if (keyIndex >= altRow.length) {
      return "";
    }
    String altKey = altRow[keyIndex] ?? "";
    // AIDEV-NOTE: Shift detection moved to OptimizedKeyWidget - this method is unused
    // TODO: Remove this method entirely if not needed
    // Shift handling is now done in OptimizedKeyWidget
    return altKey;
  }

  // ignore: unused_element
  bool _shouldShowTactileMarker(int rowIndex, int keyIndex) {
    // Check if config has homerow metadata at root level
    if (config != null && config!.homeRow != null) {
      final homeRowData = config!.homeRow!;
      final homeRowIndex = homeRowData['rowIndex'] as int;

      // Convert 1-indexed rowIndex to 0-indexed for comparison
      if (rowIndex == homeRowIndex - 1) {
        final leftPosition = homeRowData['leftPosition'] as int;
        final rightPosition = homeRowData['rightPosition'] as int;

        // For split matrix layouts, check left and right hand positions
        if (layout.leftHand != null && layout.rightHand != null) {
          int leftSideCount = _getLeftSideCount(rowIndex);

          int leftRowLength = layout.leftHand!.rows[rowIndex].length;
          int leftKeyIndex = leftRowLength - leftPosition - 1;
          int rightKeyIndex = leftSideCount + rightPosition - 2;
          if (keyIndex == leftKeyIndex) return true;
          if (keyIndex == rightKeyIndex) return true;
        } else {
          if (keyIndex == leftPosition || keyIndex == rightPosition) {
            return true;
          }
        }
      }
      return false;
    }
    return rowIndex == 2 && (keyIndex == 3 || keyIndex == 6);
  }

  Color getFingerColor(int rowIndex, int keyIndex) {
    if (rowIndex == 0 && !use6ColLayout) {
      keyIndex -= 1;
    }
    switch (keyIndex) {
      case -1:
        return pinkyLeftColor;
      case 0:
        return pinkyLeftColor;
      case 1:
        return ringLeftColor;
      case 2:
        return middleLeftColor;
      case 3:
      case 4:
        return indexLeftColor;
      case 5:
      case 6:
        return indexRightColor;
      case 7:
        return middleRightColor;
      case 8:
        return ringRightColor;
      case 9:
      case 10:
      case 11:
      case 12:
        return pinkyRightColor;
      default:
        return keyColorNotPressed;
    }
  }
}
