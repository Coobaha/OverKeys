import 'dart:math' as math;
import 'keyboard_layouts.dart';

class UserConfig {
  String? defaultUserLayout;
  String? altLayout;
  String? customFont;
  List<KeyboardLayout>? userLayouts;
  Map<String, String> customShiftMappings;
  String? kanataHost;
  int? kanataPort;
  Map<String, dynamic>? homeRow;

  UserConfig({
    this.defaultUserLayout,
    this.altLayout,
    this.customFont,
    this.userLayouts,
    Map<String, String>? customShiftMappings,
    this.kanataHost,
    this.kanataPort,
    this.homeRow,
  }) : customShiftMappings = customShiftMappings ?? {};

  factory UserConfig.fromJson(Map<String, dynamic> json) {
    List<KeyboardLayout> userLayouts = [];
    if (json['userLayouts'] != null) {
      for (var userLayout in json['userLayouts']) {
        // Parse both old and new formats
        List<List<String?>> keys = [];
        ThumbCluster? thumbCluster;
        SplitHand? leftHand;
        SplitHand? rightHand;
        
        // NEW FORMAT: explicit leftHand/rightHand
        if (userLayout['leftHand'] != null && userLayout['rightHand'] != null) {
          
          // Parse left hand
          final leftData = userLayout['leftHand'];
          if (leftData['mainRows'] != null) {
            leftHand = SplitHand(
              rows: List<List<String?>>.from(
                leftData['mainRows'].map((row) => List<String?>.from(
                  row.map((item) {
                    if (item == null) return null;
                    return item as String;
                  })
                )),
              ),
            );
          }
          
          // Parse right hand
          final rightData = userLayout['rightHand'];
          if (rightData['mainRows'] != null) {
            rightHand = SplitHand(
              rows: List<List<String?>>.from(
                rightData['mainRows'].map((row) => List<String?>.from(
                  row.map((item) {
                    if (item == null) return null;
                    return item as String;
                  })
                )),
              ),
            );
          }
          
          // Parse thumb cluster from hands
          if (leftData['thumbRows'] != null && rightData['thumbRows'] != null) {
            thumbCluster = ThumbCluster(
              leftKeys: List<List<String?>>.from(
                leftData['thumbRows'].map((row) => List<String?>.from(
                  row.map((item) => item == null ? null : item.toString())
                )),
              ),
              rightKeys: List<List<String?>>.from(
                rightData['thumbRows'].map((row) => List<String?>.from(
                  row.map((item) => item == null ? null : item.toString())
                )),
              ),
            );
          }
          
          // Create fake keys matrix for compatibility
          if (leftHand != null && rightHand != null) {
            int maxRows = math.max(leftHand.rows.length, rightHand.rows.length);
            
            // Calculate max row lengths for dynamic padding
            int maxLeftLength = leftHand.rows.fold(0, (max, row) => math.max(max, row.length));
            int maxRightLength = rightHand.rows.fold(0, (max, row) => math.max(max, row.length));
            
            
            for (int i = 0; i < maxRows; i++) {
              List<String?> row = [];
              
              // Add left hand keys (or null if row doesn't exist)
              if (i < leftHand.rows.length) {
                row.addAll(leftHand.rows[i]);
              } else {
                row.addAll(List.filled(maxLeftLength, null)); // Dynamic padding
              }
              
              // Add right hand keys (or null if row doesn't exist)
              if (i < rightHand.rows.length) {
                row.addAll(rightHand.rows[i]);
              } else {
                row.addAll(List.filled(maxRightLength, null)); // Dynamic padding
              }
              
              keys.add(row);
            }
          }
        }
        // OLD FORMAT: keys array with optional thumbCluster
        else if (userLayout['keys'] != null) {
          keys = List<List<String?>>.from(
            userLayout['keys'].map((row) => List<String?>.from(
              row.map((item) => item as String?)
            )),
          );
          
          // Parse old-style thumb cluster
          if (userLayout['thumbCluster'] != null) {
            final thumbData = userLayout['thumbCluster'];
            if (thumbData['leftKeys'] != null && thumbData['rightKeys'] != null) {
              thumbCluster = ThumbCluster(
                leftKeys: List<List<String?>>.from(
                  thumbData['leftKeys'].map((row) => List<String?>.from(row)),
                ),
                rightKeys: List<List<String?>>.from(
                  thumbData['rightKeys'].map((row) => List<String?>.from(row)),
                ),
              );
            }
          }
        } else {
          continue;
        }
        
        userLayouts.add(KeyboardLayout(
          name: userLayout['name'],
          keys: keys,
          trigger: userLayout['trigger'],
          type: userLayout['type'],
          layoutStyle: userLayout['layoutStyle'],
          thumbCluster: thumbCluster,
          leftHand: leftHand,
          rightHand: rightHand,
          metadata: userLayout['metadata'] != null 
              ? Map<String, dynamic>.from(userLayout['metadata']) 
              : null,
        ));
      }
    }

    Map<String, String> customShiftMappings = {};
    if (json['customShiftMappings'] != null) {
      customShiftMappings = Map<String, String>.from(json['customShiftMappings']);
    }

    
    return UserConfig(
      defaultUserLayout: json['defaultUserLayout'],
      altLayout: json['altLayout'],
      customFont: json['customFont'],
      userLayouts: userLayouts,
      customShiftMappings: customShiftMappings,
      kanataHost: json['kanataHost'],
      kanataPort: json['kanataPort'] != null ? json['kanataPort'] as int : null,
      homeRow: json['homeRow'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> userLayoutsJson = userLayouts != null
        ? userLayouts!
            .map((userLayout) => {
                  'name': userLayout.name,
                  'keys': userLayout.keys,
                  if (userLayout.trigger != null) 'trigger': userLayout.trigger,
                  if (userLayout.type != null) 'type': userLayout.type,
                  if (userLayout.layoutStyle != null) 'layoutStyle': userLayout.layoutStyle,
                  if (userLayout.thumbCluster != null) 'thumbCluster': {
                    'leftKeys': userLayout.thumbCluster!.leftKeys,
                    'rightKeys': userLayout.thumbCluster!.rightKeys,
                  },
                  if (userLayout.metadata != null) 'metadata': userLayout.metadata,
                })
            .toList()
        : [];

    return {
      'defaultUserLayout': defaultUserLayout,
      'altLayout': altLayout,
      'customFont': customFont,
      'userLayouts': userLayoutsJson,
      'customShiftMappings': customShiftMappings,
      'kanataHost': kanataHost,
      'kanataPort': kanataPort,
      if (homeRow != null) 'homeRow': homeRow,
    };
  }
}
