part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class LegacyAddress extends BitcoinBaseAddress {
  /// Represents a Bitcoin address
  ///
  /// [addressProgram] the addressProgram string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeem script or SHA256 for BCH(P2SH), first
  /// a SHA-256 and then an RIPEMD-160
  LegacyAddress.fromHash160({
    required String h160,
    required BitcoinAddressType type,
  })  : _addressProgram = _BitcoinAddressUtils.validateAddressProgram(h160, type),
        super();

  LegacyAddress.fromAddress({required String address, required BasedUtxoNetwork network})
      : super() {
    final decode = _BitcoinAddressUtils.decodeLegacyAddressWithNetworkAndType(
      address: address,
      type: type,
      network: network,
    );

    if (decode == null) {
      throw DartBitcoinPluginException('Invalid ${network.conf.coinName} address');
    }

    _addressProgram = decode;
  }

  LegacyAddress.fromPubkey({required ECPublic pubkey})
      : _pubkey = pubkey,
        _addressProgram = _BitcoinAddressUtils.pubkeyToHash160(pubkey.toHex());

  LegacyAddress.fromRedeemScript({required Script script})
      : _addressProgram = _BitcoinAddressUtils.scriptToHash160(script);

  LegacyAddress.fromScriptSig({required Script script}) {
    switch (type) {
      case PubKeyAddressType.p2pk:
        _signature = script.findScriptParam(0);
        break;
      case P2pkhAddressType.p2pkh:
        if (script.script.length != 2) throw DartBitcoinPluginException('Input is invalid');

        _signature = script.findScriptParam(0);

        if (!isCanonicalScriptSignature(BytesUtils.fromHexString(_signature!))) {
          throw DartBitcoinPluginException('Input has invalid signature');
        }

        _pubkey = ECPublic.fromHex(script.findScriptParam(1));
        _addressProgram = _BitcoinAddressUtils.pubkeyToHash160(_pubkey!.toHex());
        break;
      case P2shAddressType.p2wpkhInP2sh:
      case P2shAddressType.p2wshInP2sh:
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkInP2sh:
        _signature = script.findScriptParam(1);
        _addressProgram = _BitcoinAddressUtils.scriptToHash160(
            Script.fromRaw(hexData: script.findScriptParam(2)));
        break;
      default:
        throw UnimplementedError();
    }
  }

  ECPublic? _pubkey;
  String? _signature;
  late final String _addressProgram;

  ECPublic? get pubkey => _pubkey;
  String? get signature => _signature;

  @override
  String get addressProgram {
    if (type == PubKeyAddressType.p2pk) throw UnimplementedError();
    return _addressProgram;
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException("network does not support ${type.value} address");
    }

    return _BitcoinAddressUtils.legacyToAddress(
      network: network,
      addressProgram: addressProgram,
      type: type,
    );
  }

  @override
  String pubKeyHash() {
    return _BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! LegacyAddress) return false;
    if (runtimeType != other.runtimeType) return false;
    if (type != other.type) return false;
    return _addressProgram == other._addressProgram;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([_addressProgram, type]);
}

class P2shAddress extends LegacyAddress {
  static final regex = RegExp(r'[23M][a-km-zA-HJ-NP-Z1-9]{25,34}');

  P2shAddress.fromRedeemScript({
    required super.script,
    this.type = P2shAddressType.p2pkInP2sh,
  }) : super.fromRedeemScript();

  factory P2shAddress.fromRedeemScript32({
    required Script script,
    P2shAddressType type = P2shAddressType.p2pkInP2sh32,
  }) {
    if (type.hashLength != 32) {
      throw DartBitcoinPluginException("Invalid P2sh 32 address type.");
    }

    return P2shAddress.fromHash160(
      h160: BytesUtils.toHexString(QuickCrypto.sha256DoubleHash(script.toBytes())),
    );
  }

  P2shAddress.fromAddress({
    required super.address,
    required super.network,
    this.type = P2shAddressType.p2pkInP2sh,
  }) : super.fromAddress();

  P2shAddress.fromHash160({
    required super.h160,
    this.type = P2shAddressType.p2pkInP2sh,
  }) : super.fromHash160(type: type);

  factory P2shAddress.fromDerivation({
    required Bip32Base bip32,
    required BitcoinDerivationInfo derivationInfo,
    required bool isChange,
    required int index,
    P2shAddressType type = P2shAddressType.p2wpkhInP2sh,
  }) {
    final fullPath = derivationInfo.derivationPath
        .addElem(Bip32KeyIndex(BitcoinAddressUtils.getAccountFromChange(isChange)))
        .addElem(Bip32KeyIndex(index));
    final pubkey = ECPublic.fromBip32(bip32.derive(fullPath).publicKey);

    switch (type) {
      case P2shAddressType.p2pkInP2sh:
        return pubkey.toP2pkInP2sh();
      case P2shAddressType.p2pkhInP2sh:
        return pubkey.toP2pkhInP2sh();
      case P2shAddressType.p2wshInP2sh:
        return pubkey.toP2wshInP2sh();
      case P2shAddressType.p2wpkhInP2sh:
        return pubkey.toP2wpkhInP2sh();
      default:
        throw UnimplementedError();
    }
  }

