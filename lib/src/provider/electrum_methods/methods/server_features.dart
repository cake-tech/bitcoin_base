import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Return a list of features and services supported by the server.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestServerFeatures extends ElectrumRequest<dynamic, dynamic> {
  /// server.features
  @override
  String get method => ElectrumRequestMethods.serverFeatures.method;

  @override
  List toParams() {
    return [];
  }

  /// A dictionary of keys and values. Each key represents a feature or service of the server,
  ///  and the value gives additional information.
  @override
  dynamic onResponse(result) {
    return result;
  }
}
