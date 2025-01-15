import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return the confirmed and unconfirmed balances of a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetScriptHashBalance
    extends ElectrumRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumRequestGetScriptHashBalance({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.get_balance
  @override
  String get method => ElectrumRequestMethods.getBalance.method;

  @override
  List toParams() {
    return [scriptHash];
  }

  /// A dictionary with keys confirmed and unconfirmed.
  /// The value of each is the appropriate balance in minimum coin units (satoshis).
  @override
  Map<String, dynamic> onResponse(Map<String, dynamic> result) {
    return result;
  }
}

class ElectrumBatchRequestGetScriptHashBalance
    extends ElectrumBatchRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumBatchRequestGetScriptHashBalance({required this.scriptHashes});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final List<String> scriptHashes;

  /// blockchain.scripthash.get_history
  @override
  String get method => ElectrumRequestMethods.getBalance.method;

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
  ElectrumBatchRequestResult<Map<String, dynamic>> onResponse(
    Map<String, dynamic> result,
    ElectrumBatchRequestDetails details,
  ) {
    return ElectrumBatchRequestResult(details, Map<String, dynamic>.from(result));
  }
}
