import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/utils.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as fp;

final ECDomainParameters curve = ECCurve_secp256k1();

extension ECUtils on Uint8List {
  ECSignature toECSignature() {
    final sigLength = (this.length / 2).round();
    final r = BigInt.parse(
      SignUtils.getHexString(this, offset: 0, length: sigLength),
      radix: 16,
    );
    final s = BigInt.parse(
      SignUtils.getHexString(this, offset: sigLength, length: sigLength),
      radix: 16,
    );
    return ECSignature(r, s);
  }

  bool isCompressedPoint() => curve.curve.decodePoint(this)!.isCompressed;
}

class SignUtils {
  /// Returns the recovery ID, a byte with value between 0 and 3, inclusive, that specifies which of 4 possible
  /// curve points was used to sign a message. This value is also referred to as "v".
  ///
  /// @throws RuntimeException if no recovery ID can be found.
  static int findRecoveryId(String hash, ECSignature sig, Uint8List pub) {
    var recId = -1;
    final Q = curve.curve.decodePoint(pub);
    for (var i = 0; i < 4; i++) {
      final k = recoverFromSignature(i, sig, hash);
      if (k != null && k == Q) {
        recId = i;
        break;
      }
    }
    if (recId == -1) {
      throw Exception("Could not construct a recoverable key. This should never happen.");
    }
    return recId;
  }

  static String getHexString(
    List<int> list, {
    required int offset,
    required int length,
  }) {
    final sublist = list.getRange(offset, offset + length);
    return [for (var byte in sublist) byte.toRadixString(16).padLeft(2, '0').toUpperCase()].join();
  }

  /// <p>Given the components of a signature and a selector value, recover and return the public key
  /// that generated the signature according to the algorithm in SEC1v2 section 4.1.6.</p>
  ///
  /// <p>The recId is an index from 0 to 3 which indicates which of the 4 possible keys is the correct one. Because
  /// the key recovery operation yields multiple potential keys, the correct key must either be stored alongside the
  /// signature, or you must be willing to try each recId in turn until you find one that outputs the key you are
  /// expecting.</p>
  ///
  /// <p>If this method returns null it means recovery was not possible and recId should be iterated.</p>
  ///
  /// <p>Given the above two points, a correct usage of this method is inside a for loop from 0 to 3, and if the
  /// output is null OR a key that is not the one you expect, you try again with the next recId.</p>
  ///
  /// @param recId Which possible key to recover.
  /// @param sig the R and S components of the signature, wrapped.
  /// @param message Hash of the data that was signed.
  /// @param compressed Whether or not the original pubkey was compressed.
  /// @return An ECKey containing only the public part, or null if recovery wasn't possible.
  static ECPoint? recoverFromSignature(int recId, ECSignature sig, String message) {
    // see https://www.secg.org/sec1-v2.pdf, section 4.1.6
    // 1.0 For j from 0 to h   (h == recId here and the loop is outside this function)
    //   1.1 Let x = r + jn
    final n = curve.n; // Curve order.
    final i = BigInt.from(recId / 2);
    final x = sig.r + (i * n);
    //   1.2. Convert the integer x to an octet string X of length mlen using the conversion routine
    //        specified in Section 2.3.7, where mlen = ⌈(log2 p)/8⌉ or mlen = ⌈m/8⌉.
    //   1.3. Convert the octet string (16 set binary digits)||X to an elliptic curve point R using the
    //        conversion routine specified in Section 2.3.4. If this conversion routine outputs "invalid", then
    //        do another iteration of Step 1.
    //
    // More concisely, what these points mean is to use X as a compressed public key.
    final prime = (curve.curve as fp.ECCurve).q!;
    if (x.compareTo(prime) >= 0) {
      // Cannot have point co-ordinates larger than this as everything takes place modulo Q.
      return null;
    }
    // Compressed keys require you to know an extra bit of data about the y-coord as there are two possibilities.
    // So it's encoded in the recId.
    final R = _decompressKey(x, (recId & 1) == 1);
    //   1.4. If nR != point at infinity, then do another iteration of Step 1 (callers responsibility).
    if (!(R * n)!.isInfinity) return null;
    //   1.5. Compute e from M using Steps 2 and 3 of ECDSA signature verification.
    final e = BigInt.parse(message, radix: 16);
    //   1.6. For k from 1 to 2 do the following.   (loop is outside this function via iterating recId)
    //   1.6.1. Compute a candidate public key as:
    //               Q = mi(r) * (sR - eG)
    //
    // Where mi(x) is the modular multiplicative inverse. We transform this into the following:
    //               Q = (mi(r) * s ** R) + (mi(r) * -e ** G)
    // Where -e is the modular additive inverse of e, that is z such that z + e = 0 (mod n). In the above equation
    // ** is point multiplication and + is point addition (the EC group operator).
    //
    // We can find the additive inverse by subtracting e from zero then taking the mod. For example the additive
    // inverse of 3 modulo 11 is 8 because 3 + 8 mod 11 = 0, and -3 mod 11 = 8.
    final eInv = (BigInt.zero - e) % n;
    final rInv = sig.r.modInverse(n);
    final srInv = (rInv * sig.s) % n;
    final eInvrInv = (rInv * eInv) % n;
    return sumOfTwoMultiplies(curve.G, eInvrInv, R, srInv)!;
  }

