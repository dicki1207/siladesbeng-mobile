import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:siladesbeng_mobile/features/common/no_internet_page.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget child;

  const NetworkWrapper({super.key, required this.child});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _hasInternet = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool hasConnection = !results.contains(ConnectivityResult.none);

    // Kadang connectivity_plus mengembalikan list kosong atau ada exception di beberapa versi,
    // asalkan tidak secara eksplisit 'none', kita anggap terhubung.
    // Tapi yang paling aman jika isNotEmpty dan tidak hanya berisi 'none'.
    if (results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none)) {
      hasConnection = false;
    }

    if (_hasInternet != hasConnection) {
      setState(() {
        _hasInternet = hasConnection;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_hasInternet)
          Positioned.fill(
            child: NoInternetPage(
              isOverlay: true,
              onRetry: _checkInitialConnection,
            ),
          ),
      ],
    );
  }
}
