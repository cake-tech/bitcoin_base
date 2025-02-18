import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_base/src/crypto/keypair/sign_utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:bip32/src/utils/ecurve.dart' as ecc;

/// Represents an ECDSA private key.
class ECPrivate {
  final Bip32PrivateKey prive;
  const ECPrivate(this.prive);

  /// creates an object from hex
  factory ECPrivate.fromHex(String keyHex) {
    return ECPrivate.fromBytes(BytesUtils.fromHexString(keyHex));
  }

  /// creates an object from raw 32 bytes
  factory ECPrivate.fromBytes(List<int> prive) {
    final key = Bip32PrivateKey.fromBytes(
        prive, Bip32KeyData(), Bip32Const.mainNetKeyNetVersions, EllipticCurveTypes.secp256k1);
    return ECPrivate(key);
  }

  /// returns the corresponding ECPublic object
  ECPublic getPublic() => ECPublic.fromHex(BytesUtils.toHexString(prive.publicKey.compressed));

  /// creates an object from a WIF of WIFC format (string)
  factory ECPrivate.fromWif(String wif, {required List<int>? netVersion}) {
    final decode = WifDecoder.decode(wif, netVer: netVersion ?? BitcoinNetwork.mainnet.wifNetVer);
    return ECPrivate.fromBytes(decode.item1);
  }

  factory ECPrivate.fromBip32({required Bip32Base bip32, int? account, int? index}) {
    if (account != null) {
      bip32 = bip32.childKey(Bip32KeyIndex(account));

      if (index != null) {
        bip32 = bip32.childKey(Bip32KeyIndex(index));
      }
    }

    return ECPrivate(bip32.privateKey);
  }

  /// returns as WIFC (compressed) or WIF format (string)
  String toWif(
      {PubKeyModes pubKeyMode = PubKeyModes.compressed,
      BitcoinNetwork network = BitcoinNetwork.mainnet}) {
    return WifEncoder.encode(toBytes(), netVer: network.wifNetVer, pubKeyMode: pubKeyMode);
  }

  /// returns the key's raw bytes
  List<int> toBytes() {
    return prive.raw;
  }

  BigInt toBigInt() {
    return BigintUtils.fromBytes(prive.raw);
  }

  String toHex() {
    return BytesUtils.toHexString(prive.raw);
  }

  /// Returns a Bitcoin compact signature in hex
  String signMessage(List<int> message, {String messagePrefix = '\x18Bitcoin Signed Message:\n'}) {
    final messageHash =
        QuickCrypto.sha256Hash(BitcoinSignerUtils.magicMessage(message, messagePrefix));

    final messageHashBytes = Uint8List.fromList(messageHash);
    final privBytes = Uint8List.fromList(prive.raw);
    final rs = ecc.sign(messageHashBytes, privBytes);
    final rawSig = rs.toECSignature();

    final pub = prive.publicKey;
    final ECDomainParameters curve = ECCurve_secp256k1();
    final point = curve.curve.decodePoint(pub.point.toBytes());

    final recId = SignUtils.findRecoveryId(
      SignUtils.getHexString(messageHash, offset: 0, length: messageHash.length),
      rawSig,
      Uint8List.fromList(pub.uncompressed),
    );

    final v = recId + 27 + (point!.isCompressed ? 4 : 0);

    final combined = Uint8List.fromList([v, ...rs]);

    return BytesUtils.toHexString(combined);
  }

  /// sign transaction digest  and returns the signature.
  String signInput(List<int> txDigest, {int sigHash = BitcoinOpCodeConst.SIGHASH_ALL}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signature = btcSigner.signTransaction(txDigest);
    signature = <int>[...signature, sigHash];
    return BytesUtils.toHexString(signature);
  }

  String signSchnorr(List<int> txDigest, {int sighash = BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signatur = btcSigner.signSchnorrTransaction(txDigest, tapScripts: [], tweak: false);
    if (sighash != BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL) {
      signatur = <int>[...signatur, sighash];
    }
    return BytesUtils.toHexString(signatur);
  }

  /// sign taproot transaction digest and returns the signature.
  String signTapRoot(List<int> txDigest,
      {int sighash = BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL,
      List<List<Script>> tapScripts = const [],
      bool tweak = true}) {
    assert(() {
      if (!tweak && tapScripts.isNotEmpty) {
        return false;
      }
      return true;
    }(),
        'When the tweak is false, the `tapScripts` are ignored, to use the tap script path, you need to consider the tweak value to be true.');
    final tapScriptBytes =
        !tweak ? [] : tapScripts.map((e) => e.map((e) => e.toBytes()).toList()).toList();
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signature =
        btcSigner.signSchnorrTransaction(txDigest, tapScripts: tapScriptBytes, tweak: tweak);
    if (sighash != BitcoinOpCodeConst.TAPROOT_SIGHASH_ALL) {
      signature = <int>[...signature, sighash];
    }
    return BytesUtils.toHexString(signature);
  }

  ECPrivate toTweakedTaprootKey() {
    final t = P2TRUtils.calculateTweek(getPublic().publicKey.point as ProjectiveECCPoint);

    return ECPrivate.fromBytes(
        BitcoinSignerUtils.calculatePrivateTweek(toBytes(), BigintUtils.fromBytes(t)));
  }

  static ECPrivate random() {
    final secret = QuickCrypto.generateRandom();
    return ECPrivate.fromBytes(secret);
  }

  ECPrivate tweakAdd(BigInt tweak) {
    return ECPrivate.fromBytes(BigintUtils.toBytes(
      (BigintUtils.fromBytes(prive.raw) + tweak) % Curves.generatorSecp256k1.order!,
      length: getPublic().publicKey.point.curve.baselen,
    ));
  }

  ECPrivate tweakMul(BigInt tweak) {
    return ECPrivate.fromBytes(BigintUtils.toBytes(
      (BigintUtils.fromBytes(prive.raw) * tweak) % Curves.generatorSecp256k1.order!,
      length: getPublic().publicKey.point.curve.baselen,
    ));
  }

  ECPrivate negate() {
    // Negate the private key by subtracting from the order of the curve
    return ECPrivate.fromBytes(BigintUtils.toBytes(
      Curves.generatorSecp256k1.order! - BigintUtils.fromBytes(prive.raw),
      length: getPublic().publicKey.point.curve.baselen,
    ));
  }

  ECPrivate clone() {
    return ECPrivate.fromBytes(prive.raw);
  }
}
