import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/power_refresh_load_control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  List<ExampleData> dataSources = [];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    dataSources = initExampleDatas;
  }

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          PowerRefreshOrLoadControlWidget(
            builder: (context, availableHeight) {
              return Container(
                color: Colors.red,
                child: const CircularProgressIndicator(),
              );
            },
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate(
            (context, index) {
              ExampleData exampleData = dataSources[index];
              return Container(
                padding: const EdgeInsets.only(top: 8, right: 16, left: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      padding: const EdgeInsets.only(right: 16),
                      child: FadeInImage.assetNetwork(placeholder: 'images/test_custom_list_placeholder.jpeg', image: exampleData.url),
                    ),
                    Expanded(
                      child: Text(exampleData.title),
                    ),
                  ],
                ),
              );
            },
            childCount: dataSources.length,
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

List<ExampleData> initExampleDatas = [
  ExampleData('http://img.netbian.com/file/2022/0331/002127k9yUm.jpg', '客厅沙发美女 白色衬衫 黑色包臀裙 黑色丝袜美腿美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0329/small002656yDIge1648484816.jpg', '好看汉服美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0328/000822p8fgu.jpg', '居家草席 小巧身材美女美腿 蓝色裙子 小美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0325/small004328KQWAd1648140208.jpg', 'cos冰公主美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0322/small0022263YUbJ1647879746.jpg', '手持玫瑰花 美女'),
  ExampleData('http://img.netbian.com/file/2022/0321/small002309WfgXB1647793389.jpg', '居家美女小姐姐'),
  ExampleData('http://img.netbian.com/file/2022/0317/small2320324S0Yr1647530432.jpg', '长发红色美女'),
  ExampleData('http://img.netbian.com/file/2022/0305/small012609UFy0g1646414769.jpg', '中国风旗袍美女美腿 荷塘 坐在石头上的美女鹿醒壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0228/small005451d2ckI1645980891.jpg', '鹿醒 复古美式芭比系列拼图美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0308/small235821v6Cyb1646755101.jpg', '居家 烛光 养眼清纯美女唯美壁纸'),
];

List<ExampleData> loadMoreExampleDatas = [
  ExampleData('http://img.netbian.com/file/2022/0216/small001416nksAc1644941656.jpg', '花园 椅子 清纯 美女美腿 粉色裙子美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0131/small011918dnDVU1643563158.jpg', '居家 沙发 好看衣服 短裙 好看身材美女美腿壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0129/004050xGDF7.jpg', '清纯 清凉 家居 白色袜子美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0128/0028383FvYT.jpg', '刘亦菲 花海 油菜花 看书 清纯美女壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0118/small234047eqfSq1642520447.jpg', 'cos海琴烟 cosplay美女高清壁纸'),
  ExampleData('http://img.netbian.com/file/2022/0113/000229ynXOy.jpg', '舞台 长发 粉色短裙 高跟鞋大长腿美女壁纸'),
];

class ExampleData {
  ExampleData(this.url, this.title);

  String url;
  String title;
}
