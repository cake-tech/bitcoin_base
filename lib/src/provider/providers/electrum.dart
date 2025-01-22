import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:rxdart/rxdart.dart';

class BatchSubscription<T> {
  final BehaviorSubject<T> subscription;
  final ElectrumBatchRequestDetails params;

  BatchSubscription(this.subscription, this.params);
}

typedef ListenerCallback<T> = StreamSubscription<T> Function(
  void Function(T)? onData, {
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
});

class ElectrumProvider {
  final BitcoinBaseElectrumRPCService rpc;
  ElectrumProvider._(this.rpc);
  int _id = 0;
  int get id => _id;
  Timer? _aliveTimer;

  static Future<ElectrumProvider> connect(Future<BitcoinBaseElectrumRPCService> rpc) async {
    final provider = ElectrumProvider._(await rpc);
    provider.keepAlive();
    return provider;
  }

  Future<List<ElectrumBatchRequestResult<T>>> batchRequest<T, U>(
    ElectrumBatchRequest<T, U> request, [
    Duration? timeout,
  ]) async {
    final id = ++_id;
    final params = request.toRequest(id) as ElectrumBatchRequestDetails;
    _id = request.finalId;

    final results = await rpc.batchCall<U>(params, timeout);
    return results.map((r) => request.onResponse(r, params)).toList();
  }

  /// Sends a request to the Electrum server using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  Future<T> request<T, U>(ElectrumRequest<T, U> request, [Duration? timeout]) async {
    final id = ++_id;
    final params = request.toRequest(id);
    final result = await rpc.call<U>(params, timeout);
    return request.onResponse(result);
  }

  Future<List<BatchSubscription<U>>?> batchSubscribe<T, U>(
    ElectrumBatchRequest<T, U> request, [
    Duration? timeout,
  ]) async {
    final id = ++_id;
    final params = request.toRequest(id) as ElectrumBatchRequestDetails;
    _id = request.finalId;
    final subscriptions = rpc.batchSubscribe<U>(params);

    if (subscriptions == null) return null;

    return subscriptions.map((s) => BatchSubscription(s.subscription, params)).toList();
  }

  // Preserving generic type T in subscribe method
  BehaviorSubject<U>? subscribe<T, U>(ElectrumRequest<T, U> request) {
    final id = ++_id;
    final params = request.toRequest(id);
    final subscription = rpc.subscribe<U>(params);

    if (subscription == null) return null;

    return subscription.subscription;
  }

  Future<List<int>> getFeeRates() async {
    try {
      final topDoubleString = await request(ElectrumRequestEstimateFee(numberOfBlock: 1));
      final middleDoubleString = await request(ElectrumRequestEstimateFee(numberOfBlock: 5));
      final bottomDoubleString = await request(ElectrumRequestEstimateFee(numberOfBlock: 10));

      final top = (topDoubleString!.toInt() / 1000).round();
      final middle = (middleDoubleString!.toInt() / 1000).round();
      final bottom = (bottomDoubleString!.toInt() / 1000).round();

      return [bottom, middle, top];
    } catch (_) {
      return [];
    }
  }

  void keepAlive() {
    _aliveTimer?.cancel();
    _aliveTimer = Timer.periodic(const Duration(seconds: 6), (_) async => ping());
  }

  void ping() async {
    try {
      return await request(ElectrumRequestPing());
    } catch (_) {}
  }
}
