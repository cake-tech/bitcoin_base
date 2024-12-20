import 'package:bitcoin_base/src/bitcoin/amount/amount.dart';
import 'package:bitcoin_base/src/provider/api_provider.dart';
import 'dart:async';

import 'package:rxdart/rxdart.dart';

typedef ListenerCallback<T> = StreamSubscription<T> Function(
  void Function(T)? onData, {
  Function? onError,
  void Function()? onDone,
  bool? cancelOnError,
});

class ElectrumApiProvider {
  final BitcoinBaseElectrumRPCService rpc;
  ElectrumApiProvider._(this.rpc);
  int _id = 0;
  int get id => _id;
  Timer? _aliveTimer;

  static Future<ElectrumApiProvider> connect(Future<BitcoinBaseElectrumRPCService> rpc) async {
    final provider = ElectrumApiProvider._(await rpc);
    provider.keepAlive();
    return provider;
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
      final topDoubleString = await request(ElectrumEstimateFee(numberOfBlock: 1));
      final middleDoubleString = await request(ElectrumEstimateFee(numberOfBlock: 5));
      final bottomDoubleString = await request(ElectrumEstimateFee(numberOfBlock: 10));
      final top =
          (BitcoinAmountUtils.stringDoubleToBitcoinAmount(topDoubleString.toString()) / 1000)
              .round();
      final middle =
          (BitcoinAmountUtils.stringDoubleToBitcoinAmount(middleDoubleString.toString()) / 1000)
              .round();
      final bottom =
          (BitcoinAmountUtils.stringDoubleToBitcoinAmount(bottomDoubleString.toString()) / 1000)
              .round();

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
      return await request(ElectrumPing());
    } catch (_) {}
  }
}
