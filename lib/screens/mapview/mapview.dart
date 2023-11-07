import 'package:flutter/material.dart';
import 'package:sonoreapp/shared/settings.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RadioBrowserMap extends StatefulWidget {
  const RadioBrowserMap({super.key});

  @override
  State<RadioBrowserMap> createState() => _RadioBrowserMapState();
}

class _RadioBrowserMapState extends State<RadioBrowserMap> {
  late final WebViewController controller;

  @override
  void initState() {
    initWebView();
    super.initState();
  }

  initWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          // onProgress: (int progress) {},
          // onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          // onWebResourceError: (WebResourceError error) {},
          // onNavigationRequest: (NavigationRequest request) {
          //   if (request.url.startsWith('https://www.youtube.com/')) {
          //     return NavigationDecision.prevent;
          //   }
          //   return NavigationDecision.navigate;
          // },
        ),
      )
      ..loadRequest(Uri.parse(urlMapRadioBrowser));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Note Station Name',
              style: TextStyle(fontSize: 18.0),
            ),
            Text(
              'Then use it for search',
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
