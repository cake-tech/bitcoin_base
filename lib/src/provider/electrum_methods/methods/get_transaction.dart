import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return a raw transaction.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetTransactionHex extends ElectrumRequest<String, String> {
  ElectrumRequestGetTransactionHex({required this.transactionHash});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toParams() {
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

class ElectrumBatchRequestGetTransactionHex
    extends ElectrumBatchRequest<String, Map<String, dynamic>> {
  ElectrumBatchRequestGetTransactionHex({required this.transactionHashes});

  /// The transaction hash as a hexadecimal string.
  final List<String> transactionHashes;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List<List> toParams() {
    return [
      ...transactionHashes.map((e) => [e])
    ];
  }

  /// If verbose is false:
  /// The raw transaction as a hexadecimal string.
  ///
  /// If verbose is true:
  /// The result is a coin-specific dictionary – whatever the coin daemon returns when asked for a verbose form of the raw transaction.
  @override
  ElectrumBatchRequestResult<String> onResponse(
    Map<String, dynamic> data,
    ElectrumBatchRequestDetails request,
  ) {
    final id = data['id'] as int;
    return ElectrumBatchRequestResult(
      request: request,
      id: id,
      result: data['result'] as String,
    );
  }
}

class ElectrumRequestGetTransactionVerbose
    extends ElectrumRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumRequestGetTransactionVerbose({required this.transactionHash});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List toParams() {
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

class ElectrumBatchRequestGetTransactionVerbose
    extends ElectrumBatchRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumBatchRequestGetTransactionVerbose({required this.transactionHashes});

  /// The transaction hash as a hexadecimal string.
  final List<String> transactionHashes;

  /// blockchain.transaction.get
  @override
  String get method => ElectrumRequestMethods.getTransaction.method;

  @override
  List<List> toParams() {
    return [
      ...transactionHashes.map((e) => [e, true])
    ];
  }

  /// If verbose is false:
  /// The raw transaction as a hexadecimal string.
  ///
  /// If verbose is true:
  /// The result is a coin-specific dictionary – whatever the coin daemon returns when asked for a verbose form of the raw transaction.
  @override
  ElectrumBatchRequestResult<Map<String, dynamic>> onResponse(
    Map<String, dynamic> data,
    ElectrumBatchRequestDetails request,
  ) {
    final id = data['id'] as int;
    return ElectrumBatchRequestResult(
      request: request,
      id: id,
      result: data['result'] as Map<String, dynamic>,
    );
  }
}
