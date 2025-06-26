import 'package:bitcoin_base_old/src/provider/service/electrum/electrum.dart';

/// Return a list of features and services supported by the server.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumServerFeatures extends ElectrumRequest<dynamic, dynamic> {
  /// server.features
  @override
  String get method => ElectrumRequestMethods.serverFeatures.method;

  @override
  List toJson() {
    return [];
  }

  /// A dictionary of keys and values. Each key represents a feature or service of the server,
  ///  and the value gives additional information.
  @override
  dynamic onResonse(result) {
    return result;
  }
}
