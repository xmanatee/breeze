import 'dart:convert';
import 'dart:async';
import 'package:breeze/styles/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebInteractionHelper {
  WebInteractionHelper(this.webViewController);
  final InAppWebViewController webViewController;

  String _escapeSelector(final String selector) {
    return selector.replaceAll("'", "\\'");
  }

  Future<void> type(final String selector, final String text) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    final escapedText = jsonEncode(text);
    final jsCode = '''
    (function() {
      var element = document.querySelector('$escapedSelector');
      if (element != null) {
        var text = $escapedText;
        element.focus();
        element.value = '';
        for (var i = 0; i < text.length; i++) {
          var char = text.charAt(i);
          var keyEventInit = {
            key: char,
            code: 'Key' + char.toUpperCase(),
            which: char.charCodeAt(0),
            keyCode: char.charCodeAt(0),
            bubbles: true
          };
          element.dispatchEvent(new KeyboardEvent('keydown', keyEventInit));
          element.value += char;
          element.dispatchEvent(new Event('input', { bubbles: true }));
          element.dispatchEvent(new KeyboardEvent('keyup', keyEventInit));
        }
        element.dispatchEvent(new Event('change', { bubbles: true }));
        return true;
      }
      return false;
    })();
    ''';
    debugPrint('Executing JavaScript (type): $jsCode');
    final result = await webViewController.evaluateJavascript(source: jsCode);
    debugPrint('JavaScript execution result (type): $result');
    if (result != true && result != 'true') {
      throw Exception('Failed to type into element with selector "$selector"');
    }
  }

  Future<void> click(final String selector) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    final jsCode = '''
    (function() {
      var element = document.querySelector('$escapedSelector');
      if (element != null) {
        var rect = element.getBoundingClientRect();
        var x = rect.left + rect.width * 0.5;
        var y = rect.top + rect.height * 0.5;

        element.scrollIntoView({behavior: 'smooth', block: 'center'});

        var eventInit = {
          bubbles: true,
          cancelable: true,
          view: window,
          clientX: x,
          clientY: y,
          button: 0
        };

        element.dispatchEvent(new MouseEvent('mousedown', eventInit));
        element.dispatchEvent(new MouseEvent('mouseup', eventInit));
        element.dispatchEvent(new MouseEvent('click', eventInit));

        return true;
      }
      return false;
    })();
    ''';
    debugPrint('Executing JavaScript (click): $jsCode');
    final result = await webViewController.evaluateJavascript(source: jsCode);
    debugPrint('JavaScript execution result (click): $result');
    if (result != true && result != 'true') {
      throw Exception('Failed to click element with selector "$selector"');
    }
  }

  Future<void> focus(final String selector) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    final jsCode = '''
    (function() {
      var element = document.querySelector('$escapedSelector');
      if (element != null) {
        element.focus();
        return true;
      }
      return false;
    })();
    ''';
    debugPrint('Executing JavaScript (focus): $jsCode');
    final result = await webViewController.evaluateJavascript(source: jsCode);
    debugPrint('JavaScript execution result (focus): $result');
    if (result != true && result != 'true') {
      throw Exception('Failed to focus element with selector "$selector"');
    }
  }

  Future<void> hover(final String selector) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    final jsCode = '''
    (function() {
      var element = document.querySelector('$escapedSelector');
      if (element != null) {
        var mouseOverEvent = new Event('mouseover', { bubbles: true });
        element.dispatchEvent(mouseOverEvent);
        return true;
      }
      return false;
    })();
    ''';
    debugPrint('Executing JavaScript (hover): $jsCode');
    final result = await webViewController.evaluateJavascript(source: jsCode);
    debugPrint('JavaScript execution result (hover): $result');
    if (result != true && result != 'true') {
      throw Exception('Failed to hover over element with selector "$selector"');
    }
  }

  Future<void> _waitForSelector(final String selector) async {
    debugPrint('Waiting for selector: $selector');
    while (true) {
      final exists = await webViewController.evaluateJavascript(
          source: "document.querySelector('$selector') !== null;");
      debugPrint('Selector "$selector" exists: $exists');
      if (exists == true || exists == 'true') break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> highlightElement(final String selector) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    final jsCode = '''
    (function() {
      var element = document.querySelector('$escapedSelector');
      if (element != null) {
        element.setAttribute('data-original-style', element.getAttribute('style') || '');
        element.style.border = '3px solid ${AppStyles.primaryColor.cssColor}';
        element.style.transition = 'border 0.5s ease-in-out';
        return true;
      }
      return false;
    })();
    ''';
    await webViewController.evaluateJavascript(source: jsCode);
  }

  Future<void> removeHighlight(final String selector) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    final jsCode = '''
    (function() {
      var element = document.querySelector('$escapedSelector');
      if (element != null) {
        var originalStyle = element.getAttribute('data-original-style');
        if (originalStyle !== null) {
          element.setAttribute('style', originalStyle);
          element.removeAttribute('data-original-style');
        } else {
          element.style.border = '';
        }
        return true;
      }
      return false;
    })();
    ''';
    await webViewController.evaluateJavascript(source: jsCode);
  }

  Future<void> scrollIntoView(final String selector) async {
    final escapedSelector = _escapeSelector(selector);
    await _waitForSelector(escapedSelector);

    await webViewController.evaluateJavascript(source: '''
        (function() {
          var element = document.querySelector('$escapedSelector');
          if (element) {
            element.scrollIntoView({behavior: 'smooth', block: 'center'});
          }
        })();
        ''');
  }
}

extension CssColor on Color {
  String get cssColor => 'rgb($red, $green, $blue)';
}
