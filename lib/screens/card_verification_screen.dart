import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CardVerificationScreen extends StatefulWidget {
  const CardVerificationScreen({
    Key? key,
    required this.url,
    required this.sucessUrlStart,
    required this.errorUrlStart,
  }) : super(key: key);

  final String url;
  final String sucessUrlStart;
  final String errorUrlStart;

  @override
  _CardVerificationScreenState createState() => _CardVerificationScreenState();
}

class _CardVerificationScreenState extends State<CardVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    print(widget.url);
    return Scaffold(
      appBar: AppBar(title: const Text('3DS')),
      body: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: widget.url,
        navigationDelegate: (navigation) {
          if (navigation.url.startsWith(widget.sucessUrlStart)) {
            Navigator.pop(context, CardVerificationScreenResult(true, navigation.url));
            return NavigationDecision.navigate;
          } else if (navigation.url.startsWith(widget.errorUrlStart)) {
            Navigator.pop(context, CardVerificationScreenResult(false, navigation.url));
            return NavigationDecision.navigate;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}

class CardVerificationScreenResult {
  final bool success;
  final String url;

  CardVerificationScreenResult(this.success, this.url);
}
