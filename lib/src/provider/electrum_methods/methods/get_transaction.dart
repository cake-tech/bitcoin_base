import 'package:bitcoin_base/src/provider/service/electrum/methods.dart';
import 'package:bitcoin_base/src/provider/service/electrum/params.dart';

/// Return a raw transaction.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumGetTransactionHex extends ElectrumRequest<String, String> {
  ElectrumGetTransactionHex({required this.transactionHash});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toJson() {
    return [transactionHash, false];
  }

  /// If verbose is false:
  /// The raw transaction as a hexadecimal string.
  ///
  /// If verbose is true:
  /// The result is a coin-specific dictionary – whatever the coin daemon returns when asked for a verbose form of the raw transaction.
  @override
  String onResponse(result) {
    return result;
  }
}

class ElectrumGetTransactionVerbose
    extends ElectrumRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumGetTransactionVerbose({required this.transactionHash});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toJson() {
    return [transactionHash, true];
  }

  /// If verbose is false:
  /// The raw transaction as a hexadecimal string.
  ///
  /// If verbose is true:
  /// The result is a coin-specific dictionary – whatever the coin daemon returns when asked for a verbose form of the raw transaction.
  @override
  Map<String, dynamic> onResponse(result) {
    return result;
  }
}
