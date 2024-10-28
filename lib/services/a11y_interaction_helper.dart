// import 'dart:async';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
// import 'package:flutter_accessibility_service/accessibility_event.dart';
// import 'package:flutter_accessibility_service/constants.dart';

// class A11yInteractionHelper {
//   A11yInteractionHelper(this.webViewController);
//   final InAppWebViewController webViewController;

//   static Future<void> ensureInitialized() async {
//     final isPermissionEnabled =
//         await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
//     if (!isPermissionEnabled) {
//       final permissionGranted =
//           await FlutterAccessibilityService.requestAccessibilityPermission();
//       if (!permissionGranted) {
//         // Handle the case where permission is not granted
//       }
//     }
//   }

//   Future<void> clickThroughAcc(final String buttonText) async {
//     // Attempt to find the node and perform a click
//     final node = await _findNodeByText(buttonText);
//     if (node != null && node.nodeId != null) {
//       await FlutterAccessibilityService.performAction(
//         node,
//         NodeAction.actionClick,
//       );
//     } else {
//       throw Exception('Failed to find element with text "$buttonText"');
//     }
//   }

//   Future<AccessibilityEvent?> _findNodeByText(final String text) async {
//     final completer = Completer<AccessibilityEvent?>();
//     StreamSubscription? subscription;
//     subscription =
//         FlutterAccessibilityService.accessStream.listen((final event) {
//       // Search through event and subnodes for matching text
//       final matchingNode = _searchNodeForText(event, text);
//       if (matchingNode != null) {
//         subscription?.cancel();
//         completer.complete(matchingNode);
//       }
//     });

//     Future.delayed(const Duration(seconds: 5), () {
//       if (!completer.isCompleted) {
//         subscription?.cancel();
//         completer.complete(null);
//       }
//     });

//     return completer.future;
//   }

//   AccessibilityEvent? _searchNodeForText(
//       final AccessibilityEvent node, final String text) {
//     if ((node.text?.contains(text) ?? false) && node.isClickable == true) {
//       return node;
//     }

//     for (final child in node.subNodes ?? []) {
//       final result = _searchNodeForText(child, text);
//       if (result != null) return result;
//     }
//     return null;
//   }
// }
