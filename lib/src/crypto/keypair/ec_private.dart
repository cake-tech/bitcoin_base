import 'package:bitcoin_base/src/bitcoin/script/op_code/constant.dart';
import 'package:bitcoin_base/src/bitcoin/taproot/taproot.dart';
import 'package:bitcoin_base/src/exception/exception.dart';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'ec_public.dart';

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
    final key = Bip32PrivateKey.fromBytes(prive, Bip32KeyData(),
        Bip32Const.mainNetKeyNetVersions, EllipticCurveTypes.secp256k1);
    return ECPrivate(key);
  }

  /// returns the corresponding ECPublic object
  ECPublic getPublic() =>
      ECPublic.fromHex(BytesUtils.toHexString(prive.publicKey.compressed));

  /// creates an object from a WIF of WIFC format (string)
  factory ECPrivate.fromWif(String wif, {required List<int>? netVersion}) {
    final decode = WifDecoder.decode(wif,
        netVer: netVersion ?? BitcoinNetwork.mainnet.wifNetVer);
    return ECPrivate.fromBytes(decode.item1);
  }

  /// returns as WIFC (compressed) or WIF format (string)
  String toWif(
      {PubKeyModes pubKeyMode = PubKeyModes.compressed,
      BitcoinNetwork network = BitcoinNetwork.mainnet}) {
    return WifEncoder.encode(toBytes(),
        netVer: network.wifNetVer, pubKeyMode: pubKeyMode);
  }

  /// returns the key's raw bytes
  List<int> toBytes() {
    return prive.raw;
  }

  String toHex() {
    return BytesUtils.toHexString(prive.raw);
  }

  /// Returns a Bitcoin compact signature in hex
  String signMessage(List<int> message,
      {String messagePrefix = '\x18Bitcoin Signed Message:\n'}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    final signature = btcSigner.signMessage(message, messagePrefix);
    return BytesUtils.toHexString(signature);
  }

  /// sign transaction digest  and returns the signature.
  String signInput(List<int> txDigest,
      {int? sigHash = BitcoinOpCodeConst.sighashAll}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    List<int> signature = btcSigner.signTransaction(txDigest);
    if (sigHash != null) {
      signature = <int>[...signature, sigHash];
    }
    return BytesUtils.toHexString(signature);
  }

  String signSchnorr(List<int> txDigest,
      {int sighash = BitcoinOpCodeConst.sighashDefault}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    var signature = btcSigner.signSchnorrTransaction(txDigest,
        tapScripts: [], tweak: false);
    if (sighash != BitcoinOpCodeConst.sighashDefault) {
      signature = <int>[...signature, sighash];
    }
    return BytesUtils.toHexString(signature);
  }

  /// Signs a Taproot transaction digest and returns the signature.
  ///
  /// - [txDigest]: The transaction digest to be signed.
  /// - [sighash]: The sighash type (default: `TAPROOT_SIGHASH_ALL`).
  /// - [treeScript]: Taproot script tree for Tweaking with public key.
  /// - [merkleRoot]: Merkle root for the Taproot tree. If provided, this overrides the default computation of the Merkle root from [treeScript].
  /// - [tweak]: If `true`, the internal key is tweaked, either with or without [treeScript] or [merkleRoot], before signing.
  String signTapRoot(List<int> txDigest,
      {int sighash = BitcoinOpCodeConst.sighashDefault,
      TaprootTree? treeScript,
      List<int>? merkleRoot,
      bool tweak = true}) {
    if (!tweak && treeScript != null) {
      throw DartBitcoinPluginException(
          "Invalid parameters: 'tweak' must be true when using 'treeScript'.");
    }
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    List<int> signature = btcSigner.signSchnorrTx(txDigest,
        tweak: tweak
            ? TaprootUtils.calculateTweek(getPublic().toXOnly(),
                treeScript: merkleRoot != null ? null : treeScript,
                merkleRoot: merkleRoot)
            : null);
    if (sighash != BitcoinOpCodeConst.sighashDefault) {
      signature = <int>[...signature, sighash];
    }
    return BytesUtils.toHexString(signature);
  }

  /// Signs a Taproot transaction digest and returns the signature.
  ///
  /// - [txDigest]: The transaction digest to be signed.
  /// - [tweak]: Optional public key tweak to be applied when signing.
  List<int> signBtcSchnorr(List<int> txDigest, {List<int>? tweak}) {
    final btcSigner = BitcoinSigner.fromKeyBytes(toBytes());
    List<int> signature = btcSigner.signSchnorrTx(txDigest, tweak: tweak);
    return signature;
  }

  static ECPrivate random() {
    final secret = QuickCrypto.generateRandom();
    return ECPrivate.fromBytes(secret);
  }
}
