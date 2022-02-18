import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:xl_flutter/bruno.dart';

class BrnTextUtil {
  /// 根据 TextStyle 计算 text 宽度。
  static Size textSize(String text, TextStyle style) {
    if (BrunoTools.isEmpty(text)) return Size(0, 0);
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style), maxLines: 1, textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }
}
