part of 'package:bitcoin_base/src/bitcoin/address/address.dart';

abstract class LegacyAddress implements BitcoinBaseAddress {
  /// Represents a Bitcoin address
  ///
  /// [addressProgram] the addressProgram string representation of the address; hash160 represents
  /// two consequtive hashes of the public key or the redeem script or SHA256 for BCH(P2SH), first
  /// a SHA-256 and then an RIPEMD-160
  LegacyAddress.fromHash160(String h160, BitcoinAddressType addressType)
      : _addressProgram = _BitcoinAddressUtils.validateAddressProgram(h160, addressType);
  LegacyAddress.fromAddress({required String address, required BasedUtxoNetwork network}) {
    final decode = _BitcoinAddressUtils.decodeLegacyAddressWithNetworkAndType(
        address: address, type: type, network: network);
    if (decode == null) {
      throw MessageException("Invalid ${network.conf.coinName} address");
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
        if (script.script.length != 2) throw ArgumentError('Input is invalid');
        _signature = script.findScriptParam(0);
        if (!isCanonicalScriptSignature(BytesUtils.fromHexString(_signature!))) {
          throw ArgumentError('Input has invalid signature');
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

  ECPublic? get pubkey {
    return _pubkey;
  }

  String? get signature {
    return _signature;
  }

  @override
  String get addressProgram {
    if (type == PubKeyAddressType.p2pk) throw UnimplementedError();
    return _addressProgram;
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    return _BitcoinAddressUtils.legacyToAddress(
        network: network, addressProgram: addressProgram, type: type);
  }

  @override
  String pubKeyHash() {
    return _BitcoinAddressUtils.pubKeyHash(toScriptPubKey());
  }
}

class P2shAddress extends LegacyAddress {
  static RegExp get regex => RegExp(r'(^|\s)[23M][a-km-zA-HJ-NP-Z1-9]{25,34}($|\s)');

  P2shAddress.fromRedeemScript({required Script script, this.type = P2shAddressType.p2pkInP2sh})
      : super.fromRedeemScript(script: script);

  P2shAddress.fromAddress(
      {required String address,
      required BasedUtxoNetwork network,
      this.type = P2shAddressType.p2pkInP2sh})
      : super.fromAddress(address: address, network: network);
  P2shAddress.fromHash160({required String h160, this.type = P2shAddressType.p2pkInP2sh})
      : super.fromHash160(h160, type);

  @override
  final P2shAddressType type;

  factory P2shAddress.fromScriptPubkey(
      {required Script script, type = P2shAddressType.p2pkInP2sh}) {
    if (script.getAddressType() is! P2shAddressType) {
      throw ArgumentError("Invalid scriptPubKey");
    }
    return P2shAddress.fromHash160(h160: script.findScriptParam(1), type: type);
  }

  @override
  String toAddress(BasedUtxoNetwork network) {
    if (!network.supportedAddress.contains(type)) {
      throw MessageException("network does not support ${type.value} address");
    }
    return super.toAddress(network);
  }

  /// Returns the scriptPubKey (P2SH) that corresponds to this address
  @override
  Script toScriptPubKey() {
    if (addressProgram.length == 64) {
      return Script(
          script: [BitcoinOpCodeConst.OP_HASH256, addressProgram, BitcoinOpCodeConst.OP_EQUAL]);
    }
    return Script(
        script: [BitcoinOpCodeConst.OP_HASH160, addressProgram, BitcoinOpCodeConst.OP_EQUAL]);
  }
}

class P2pkhAddress extends LegacyAddress {
  static RegExp get regex => RegExp(r'(^|\s)[1mnL][a-km-zA-HJ-NP-Z1-9]{25,34}($|\s)');
  factory P2pkhAddress.fromScriptPubkey(
      {required Script script, P2pkhAddressType type = P2pkhAddressType.p2pkh}) {
    if (script.getAddressType() != P2pkhAddressType.p2pkh) {
      throw ArgumentError("Invalid scriptPubKey");
    }
    return P2pkhAddress.fromHash160(h160: script.findScriptParam(2), type: type);
  }
  P2pkhAddress.fromAddress(
      {required String address,
      required BasedUtxoNetwork network,
      this.type = P2pkhAddressType.p2pkh})
      : super.fromAddress(address: address, network: network);
  P2pkhAddress.fromHash160({required String h160, this.type = P2pkhAddressType.p2pkh})
      : super.fromHash160(h160, type);

  P2pkhAddress.fromScriptSig({required Script scriptSig, this.type = P2pkhAddressType.p2pkh})
      : super.fromScriptSig(script: scriptSig);

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
  static RegExp get regex => RegExp(r'(^|\s)1([A-Za-z0-9]{34})($|\s)');

  P2pkAddress({required ECPublic publicKey})
      : _pubkeyHex = publicKey.toHex(),
        super.fromPubkey(pubkey: publicKey);
  factory P2pkAddress.fromPubkey({required ECPublic pubkey}) => pubkey.toP2pkAddress();
  P2pkAddress.fromAddress({required String address, required BasedUtxoNetwork network})
      : super.fromAddress(address: address, network: network);

  factory P2pkAddress.fromScriptPubkey({required Script script}) {
    if (script.getAddressType() is! PubKeyAddressType) {
      throw ArgumentError("Invalid scriptPubKey");
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
        type: type);
  }

  @override
  final PubKeyAddressType type = PubKeyAddressType.p2pk;
}
