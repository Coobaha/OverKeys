import 'package:flutter/material.dart';
import '../models/keyboard_layouts.dart';
import '../models/mappings.dart';
import '../models/user_config.dart';

class KeyboardScreen extends StatelessWidget {
  final KeyboardLayout layout;
  final String keymapStyle;
  final bool showTopRow;
  final bool showGraveKey;
  final double keySize;
  final double keyBorderRadius;
  final double keyBorderThickness;
  final double keyPadding;
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
  final Map<String, bool> keyPressStates;
  final Map<String, String>? customShiftMappings;
  final UserConfig? config;

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
    required this.keyPressStates,
    this.customShiftMappings,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    // DEBUG MODE: Text rendering for layout analysis
    if (layout.name.contains("DEBUG")) {
      return buildDebugTextLayout();
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

  Widget buildDebugTextLayout() {
    StringBuffer debug = StringBuffer();
    debug.writeln("🔍 DEBUG: Glove80 Layout Analysis");
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(keyPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...mainRows,
          if (thumbClusterWidget != null) ...[
            SizedBox(height: keyPadding),
            thumbClusterWidget,
            SizedBox(height: keyPadding * 2),
          ],
        ],
      ),
    );
  }

  Widget buildThumbCluster(ThumbCluster thumbCluster) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left thumb cluster
        buildThumbClusterSide(thumbCluster.leftKeys, true),
        SizedBox(width: splitWidth * 2),
        // Right thumb cluster
        buildThumbClusterSide(thumbCluster.rightKeys, false),
      ],
    );
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
          thumbRows.add(SizedBox(height: keyPadding)); // Row spacing
        }
        continue;
      }

      for (int keyIndex = 0; keyIndex < keys.length; keyIndex++) {
        String? key = keys[keyIndex];
        rowWidgets.add(buildKeys(-1, key, keyIndex, isThumbKey: true));
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
          thumbRows.add(SizedBox(height: keyPadding));
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
      leftKeys.add(buildKeys(rowIndex, keys[i], i));
      if (i < leftSideCount - 1) {
        leftKeys.add(SizedBox(width: keyPadding));
      }
    }

    // Build right hand keys
    List<Widget> rightKeys = [];
    for (int i = rightSideStart; i < keys.length; i++) {
      rightKeys.add(buildKeys(rowIndex, keys[i], i));
      if (i < keys.length - 1) {
        rightKeys.add(SizedBox(width: keyPadding));
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: keyPadding / 2),
      child: Row(
        children: [
          // Left hand - right aligned
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: leftKeys,
            ),
          ),
          // Split gap
          SizedBox(width: splitWidth),
          // Right hand - left aligned
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: rightKeys,
            ),
          ),
        ],
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
        rowWidgets.add(buildKeys(rowIndex, keys[i], i,
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
        rowWidgets.add(buildKeys(rowIndex, keys[0], 0));

        for (int i = 1; i < 6; i++) {
          rowWidgets.add(buildKeys(rowIndex, keys[i], i));
        }

        rowWidgets.add(SizedBox(width: splitWidth));

        for (int i = 6; i < 11; i++) {
          rowWidgets.add(buildKeys(rowIndex, keys[i], i));
        }

        rowWidgets.add(buildKeys(rowIndex, keys[11], 11));
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
            rowWidgets.add(buildKeys(rowIndex, keys[i], i));
            rowWidgets.add(SizedBox(width: lastRowSplitWidth));
            rowWidgets.add(buildKeys(rowIndex, keys[i], i));
          } else {
            rowWidgets.add(buildKeys(rowIndex, keys[i], i));
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

  Widget buildKeys(int rowIndex, String? key, int keyIndex,
      {bool isLastKeyFirstRow = false, bool isThumbKey = false}) {
    // Handle null as invisible placeholder ONLY
    if (key == null) {
      // Invisible placeholder must have SAME total size as visible keys (including padding)
      return Padding(
        padding: EdgeInsets.all(keyPadding),
        child: SizedBox(width: keySize, height: keySize),
      );
    }

    // Empty strings should render as visible empty keys, not invisible
    // Only null should be invisible

    bool isShiftPressed = (keyPressStates["LShift"] ?? false) ||
        (keyPressStates["RShift"] ?? false);

    if (isShiftPressed) {
      if (customShiftMappings != null &&
          customShiftMappings!.containsKey(key)) {
        key = customShiftMappings![key]!;
      } else {
        key = Mappings.getShiftedSymbol(key) ?? key;
      }
    }
    String realKey = (layout.foreign ?? false)
        ? (qwerty.keys[rowIndex][keyIndex] ?? "")
        : (key ?? "");

    String keyStateKey = Mappings.getKeyForSymbol(realKey);
    bool isPressed = keyPressStates[keyStateKey] ?? false;

    if (use6ColLayout) {
      keyIndex -= 1;
    }
    Color keyColor;

    if (isPressed) {
      keyColor = keyColorPressed;
    } else if (learningModeEnabled && rowIndex < 4) {
      keyColor = getFingerColor(rowIndex, keyIndex);
    } else {
      keyColor = keyColorNotPressed;
    }

    Color textColor = isPressed ? keyTextColor : keyTextColorNotPressed;
    Color tactMarkerColor = isPressed ? markerColor : markerColorNotPressed;
    Color borderColor =
        isPressed ? keyBorderColorPressed : keyBorderColorNotPressed;

    double width = key == " "
        ? spaceWidth
        : (isLastKeyFirstRow ? keySize * 2 + keyPadding / 2 : keySize);

    Widget keyWidget = Padding(
      padding: EdgeInsets.all(keyPadding),
      child: AnimatedContainer(
        duration: Duration(
            milliseconds: animationEnabled ? animationDuration.toInt() : 20),
        curve: Curves.easeInOutCubic,
        width: width,
        height: keySize,
        decoration: BoxDecoration(
            color: keyColor,
            borderRadius: BorderRadius.circular(keyBorderRadius),
            boxShadow: keyShadowBlurRadius > 0
                ? [
                    BoxShadow(
                      blurRadius: keyShadowBlurRadius,
                      offset: Offset(keyShadowOffsetX, keyShadowOffsetY),
                    ),
                  ]
                : null,
            border: keyBorderThickness > 0
                ? Border.all(
                    color: borderColor,
                    width: keyBorderThickness,
                  )
                : null),
        transform: _getAnimationTransform(isPressed),
        child: key == " "
            ? Center(
                child: Text(
                  showAltLayout && altLayout != null
                      ? "${layout.name.toLowerCase()} (${altLayout!.name.toLowerCase()})"
                      : layout.name.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: spaceFontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              )
            : showAltLayout && altLayout != null
                ? Stack(
                    children: [
                      // Primary layout key (top left)
                      Positioned(
                        top: 4,
                        left: 8,
                        child: Text(
                          key,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: textColor,
                            fontSize: key.length > 2
                                ? keyFontSize * 0.6
                                : keyFontSize * 0.85,
                            fontWeight: fontWeight,
                          ),
                        ),
                      ),
                      // Alt layout key (bottom right)
                      Positioned(
                        bottom: 4,
                        right: 8,
                        child: Text(
                          _getAltLayoutKey(rowIndex, keyIndex),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: textColor,
                            fontSize:
                                _getAltLayoutKey(rowIndex, keyIndex).length > 2
                                    ? keyFontSize * 0.6
                                    : keyFontSize * 0.85,
                            fontWeight: fontWeight,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize:
                            key.length > 2 ? keyFontSize * 0.7 : keyFontSize,
                        fontWeight: fontWeight,
                      ),
                    ),
                  ),
      ),
    );

    // Tactile Markers - Use homerow metadata or fallback to QWERTY default
    if (_shouldShowTactileMarker(rowIndex, keyIndex)) {
      keyWidget = Stack(
        alignment: showAltLayout && altLayout != null
            ? Alignment.center
            : Alignment.bottomCenter,
        children: [
          keyWidget,
          Positioned(
            bottom: showAltLayout && altLayout != null ? null : markerOffset,
            child: AnimatedContainer(
              duration: Duration(
                  milliseconds:
                      animationEnabled ? animationDuration.toInt() : 20),
              curve: Curves.easeInOutCubic,
              transform: _getMarkerAnimationTransform(isPressed),
              width:
                  markerWidth * (showAltLayout && altLayout != null ? 0.5 : 1),
              height: showAltLayout && altLayout != null
                  ? markerWidth * 0.5
                  : markerHeight,
              decoration: BoxDecoration(
                color: tactMarkerColor,
                borderRadius: BorderRadius.circular(markerBorderRadius),
              ),
            ),
          ),
        ],
      );
    }
    return keyWidget;
  }

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
          ..scale(scaleValue)
          ..translate(
            -keySize * (scaleValue - 1) / (2 * scaleValue),
            -keySize * (scaleValue - 1) / (2 * scaleValue),
          );
      case 'shrink':
        final scaleValue = 1 - 0.05 * animationScale;
        return Matrix4.identity()
          ..scale(scaleValue)
          ..translate(
            keySize * (1 - scaleValue) / (2 * scaleValue),
            keySize * (1 - scaleValue) / (2 * scaleValue),
          );
      default:
        return Matrix4.translationValues(
            0, 2 * animationScale, 0); // Default animation
    }
  }

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
            ..scale(scaleValue)
            ..translate(
              -markerWidth * (scaleValue - 1) / (2 * scaleValue),
              -markerWidth * (scaleValue - 1) / (2 * scaleValue),
            );
        } else {
          return Matrix4.identity()
            ..scale(scaleValue)
            ..translate(
              -markerWidth * (scaleValue - 1) / (2 * scaleValue),
              -markerHeight * (scaleValue - 1) / (2 * scaleValue) +
                  0.8 * animationScale,
            );
        }
      case 'shrink':
        final scaleValue = 1 - 0.05 * animationScale;
        if (showAltLayout) {
          return Matrix4.identity()
            ..scale(scaleValue)
            ..translate(
              markerWidth * (1 - scaleValue) / (2 * scaleValue),
              markerWidth * (1 - scaleValue) / (2 * scaleValue),
            );
        } else {
          return Matrix4.identity()
            ..scale(scaleValue)
            ..translate(
              markerWidth * (1 - scaleValue) / (2 * scaleValue),
              markerHeight * (1 - scaleValue) / (2 * scaleValue) -
                  0.8 * animationScale,
            );
        }
      default:
        return Matrix4.translationValues(0, 2 * animationScale, 0);
    }
  }

  String _getAltLayoutKey(int rowIndex, int keyIndex) {
    if (altLayout == null || rowIndex >= altLayout!.keys.length) {
      return "";
    }
    List<String?> altRow = altLayout!.keys[rowIndex];
    if (keyIndex >= altRow.length) {
      return "";
    }
    String altKey = altRow[keyIndex] ?? "";
    bool isShiftPressed = (keyPressStates["LShift"] ?? false) ||
        (keyPressStates["RShift"] ?? false);
    if (isShiftPressed) {
      if (customShiftMappings != null &&
          customShiftMappings!.containsKey(altKey)) {
        altKey = customShiftMappings![altKey]!;
      } else {
        altKey = Mappings.getShiftedSymbol(altKey) ?? altKey;
      }
    }
    return altKey;
  }

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
          int rightRowLength = layout.rightHand!.rows[rowIndex].length;
          int leftKeyIndex = leftRowLength - leftPosition - 1;
          int rightKeyIndex = leftSideCount + rightPosition - 2;
          if (keyIndex == leftKeyIndex) return true;
          if (keyIndex == rightKeyIndex) return true;
        } else {
          if (keyIndex == leftPosition || keyIndex == rightPosition)
            return true;
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
