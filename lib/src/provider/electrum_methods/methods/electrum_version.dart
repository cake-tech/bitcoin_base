import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';


/// Identify the client to the server and negotiate the protocol version. Only the first server.version() message is accepted.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestVersion
    extends ElectrumRequest<List<String>, List<dynamic>> {
  ElectrumRequestVersion(
      {required this.clientName, required this.protocolVersion});

  /// A string identifying the connecting client software.
  final String clientName;

  final String protocolVersion;

  /// blockchain.version
  @override
  String get method => ElectrumRequestMethods.version.method;

  @override
  List toJson() {
    return [clientName, protocolVersion];
  }

  /// identifying the server and the protocol version that will be used for future communication.
  @override
  List<String> onResponse(result) {
    return List<String>.from(result);
  }
}
