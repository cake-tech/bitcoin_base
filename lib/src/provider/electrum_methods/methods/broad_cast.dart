import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Broadcast a transaction to the network.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestBroadCastTransaction extends ElectrumRequest<String?, String?> {
  ElectrumRequestBroadCastTransaction({required this.transactionRaw});

  /// The raw transaction as a hexadecimal string.
  final String transactionRaw;

  /// blockchain.transaction.broadcast
  @override
  String get method => ElectrumRequestMethods.broadcast.method;

  @override
  List toParams() {
    return [transactionRaw];
  }

  /// The transaction hash as a hexadecimal string.
  @override
  String? onResponse(result) {
    return result;
  }
}
