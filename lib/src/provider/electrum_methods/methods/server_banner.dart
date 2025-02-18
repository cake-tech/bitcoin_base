import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return a banner to be shown in the Electrum console.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestServerBanner extends ElectrumRequest<String, dynamic> {
  @override
  String get method => ElectrumRequestMethods.serverBanner.method;

  @override
  List toParams() {
    return [];
  }

  @override
  String onResponse(result) {
    return result.toString();
  }
}
