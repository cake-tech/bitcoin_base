import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return the confirmed and unconfirmed history of a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashGetHistory
    extends ElectrumRequest<List<Map<String, dynamic>>, List<dynamic>> {
  ElectrumRequestScriptHashGetHistory({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.get_history
  @override
  String get method => ElectrumRequestMethods.getHistory.method;

  @override
  List toParams() {
    return [scriptHash];
  }

  /// A list of confirmed transactions in blockchain order,
  ///  with the output of blockchain.scripthash.get_mempool() appended to the list.
  ///  Each confirmed transaction is a dictionary
  @override
  List<Map<String, dynamic>> onResponse(List<dynamic> result) {
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class ElectrumBatchRequestScriptHashGetHistory
    extends ElectrumBatchRequest<List<Map<String, dynamic>>, Map<String, dynamic>> {
  ElectrumBatchRequestScriptHashGetHistory({required this.scriptHashes});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final List<String> scriptHashes;

  /// blockchain.scripthash.get_history
  @override
  String get method => ElectrumRequestMethods.getHistory.method;

  @override
  List<List> toParams() {
    return [
      ...scriptHashes.map((e) => [e])
    ];
  }

  /// A list of confirmed transactions in blockchain order,
  ///  with the output of blockchain.scripthash.get_mempool() appended to the list.
  ///  Each confirmed transaction is a dictionary
  @override
  ElectrumBatchRequestResult<List<Map<String, dynamic>>> onResponse(
    Map<String, dynamic> data,
    ElectrumBatchRequestDetails request,
  ) {
    final id = data['id'] as int;
    final result = data['result'] as List<dynamic>;
    return ElectrumBatchRequestResult(
      request: request,
      id: id,
      result: result.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }
}
