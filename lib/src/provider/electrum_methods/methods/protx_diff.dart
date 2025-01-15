import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';


/// Returns a diff between two deterministic masternode lists. The result also contains proof data..
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestProtXDiff
    extends ElectrumRequest<Map<String, dynamic>, dynamic> {
  ElectrumRequestProtXDiff({required this.baseHeight, required this.height});

  /// The starting block height
  final int baseHeight;

  /// The ending block height.
  final int height;

  /// protx.diff
  @override
  String get method => ElectrumRequestMethods.protxDiff.method;

  @override
  List toParams() {
    return [baseHeight, height];
  }

  /// A dictionary with deterministic masternode lists diff plus proof data.
  @override
  Map<String, dynamic> onResponse(result) {
    return Map<String, dynamic>.from(result);
  }
}
