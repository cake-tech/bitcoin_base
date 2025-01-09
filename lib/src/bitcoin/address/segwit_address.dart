part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class SegwitAddress extends BitcoinBaseAddress {
  SegwitAddress.fromAddress({
    required String address,
    required BasedUtxoNetwork network,
    required this.segwitVersion,
  }) : super() {
    addressProgram = _BitcoinAddressUtils.toSegwitProgramWithVersionAndNetwork(
      address: address,
      version: segwitVersion,
      network: network,
    );
  }

  SegwitAddress.fromProgram({
    required String program,
    required SegwitAddressType addressType,
    required this.segwitVersion,
    this.pubkey,
  })  : addressProgram = _BitcoinAddressUtils.validateAddressProgram(program, addressType),
        super();

  SegwitAddress.fromRedeemScript({
    required Script script,
    required this.segwitVersion,
  }) : addressProgram = _BitcoinAddressUtils.segwitScriptToSHA256(script);

  @override
  late final String addressProgram;
  final int segwitVersion;
  ECPublic? pubkey;

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException("network does not support ${type.value} address");
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
  static final regex = RegExp(r'(bc|tb|ltc)1q[ac-hj-np-z02-9]{25,39}');

  P2wpkhAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV0);

  P2wpkhAddress.fromProgram({required super.program})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV0,
          addressType: SegwitAddressType.p2wpkh,
        );

  P2wpkhAddress.fromRedeemScript({required super.script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0);

  factory P2wpkhAddress.fromDerivation({
    required Bip32Base bip32,
    required BitcoinDerivationInfo derivationInfo,
    required bool isChange,
    required int index,
  }) {
    final fullPath = derivationInfo.derivationPath
        .addElem(Bip32KeyIndex(BitcoinAddressUtils.getAccountFromChange(isChange)))
        .addElem(Bip32KeyIndex(index));

    return ECPublic.fromBip32(bip32.derive(fullPath).publicKey).toP2wpkhAddress();
  }

  factory P2wpkhAddress.fromPath({required Bip32Base bip32, required Bip32Path path}) {
    return ECPublic.fromBip32(bip32.derive(path).publicKey).toP2wpkhAddress();
  }

  factory P2wpkhAddress.fromScriptPubkey({required Script script}) {
    if (script.getAddressType() != SegwitAddressType.p2wpkh) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
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
  SegwitAddressType get type => SegwitAddressType.p2wpkh;
}

class P2trAddress extends SegwitAddress {
  static final regex =
      RegExp(r'(bc|tb)1p([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59}|[ac-hj-np-z02-9]{8,89})');

  P2trAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV1);

  P2trAddress.fromProgram({required super.program, super.pubkey})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV1,
          addressType: SegwitAddressType.p2tr,
        );

  P2trAddress.fromRedeemScript({required super.script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV1);

  factory P2trAddress.fromDerivation({
    required Bip32Base bip32,
    required BitcoinDerivationInfo derivationInfo,
    required bool isChange,
    required int index,
  }) {
    final fullPath = derivationInfo.derivationPath
        .addElem(Bip32KeyIndex(BitcoinAddressUtils.getAccountFromChange(isChange)))
        .addElem(Bip32KeyIndex(index));
    return ECPublic.fromBip32(bip32.derive(fullPath).publicKey).toP2trAddress();
  }

  factory P2trAddress.fromPath({required Bip32Base bip32, required Bip32Path path}) {
    return ECPublic.fromBip32(bip32.derive(path).publicKey).toP2trAddress();
  }

  factory P2trAddress.fromScriptPubkey({required Script script}) {
    if (script.getAddressType() != SegwitAddressType.p2tr) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
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
  SegwitAddressType get type => SegwitAddressType.p2tr;
}

class P2wshAddress extends SegwitAddress {
  static final regex = RegExp(r'(bc|tb)1q[ac-hj-np-z02-9]{40,80}');

  P2wshAddress.fromAddress({required super.address, required super.network})
      : super.fromAddress(segwitVersion: _BitcoinAddressUtils.segwitV0);

  P2wshAddress.fromProgram({required super.program})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV0,
          addressType: SegwitAddressType.p2wsh,
        );

  P2wshAddress.fromRedeemScript({required super.script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0);

  factory P2wshAddress.fromDerivation({
    required Bip32Base bip32,
    required BitcoinDerivationInfo derivationInfo,
    required bool isChange,
    required int index,
  }) {
    final fullPath = derivationInfo.derivationPath
        .addElem(Bip32KeyIndex(BitcoinAddressUtils.getAccountFromChange(isChange)))
        .addElem(Bip32KeyIndex(index));
    return ECPublic.fromBip32(bip32.derive(fullPath).publicKey).toP2wshAddress();
  }

  factory P2wshAddress.fromScriptPubkey({required Script script}) {
    if (script.getAddressType() != SegwitAddressType.p2wsh) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
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
  SegwitAddressType get type => SegwitAddressType.p2wsh;
}

class MwebAddress extends SegwitAddress {
  static RegExp get regex => RegExp(r'(ltc|t)mweb1q[ac-hj-np-z02-9]{90,120}');

  factory MwebAddress.fromAddress({required String address}) {
    final decoded = Bech32DecoderBase.decodeBech32(
        address,
        Bech32Const.separator,
        Bech32Const.checksumStrLen,
        (hrp, data) => Bech32Utils.verifyChecksum(hrp, data, Bech32Encodings.bech32));
    final hrp = decoded.item1;
    final data = decoded.item2;
    if (hrp != 'ltcmweb') {
      throw DartBitcoinPluginException(
          'Invalid format (HRP not valid, expected ltcmweb, got $hrp)');
    }
    if (data[0] != _BitcoinAddressUtils.segwitV0) {
      throw DartBitcoinPluginException("Invalid segwit version");
    }
    final convData = Bech32BaseUtils.convertFromBase32(data.sublist(1));
    if (convData.length != 66) {
      throw DartBitcoinPluginException(
          'Invalid format (witness program length not valid: ${convData.length})');
    }

    return MwebAddress.fromProgram(program: BytesUtils.toHexString(convData));
  }

  MwebAddress.fromProgram({required super.program})
      : super.fromProgram(
          segwitVersion: _BitcoinAddressUtils.segwitV0,
          addressType: SegwitAddressType.mweb,
        );
  MwebAddress.fromRedeemScript({required super.script})
      : super.fromRedeemScript(segwitVersion: _BitcoinAddressUtils.segwitV0);

  factory MwebAddress.fromScriptPubkey({required Script script, type = SegwitAddressType.mweb}) {
    if (script.getAddressType() != SegwitAddressType.mweb) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
    }
    return MwebAddress.fromProgram(program: BytesUtils.toHexString(script.script as List<int>));
  }

  /// returns the scriptPubKey of a MWEB witness script
  @override
  Script toScriptPubKey() {
    return Script(script: BytesUtils.fromHexString(addressProgram));
  }

  /// returns the type of address
  @override
  SegwitAddressType get type => SegwitAddressType.mweb;
}
