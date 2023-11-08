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
        leadingWidth: 32.0,
        title: Text(
          'Find Station Name for Search',
          style: TextStyle(
            fontSize: 16.0,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