  factory P2shAddress.fromPath({required Bip32Base bip32, required Bip32Path path}) {
    return ECPublic.fromBip32(bip32.derive(path).publicKey).toP2wpkhInP2sh();
  }

  factory P2shAddress.fromScriptPubkey({
    required Script script,
    type = P2shAddressType.p2pkInP2sh,
  }) {
    if (script.getAddressType() is! P2shAddressType) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
    }

    return P2shAddress.fromHash160(h160: script.findScriptParam(1), type: type);
  }

  @override
  final P2shAddressType type;

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw DartBitcoinPluginException('network does not support ${type.value} address.');
    }
    return super.toAddress(network);
  }

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    if (addressProgram.length == 64) {
      return Script(
        script: [BitcoinOpCodeConst.OP_HASH256, addressProgram, BitcoinOpCodeConst.OP_EQUAL],
      );
    } else {
      return Script(
        script: [BitcoinOpCodeConst.OP_HASH160, addressProgram, BitcoinOpCodeConst.OP_EQUAL],
      );
    }
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! LegacyAddress) return false;
    if (runtimeType != other.runtimeType) return false;
    return _addressProgram == other._addressProgram;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([_addressProgram]);
}

class P2pkhAddress extends LegacyAddress {
  static final regex = RegExp(r'[1mnL][a-km-zA-HJ-NP-Z1-9]{25,34}');

  factory P2pkhAddress.fromScriptPubkey({
    required Script script,
    P2pkhAddressType type = P2pkhAddressType.p2pkh,
  }) {
    if (script.getAddressType() != P2pkhAddressType.p2pkh) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
    }

    return P2pkhAddress.fromHash160(h160: script.findScriptParam(2), type: type);
  }

  P2pkhAddress.fromAddress({
    required super.address,
    required super.network,
    this.type = P2pkhAddressType.p2pkh,
  }) : super.fromAddress();

  P2pkhAddress.fromHash160({required super.h160, this.type = P2pkhAddressType.p2pkh})
      : super.fromHash160(type: type);

  P2pkhAddress.fromScriptSig({required super.script, this.type = P2pkhAddressType.p2pkh})
      : super.fromScriptSig();

  factory P2pkhAddress.fromDerivation({
    required Bip32Base bip32,
    required BitcoinDerivationInfo derivationInfo,
    required bool isChange,
    required int index,
  }) {
    final fullPath = derivationInfo.derivationPath
        .addElem(Bip32KeyIndex(BitcoinAddressUtils.getAccountFromChange(isChange)))
        .addElem(Bip32KeyIndex(index));
    return ECPublic.fromBip32(bip32.derive(fullPath).publicKey).toP2pkhAddress();
  }

  factory P2pkhAddress.fromPath({required Bip32Base bip32, required Bip32Path path}) {
    return ECPublic.fromBip32(bip32.derive(path).publicKey).toP2pkhAddress();
  }

  @override
  Script toScriptPubKey() {
    return Script(script: [
      BitcoinOpCodeConst.OP_DUP,
      BitcoinOpCodeConst.OP_HASH160,
      _addressProgram,
      BitcoinOpCodeConst.OP_EQUALVERIFY,
      BitcoinOpCodeConst.OP_CHECKSIG
    ]);
  }

  @override
  final P2pkhAddressType type;

  Script toScriptSig() {
    return Script(script: [_signature, _pubkey]);
  }
}

class P2pkAddress extends LegacyAddress {
  static RegExp get regex => RegExp(r'1([A-Za-z0-9]{34})');

  P2pkAddress({required ECPublic publicKey})
      : _pubkeyHex = publicKey.toHex(),
        super.fromPubkey(pubkey: publicKey);

  factory P2pkAddress.fromPubkey({required ECPublic pubkey}) => pubkey.toP2pkAddress();

  P2pkAddress.fromAddress({required super.address, required super.network}) : super.fromAddress();

  factory P2pkAddress.fromScriptPubkey({required Script script}) {
    if (script.getAddressType() is! PubKeyAddressType) {
      throw DartBitcoinPluginException("Invalid scriptPubKey");
    }

    return P2pkAddress.fromPubkey(pubkey: ECPublic.fromHex(script.script[0]));
  }

  late final String _pubkeyHex;

  @override
  Script toScriptPubKey() {
    return Script(script: [_pubkeyHex, BitcoinOpCodeConst.OP_CHECKSIG]);
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    return _BitcoinAddressUtils.legacyToAddress(
      network: network,
      addressProgram: _BitcoinAddressUtils.pubkeyToHash160(_pubkeyHex),
      type: type,
    );
  }

  @override
  final PubKeyAddressType type = PubKeyAddressType.p2pk;

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! P2pkAddress) return false;
    return _pubkeyHex == other._pubkeyHex;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([_pubkeyHex, type]);
}
