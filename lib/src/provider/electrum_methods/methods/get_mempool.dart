import 'package:bitcoin_base/src/provider/service/electrum/methods.dart';
import 'package:bitcoin_base/src/provider/service/electrum/params.dart';

/// Return the unconfirmed transactions of a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumScriptHashGetMempool
    extends ElectrumRequest<List<Map<String, dynamic>>, List<dynamic>> {
  ElectrumScriptHashGetMempool({required this.scriptHash});

  /// The script hash as a hexadecimal string (BitcoinBaseAddress.pubKeyHash())
  final String scriptHash;

  /// blockchain.scripthash.get_mempool
  @override
  String get method => ElectrumRequestMethods.getMempool.method;

  @override
  List toJson() {
    return [scriptHash];
  }

  /// A list of mempool transactions in arbitrary order. Each mempool transaction is a dictionary
  @override
  List<Map<String, dynamic>> onResponse(List<dynamic> result) {
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
