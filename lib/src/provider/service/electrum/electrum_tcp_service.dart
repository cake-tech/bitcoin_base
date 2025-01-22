import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bitcoin_base/src/provider/service/electrum/params.dart';
import 'package:bitcoin_base/src/provider/service/electrum/request_completer.dart';
import 'package:bitcoin_base/src/provider/service/electrum/service.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

class ElectrumTCPService implements BitcoinBaseElectrumRPCService {
  ElectrumTCPService._(
    this.url,
    Socket channel, {
    this.defaultRequestTimeOut = const Duration(seconds: 30),
    this.onConnectionStatusChange,
  }) : _socket = channel {
    _setConnectionStatus(ConnectionStatus.connected);
    _subscription = _socket!.listen(_onMessage, onError: close, onDone: _onDone);
  }
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  final Duration defaultRequestTimeOut;
  String unterminatedString = '';
  final Map<int, RPCError> _errors = {};
  final Map<int, SocketTask> _tasks = {};

  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  bool get _isDisconnected => _connectionStatus == ConnectionStatus.disconnected;
  @override
  bool get isConnected => !_isDisconnected;
  void Function(ConnectionStatus)? onConnectionStatusChange;

  @override
  final String url;

  void add(List<int> params) {
    if (_isDisconnected) {
      throw StateError("socket has been disconnected");
    }
    _socket?.add(params);
  }

  void _setConnectionStatus(ConnectionStatus status) {
    onConnectionStatusChange?.call(status);
    _connectionStatus = status;
    if (!isConnected) {
      try {
        _socket?.destroy();
      } catch (_) {}
      _socket = null;
    }
  }

  @override
  void reconnect() {
    if (_isDisconnected) {
      _setConnectionStatus(ConnectionStatus.connecting);
      connect(Uri.parse(url)).then((value) {
        _setConnectionStatus(ConnectionStatus.connected);
      }).catchError((e) {
        _setConnectionStatus(ConnectionStatus.failed);
      });
    }
  }

  void close(Object? error) async {
    await _socket?.close();
    _socket = null;
    _subscription?.cancel().catchError((e) {});
    _subscription = null;

    _setConnectionStatus(ConnectionStatus.disconnected);
  }

  void _onDone() {
    close(null);
  }

  @override
  void disconnect() {
    close(null);
  }

  static Future<ElectrumTCPService> connect(
    Uri uri, {
    Iterable<String>? protocols,
    Duration defaultRequestTimeOut = const Duration(seconds: 30),
    final Duration connectionTimeOut = const Duration(seconds: 30),
    void Function(ConnectionStatus)? onConnectionStatusChange,
  }) async {
    final channel = await Socket.connect(uri.host, uri.port).timeout(connectionTimeOut);

    return ElectrumTCPService._(
      uri.toString(),
      channel,
      defaultRequestTimeOut: defaultRequestTimeOut,
      onConnectionStatusChange: onConnectionStatusChange,
    );
  }

  void _parseResponse(String message) {
    try {
      final response = json.decode(message) as Map<String, dynamic>;
      _handleResponse(response);
    } on FormatException catch (e) {
      final msg = e.message.toLowerCase();

      if (e.source is String) {
        unterminatedString += e.source as String;
      }

      if (msg.contains("not a subtype of type")) {
        unterminatedString += e.source as String;
        return;
      }

      if (isJSONStringCorrect(unterminatedString)) {
        try {
          final response = json.decode(unterminatedString) as Map<String, dynamic>;
          _handleResponse(response);
          unterminatedString = '';
        } catch (_) {
          final response = json.decode(unterminatedString) as List<dynamic>;
          for (final element in response) {
            _handleResponse(element as Map<String, dynamic>);
          }

          unterminatedString = '';
        }
      }
    } on TypeError catch (e) {
      if (!e.toString().contains('Map<String, Object>') &&
          !e.toString().contains('Map<String, dynamic>')) {
        return;
      }

      unterminatedString += message;

      if (isJSONStringCorrect(unterminatedString)) {
        try {
          final response = json.decode(unterminatedString) as Map<String, dynamic>;
          _handleResponse(response);
          unterminatedString = '';
        } catch (_) {
          final response = json.decode(unterminatedString) as List<dynamic>;
          for (final element in response) {
            _handleResponse(element as Map<String, dynamic>);
          }
          unterminatedString = '';
        }
      }
    } catch (_) {}
  }

  void _handleResponse(Map<String, dynamic> response) {
    var id = response['id'] == null ? null : int.parse(response['id']!.toString());

    if (id == null) {
      String? method = response['method'];

      if (method == null) {
        final error = response["error"];
        if (response["error"] != null) {
          final message = error["message"];
          if (message != null) {
            final isFulcrum = message.toLowerCase().contains("unsupported request");
            final match = (isFulcrum ? RegExp(r'request:\s*(\S+)') : RegExp(r'"([^"]*)"'))
                .firstMatch(message);
            method = match?.group(1) ?? '';
          }
        }
      }

      _tasks.forEach((key, value) {
        if (value.request.method == method) {
          id = key;
        }
      });
    }

    final result = _findResult(response, _tasks[id]!.request);
    _finish(id!, result);
  }

