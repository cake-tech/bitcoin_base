import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

class ElectrumHeaderResponse {
  final String hex;
  final int height;

  ElectrumHeaderResponse(this.hex, this.height);

  factory ElectrumHeaderResponse.fromJson(Map<String, dynamic> json) {
    return ElectrumHeaderResponse(json['hex'], json['height']);
  }

  Map<String, dynamic> toJson() {
    return {'hex': hex, 'height': height};
  }
}

/// Subscribe to receive block headers when a new block is found.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestHeaderSubscribe
    extends ElectrumRequest<ElectrumHeaderResponse, Map<String, dynamic>> {
  /// blockchain.headers.subscribe
  @override
  String get method => ElectrumRequestMethods.headersSubscribe.method;

  @override
  List toJson() {
    return [];
  }

  /// The header of the current block chain tip.
  @override
  ElectrumHeaderResponse onResponse(result) {
    return ElectrumHeaderResponse.fromJson(result);
  }
}
