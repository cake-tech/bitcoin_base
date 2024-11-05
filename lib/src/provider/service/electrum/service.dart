import 'dart:convert';

import 'package:bitcoin_base/src/provider/service/electrum/params.dart';
import 'package:bitcoin_base/src/provider/service/electrum/request_completer.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

enum ConnectionStatus { connected, disconnected, connecting, failed }

class SocketTask {
  SocketTask({
    required this.isSubscription,
    required this.request,
    this.completer,
    this.subject,
  });

  final Completer<dynamic>? completer;
  final BehaviorSubject<dynamic>? subject;
  final bool isSubscription;
  final ElectrumRequestDetails request;
}

/// Abstract class for providing JSON-RPC service functionality.
abstract class BitcoinBaseElectrumRPCService {
  BitcoinBaseElectrumRPCService();

  /// Represents the URL endpoint for JSON-RPC calls.
  String get url;

  AsyncBehaviorSubject<T>? subscribe<T>(ElectrumRequestDetails params);

  /// Makes an HTTP GET request with the specified [params].
  ///
  /// The optional [timeout] parameter sets the maximum duration for the request.
  Future<T> call<T>(ElectrumRequestDetails params, [Duration? timeout]);

  bool get isConnected;
  void disconnect();
  void reconnect();
}

bool isJSONStringCorrect(String source) {
  try {
    json.decode(source);
    return true;
  } catch (_) {
    return false;
  }
}
