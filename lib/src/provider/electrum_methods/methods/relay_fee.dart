import 'package:bitcoin_base_old/src/provider/service/electrum/electrum.dart';
import 'package:bitcoin_base_old/src/utils/btc_utils.dart';

/// Return the minimum fee a low-priority transaction must pay in order to be accepted to the daemon’s memory pool.
/// https://electrumx-spesmilo.readthedocs.io/en/latest/protocol-methods.html
class ElectrumRelayFee extends ElectrumRequest<BigInt, dynamic> {
  /// blockchain.relayfee
  @override
  String get method => ElectrumRequestMethods.relayFee.method;

  @override
  List toJson() {
    return [];
  }

  /// relay fee in Bigint(satoshi)
  @override
  BigInt onResonse(result) {
    return BtcUtils.toSatoshi(result.toString());
  }
}
