
import 'package:UIKit/bruno.dart';

class BrnSelectionEntityListBean {
  List<BrnSelectionEntity> list;

  BrnSelectionEntityListBean(this.list);

  static BrnSelectionEntityListBean fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
    BrnSelectionEntityListBean bean = BrnSelectionEntityListBean(null);
    bean.list = List()
      ..addAll((map['list'] as List ?? []).map((o) => BrnSelectionEntity.fromMap(o)));
    return bean;
  }
}
