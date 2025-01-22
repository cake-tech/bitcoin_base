import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Subscribe to a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashSubscribe extends ElectrumRequest<String?, String?> {
  ElectrumRequestScriptHashSubscribe({required this.scriptHash});

  /// /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.subscribe
  @override
  String get method => ElectrumRequestMethods.scriptHashSubscribe.method;

  @override
  List toParams() {
    return [scriptHash];
  }

  /// The status of the script hash.
  @override
  String? onResponse(result) {
    return result;
  }
}

class ElectrumBatchRequestScriptHashSubscribe
    extends ElectrumBatchRequest<String?, Map<String, dynamic>> {
  ElectrumBatchRequestScriptHashSubscribe({required this.scriptHashes});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final List<String> scriptHashes;

  /// blockchain.scripthash.get_history
  @override
  String get method => ElectrumRequestMethods.scriptHashSubscribe.method;

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
  ElectrumBatchRequestResult<String?> onResponse(
    Map<String, dynamic> data,
    ElectrumBatchRequestDetails request,
  ) {
    final id = data['id'] as int;
    final result = data['result'] as String?;
    return ElectrumBatchRequestResult(request: request, id: id, result: result);
  }
}
