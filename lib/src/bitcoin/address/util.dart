import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/models/network.dart';

class BitcoinAddressUtils {
  static bool validateAddress({required String address, required BasedUtxoNetwork network}) {
    try {
      addressToOutputScript(address: address, network: network);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<int> addressToOutputScript(
      {required String address, required BasedUtxoNetwork network}) {
    if (network == BitcoinCashNetwork.mainnet) {
      return BitcoinCashAddress(address).baseAddress.toScriptPubKey().toBytes();
    }

    if (P2pkhAddress.regex.hasMatch(address)) {
      return P2pkhAddress.fromAddress(address: address, network: network)
          .toScriptPubKey()
          .toBytes();
    }

    if (P2shAddress.regex.hasMatch(address)) {
      return P2shAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
    }

    if (P2wpkhAddress.regex.hasMatch(address)) {
      return P2wpkhAddress.fromAddress(address: address, network: network)
          .toScriptPubKey()
          .toBytes();
    }

    if (P2wshAddress.regex.hasMatch(address)) {
      return P2wshAddress.fromAddress(address: address, network: network)
          .toScriptPubKey()
          .toBytes();
    }

    if (P2trAddress.regex.hasMatch(address)) {
      return P2trAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
    }

    if (MwebAddress.regex.hasMatch(address)) {
      return BytesUtils.fromHexString(
        MwebAddress.fromAddress(address: address, network: network).addressProgram,
      );
    }

    return P2wpkhAddress.fromAddress(address: address, network: network).toScriptPubKey().toBytes();
  }

  static String scriptHash(String address, {required BasedUtxoNetwork network}) {
    final outputScript = addressToOutputScript(address: address, network: network);
    final parts = QuickCrypto.sha256Hash(outputScript).toString().split('');
    var res = '';

    for (var i = parts.length - 1; i >= 0; i--) {
      final char = parts[i];
      i--;
      final nextChar = parts[i];
      res += nextChar;
      res += char;
    }

    return res;
  }
}
