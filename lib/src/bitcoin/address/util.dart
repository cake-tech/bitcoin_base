import 'package:bitcoin_base/src/bitcoin/script/scripts.dart';
import 'package:bitcoin_base/src/bitcoin/silent_payments/silent_payments.dart';
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

  static String addressFromOutputScript(Script script, BasedUtxoNetwork network) {
    try {
      switch (script.getAddressType()) {
        case P2pkhAddressType.p2pkh:
          return P2pkhAddress.fromScriptPubkey(script: script).toAddress(network);
        case P2shAddressType.p2pkInP2sh:
          return P2shAddress.fromScriptPubkey(script: script).toAddress(network);
        case SegwitAddresType.p2wpkh:
          return P2wpkhAddress.fromScriptPubkey(script: script).toAddress(network);
        case P2shAddressType.p2pkhInP2sh:
          return P2shAddress.fromScriptPubkey(script: script).toAddress(network);
        case SegwitAddresType.p2wsh:
          return P2wshAddress.fromScriptPubkey(script: script).toAddress(network);
        case SegwitAddresType.p2tr:
          return P2trAddress.fromScriptPubkey(script: script).toAddress(network);
        default:
      }
    } catch (_) {}

    return '';
  }

  static BitcoinAddressType addressTypeFromStr(String address, BasedUtxoNetwork network) {
    try {
      return P2pkhAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return P2shAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return P2wpkhAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return P2shAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return P2wshAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return P2trAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return MwebAddress.fromAddress(address: address, network: network).type;
    } catch (_) {}

    try {
      return SilentPaymentAddress.fromAddress(address).type;
    } catch (_) {}

    throw Exception('Invalid address');
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

  static BitcoinAddressType getScriptType(BitcoinBaseAddress type) {
    if (type is P2pkhAddress) {
      return P2pkhAddressType.p2pkh;
    } else if (type is P2shAddress) {
      return P2shAddressType.p2wpkhInP2sh;
    } else if (type is P2wshAddress) {
      return SegwitAddresType.p2wsh;
    } else if (type is P2trAddress) {
      return SegwitAddresType.p2tr;
    } else if (type is MwebAddress) {
      return SegwitAddresType.mweb;
    } else if (type is SilentPaymentsAddresType) {
      return SilentPaymentsAddresType.p2sp;
    } else {
      return SegwitAddresType.p2wpkh;
    }
  }

  static int getAccountFromChange(bool isChange) {
    return isChange ? 1 : 0;
  }

  static BitcoinDerivationInfo getDerivationFromType(
    BitcoinAddressType scriptType, {
    bool? isElectrum = false,
  }) {
    switch (scriptType) {
      case P2pkhAddressType.p2pkh:
        return BitcoinDerivationInfos.BIP44;
      case P2shAddressType.p2wpkhInP2sh:
        return BitcoinDerivationInfos.BIP49;
      case SegwitAddresType.p2wpkh:
        if (isElectrum == true) {
          return BitcoinDerivationInfos.ELECTRUM;
        } else {
          return BitcoinDerivationInfos.BIP84;
        }
      case SegwitAddresType.p2tr:
        return BitcoinDerivationInfos.BIP86;
      case SegwitAddresType.mweb:
        return BitcoinDerivationInfos.BIP86;
      case SegwitAddresType.p2wsh:
        return BitcoinDerivationInfos.BIP84;
      default:
        throw Exception("Derivation not available for $scriptType");
    }
  }
}
