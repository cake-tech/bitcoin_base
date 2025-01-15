import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return a server donation address.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestDonationAddress extends ElectrumRequest<String, String> {
  /// server.donation_address
  @override
  String get method => ElectrumRequestMethods.serverDontionAddress.method;

  @override
  List toParams() {
    return [];
  }

  @override
  String onResponse(result) {
    return result;
  }
}
