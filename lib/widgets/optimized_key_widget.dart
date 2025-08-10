import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../services/key_state_manager.dart';
import '../services/key_render_cache.dart';
import '../models/mappings.dart';

class OptimizedKeyWidget extends StatefulWidget {
  final String? keyLabel;
  final String physicalKey;
  final int rowIndex;
  final int keyIndex;
  final double keySize;
  final double keyBorderRadius;
  final double keyBorderThickness;
  final double keyPadding;
  final double keyFontSize;
  final FontWeight fontWeight;
  final Color keyColorPressed;
  final Color keyColorNotPressed;
  final Color keyTextColor;
  final Color keyTextColorNotPressed;
  final Color keyBorderColorPressed;
  final Color keyBorderColorNotPressed;
  final bool animationEnabled;
  final String animationStyle;
  final double animationDuration;
  final double animationScale;
  final bool learningModeEnabled;
  final List<Color> fingerColors;
  final Map<String, String>? actionMappings;
  final bool isLastKeyFirstRow;
  final double spaceWidth;
  final AutoSizeGroup? autoSizeGroup;

  const OptimizedKeyWidget({
    super.key,
    required this.keyLabel,
    required this.physicalKey,
    required this.rowIndex,
    required this.keyIndex,
    required this.keySize,
    required this.keyBorderRadius,
    required this.keyBorderThickness,
    required this.keyPadding,
    required this.keyFontSize,
    required this.fontWeight,
    required this.keyColorPressed,
    required this.keyColorNotPressed,
    required this.keyTextColor,
    required this.keyTextColorNotPressed,
    required this.keyBorderColorPressed,
    required this.keyBorderColorNotPressed,
    required this.animationEnabled,
    required this.animationStyle,
    required this.animationDuration,
    required this.animationScale,
    required this.learningModeEnabled,
    required this.fingerColors,
    this.actionMappings,
    this.isLastKeyFirstRow = false,
    required this.spaceWidth,
    this.autoSizeGroup,
  });

  @override
  State<OptimizedKeyWidget> createState() => _OptimizedKeyWidgetState();
}

class _OptimizedKeyWidgetState extends State<OptimizedKeyWidget>
    with SingleTickerProviderStateMixin {
  late final KeyStateManager _keyStateManager;
  late final KeyRenderCache _renderCache;
  late ValueNotifier<bool> _keyNotifier;
  late final AnimationController _animationController;

  // Cached values
  int? _fingerIndex;
  String? _displayText;
  double? _keyWidth;

  @override
  void initState() {
    super.initState();

    _keyStateManager = KeyStateManager();
    _renderCache = KeyRenderCache();
    _keyNotifier = _keyStateManager.getKeyNotifier(widget.physicalKey);

    _animationController = AnimationController(
      duration: Duration(milliseconds: widget.animationDuration.toInt()),
      vsync: this,
    );

    // Pre-calculate static values
    _precalculateValues();
  }

  @override
  void didUpdateWidget(OptimizedKeyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recalculate values if key properties changed (e.g., during layer switching)
    if (oldWidget.keyLabel != widget.keyLabel ||
        oldWidget.physicalKey != widget.physicalKey ||
        oldWidget.spaceWidth != widget.spaceWidth ||
        oldWidget.keySize != widget.keySize) {
      _precalculateValues();

      // Update the key notifier if the physical key changed
      if (oldWidget.physicalKey != widget.physicalKey) {
        _keyNotifier = _keyStateManager.getKeyNotifier(widget.physicalKey);
      }
    }
  }

  void _precalculateValues() {
    // Calculate finger index once
    _fingerIndex = _calculateFingerIndex();

    // Calculate display text once
    _displayText = _calculateDisplayText();

    // Calculate key width once
    _keyWidth = widget.keyLabel == " "
        ? widget.spaceWidth
        : (widget.isLastKeyFirstRow
            ? widget.keySize * 2 + widget.keyPadding / 2
            : widget.keySize);
  }

  int _calculateFingerIndex() {
    // Finger mapping logic based on key position
    if (widget.rowIndex >= 4) return -1; // No finger color for bottom rows

    int adjustedIndex = widget.keyIndex;
    if (widget.rowIndex == 0 && widget.keyIndex > 0) {
      adjustedIndex -= 1;
    }

    // Map to finger colors (0-7 for left pinky to right pinky)
    switch (adjustedIndex) {
      case -1:
      case 0:
        return 0; // Left pinky
      case 1:
        return 1; // Left ring
      case 2:
        return 2; // Left middle
      case 3:
      case 4:
        return 3; // Left index
      case 5:
      case 6:
        return 4; // Right index
      case 7:
        return 5; // Right middle
      case 8:
        return 6; // Right ring
      case 9:
      case 10:
      case 11:
      case 12:
        return 7; // Right pinky
      default:
        return -1;
    }
  }

  String _calculateDisplayText() {
    if (widget.keyLabel == null || widget.keyLabel!.isEmpty) {
      return '';
    }

    return Mappings.getDisplayName(widget.keyLabel!, widget.actionMappings);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.keyPadding),
      child: ValueListenableBuilder<bool>(
        valueListenable: _keyNotifier,
        builder: (context, isPressed, child) {
          // Update animation
          if (widget.animationEnabled) {
            if (isPressed) {
              _animationController.forward();
            } else {
              _animationController.reverse();
            }
          }

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return _buildKeyContainer(isPressed);
            },
          );
        },
      ),
    );
  }

  Widget _buildKeyContainer(bool isPressed) {
    // Use cached colors
    final keyColor = _renderCache.getCachedKeyColor(
      isPressed: isPressed,
      learningMode: widget.learningModeEnabled,
      fingerIndex: _fingerIndex ?? -1,
      keyColorPressed: widget.keyColorPressed,
      keyColorNotPressed: widget.keyColorNotPressed,
      fingerColors: widget.fingerColors,
    );

    final textColor =
        isPressed ? widget.keyTextColor : widget.keyTextColorNotPressed;
    final borderColor = isPressed
        ? widget.keyBorderColorPressed
        : widget.keyBorderColorNotPressed;

    // Use cached transform
    final transform = widget.animationEnabled
        ? _renderCache.getCachedTransform(
            isPressed: isPressed,
            animationStyle: widget.animationStyle,
            animationScale: widget.animationScale,
            keySize: widget.keySize,
          )
        : Matrix4.identity();

    return Container(
      width: _keyWidth,
      height: widget.keySize,
      transform: transform,
      decoration: BoxDecoration(
        color: keyColor,
        borderRadius: BorderRadius.circular(widget.keyBorderRadius),
        border: widget.keyBorderThickness > 0
            ? Border.all(color: borderColor, width: widget.keyBorderThickness)
            : null,
      ),
      child: _buildKeyContent(textColor),
    );
  }

  Widget _buildKeyContent(Color textColor) {
    if (widget.keyLabel == " ") {
      // Space bar content
      return Center(
        child: Text(
          "space", // Or layout name
          style: TextStyle(
            color: textColor,
            fontSize: widget.keyFontSize * 0.7,
            fontWeight: widget.fontWeight,
          ),
        ),
      );
    }

    return Center(
      child: AutoSizeText(
        _displayText ?? '',
        style: TextStyle(
          color: textColor,
          fontWeight: widget.fontWeight,
          fontSize: widget.keyFontSize,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        minFontSize: 8,
        overflow: TextOverflow.visible,
        group: widget.autoSizeGroup,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Note: Don't dispose _keyNotifier - it's managed by KeyStateManager
    super.dispose();
  }
}
