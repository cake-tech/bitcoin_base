/// Simple example how to send request to electurm  with websocket
import 'dart:async';
import 'dart:convert';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:example/services_examples/cross_platform_websocket/core.dart';

class ElectrumWebSocketService implements BitcoinBaseElectrumRPCService {
  ElectrumWebSocketService._(
    this.url,
    WebSocketCore channel, {
    this.defaultRequestTimeOut = const Duration(seconds: 30),
  }) : _socket = channel {
    _subscription =
        channel.stream.cast<String>().listen(_onMessage, onError: _onClose, onDone: _onDone);
  }
  WebSocketCore? _socket;
  StreamSubscription<String>? _subscription;
  final Duration defaultRequestTimeOut;

  Map<int, AsyncRequestCompleter> requests = {};
  bool _isDisconnected = false;

  bool get isConnected => !_isDisconnected;

  @override
  final String url;

  void add(List<int> params) {
    if (_isDisconnected) {
      throw StateError("socket has been disconnected");
    }
    _socket?.sink(params);
  }

  void _onClose(Object? error) {
    _isDisconnected = true;

    _socket?.close();
    _socket = null;
    _subscription?.cancel().catchError((e) {});
    _subscription = null;
  }

  void _onDone() {
    _onClose(null);
  }

  @override
  void disconnect() {
    _onClose(null);
  }

  static Future<ElectrumWebSocketService> connect(
    String url, {
    Iterable<String>? protocols,
    Duration defaultRequestTimeOut = const Duration(seconds: 30),
    final Duration connectionTimeOut = const Duration(seconds: 30),
  }) async {
    final channel = await WebSocketCore.connect(url, protocols: protocols?.toList());

    return ElectrumWebSocketService._(url, channel, defaultRequestTimeOut: defaultRequestTimeOut);
  }

  void _onMessage(String event) {
    final Map<String, dynamic> decode = json.decode(event);
    if (decode.containsKey("id")) {
      final int id = int.parse(decode["id"]!.toString());
      final request = requests.remove(id);
      request?.completer.complete(decode);
    }
  }

  @override
  Future<Map<String, dynamic>> call(ElectrumRequestDetails params, [Duration? timeout]) async {
    final AsyncRequestCompleter compeleter = AsyncRequestCompleter(params.params);

    try {
      requests[params.id] = compeleter;
      add(params.toWebSocketParams());
      final result = await compeleter.completer.future.timeout(timeout ?? defaultRequestTimeOut);
      return result;
    } finally {
      requests.remove(params.id);
    }
  }
}
