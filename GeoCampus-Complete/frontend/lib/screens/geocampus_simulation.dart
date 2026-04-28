import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GeoCampusSimulationScreen extends StatefulWidget {
  const GeoCampusSimulationScreen({super.key});

  @override
  State<GeoCampusSimulationScreen> createState() =>
      _GeoCampusSimulationScreenState();
}

class _GeoCampusSimulationScreenState extends State<GeoCampusSimulationScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Using the same local IP you have the python web server running on
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse('http://192.168.1.44:8080/ez-tree/dist/index.html'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: WebViewWidget(controller: _controller),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: const Text(
                '3D TREE SIMULATION',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