  void _onMessage(List<int> event) {
    try {
      final msg = utf8.decode(event.toList());
      final messagesList = msg.split("\n");
      for (var message in messagesList) {
        if (message.isEmpty) {
          continue;
        }

        _parseResponse(message);
      }
    } catch (_) {}
  }

  dynamic _findResult(dynamic data, BaseElectrumRequestDetails? request) {
    final error = data["error"];
    int? id;
    try {
      id = request?.params["id"];
    } catch (_) {}
    final requestParams = data["request"] ?? request?.params;

    if (error != null) {
      if (error is String) {
        if (id != null) {
          _errors[id] = RPCError(
            data: error,
            errorCode: 0,
            message: error,
            request: requestParams,
          );
        }
      } else {
        final code = int.tryParse(((error['code']?.toString()) ?? "0")) ?? 0;
        final message = error['message'] ?? "";

        if (id != null) {
          _errors[id] = RPCError(
            errorCode: code,
            message: message,
            data: error["data"],
            request: requestParams,
          );
        }

        if (message.toLowerCase().contains("unknown method") ||
            message.toLowerCase().contains("unsupported request")) {
          return <String, dynamic>{};
        }

        if (message.toLowerCase().contains("batch limit")) {
          for (final k in _tasks.keys) {
            if (_tasks[k]?.isBatchRequest ?? false) {
              _errors[k] = RPCError(
                errorCode: code,
                message: message,
                data: error["data"],
                request: requestParams,
              );

              _tasks[k]!.completer?.completeError(_errors[k]!);
            }
          }
        }
      }
    }

    return data["result"] ?? data["params"]?[0];
  }

  void _finish(int id, dynamic result) {
    final task = _tasks[id];
    if (task == null) {
      return;
    }

    if (!task.isSubscription) {
      final notCompleted = task.completer != null && task.completer!.isCompleted == false;
      if (notCompleted) {
        if (task.isBatchRequest) {
          task.completer!.complete({"id": id, "result": result});
        } else {
          task.completer!.complete(result);
        }
      }

      _tasks.remove(id);
    } else {
      if (task.isBatchRequest) {
        task.subject?.add({"id": id, "result": result});
      } else {
        task.subject?.add(result);
      }
    }
  }

  AsyncBehaviorSubject<T> _registerSubscription<T>(ElectrumRequestDetails params) {
    final subscription = AsyncBehaviorSubject<T>(params.params);
    _tasks[params.id] = SocketTask(
      subject: subscription.subscription,
      request: params,
      isSubscription: true,
    );
    return subscription;
  }

  @override
  AsyncBehaviorSubject<T>? subscribe<T>(ElectrumRequestDetails params) {
    try {
      final subscription = _registerSubscription<T>(params);
      add(params.toTCPParams());

      return subscription;
    } catch (e) {
      return null;
    }
  }

  List<AsyncBehaviorSubject<T>> _registerBatchSubscription<T>(
    ElectrumBatchRequestDetails mainParams,
  ) {
    return mainParams.params.map((params) {
      final subscription = AsyncBehaviorSubject<T>(params);

      final id = params["id"] as int;
      _tasks[id] = SocketTask(
        subject: subscription.subscription,
        request: mainParams,
        isSubscription: true,
        isBatchRequest: true,
      );

      return subscription;
    }).toList();
  }

  @override
  List<AsyncBehaviorSubject<T>>? batchSubscribe<T>(ElectrumBatchRequestDetails params) {
    try {
      final subscriptions = _registerBatchSubscription<T>(params);
      add(params.toTCPParams());

      return subscriptions;
    } catch (e) {
      return null;
    }
  }

  AsyncRequestCompleter<T> _registerTask<T>(ElectrumRequestDetails params) {
    final completer = AsyncRequestCompleter<T>(params.params);

    _tasks[params.id] = SocketTask(
      completer: completer.completer,
      request: params,
      isSubscription: false,
    );

    return completer;
  }

  @override
  Future<T> call<T>(ElectrumRequestDetails params, [Duration? timeout]) async {
    try {
      final completer = _registerTask<T>(params);
      add(params.toTCPParams());
      final result = await completer.completer.future.timeout(timeout ?? defaultRequestTimeOut);
      return result;
    } finally {
      _tasks.remove(params.id);
    }
  }

  List<AsyncRequestCompleter<T>> _registerBatchTask<T>(ElectrumBatchRequestDetails mainParams) {
    return mainParams.params.map((params) {
      final completer = AsyncRequestCompleter<T>(params);

      final id = params["id"] as int;
      _tasks[id] = SocketTask(
        completer: completer.completer,
        request: mainParams,
        isSubscription: false,
      );

      return completer;
    }).toList();
  }

  @override
  Future<List<T>> batchCall<T>(ElectrumBatchRequestDetails params, [Duration? timeout]) async {
    try {
      final completers = _registerBatchTask<T>(params);
      add(params.toTCPParams());
      final result = await Future.wait(completers.map((e) => e.completer.future))
          .timeout(timeout ?? defaultRequestTimeOut);
      return result;
    } finally {
      for (final id in params.paramsById.keys) {
        _tasks.remove(id);
      }
    }
  }

  String getErrorMessage(int id) => _errors[id]?.data ?? '';
}
