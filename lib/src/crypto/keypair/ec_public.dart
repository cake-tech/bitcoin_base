import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils_old/blockchain_utils.dart';
import 'package:blockchain_utils_old/crypto/crypto/cdsa/point/base.dart';

typedef PublicKeyType = PubKeyModes;

class ECPublic {
  final Secp256k1PublicKeyEcdsa publicKey;
  const ECPublic._(this.publicKey);

  factory ECPublic.fromPubkey(Secp256k1PublicKeyEcdsa publicKey) {
    return ECPublic._(publicKey);
  }

  factory ECPublic.fromBip32(Bip32PublicKey publicKey) {
    if (publicKey.curveType != EllipticCurveTypes.secp256k1) {
      throw const DartBitcoinPluginException('invalid public key curve for bitcoin');
    }
    return ECPublic._(publicKey.pubKey as Secp256k1PublicKeyEcdsa);
  }

  ProjectiveECCPoint get point => publicKey.point.cast();

  /// Constructs an ECPublic key from a byte representation.
  factory ECPublic.fromBytes(List<int> public) {
    final publicKey = Secp256k1PublicKeyEcdsa.fromBytes(public);
    return ECPublic._(publicKey);
  }

  /// Constructs an ECPublic key from hex representation.
  factory ECPublic.fromHex(String hex) {
    return ECPublic.fromBytes(BytesUtils.fromHexString(hex));
  }

  /// toHex converts the ECPublic key to a hex-encoded string.
  /// If 'compressed' is true, the key is in compressed format.
  String toHex({PublicKeyType mode = PublicKeyType.compressed}) {
    return BytesUtils.toHexString(toBytes(mode: mode));
  }

