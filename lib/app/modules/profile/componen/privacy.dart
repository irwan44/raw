import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Privacy extends StatefulWidget {
  const Privacy({super.key});

  @override
  State<Privacy> createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // <-- SEE HERE
            statusBarIconBrightness: Brightness.dark, //<-- For Android SEE HERE (dark icons)
            statusBarBrightness: Brightness.light, //<-- For iOS SEE HERE (dark icons)
            systemNavigationBarColor:  Colors.transparent,
          ),
          elevation: 0,
          // leadingWidth: 45,
          actionsIconTheme: const IconThemeData(size: 20),
          backgroundColor: Colors.transparent,
          title: Text(
            'Privacy Policy',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold,),
          ),
        ),
        body:
        WebView(
          initialUrl: 'https://doc-hosting.flycricket.io/bengkelly-privacy-policy/5a119fea-9881-4ddd-946f-4f14ec9f02c1/privacy',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          javascriptChannels: <JavascriptChannel>{
            _createOpenLinkJavascriptChannel(context),
          },
        )
    );
  }

  JavascriptChannel _createOpenLinkJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'OpenLink',
        onMessageReceived: (JavascriptMessage message) {
          _launchURL(message.message);
        });
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}