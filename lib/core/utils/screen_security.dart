import 'dart:io';
import 'package:flutter/services.dart';

class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('carepass/screen_security');

  /// ✅ منع السكرين شوت
  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (_) {}
  }

  /// ✅ السماح بالسكرين شوت
  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (_) {}
  }
}
