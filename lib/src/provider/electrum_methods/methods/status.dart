import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Subscribe to a script hash.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestScriptHashSubscribe extends ElectrumRequest<Map<String, dynamic>, dynamic> {
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
  Map<String, dynamic> onResponse(result) {
    return result;
  }
}
