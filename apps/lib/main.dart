import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = "";

  // _getSlackWSSUrl は Slack に問い合わせを行い WebSocket 用の URL を取得する
  _getSlackWSSUrl() async {
    const appToken = 'YOUR_SLACK_APP_TOKEN';

    Uri url = Uri.parse("https://slack.com/api/apps.connections.open");
    Map<String, String> headers = {
      'Content-type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer $appToken'
    };

    http.Response resp = await http.post(url, headers: headers);
    if (resp.statusCode != 200) {
      return;
    } else {
      String slackWSSUrl = json.decode(resp.body)["url"];
      if (slackWSSUrl == "") return;
      _connectToSlackWSS(slackWSSUrl);
    }
  }

  // _connectToSlackWSS は Slack に WebSocket 接続を行い
  // メッセージを受信したら _message にセットする
  _connectToSlackWSS(String slackWSSUrl) {

    final channel = WebSocketChannel.connect(Uri.parse(slackWSSUrl));
    int eventTs = 0;

    channel.stream.listen((event) {
      var ev = json.decode(event);

      if (ev["type"] == "events_api"
      // メッセージタイプのイベントのみを処理する
      && ev["payload"]["event"]["type"] == "message"
      // 同じメッセージが複数回飛んでくることがあるので、event_time を取得しておき
      // それ以降のメッセージのみ受け付けるようにしている
      && ev["payload"]["event_time"] >= eventTs) {
        setState(() {
          _message = ev["payload"]["event"]["text"] ?? "";
          eventTs = ev["payload"]["event_time"];
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getSlackWSSUrl();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Text(_message),
      ),
    );
  }
}