  /// toHash160 computes the RIPEMD160 hash of the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  List<int> toHash160({PublicKeyType mode = PublicKeyType.compressed}) {
    final bytes = BytesUtils.fromHexString(toHex(mode: mode));
    return QuickCrypto.hash160(bytes);
  }

  /// toHash160 computes the RIPEMD160 hash of the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  String toHash160Hex({PublicKeyType mode = PublicKeyType.compressed}) {
    return BytesUtils.toHexString(toHash160(mode: mode));
  }

  /// toP2pkhAddress generates a P2PKH (Pay-to-Public-Key-Hash) address from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2pkhAddress toAddress({PublicKeyType mode = PublicKeyType.compressed}) {
    final h16 = toHash160(mode: mode);
    final toHex = BytesUtils.toHexString(h16);
    return P2pkhAddress.fromHash160(h160: toHex);
  }

  P2pkhAddress toP2pkhAddress({PublicKeyType mode = PublicKeyType.compressed}) {
    return toAddress(mode: mode);
  }

  /// toSegwitAddress generates a P2WPKH (Pay-to-Witness-Public-Key-Hash) SegWit address
  /// from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  P2wpkhAddress toSegwitAddress() {
    final h16 = toHash160();
    final toHex = BytesUtils.toHexString(h16);

    return P2wpkhAddress.fromProgram(program: toHex);
  }

  P2wpkhAddress toP2wpkhAddress() {
    return toSegwitAddress();
  }

  /// toP2pkAddress generates a P2PK (Pay-to-Public-Key) address from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2pkAddress toP2pkAddress({PublicKeyType mode = PublicKeyType.compressed}) {
    final h = toHex(mode: mode);
    return P2pkAddress(publicKey: ECPublic.fromHex(h));
  }

  /// toRedeemScript generates a redeem script from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  Script toRedeemScript({PublicKeyType mode = PublicKeyType.compressed}) {
    final redeem = toHex(mode: mode);
    return Script(script: [redeem, 'OP_CHECKSIG']);
  }

  /// toP2pkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2pkhInP2sh({
    PublicKeyType mode = PublicKeyType.compressed,
    useBCHP2sh32 = false,
  }) {
    final addr = toAddress(mode: mode);
    final script = addr.toScriptPubKey();
    if (useBCHP2sh32) {
      return P2shAddress.fromHash160(
        h160: BytesUtils.toHexString(QuickCrypto.sha256DoubleHash(script.toBytes())),
        type: P2shAddressType.p2pkhInP2sh32,
      );
    }
    return P2shAddress.fromRedeemScript(script: script, type: P2shAddressType.p2pkhInP2sh);
  }

  /// toP2pkInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2PK (Pay-to-Public-Key) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2pkInP2sh({
    PublicKeyType mode = PublicKeyType.compressed,
    bool useBCHP2sh32 = false,
  }) {
    final script = toRedeemScript(mode: mode);
    if (useBCHP2sh32) {
      return P2shAddress.fromHash160(
          h160: BytesUtils.toHexString(QuickCrypto.sha256DoubleHash(script.toBytes())),
          type: P2shAddressType.p2pkInP2sh32);
    }
    return P2shAddress.fromRedeemScript(script: script, type: P2shAddressType.p2pkInP2sh);
  }

  /// ToTaprootAddress generates a P2TR(Taproot) address from the ECPublic key
  /// and an optional script. The 'script' parameter can be used to specify
  /// custom spending conditions.
  P2trAddress toTaprootAddress({TaprootTree? treeScript, bool tweak = true}) {
    return P2trAddress.fromInternalKey(
      internalKey: publicKey.point.cast<ProjectiveECCPoint>().toXonly(),
      treeScript: treeScript,
      tweak: tweak,
    );
  }

  P2trAddress toP2trAddress({TaprootTree? treeScript, bool tweak = true}) {
    return toTaprootAddress(treeScript: treeScript, tweak: tweak);
  }

  /// toP2wpkhInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WPKH (Pay-to-Witness-Public-Key-Hash) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2wpkhInP2sh() {
    final addr = toSegwitAddress();
    return P2shAddress.fromRedeemScript(
        script: addr.toScriptPubKey(), type: P2shAddressType.p2wpkhInP2sh);
  }

  /// toP2wshScript generates a P2WSH (Pay-to-Witness-Script-Hash) script
  /// derived from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  Script toP2wshRedeemScript() {
    return Script(script: ['OP_1', toHex(), 'OP_1', 'OP_CHECKMULTISIG']);
  }

  /// toP2wshAddress generates a P2WSH (Pay-to-Witness-Script-Hash) address
  /// from the ECPublic key. If 'compressed' is true, the key is in compressed format.
  P2wshAddress toP2wshAddress() {
    return P2wshAddress.fromRedeemScript(script: toP2wshRedeemScript());
  }

  /// toP2wshInP2sh generates a P2SH (Pay-to-Script-Hash) address
  /// wrapping a P2WSH (Pay-to-Witness-Script-Hash) script derived from the ECPublic key.
  /// If 'compressed' is true, the key is in compressed format.
  P2shAddress toP2wshInP2sh() {
    final p2sh = toP2wshAddress();
    return P2shAddress.fromRedeemScript(
        script: p2sh.toScriptPubKey(), type: P2shAddressType.p2wshInP2sh);
  }

  MwebAddress toMwebAddress() {
    return MwebAddress.fromRedeemScript(script: toRedeemScript());
  }

  bool compareToAddress(BitcoinBaseAddress other, BasedUtxoNetwork network) {
    late BitcoinBaseAddress address;

    if (other is P2pkAddress) {
      address = toP2pkAddress();
    } else if (other is P2pkhAddress) {
      address = toP2pkhAddress();
    } else if (other is P2wpkhAddress) {
      address = toP2wpkhAddress();
    } else if (other is P2wshAddress) {
      address = toP2wshAddress();
    } else if (other is P2trAddress) {
      address = toTaprootAddress();
    }

    return address.toAddress(network) == other.toAddress(network);
  }

  /// toBytes returns the uncompressed byte representation of the ECPublic key.
  List<int> toBytes({PubKeyModes mode = PubKeyModes.uncompressed}) {
    switch (mode) {
      case PubKeyModes.uncompressed:
        return publicKey.uncompressed;
      case PubKeyModes.compressed:
        return publicKey.compressed;
    }
  }

  /// toCompressedBytes returns the compressed byte representation of the ECPublic key.
  List<int> toCompressedBytes() {
    return publicKey.compressed;
  }

  EncodeType? getEncodeType() {
    return publicKey.point.encodeType;
  }

  String tweakPublicKey({TaprootTree? treeScript}) {
    final pubKey =
        TaprootUtils.tweakPublicKey(toBytes(mode: PubKeyModes.compressed), treeScript: treeScript);
    return BytesUtils.toHexString(pubKey.toXonly());
  }

  List<int> toXOnly() {
    return publicKey.point.cast<ProjectiveECCPoint>().toXonly();
  }

  /// toXOnlyHex extracts and returns the x-coordinate (first 32 bytes) of the ECPublic key
  /// as a hexadecimal string.
  String toXOnlyHex() {
    return BytesUtils.toHexString(toXOnly());
  }

  /// returns true if the message was signed with this public key's
  bool verify(List<int> message, List<int> signature,
      {String messagePrefix = '\x18Bitcoin Signed Message:\n'}) {
    final verifyKey = BitcoinVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyMessage(message, messagePrefix, signature);
  }

  /// returns true if the message was signed with this public key's
  bool verifyTransaactionSignature(List<int> message, List<int> signature) {
    final verifyKey = BitcoinVerifier.fromKeyBytes(toBytes());
    return verifyKey.verifyTransaction(message, signature);
  }

  /// returns true if the message was signed with this public key's
  bool verifySchnorrTransactionSignature(List<int> message, List<int> signature,
      {List<List<Script>> tapleafScripts = const [], bool isTweak = true}) {
    final verifyKey = BitcoinVerifier.fromKeyBytes(toBytes());
    final tapScriptBytes =
        !isTweak ? [] : tapleafScripts.map((e) => e.map((e) => e.toBytes()).toList()).toList();
    return verifyKey.verifySchnorr(message, signature,
        tapleafScripts: tapScriptBytes, isTweak: isTweak);
  }

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ECPublic) return false;
    return other.publicKey == publicKey;
  }

  @override
  int get hashCode => publicKey.hashCode;

  ECPublic tweakAdd(BigInt tweak) {
    final point = publicKey.point;
    // Compute the new public key after adding the tweak
    final tweakedKey = point + (Curves.generatorSecp256k1 * tweak);

    return ECPublic.fromBytes(tweakedKey.toBytes());
  }

  // Perform the tweak multiplication
  ECPublic tweakMul(BigInt tweak) {
    final point = publicKey.point;
    // Perform the tweak multiplication
    final tweakedKey = point * tweak;

    return ECPublic.fromBytes(tweakedKey.toBytes());
  }

  ECPublic pubkeyAdd(ECPublic other) {
    final tweakedKey = publicKey.point + other.publicKey.point;
    return ECPublic.fromBytes(tweakedKey.toBytes());
  }

  ECPublic negate() {
    // Negate the Y-coordinate by subtracting it from the field size (p).
    final point = publicKey.point;
    final y = point.curve.p - point.y;
    return ECPublic.fromBytes(BytesUtils.fromHexString(
        "04${BytesUtils.toHexString(BigintUtils.toBytes(point.x, length: point.curve.baselen))}${BytesUtils.toHexString(BigintUtils.toBytes(y, length: point.curve.baselen))}"));
  }

  ECPublic clone() {
    return ECPublic.fromBytes(publicKey.uncompressed);
  }
}

extension Bip32Slip10Secp256k1Ext on Bip32Slip10Secp256k1 {
  ECPublic toECPublic() {
    return ECPublic.fromBip32(publicKey);
  }
}