  /// Decompress a compressed public key (x co-ord and low-bit of y-coord).
  static ECPoint _decompressKey(BigInt xBN, bool yBit) {
    final curveByteLength = ((curve.curve.fieldSize + 7) ~/ 8);
    final compEnc = _x9IntegerToBytes(xBN, 1 + curveByteLength);
    compEnc[0] = (yBit ? 0x03 : 0x02);
    return curve.curve.decodePoint(compEnc)!;
  }

// Extracted from pointycastle/lib/ecc/ecc_fp.dart
  static Uint8List _x9IntegerToBytes(BigInt? s, int qLength) {
    var bytes = Uint8List.fromList(encodeBigInt(s));

    if (qLength < bytes.length) {
      return bytes.sublist(bytes.length - qLength);
    } else if (qLength > bytes.length) {
      return Uint8List(qLength)..setAll(qLength - bytes.length, bytes);
    }

    return bytes;
  }

  // Extracted from pointycastle/lib/signers/ecdsa_signer.dart
  static ECPoint? sumOfTwoMultiplies(ECPoint P, BigInt a, ECPoint Q, BigInt b) {
    var c = P.curve;

    if (c != Q.curve) {
      throw ArgumentError('P and Q must be on same curve');
    }

    // Point multiplication for Koblitz curves (using WTNAF) beats Shamir's trick
    // TODO: uncomment this when F2m available
    /*
    if( c is ECCurve.F2m ) {
      ECCurve.F2m f2mCurve = (ECCurve.F2m)c;
      if( f2mCurve.isKoblitz() ) {
        return P.multiply(a).add(Q.multiply(b));
      }
    }
    */

    return _implShamirsTrick(P, a, Q, b);
  }

  // Extracted from pointycastle/lib/signers/ecdsa_signer.dart
  static ECPoint? _implShamirsTrick(ECPoint P, BigInt k, ECPoint Q, BigInt l) {
    var m = max(k.bitLength, l.bitLength);

    var Z = P + Q;
    var R = P.curve.infinity;

    for (var i = m - 1; i >= 0; --i) {
      R = R!.twice();

      if (_testBit(k, i)) {
        if (_testBit(l, i)) {
          R = R! + Z;
        } else {
          R = R! + P;
        }
      } else {
        if (_testBit(l, i)) {
          R = R! + Q;
        }
      }
    }

    return R;
  }

  // Extracted from pointycastle/lib/signers/ecdsa_signer.dart
  static bool _testBit(BigInt i, int n) => (i & (BigInt.one << n)) != BigInt.zero;
}
