import 'package:xl_flutter/bruno.dart';
import 'package:xl_flutter/src/theme/img/brn_theme_img_utils.dart';

///bruno初始化

class BrnInitializer {
  /// 手动注册时，默认注册渠道是 GLOBAL_CONFIG_ID
  static register(
      {BrnAllThemeConfig allThemeConfig,
      String configId = BrnThemeConfigurator.GLOBAL_CONFIG_ID,
      BrnThemeImgUtils brunoImgUtils}) {
    /// 配置图片
    if (brunoImgUtils != null) {
      BrnThemeImg.register(brunoImgUtils: brunoImgUtils);
    }
    /// 配置主题定制
    BrnThemeConfigurator.instance.register(allThemeConfig, configId: configId);
  }
}
