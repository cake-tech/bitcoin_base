import 'package:bitcoin_base/src/provider/service/electrum/electrum.dart';

/// Ping the server to ensure it is responding, and to keep the session alive. The server may disconnect clients that have sent no requests for roughly 10 minutes.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRequestPing extends ElectrumRequest<dynamic, dynamic> {
  @override
  String get method => ElectrumRequestMethods.ping.method;

  @override
  List toParams() {
    return [];
  }

  @override
  dynamic onResponse(result) {
    return null;
  }
}
