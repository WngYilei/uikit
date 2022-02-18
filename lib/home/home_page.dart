import 'package:flutter/cupertino.dart';
import 'package:xl_flutter/home/dialog_entry_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: DialogEntryPage("弹窗示例"),
    );
  }
}
