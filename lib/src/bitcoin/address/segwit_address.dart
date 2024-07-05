part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class SegwitAddress implements BitcoinBaseAddress {
  SegwitAddress.fromAddress(
      {required String address, required BasedUtxoNetwork network, required this.segwitVersion}) {
    if (!network.supportedAddress.contains(type)) {
      throw BitcoinBasePluginException(
          "network does not support ${type.value} address");
    }
    addressProgram = _BitcoinAddressUtils.toSegwitProgramWithVersionAndNetwork(
        address: address, version: segwitVersion, network: network);
  }
  SegwitAddress.fromProgram(
      {required String program,
      required this.segwitVersion,
      required SegwitAddresType addressType,
      ECPublic? ecpublic})
      : addressProgram = _BitcoinAddressUtils.validateAddressProgram(program, addressType),
        pubkey = ecpublic;
  SegwitAddress.fromRedeemScript({required Script script, required this.segwitVersion})
      : addressProgram = _BitcoinAddressUtils.segwitScriptToSHA256(script);

  @override
  late final String addressProgram;

  final int segwitVersion;
  ECPublic? pubkey;

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw BitcoinBasePluginException(
          "network does not support ${type.value} address");
    }
    return _BitcoinAddressUtils.segwitToAddress(
        addressProgram: addressProgram, network: network, segwitVersion: segwitVersion);
  }

  @override
  String pubKeyHash() {
    return _BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }
}

class P2wpkhAddress extends SegwitAddress {
  static RegExp get regex => RegExp(r'(bc|tb|ltc)1q[ac-hj-np-z02-9]{25,39}($|\s)');

  P2wpkhAddress.fromAddress({required String address, required BasedUtxoNetwork network})
      : super.fromAddress(
            segwitVersion: _BitcoinAddressUtils.segwitV0, address: address, network: network);

  P2wpkhAddress.fromProgram({required String program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            program: program,
            addressType: SegwitAddresType.p2wpkh);
  P2wpkhAddress.fromRedeemScript({required Script script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0, script: script);

  factory P2wpkhAddress.fromScriptPubkey({required Script script, type = SegwitAddresType.p2wpkh}) {
    if (script.getAddressType() != SegwitAddresType.p2wpkh) {
      throw ArgumentError("Invalid scriptPubKey");
    }
    return P2wpkhAddress.fromProgram(program: script.findScriptParam(1));
  }

  /// returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: [BitcoinOpCodeConst.OP_0, addressProgram]);
  }

  /// returns the type of address
  @override
  SegwitAddresType get type => SegwitAddresType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  static RegExp get regex =>
      RegExp(r'(bc|tb)1p([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59}|[ac-hj-np-z02-9]{8,89})');

  P2trAddress.fromAddress({required String address, required BasedUtxoNetwork network})
      : super.fromAddress(
            segwitVersion: _BitcoinAddressUtils.segwitV1, address: address, network: network);
  P2trAddress.fromProgram({required String program, ECPublic? pubkey})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV1,
            program: program,
            addressType: SegwitAddresType.p2tr,
            ecpublic: pubkey);
  P2trAddress.fromRedeemScript({required Script script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV1, script: script);

  factory P2trAddress.fromScriptPubkey({required Script script, type = SegwitAddresType.p2wpkh}) {
    if (script.getAddressType() != SegwitAddresType.p2tr) {
      throw ArgumentError("Invalid scriptPubKey");
    }
    return P2trAddress.fromProgram(program: script.findScriptParam(1));
  }

  /// returns the scriptPubKey of a P2TR witness script
  @override
  Script toScriptPubKey() {
    return Script(script: [BitcoinOpCodeConst.OP_1, addressProgram]);
  }

  /// returns the type of address
  @override
  SegwitAddresType get type => SegwitAddresType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  static RegExp get regex => RegExp(r'(bc|tb)1q[ac-hj-np-z02-9]{40,80}');

  P2wshAddress.fromAddress({required String address, required BasedUtxoNetwork network})
      : super.fromAddress(
            segwitVersion: _BitcoinAddressUtils.segwitV0, address: address, network: network);
  P2wshAddress.fromProgram({required String program})
      : super.fromProgram(
            segwitVersion: _BitcoinAddressUtils.segwitV0,
            program: program,
            addressType: SegwitAddresType.p2wsh);
  P2wshAddress.fromRedeemScript({required Script script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0, script: script);

  factory P2wshAddress.fromScriptPubkey({required Script script, type = SegwitAddresType.p2wsh}) {
    if (script.getAddressType() != SegwitAddresType.p2wsh) {
      throw ArgumentError("Invalid scriptPubKey");
    }
    return P2wshAddress.fromProgram(program: script.findScriptParam(1));
  }

  /// Returns the scriptPubKey of a P2WPKH witness script
  @override
  Script toScriptPubKey() {
    return Script(script: [BitcoinOpCodeConst.OP_0, addressProgram]);
  }

  /// Returns the type of address
  @override
  SegwitAddresType get type => SegwitAddresType.p2wsh;
}
