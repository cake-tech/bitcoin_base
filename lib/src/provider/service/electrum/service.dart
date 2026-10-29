import 'dart:convert';
import 'dart:typed_data';

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

/// Splits an Electrum socket byte stream into newline-delimited JSON-RPC
/// messages. Bytes are buffered until a full line arrives, so a message split
/// across socket reads is decoded exactly once, and a bad line only ever
/// loses that one line - nothing is carried over into the next message.
class ElectrumLineFramer {
  ElectrumLineFramer(this.onMessage);

  final void Function(Map<String, dynamic> message) onMessage;
  final BytesBuilder _pending = BytesBuilder(copy: false);

  void add(List<int> chunk) {
    var start = 0;
    var newline = chunk.indexOf(0x0A, start);

    while (newline != -1) {
      _pending.add(chunk.sublist(start, newline));
      _dispatch(_pending.takeBytes());
      start = newline + 1;
      newline = chunk.indexOf(0x0A, start);
    }

    if (start < chunk.length) {
      _pending.add(chunk.sublist(start));
    }
  }

  void _dispatch(List<int> line) {
    if (line.isEmpty) {
      return;
    }

    final dynamic decoded;
    try {
      decoded = json.decode(utf8.decode(line));
    } catch (e) {
      print("ElectrumLineFramer: dropping undecodable line (${line.length} bytes): $e");
      return;
    }

    final messages = decoded is List ? decoded : [decoded];
    for (final message in messages) {
      if (message is! Map<String, dynamic>) {
        continue;
      }

      try {
        onMessage(message);
      } catch (e) {
        print("ElectrumLineFramer: message handler failed: $e");
      }
    }
  }
}

/// Fails every pending call and subscription once the connection is gone, so
/// callers see the disconnect instead of waiting forever on a dead socket.
void failSocketTasks(Map<int, SocketTask> tasks, Object error) {
  final pending = tasks.values.toList();
  tasks.clear();

  for (final task in pending) {
    final subject = task.subject;
    if (subject != null && !subject.isClosed) {
      subject.addError(error);
      subject.close();
    }

    final completer = task.completer;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
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
