part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class BitcoinAddressType implements Enumerate {
  @override
  final String value;

  const BitcoinAddressType._(this.value);

  /// Factory method to create a BitcoinAddressType enum value from a name or value.
  static BitcoinAddressType fromValue(String value) {
    return values.firstWhere((element) => element.value == value,
        orElse: () => throw DartBitcoinPluginException('Invalid BitcoinAddressType: $value'));
  }

  static BitcoinAddressType fromAddress(BitcoinBaseAddress address) {
    if (address is P2pkhAddress) {
      return P2pkhAddressType.p2pkh;
    } else if (address is P2shAddress) {
      return P2shAddressType.p2wpkhInP2sh;
    } else if (address is P2wshAddress) {
      return SegwitAddressType.p2wsh;
    } else if (address is P2trAddress) {
      return SegwitAddressType.p2tr;
    } else if (address is SilentPaymentsAddresType) {
      return SilentPaymentsAddresType.p2sp;
    } else if (address is P2wpkhAddress) {
      return SegwitAddressType.p2wpkh;
    }

    throw DartBitcoinPluginException('Invalid BitcoinAddressType: $address');
  }

  /// Check if the address type is Pay-to-Script-Hash (P2SH).
  bool get isP2sh;
  int get hashLength;
  bool get isSegwit;

  // Enum values as a list for iteration
  static const List<BitcoinAddressType> values = [
    P2pkhAddressType.p2pkh,
    SegwitAddressType.p2wpkh,
    SegwitAddressType.p2tr,
    SegwitAddressType.p2wsh,
    SegwitAddressType.mweb,
    P2shAddressType.p2wshInP2sh,
    P2shAddressType.p2wpkhInP2sh,
    P2shAddressType.p2pkhInP2sh,
    P2shAddressType.p2pkInP2sh,
    P2shAddressType.p2pkhInP2sh32,
    P2shAddressType.p2pkInP2sh32,
    P2shAddressType.p2pkhInP2sh32wt,
    P2shAddressType.p2pkInP2sh32wt,
    P2shAddressType.p2pkhInP2shwt,
    P2shAddressType.p2pkInP2shwt,
    P2pkhAddressType.p2pkhwt,
    SilentPaymentsAddresType.p2sp
  ];
  T cast<T extends BitcoinAddressType>() {
    if (this is! T) {
      throw DartBitcoinPluginException('BitcoinAddressType casting failed.',
          details: {'excepted': '$T', 'type': value});
    }
    return this as T;
  }

  @override
  String toString() => value;
}

abstract class BitcoinBaseAddress {
  BitcoinBaseAddress();

  BitcoinAddressType get type;
  String toAddress(BasedUtxoNetwork network);
  Script toScriptPubKey();
  String pubKeyHash();
  String get addressProgram;

  static BitcoinBaseAddress fromString(
    String address, [
    BasedUtxoNetwork network = BitcoinNetwork.mainnet,
  ]) {
    if (network is BitcoinCashNetwork) {
      if (!address.startsWith("bitcoincash:") &&
          (address.startsWith("q") || address.startsWith("p"))) {
        address = "bitcoincash:$address";
      }

      return BitcoinCashAddress(address).baseAddress;
    }

    if (P2pkhAddress.regex.hasMatch(address)) {
      return P2pkhAddress.fromAddress(address: address, network: network);
    } else if (P2shAddress.regex.hasMatch(address)) {
      return P2shAddress.fromAddress(address: address, network: network);
    } else if (P2wshAddress.regex.hasMatch(address)) {
      return P2wshAddress.fromAddress(address: address, network: network);
    } else if (P2trAddress.regex.hasMatch(address)) {
      return P2trAddress.fromAddress(address: address, network: network);
    } else if (SilentPaymentAddress.regex.hasMatch(address)) {
      return SilentPaymentAddress.fromAddress(address);
    } else if (P2wpkhAddress.regex.hasMatch(address)) {
      return P2wpkhAddress.fromAddress(address: address, network: network);
    }

    throw DartBitcoinPluginException('Invalid BitcoinBaseAddress: $address');
  }
}

