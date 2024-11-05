/// Simple example how to send request to electurm  with tcp

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:rxdart/rxdart.dart';

class SocketTask {
  SocketTask({required this.isSubscription, this.completer, this.subject});

  final Completer<dynamic>? completer;
  final BehaviorSubject<dynamic>? subject;
  final bool isSubscription;
}

class ElectrumTCPService implements BitcoinBaseElectrumRPCService {
  ElectrumTCPService._(
    this.url,
    SecureSocket channel, {
    this.defaultRequestTimeOut = const Duration(seconds: 30),
  }) : _socket = channel {
    _subscription = _socket!.listen(_onMessage, onError: _onClose, onDone: _onDone);
  }
  SecureSocket? _socket;
  StreamSubscription<List<int>>? _subscription;
  final Duration defaultRequestTimeOut;

  final Map<int, SocketTask> _tasks = {};

  bool _isDisconnected = false;
  @override
  bool get isConnected => !_isDisconnected;

  @override
  final String url;

  void add(List<int> params) {
    if (_isDisconnected) {
      throw StateError("socket has been disconnected");
    }
    _socket?.add(params);
  }

  void _onClose(Object? error) {
    _isDisconnected = true;

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

  static Future<ElectrumTCPService> connect(
    String url, {
    Iterable<String>? protocols,
    Duration defaultRequestTimeOut = const Duration(seconds: 30),
    final Duration connectionTimeOut = const Duration(seconds: 30),
  }) async {
    final parts = url.split(":");
    final channel =
        await SecureSocket.connect(parts[0], int.parse(parts[1])).timeout(connectionTimeOut);

    return ElectrumTCPService._(url, channel, defaultRequestTimeOut: defaultRequestTimeOut);
  }

  void _onMessage(List<int> event) {
    final Map<String, dynamic> decode = json.decode(utf8.decode(event));
    if (decode.containsKey("id")) {
      _finish(decode["id"]!.toString(), decode);
      final int id = int.parse(decode["id"]!.toString());
      final request = _tasks.remove(id);
      request?.completer?.complete(decode);
    }
  }

  void _finish(String id, Map<String, dynamic> decode) {
    final int id = int.parse(decode["id"]!.toString());
    if (_tasks[id] == null) {
      return;
    }

    if (!(_tasks[id]?.completer?.isCompleted ?? false)) {
      _tasks[id]?.completer!.complete(decode);
    }

    final isSubscription = _tasks[id]?.isSubscription ?? false;
    if (!isSubscription) {
      _tasks.remove(id);
    } else {
      _tasks[id]?.subject?.add(decode);
    }
  }

  void _registerSubscription(int id, BehaviorSubject<dynamic> subject) =>
      _tasks[id] = SocketTask(subject: subject, isSubscription: true);

  @override
  AsyncBehaviorSubject<T>? subscribe<T>(ElectrumRequestDetails params) {
    final subscription = AsyncBehaviorSubject<T>(params.params);

    try {
      _registerSubscription(params.id, subscription.subscription);
      add(params.toTCPParams());

      return subscription;
    } catch (e) {
      return null;
    }
  }

  void _registerTask(int id, Completer<dynamic> completer) =>
      _tasks[id] = SocketTask(completer: completer, isSubscription: false);

  @override
  Future<Map<String, dynamic>> call(ElectrumRequestDetails params, [Duration? timeout]) async {
    final completer = AsyncRequestCompleter(params.params);

    try {
      _registerTask(params.id, completer.completer);
      add(params.toTCPParams());
      final result = await completer.completer.future.timeout(timeout ?? defaultRequestTimeOut);
      return result;
    } finally {
      _tasks.remove(params.id);
    }
  }
}
