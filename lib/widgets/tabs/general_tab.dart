import 'package:flutter/material.dart';
import 'package:overkeys/widgets/options/options.dart';
import 'package:overkeys/models/keyboard_layouts.dart';

class GeneralTab extends StatefulWidget {
  final bool launchAtStartup;
  final bool autoHideEnabled;
  final double autoHideDuration;
  final String keyboardLayoutName;
  final double opacity;
  final double customLayerDelay;
  final double defaultLayerDelay;
  final double quickSuccessionWindow;
  final Function(bool) updateLaunchAtStartup;
  final Function(bool) updateAutoHideEnabled;
  final Function(double) updateAutoHideDuration;
  final Function(String) updateKeyboardLayoutName;
  final Function(double) updateOpacity;
  final Function(double) updateCustomLayerDelay;
  final Function(double) updateDefaultLayerDelay;
  final Function(double) updateQuickSuccessionWindow;

  const GeneralTab({
    super.key,
    required this.launchAtStartup,
    required this.autoHideEnabled,
    required this.autoHideDuration,
    required this.keyboardLayoutName,
    required this.opacity,
    required this.customLayerDelay,
    required this.defaultLayerDelay,
    required this.quickSuccessionWindow,
    required this.updateLaunchAtStartup,
    required this.updateAutoHideEnabled,
    required this.updateAutoHideDuration,
    required this.updateKeyboardLayoutName,
    required this.updateOpacity,
    required this.updateCustomLayerDelay,
    required this.updateDefaultLayerDelay,
    required this.updateQuickSuccessionWindow,
  });

  @override
  State<GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<GeneralTab> {
  late double _localAutoHideDuration;
  late double _localOpacity;
  late double _localCustomLayerDelay;
  late double _localDefaultLayerDelay;
  late double _localQuickSuccessionWindow;

  @override
  void initState() {
    super.initState();
    _localAutoHideDuration = widget.autoHideDuration;
    _localOpacity = widget.opacity.clamp(0.1, 1.0);
    _localCustomLayerDelay = widget.customLayerDelay;
    _localDefaultLayerDelay = widget.defaultLayerDelay;
    _localQuickSuccessionWindow = widget.quickSuccessionWindow;
  }

  @override
  void didUpdateWidget(GeneralTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoHideDuration != widget.autoHideDuration) {
      _localAutoHideDuration = widget.autoHideDuration;
    }
    if (oldWidget.opacity != widget.opacity) {
      _localOpacity = widget.opacity.clamp(0.1, 1.0);
    }
    if (oldWidget.customLayerDelay != widget.customLayerDelay) {
      _localCustomLayerDelay = widget.customLayerDelay;
    }
    if (oldWidget.defaultLayerDelay != widget.defaultLayerDelay) {
      _localDefaultLayerDelay = widget.defaultLayerDelay;
    }
    if (oldWidget.quickSuccessionWindow != widget.quickSuccessionWindow) {
      _localQuickSuccessionWindow = widget.quickSuccessionWindow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ToggleOption(
          label: 'Open on system startup',
          value: widget.launchAtStartup,
          onChanged: widget.updateLaunchAtStartup,
        ),
        ToggleOption(
          label: 'Auto-hide keyboard',
          value: widget.autoHideEnabled,
          onChanged: widget.updateAutoHideEnabled,
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstChild: const SizedBox.shrink(),
          secondChild: SliderOption(
            label: 'Auto-hide duration (seconds)',
            value: _localAutoHideDuration,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            onChanged: (value) {
              double roundedValue = (value * 2).round() / 2;
              setState(() => _localAutoHideDuration = roundedValue);
            },
            onChangeEnd: (value) {
              double roundedValue = (value * 2).round() / 2;
              widget.updateAutoHideDuration(roundedValue);
            },
            valueDisplayFormatter: (value) => value.toStringAsFixed(1),
          ),
          crossFadeState: widget.autoHideEnabled
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          sizeCurve: Curves.easeInOut,
        ),
        SliderOption(
          label: 'Opacity',
          value: _localOpacity,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          onChanged: (value) {
            setState(() => _localOpacity = value);
          },
          onChangeEnd: widget.updateOpacity,
        ),
        DropdownOption(
          label: 'Layout',
          value: widget.keyboardLayoutName,
          options: availableLayouts.map((layout) => (layout.name)).toList(),
          onChanged: (value) => widget.updateKeyboardLayoutName(value!),
        ),
        const SizedBox(height: 16),
        Text(
          'Smart Layer Visibility',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SliderOption(
          label: 'Custom layer delay (seconds)',
          subtitle: 'Delay before showing custom layers when inactive',
          value: _localCustomLayerDelay / 1000.0,
          min: 0.1,
          max: 3.0,
          divisions: 29,
          onChanged: (value) {
            setState(() =>
                _localCustomLayerDelay = (value * 1000).round().toDouble());
          },
          onChangeEnd: (value) {
            widget.updateCustomLayerDelay((value * 1000).round().toDouble());
          },
          valueDisplayFormatter: (value) => value.toStringAsFixed(1),
        ),
        SliderOption(
          label: 'Default layer delay (seconds)',
          subtitle: 'Delay before showing default layer when inactive',
          value: _localDefaultLayerDelay / 1000.0,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          onChanged: (value) {
            setState(() =>
                _localDefaultLayerDelay = (value * 1000).round().toDouble());
          },
          onChangeEnd: (value) {
            widget.updateDefaultLayerDelay((value * 1000).round().toDouble());
          },
          valueDisplayFormatter: (value) => value.toStringAsFixed(1),
        ),
        SliderOption(
          label: 'Quick succession window (ms)',
          subtitle: 'Suppress overlay for this duration after first keypress',
          value: _localQuickSuccessionWindow,
          min: 0.0,
          max: 3000.0,
          divisions: 60,
          onChanged: (value) {
            setState(
                () => _localQuickSuccessionWindow = value.round().toDouble());
          },
          onChangeEnd: (value) {
            widget.updateQuickSuccessionWindow(value.round().toDouble());
          },
          valueDisplayFormatter: (value) => '${value.round()}ms',
        ),
        Text(
          'Tip: Press ESC key to close the preferences window',
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
