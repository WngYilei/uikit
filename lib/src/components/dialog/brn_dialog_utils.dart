
import 'package:flutter/material.dart';
import 'package:UIKit/bruno.dart';

class BrnDialogUtils {
  /// dialog标题配置
  static TextStyle getDialogTitleStyle(BrnDialogConfig themeData) {
    return themeData?.titleTextStyle?.generateTextStyle();
  }

  /// dialog圆角配置
  static double getDialogRadius(BrnDialogConfig themeData) {
    return themeData?.radius;
  }
}