class PubKeyAddressType extends BitcoinAddressType {
  const PubKeyAddressType._(super.value) : super._();
  static const PubKeyAddressType p2pk = PubKeyAddressType._('P2PK');
  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  int get hashLength => 20;
  @override
  String toString() => value;
}

class P2pkhAddressType extends BitcoinAddressType {
  const P2pkhAddressType._(super.value) : super._();
  static const P2pkhAddressType p2pkh = P2pkhAddressType._('P2PKH');
  static const P2pkhAddressType p2pkhwt = P2pkhAddressType._('P2PKHWT');

  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => false;

  @override
  int get hashLength => 20;
  @override
  String toString() => value;
}

class P2shAddressType extends BitcoinAddressType {
  const P2shAddressType._(super.value, this.hashLength, this.withToken) : super._();
  static const P2shAddressType p2wshInP2sh =
      P2shAddressType._("P2SH/P2WSH", _BitcoinAddressUtils.hash160DigestLength, false);
  static const P2shAddressType p2wpkhInP2sh =
      P2shAddressType._("P2SH/P2WPKH", _BitcoinAddressUtils.hash160DigestLength, false);
  static const P2shAddressType p2pkhInP2sh =
      P2shAddressType._("P2SH/P2PKH", _BitcoinAddressUtils.hash160DigestLength, false);
  static const P2shAddressType p2pkInP2sh =
      P2shAddressType._("P2SH/P2PK", _BitcoinAddressUtils.hash160DigestLength, false);
  @override
  bool get isP2sh => true;
  @override
  bool get isSegwit => false;

  @override
  final int hashLength;
  final bool withToken;

  /// specify BCH NETWORK for now!
  /// Pay-to-Script-Hash-32
  static const P2shAddressType p2pkhInP2sh32 =
      P2shAddressType._("P2SH32/P2PKH", _BitcoinAddressUtils.scriptHashLenght, false);
  //// Pay-to-Script-Hash-32
  static const P2shAddressType p2pkInP2sh32 =
      P2shAddressType._("P2SH32/P2PK", _BitcoinAddressUtils.scriptHashLenght, false);

  /// Pay-to-Script-Hash-32-with-token
  static const P2shAddressType p2pkhInP2sh32wt =
      P2shAddressType._("P2SH32WT/P2PKH", _BitcoinAddressUtils.scriptHashLenght, true);

  /// Pay-to-Script-Hash-32-with-token
  static const P2shAddressType p2pkInP2sh32wt =
      P2shAddressType._("P2SH32WT/P2PK", _BitcoinAddressUtils.scriptHashLenght, true);

  /// Pay-to-Script-Hash-with-token
  static const P2shAddressType p2pkhInP2shwt =
      P2shAddressType._("P2SHWT/P2PKH", _BitcoinAddressUtils.hash160DigestLength, true);

  /// Pay-to-Script-Hash-with-token
  static const P2shAddressType p2pkInP2shwt =
      P2shAddressType._("P2SHWT/P2PK", _BitcoinAddressUtils.hash160DigestLength, true);

  @override
  String toString() => value;
}

class SegwitAddressType extends BitcoinAddressType {
  const SegwitAddressType._(super.value) : super._();
  static const SegwitAddressType p2wpkh = SegwitAddressType._("P2WPKH");
  static const SegwitAddressType p2tr = SegwitAddressType._("P2TR");
  static const SegwitAddressType p2wsh = SegwitAddressType._("P2WSH");
  static const SegwitAddressType mweb = SegwitAddressType._("MWEB");
  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => true;

  @override
  int get hashLength {
    switch (this) {
      case SegwitAddressType.p2wpkh:
        return 20;
      case SegwitAddressType.mweb:
        return 66;
      default:
        return 32;
    }
  }

  @override
  String toString() => value;
}

class SilentPaymentsAddresType extends BitcoinAddressType {
  const SilentPaymentsAddresType._(super.value) : super._();
  static const SilentPaymentsAddresType p2sp = SilentPaymentsAddresType._("P2SP");
  @override
  bool get isP2sh => false;
  @override
  bool get isSegwit => true;

  @override
  int get hashLength {
    return 32;
  }

  @override
  String toString() => value;
}
