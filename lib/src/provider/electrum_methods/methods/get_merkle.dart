import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return the merkle branch to a confirmed transaction given its hash and height.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestGetMerkle extends ElectrumRequest<Map<String, dynamic>, Map<String, dynamic>> {
  ElectrumRequestGetMerkle({required this.transactionHash, required this.height});

  /// The transaction hash as a hexadecimal string.
  final String transactionHash;

  /// he height at which it was confirmed.
  final int height;

  /// blockchain.transaction.get_merkle
  @override
  String get method => ElectrumRequestMethods.getMerkle.method;

  @override
  List toParams() {
    return [transactionHash, height];
  }

  @override
  Map<String, dynamic> onResponse(result) {
    return result;
  }
}
