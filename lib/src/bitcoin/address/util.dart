import 'package:bitcoin_base/src/utils/utils.dart';
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
    final addressType = RegexUtils.addressTypeFromStr(address, network);

    if (addressType.type == SegwitAddresType.mweb) {
      return BytesUtils.fromHexString(
        MwebAddress.fromAddress(address: address, network: network).addressProgram,
      );
    }

    return addressType.toScriptPubKey().toBytes();
  }

  static String scriptHash(String address, {required BasedUtxoNetwork network}) {
    final outputScript = addressToOutputScript(address: address, network: network);
    final parts = BytesUtils.toHexString(QuickCrypto.sha256Hash(outputScript)).split('');
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
