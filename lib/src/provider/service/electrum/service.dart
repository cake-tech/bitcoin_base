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
    this.isBatchRequest = false,
    this.completer,
    this.subject,
  });

  final Completer<dynamic>? completer;
  final BehaviorSubject<dynamic>? subject;
  final bool isSubscription;
  final bool isBatchRequest;
  final BaseElectrumRequestDetails request;
}

/// Abstract class for providing JSON-RPC service functionality.
abstract class BitcoinBaseElectrumRPCService {
  BitcoinBaseElectrumRPCService();

  /// Represents the URL endpoint for JSON-RPC calls.
  String get url;

  AsyncBehaviorSubject<T>? subscribe<T>(ElectrumRequestDetails params);

  List<AsyncBehaviorSubject<T>>? batchSubscribe<T>(ElectrumBatchRequestDetails params);

  /// Makes an HTTP GET request with the specified [params].
  ///
  /// The optional [timeout] parameter sets the maximum duration for the request.
  Future<T> call<T>(ElectrumRequestDetails params, [Duration? timeout]);

  Future<List<T>> batchCall<T>(ElectrumBatchRequestDetails params, [Duration? timeout]);

  bool get isConnected;
  void disconnect();
  void reconnect();
  static Future<BitcoinBaseElectrumRPCService> connect(
    Uri uri, {
    Iterable<String>? protocols,
    Duration defaultRequestTimeOut = const Duration(seconds: 30),
    final Duration connectionTimeOut = const Duration(seconds: 30),
    void Function(ConnectionStatus)? onConnectionStatusChange,
  }) {
    throw UnimplementedError();
  }
}

bool isJSONStringCorrect(String source) {
  try {
    json.decode(source);
    return true;
  } catch (_) {
    return false;
  }
}
