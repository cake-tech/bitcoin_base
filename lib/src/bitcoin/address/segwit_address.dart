part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class SegwitAddress extends BitcoinBaseAddress {
  SegwitAddress.fromAddress({
    required String address,
    required BasedUtxoNetwork network,
    required this.segwitVersion,
  }) : super(network: network) {
    addressProgram = _BitcoinAddressUtils.toSegwitProgramWithVersionAndNetwork(
      address: address,
      version: segwitVersion,
      network: network,
    );
  }

  SegwitAddress.fromProgram({
    required String program,
    required SegwitAddresType addressType,
    super.network,
    required this.segwitVersion,
    this.pubkey,
  })  : addressProgram = _BitcoinAddressUtils.validateAddressProgram(program, addressType),
        super();

  SegwitAddress.fromRedeemScript({
    required Script script,
    super.network,
    required this.segwitVersion,
  }) : addressProgram = _BitcoinAddressUtils.segwitScriptToSHA256(script);

  @override
  late final String addressProgram;
  final int segwitVersion;
  ECPublic? pubkey;

  @override
  String toAddress([BasedUtxoNetwork? network]) {
    network ??= this.network;

    if (network == null) {
      throw const BitcoinBasePluginException("Network is required");
    }

    if (!network.supportedAddress.contains(type)) {
      throw BitcoinBasePluginException("network does not support ${type.value} address");
    }

    return _BitcoinAddressUtils.segwitToAddress(
      addressProgram: addressProgram,
      network: network,
      segwitVersion: segwitVersion,
    );
  }

  @override
  String pubKeyHash() {
    return _BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }
}

class P2wpkhAddress extends SegwitAddress {
  static RegExp get regex => RegExp(r'(bc|tb|ltc)1q[ac-hj-np-z02-9]{25,39}($|\s)');

  P2wpkhAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV0);

  P2wpkhAddress.fromProgram({required super.program, super.network})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV0,
          addressType: SegwitAddresType.p2wpkh,
        );

  P2wpkhAddress.fromRedeemScript({required super.script, super.network})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0);

  factory P2wpkhAddress.fromScriptPubkey({required Script script, BasedUtxoNetwork? network}) {
    if (script.getAddressType() != SegwitAddresType.p2wpkh) {
      throw ArgumentError("Invalid scriptPubKey");
    }

    return P2wpkhAddress.fromProgram(program: script.findScriptParam(1), network: network);
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

  P2trAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV1);

  P2trAddress.fromProgram({required super.program, super.network, super.pubkey})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV1,
          addressType: SegwitAddresType.p2tr,
        );

  P2trAddress.fromRedeemScript({required super.script, super.network})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV1);

  factory P2trAddress.fromScriptPubkey({required Script script, BasedUtxoNetwork? network}) {
    if (script.getAddressType() != SegwitAddresType.p2tr) {
      throw ArgumentError("Invalid scriptPubKey");
    }

    return P2trAddress.fromProgram(program: script.findScriptParam(1), network: network);
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

  P2wshAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV0);

  P2wshAddress.fromProgram({required super.program, super.network})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV0,
          addressType: SegwitAddresType.p2wsh,
        );

  P2wshAddress.fromRedeemScript({required super.script, super.network})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0);

  factory P2wshAddress.fromScriptPubkey({required Script script, BasedUtxoNetwork? network}) {
    if (script.getAddressType() != SegwitAddresType.p2wsh) {
      throw ArgumentError("Invalid scriptPubKey");
    }

    return P2wshAddress.fromProgram(program: script.findScriptParam(1), network: network);
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
