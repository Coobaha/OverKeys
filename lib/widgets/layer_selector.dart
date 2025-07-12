import 'package:flutter/material.dart';
import '../models/keyboard_layouts.dart';

class LayerSelector extends StatelessWidget {
  final List<KeyboardLayout> availableLayers;
  final KeyboardLayout currentLayer;
  final Function(KeyboardLayout) onLayerChanged;
  final bool isVisible;
  final double opacity;
  final Color keyColorNotPressed;
  final Color keyTextColorNotPressed;
  final Color keyBorderColorNotPressed;
  final double keyBorderRadius;
  final double keyBorderThickness;

  const LayerSelector({
    super.key,
    required this.availableLayers,
    required this.currentLayer,
    required this.onLayerChanged,
    required this.isVisible,
    required this.opacity,
    required this.keyColorNotPressed,
    required this.keyTextColorNotPressed,
    required this.keyBorderColorNotPressed,
    required this.keyBorderRadius,
    required this.keyBorderThickness,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || availableLayers.isEmpty) {
      return const SizedBox.shrink();
    }

    // AIDEV-NOTE: Ensure currentLayer exists in availableLayers list to prevent dropdown errors
    KeyboardLayout actualCurrentLayer = currentLayer;
    if (!availableLayers.contains(currentLayer)) {
      // Find layer with same name if exact object not found
      final matchingLayer = availableLayers
          .where((layer) => layer.name == currentLayer.name)
          .firstOrNull;
      if (matchingLayer != null) {
        actualCurrentLayer = matchingLayer;
      } else {
        // Fallback to first available layer if current layer not found
        actualCurrentLayer = availableLayers.first;
      }
    }

    return Positioned(
      bottom: 20,
      left: 20,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 200),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 200,
            maxWidth: 280,
          ),
          decoration: BoxDecoration(
            color: keyColorNotPressed,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: keyBorderColorNotPressed.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<KeyboardLayout>(
                value: actualCurrentLayer,
                isExpanded: true,
                dropdownColor: keyColorNotPressed,
                elevation: 8,
                menuMaxHeight: 300,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: keyTextColorNotPressed,
                ),
                style: TextStyle(
                  color: keyTextColorNotPressed,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                items: availableLayers.map((layer) {
                  return DropdownMenuItem<KeyboardLayout>(
                    value: layer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Layer type indicator icon
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getLayerTypeColor(layer),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Layer name
                          Expanded(
                            child: Text(
                              layer.name,
                              style: TextStyle(
                                color: keyTextColorNotPressed,
                                fontSize: 14,
                                fontWeight: layer == actualCurrentLayer
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Current layer indicator
                          if (layer == actualCurrentLayer)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: keyTextColorNotPressed,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (KeyboardLayout? newLayer) {
                  if (newLayer != null && newLayer != actualCurrentLayer) {
                    onLayerChanged(newLayer);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getLayerTypeColor(KeyboardLayout layer) {
    // AIDEV-NOTE: Color coding for different layer types for quick visual identification
    if (layer.name.toLowerCase().contains('symbol')) {
      return Colors.orange;
    } else if (layer.name.toLowerCase().contains('number')) {
      return Colors.blue;
    } else if (layer.name.toLowerCase().contains('cursor')) {
      return Colors.green;
    } else if (layer.name.toLowerCase().contains('function')) {
      return Colors.purple;
    } else if (layer.name.toLowerCase().contains('emoji')) {
      return Colors.yellow;
    } else if (layer.name.toLowerCase().contains('world')) {
      return Colors.cyan;
    } else if (layer.name.toLowerCase().contains('mouse')) {
      return Colors.red;
    } else if (layer.name.toLowerCase().contains('system')) {
      return Colors.grey;
    } else {
      return keyTextColorNotPressed.withValues(alpha: 0.7);
    }
  }
}
